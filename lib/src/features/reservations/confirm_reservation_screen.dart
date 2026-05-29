import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';

import 'package:reservpy/src/shared/models/models.dart';
import 'package:reservpy/src/shared/models/category_fields.dart';
import 'package:reservpy/src/shared/providers/providers.dart';
import 'package:reservpy/src/core/widgets/widgets.dart';
import 'package:reservpy/src/core/constants/app_sizes.dart';
import 'package:reservpy/src/core/constants/app_strings.dart';
import 'package:reservpy/src/core/utils/date_utils.dart';
import 'package:reservpy/src/data/repositories/reservation_repository.dart';
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
