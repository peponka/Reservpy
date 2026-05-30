import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';

import 'package:reservpy/src/shared/models/models.dart';
import 'package:reservpy/src/shared/models/employee.dart';
import 'package:reservpy/src/shared/models/category_fields.dart';
import 'package:reservpy/src/shared/providers/providers.dart';
import 'package:reservpy/src/core/widgets/widgets.dart';
import 'package:reservpy/src/core/constants/app_sizes.dart';
import 'package:reservpy/src/core/constants/app_strings.dart';
import 'package:reservpy/src/core/utils/date_utils.dart';
import 'package:reservpy/src/data/repositories/reservation_repository.dart';
import 'package:reservpy/src/data/repositories/notification_repository.dart';
import 'package:reservpy/src/data/repositories/profile_repository.dart';
import 'package:reservpy/src/data/services/email_service.dart';

const _uuid = Uuid();

/// Confirm reservation screen. Shows a summary of the booking and lets the
/// user add optional notes before confirming.
class ConfirmReservationScreen extends ConsumerStatefulWidget {
  final String businessId;
  final String serviceId;
  final DateTime selectedTime;

  const ConfirmReservationScreen({
    super.key,
    required this.businessId,
    required this.serviceId,
    required this.selectedTime,
  });

  @override
  ConsumerState<ConfirmReservationScreen> createState() =>
      _ConfirmReservationScreenState();
}

class _ConfirmReservationScreenState
    extends ConsumerState<ConfirmReservationScreen> {
  final _notesController = TextEditingController();
  bool _isSubmitting = false;
  final Map<String, dynamic> _fieldValues = {};
  final Map<String, TextEditingController> _fieldControllers = {};

  // Recurring reservation
  bool _isRecurring = false;
  String _recurrenceType = 'weekly'; // weekly, biweekly, monthly
  int _recurrenceCount = 3;
  Employee? _selectedEmployee;

  @override
  void dispose() {
    _notesController.dispose();
    for (final c in _fieldControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  TextEditingController _getController(String key) {
    return _fieldControllers.putIfAbsent(key, () => TextEditingController());
  }

  String _serializeFields(List<CategoryField> fields) {
    final data = <String, dynamic>{};
    for (final field in fields) {
      final value = _fieldValues[field.key];
      if (value == null) continue;
      if (value is List && value.isEmpty) continue;
      if (value is String && value.isEmpty) continue;
      data[field.key] = value;
    }
    final extraNotes = _notesController.text.trim();
    if (extraNotes.isNotEmpty) data['notes'] = extraNotes;
    if (data.isEmpty) return '';
    return jsonEncode(data);
  }

  Future<void> _confirmReservation() async {
    final user = ref.read(currentUserProvider);

    if (user == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tenés que iniciar sesión para reservar'),
            backgroundColor: Color(0xFFE53E3E),
          ),
        );
      }
      return;
    }
    final businesses = ref.read(businessesProvider).value ?? [];
    final services = ref.read(businessServicesProvider(widget.businessId)).value ?? [];

    final business =
        businesses.where((b) => b.id == widget.businessId).firstOrNull;
    final service =
        services.where((s) => s.id == widget.serviceId).firstOrNull;

    if (business == null || service == null) return;

    setState(() => _isSubmitting = true);

    final endTime =
        widget.selectedTime.add(Duration(minutes: service.durationMinutes));

    final reservation = Reservation(
      id: _uuid.v4(),
      businessId: widget.businessId,
      clientId: user.id,
      serviceId: widget.serviceId,
      startTime: widget.selectedTime,
      endTime: endTime,
      status: ReservationStatus.pending,
      notes: () {
          final cats = ref.read(categoriesProvider).value ?? [];
          final catName = cats.isEmpty
              ? 'Otros'
              : cats.firstWhere(
                  (c) => c.id == business.categoryId,
                  orElse: () => cats.first,
                ).name;
          final fields = getFieldsForCategory(catName);
          final serialized = _serializeFields(fields);
          return serialized.isNotEmpty ? serialized : null;
        }(),
      createdAt: DateTime.now(),
      clientName: user.fullName,
      serviceName: service.name,
      businessName: business.name,
      employeeId: _selectedEmployee?.id,
      employeeName: _selectedEmployee?.name,
    );

    // Re-verify slot availability before creating (prevent race condition)
    try {
      final isAvailable = await ReservationRepository().isSlotAvailable(
        widget.businessId,
        widget.selectedTime,
        endTime,
      );
      if (!isAvailable) {
        if (mounted) {
          setState(() => _isSubmitting = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Este horario ya fue reservado. Elegí otro.'),
              backgroundColor: Color(0xFFE53E3E),
            ),
          );
        }
        return;
      }

      await ReservationRepository().create(reservation);

      // Create recurring reservations if enabled
      if (_isRecurring) {
        for (int i = 1; i <= _recurrenceCount; i++) {
          final offset = _recurrenceType == 'weekly'
              ? Duration(days: 7 * i)
              : _recurrenceType == 'biweekly'
                  ? Duration(days: 14 * i)
                  : Duration(days: 0); // monthly handled below

          DateTime nextStart;
          if (_recurrenceType == 'monthly') {
            nextStart = DateTime(
              widget.selectedTime.year,
              widget.selectedTime.month + i,
              widget.selectedTime.day,
              widget.selectedTime.hour,
              widget.selectedTime.minute,
            );
          } else {
            nextStart = widget.selectedTime.add(offset);
          }
          final nextEnd = nextStart.add(Duration(minutes: service.durationMinutes));

          final recRes = Reservation(
            id: _uuid.v4(),
            businessId: widget.businessId,
            clientId: user.id,
            serviceId: widget.serviceId,
            startTime: nextStart,
            endTime: nextEnd,
            status: ReservationStatus.pending,
            notes: reservation.notes,
            createdAt: DateTime.now(),
            clientName: user.fullName,
            serviceName: service.name,
            businessName: business.name,
            employeeId: _selectedEmployee?.id,
            employeeName: _selectedEmployee?.name,
          );
          // Best-effort: skip unavailable slots silently
          try {
            final avail = await ReservationRepository().isSlotAvailable(
              widget.businessId, nextStart, nextEnd,
            );
            if (avail) await ReservationRepository().create(recRes);
          } catch (_) {}
        }
      }
      ref.invalidate(businessReservationsProvider);
      ref.invalidate(clientReservationsProvider);

      // ── Send confirmation emails to client + business (fire-and-forget) ──
      final clientEmail = user.email;
      if (clientEmail.isNotEmpty) {
        // Email al cliente
        EmailService.enviarEmailConfirmacionTurnoCliente(
          clientEmail: clientEmail,
          clientName: user.fullName,
          businessName: business.name,
          serviceName: service.name,
          startTime: widget.selectedTime,
          address: business.address,
          notes: reservation.notes,
        );
      }
      // ── Notify business owner (fire-and-forget) ──
      NotificationRepository().create(
        userId: business.ownerId,
        businessId: business.id,
        type: NotificationType.newReservation,
        title: 'Nueva reserva',
        body: '${user.fullName} reservó ${service.name} para el ${DateFormat('dd/MM HH:mm', 'es').format(widget.selectedTime)}',
        reservationId: reservation.id,
      ).catchError((_) {});

      // Email al negocio
      ProfileRepository().getProfile(business.ownerId).then((owner) {
        if (owner != null && owner.email.isNotEmpty) {
          EmailService.enviarEmailConfirmacionTurnoNegocio(
            businessEmail: owner.email,
            businessName: business.name,
            clientName: user.fullName,
            serviceName: service.name,
            startTime: widget.selectedTime,
            notes: reservation.notes,
          );
        }
      }).catchError((_) {});
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al crear reserva: $e')),
        );
        return;
      }
    }

    // Navigate to success screen
    if (mounted) {
      context.go(
        '/reservation-success'
        '?businessName=${Uri.encodeComponent(business.name)}'
        '&serviceName=${Uri.encodeComponent(service.name)}'
        '&date=${Uri.encodeComponent(widget.selectedTime.toIso8601String())}'
        '&endDate=${Uri.encodeComponent(endTime.toIso8601String())}',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final businesses = ref.watch(businessesProvider).value ?? [];
    final services = ref.watch(businessServicesProvider(widget.businessId)).value ?? [];

    final business =
        businesses.where((b) => b.id == widget.businessId).firstOrNull;
    final service =
        services.where((s) => s.id == widget.serviceId).firstOrNull;

    if (business == null || service == null) {
      return Scaffold(
        appBar: AppBar(title: const Text(AppStrings.confirmReservation)),
        body: const EmptyState(
          icon: Icons.error_outline_rounded,
          title: 'Datos no encontrados',
        ),
      );
    }

    final categories = ref.watch(categoriesProvider).value ?? [];
    final category = categories.isEmpty
        ? BusinessCategory(id: '', name: '...', icon: Icons.category, color: Colors.grey)
        : categories.firstWhere(
            (c) => c.id == business.categoryId,
            orElse: () => categories.first,
          );
    final endTime =
        widget.selectedTime.add(Duration(minutes: service.durationMinutes));

    // Format date nicely: "Lunes 26 de Mayo"
    final dayName = DateFormat('EEEE', 'es').format(widget.selectedTime);
    final capitalizedDay = dayName[0].toUpperCase() + dayName.substring(1);
    final dayMonth = AppDateUtils.formatDayMonth(widget.selectedTime);
    final formattedDate = '$capitalizedDay, $dayMonth';
    final timeRange = AppDateUtils.formatTimeRange(widget.selectedTime, endTime);

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.confirmReservation),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSizes.s24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Title
            Text(
              'Revisá tu reserva',
              style: theme.textTheme.headlineMedium,
            ),

            const SizedBox(height: AppSizes.s6),

            Text(
              'Verificá los datos antes de confirmar',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),

            const SizedBox(height: AppSizes.s24),

            // ── Summary Card ──
            AppCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  // Business header
                  Container(
                    padding: const EdgeInsets.all(AppSizes.s20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          category.color.withValues(alpha: 0.1),
                          category.color.withValues(alpha: 0.03),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(AppSizes.radiusMd),
                        topRight: Radius.circular(AppSizes.radiusMd),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: theme.cardTheme.color,
                            borderRadius:
                                BorderRadius.circular(AppSizes.radiusMd),
                            boxShadow: [
                              BoxShadow(
                                color:
                                    category.color.withValues(alpha: 0.25),
                                blurRadius: 8,
                              ),
                            ],
                          ),
                          child: Icon(
                            category.icon,
                            color: category.color,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: AppSizes.s16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                business.name,
                                style: theme.textTheme.titleLarge,
                              ),
                              const SizedBox(height: AppSizes.s2),
                              Text(
                                category.name,
                                style:
                                    theme.textTheme.bodySmall?.copyWith(
                                  color: category.color,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const Divider(height: 1),

                  // Service row
                  _SummaryRow(
                    icon: Icons.spa_rounded,
                    iconColor: theme.colorScheme.primary,
                    label: 'Servicio',
                    value: service.name,
                    trailing: service.formattedDuration,
                  ),

                  Divider(
                    height: 1,
                    indent: AppSizes.s56,
                    color: theme.colorScheme.outline.withValues(alpha: 0.15),
                  ),

                  // Date row
                  _SummaryRow(
                    icon: Icons.calendar_today_rounded,
                    iconColor: theme.colorScheme.secondary,
                    label: 'Fecha',
                    value: formattedDate,
                  ),

                  Divider(
                    height: 1,
                    indent: AppSizes.s56,
                    color: theme.colorScheme.outline.withValues(alpha: 0.15),
                  ),

                  // Time row
                  _SummaryRow(
                    icon: Icons.schedule_rounded,
                    iconColor: Colors.deepOrange,
                    label: 'Horario',
                    value: timeRange,
                  ),

                  Divider(
                    height: 1,
                    indent: AppSizes.s56,
                    color: theme.colorScheme.outline.withValues(alpha: 0.15),
                  ),

                  // Price row
                  _SummaryRow(
                    icon: Icons.payments_rounded,
                    iconColor: Colors.amber.shade700,
                    label: 'Precio',
                    value: service.formattedPrice,
                    isHighlighted: true,
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppSizes.s24),

            // ── Category-Specific Fields ──
            Builder(
              builder: (context) {
                final catName = category.name;
                final fields = getFieldsForCategory(catName);
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.assignment_rounded, size: 20, color: category.color),
                        const SizedBox(width: 8),
                        Text(
                          'Datos para tu reserva',
                          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Completá los campos para que el negocio pueda atenderte mejor',
                      style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline),
                    ),
                    const SizedBox(height: AppSizes.s16),
                    ...fields.map((field) => _buildCategoryField(theme, field, category.color)),
                  ],
                );
              },
            ),

            const SizedBox(height: AppSizes.s16),

            // ── Extra Notes ──
            Text(
              'Notas adicionales (opcional)',
              style: theme.textTheme.titleSmall,
            ),
            const SizedBox(height: AppSizes.s8),
            AppTextField(
              controller: _notesController,
              hint: 'Algo más que quieras agregar...',
              prefixIcon: Icons.notes_rounded,
              maxLines: 2,
            ),

            const SizedBox(height: AppSizes.s24),

            // ── Employee Selector ──
            Consumer(
              builder: (context, ref, _) {
                final employees = ref.watch(employeesProvider).value ?? [];
                final activeEmployees = employees.where((e) => e.isActive).toList();
                if (activeEmployees.isEmpty) return const SizedBox.shrink();

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '¿Con quién preferís?',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Elegí un profesional (opcional)',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.outline,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        // "Sin preferencia" chip
                        ChoiceChip(
                          label: Text('Sin preferencia',
                              style: TextStyle(
                                fontWeight: _selectedEmployee == null
                                    ? FontWeight.w700
                                    : FontWeight.w400,
                                fontSize: 13,
                              )),
                          selected: _selectedEmployee == null,
                          selectedColor: theme.colorScheme.primary.withValues(alpha: 0.12),
                          checkmarkColor: theme.colorScheme.primary,
                          side: BorderSide(
                            color: _selectedEmployee == null
                                ? theme.colorScheme.primary
                                : theme.colorScheme.outline.withValues(alpha: 0.2),
                          ),
                          onSelected: (_) => setState(() => _selectedEmployee = null),
                        ),
                        ...activeEmployees.map((emp) {
                          final isSelected = _selectedEmployee?.id == emp.id;
                          return ChoiceChip(
                            avatar: CircleAvatar(
                              backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.2),
                              radius: 12,
                              child: Text(emp.initials,
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: theme.colorScheme.primary,
                                  )),
                            ),
                            label: Text(emp.name,
                                style: TextStyle(
                                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
                                  fontSize: 13,
                                )),
                            selected: isSelected,
                            selectedColor: theme.colorScheme.primary.withValues(alpha: 0.12),
                            checkmarkColor: theme.colorScheme.primary,
                            side: BorderSide(
                              color: isSelected
                                  ? theme.colorScheme.primary
                                  : theme.colorScheme.outline.withValues(alpha: 0.2),
                            ),
                            onSelected: (_) => setState(() => _selectedEmployee = emp),
                          );
                        }),
                      ],
                    ),
                    const SizedBox(height: AppSizes.s16),
                  ],
                );
              },
            ),

            // ── Recurring Toggle ──
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _isRecurring
                    ? theme.colorScheme.primary.withValues(alpha: 0.04)
                    : theme.cardTheme.color,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: _isRecurring
                      ? theme.colorScheme.primary.withValues(alpha: 0.2)
                      : theme.colorScheme.outline.withValues(alpha: 0.1),
                ),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(Icons.repeat_rounded, size: 20,
                          color: _isRecurring
                              ? theme.colorScheme.primary
                              : theme.colorScheme.outline),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Repetir turno',
                                style: theme.textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w700)),
                            Text('Reservar automáticamente las próximas semanas',
                                style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.outline)),
                          ],
                        ),
                      ),
                      Switch.adaptive(
                        value: _isRecurring,
                        onChanged: (v) => setState(() => _isRecurring = v),
                      ),
                    ],
                  ),
                  if (_isRecurring) ...[
                    const SizedBox(height: 16),
                    // Type selector
                    Row(
                      children: [
                        _RecurrenceChip(
                          label: 'Semanal',
                          selected: _recurrenceType == 'weekly',
                          onTap: () => setState(() => _recurrenceType = 'weekly'),
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        _RecurrenceChip(
                          label: 'Quincenal',
                          selected: _recurrenceType == 'biweekly',
                          onTap: () => setState(() => _recurrenceType = 'biweekly'),
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        _RecurrenceChip(
                          label: 'Mensual',
                          selected: _recurrenceType == 'monthly',
                          onTap: () => setState(() => _recurrenceType = 'monthly'),
                          color: theme.colorScheme.primary,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Count selector
                    Row(
                      children: [
                        Text('Repeticiones:',
                            style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600)),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.remove_circle_outline_rounded, size: 24),
                          onPressed: _recurrenceCount > 2
                              ? () => setState(() => _recurrenceCount--)
                              : null,
                        ),
                        Text('$_recurrenceCount',
                            style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w800)),
                        IconButton(
                          icon: const Icon(Icons.add_circle_outline_rounded, size: 24),
                          onPressed: _recurrenceCount < 8
                              ? () => setState(() => _recurrenceCount++)
                              : null,
                        ),
                      ],
                    ),
                    // Preview dates
                    const SizedBox(height: 8),
                    ...List.generate(_recurrenceCount, (i) {
                      DateTime nextDate;
                      if (_recurrenceType == 'weekly') {
                        nextDate = widget.selectedTime.add(Duration(days: 7 * (i + 1)));
                      } else if (_recurrenceType == 'biweekly') {
                        nextDate = widget.selectedTime.add(Duration(days: 14 * (i + 1)));
                      } else {
                        nextDate = DateTime(
                          widget.selectedTime.year,
                          widget.selectedTime.month + (i + 1),
                          widget.selectedTime.day,
                          widget.selectedTime.hour,
                          widget.selectedTime.minute,
                        );
                      }
                      final dayName = DateFormat('EEEE', 'es').format(nextDate);
                      final cap = dayName[0].toUpperCase() + dayName.substring(1);
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          children: [
                            Icon(Icons.event_rounded, size: 14,
                                color: theme.colorScheme.primary.withValues(alpha: 0.6)),
                            const SizedBox(width: 8),
                            Text(
                              '$cap ${DateFormat('dd/MM').format(nextDate)} - ${DateFormat('HH:mm').format(nextDate)}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.outline),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ],
              ),
            ),

            const SizedBox(height: AppSizes.s32),

            // ── Confirm button ──
            AppButton(
              label: AppStrings.confirmReservation,
              icon: Icons.check_circle_outline_rounded,
              isLoading: _isSubmitting,
              onPressed: _isSubmitting ? null : _confirmReservation,
            ),

            const SizedBox(height: AppSizes.s16),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryField(ThemeData theme, CategoryField field, Color accentColor) {
    final label = '${field.label}${field.required ? ' *' : ''}';

    switch (field.type) {
      case CategoryFieldType.text:
      case CategoryFieldType.number:
      case CategoryFieldType.phone:
        final ctrl = _getController(field.key);
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: TextField(
            controller: ctrl,
            keyboardType: field.type == CategoryFieldType.number
                ? TextInputType.number
                : field.type == CategoryFieldType.phone
                    ? TextInputType.phone
                    : TextInputType.text,
            decoration: InputDecoration(
              labelText: label,
              hintText: field.hint,
              filled: true,
              fillColor: theme.colorScheme.surface,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: theme.colorScheme.outline.withValues(alpha: 0.2)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: accentColor, width: 2),
              ),
            ),
            onChanged: (v) => _fieldValues[field.key] = v,
          ),
        );

      case CategoryFieldType.textarea:
        final ctrl = _getController(field.key);
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: TextField(
            controller: ctrl,
            maxLines: 3,
            decoration: InputDecoration(
              labelText: label,
              hintText: field.hint,
              filled: true,
              fillColor: theme.colorScheme.surface,
              alignLabelWithHint: true,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: theme.colorScheme.outline.withValues(alpha: 0.2)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: accentColor, width: 2),
              ),
            ),
            onChanged: (v) => _fieldValues[field.key] = v,
          ),
        );

      case CategoryFieldType.select:
        final current = _fieldValues[field.key] as String?;
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: (field.options ?? []).map((opt) {
                  final selected = current == opt;
                  return ChoiceChip(
                    label: Text(opt, style: TextStyle(fontSize: 13, fontWeight: selected ? FontWeight.w600 : FontWeight.w400)),
                    selected: selected,
                    selectedColor: accentColor.withValues(alpha: 0.15),
                    side: BorderSide(color: selected ? accentColor : theme.colorScheme.outline.withValues(alpha: 0.2)),
                    onSelected: (v) => setState(() => _fieldValues[field.key] = v ? opt : null),
                  );
                }).toList(),
              ),
            ],
          ),
        );

      case CategoryFieldType.multiSelect:
        final current = (_fieldValues[field.key] as List<String>?) ?? [];
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: (field.options ?? []).map((opt) {
                  final selected = current.contains(opt);
                  return FilterChip(
                    label: Text(opt, style: TextStyle(fontSize: 13, fontWeight: selected ? FontWeight.w600 : FontWeight.w400)),
                    selected: selected,
                    selectedColor: accentColor.withValues(alpha: 0.15),
                    checkmarkColor: accentColor,
                    side: BorderSide(color: selected ? accentColor : theme.colorScheme.outline.withValues(alpha: 0.2)),
                    onSelected: (v) {
                      setState(() {
                        final list = List<String>.from(current);
                        if (v) { list.add(opt); } else { list.remove(opt); }
                        _fieldValues[field.key] = list;
                      });
                    },
                  );
                }).toList(),
              ),
            ],
          ),
        );

      case CategoryFieldType.toggle:
        final current = _fieldValues[field.key] as bool? ?? (field.defaultValue == 'true');
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            children: [
              Expanded(child: Text(label, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600))),
              Switch.adaptive(
                value: current,
                activeThumbColor: accentColor,
                onChanged: (v) => setState(() => _fieldValues[field.key] = v),
              ),
            ],
          ),
        );

      case CategoryFieldType.date:
        final current = _fieldValues[field.key] as String?;
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: DateTime.now().add(const Duration(days: 7)),
                firstDate: DateTime.now(),
                lastDate: DateTime.now().add(const Duration(days: 365)),
              );
              if (picked != null) {
                setState(() => _fieldValues[field.key] = DateFormat('dd/MM/yyyy').format(picked));
              }
            },
            child: InputDecorator(
              decoration: InputDecoration(
                labelText: label,
                filled: true,
                fillColor: theme.colorScheme.surface,
                suffixIcon: Icon(Icons.calendar_today_rounded, color: accentColor, size: 20),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: theme.colorScheme.outline.withValues(alpha: 0.2)),
                ),
              ),
              child: Text(
                current ?? 'Seleccionar fecha',
                style: TextStyle(color: current != null ? null : theme.colorScheme.outline),
              ),
            ),
          ),
        );
    }
  }
}

/// A single row in the summary card.
class _SummaryRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  final String? trailing;
  final bool isHighlighted;

  const _SummaryRow({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    this.trailing,
    this.isHighlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.s20,
        vertical: AppSizes.s16,
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppSizes.radiusSm),
            ),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          const SizedBox(width: AppSizes.s16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.outline,
                  ),
                ),
                const SizedBox(height: AppSizes.s2),
                Text(
                  value,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight:
                        isHighlighted ? FontWeight.w700 : FontWeight.w600,
                    color: isHighlighted
                        ? theme.colorScheme.primary
                        : null,
                  ),
                ),
              ],
            ),
          ),
          if (trailing != null)
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.s8,
                vertical: AppSizes.s4,
              ),
              decoration: BoxDecoration(
                color: theme.colorScheme.outline.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(AppSizes.radiusFull),
              ),
              child: Text(
                trailing!,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.outline,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Chip for selecting recurrence type (weekly/biweekly/monthly).
class _RecurrenceChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color color;

  const _RecurrenceChip({
    required this.label,
    required this.selected,
    required this.onTap,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? color.withValues(alpha: 0.1) : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected ? color : Theme.of(context).colorScheme.outline.withValues(alpha: 0.15),
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              color: selected ? color : Theme.of(context).colorScheme.outline,
            ),
          ),
        ),
      ),
    );
  }
}
