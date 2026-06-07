import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import 'package:reservpy/src/shared/models/models.dart';
import 'package:reservpy/src/shared/providers/providers.dart';
import 'package:reservpy/src/core/widgets/widgets.dart';
import 'package:reservpy/src/core/constants/app_colors.dart';
import 'package:reservpy/src/core/constants/app_sizes.dart';
import 'package:reservpy/src/core/constants/app_strings.dart';
import 'package:reservpy/src/core/utils/date_utils.dart';
import 'package:reservpy/src/data/repositories/reservation_repository.dart';
import 'package:reservpy/src/data/repositories/blocked_slot_repository.dart';
import 'package:reservpy/src/data/repositories/profile_repository.dart';
import 'package:reservpy/src/core/utils/whatsapp_helper.dart';
import 'package:reservpy/src/data/services/email_service.dart';

const _uuid = Uuid();

/// Business owner's calendar view with Day/Week toggle.
class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

enum _CalView { day, week, month }

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  /// Vista actual del calendario: día, semana o mes.
  _CalView _view = _CalView.day;

  // Helpers para mantener compatibilidad con el código existente
  bool get _isDayView => _view == _CalView.day;
  bool get _isWeekView => _view == _CalView.week;
  bool get _isMonthView => _view == _CalView.month;

  /// Currently selected date.
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedDate = DateTime(now.year, now.month, now.day);
  }

  /// Generates the 7-day range starting from Monday of the selected week.
  List<DateTime> get _weekDays {
    final monday = _selectedDate.subtract(Duration(days: _selectedDate.weekday - 1));
    return List.generate(
      7,
      (i) => DateTime(monday.year, monday.month, monday.day + i),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final business = ref.watch(currentBusinessProvider);
    final reservations = ref.watch(businessReservationsProvider).value ?? [];
    final blockedSlots = ref.watch(blockedSlotsProvider).value ?? [];

    // Filter blocked slots for current business
    final businessBlocked = blockedSlots
        .where((b) => b.businessId == (business?.id ?? ''))
        .toList();

    return LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
          children: [
            Column(
              children: [
            // ── Header ──
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSizes.s24,
                AppSizes.s20,
                AppSizes.s24,
                AppSizes.s4,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Fila 1: título + botón "Hoy" (lo que SIEMPRE entra)
                  Row(
                    children: [
                      Text(
                        AppStrings.calendar,
                        style: theme.textTheme.headlineLarge,
                      ),
                      const SizedBox(width: AppSizes.s12),
                      if (!AppDateUtils.isToday(_selectedDate))
                        SizedBox(
                          height: 32,
                          child: OutlinedButton(
                            onPressed: () {
                              final now = DateTime.now();
                              setState(() => _selectedDate =
                                  DateTime(now.year, now.month, now.day));
                            },
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.primary,
                              side: const BorderSide(
                                  color: AppColors.primary, width: 1.5),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(AppSizes.radiusMd),
                              ),
                            ),
                            child: Text(
                              'Hoy',
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: AppSizes.s12),
                  // Fila 2: toggle Día / Semana / Mes (siempre cabe)
                  SizedBox(
                    width: double.infinity,
                    child: SegmentedButton<_CalView>(
                      segments: const [
                        ButtonSegment(
                          value: _CalView.day,
                          label: Text('Día'),
                          icon: Icon(Icons.view_day_rounded, size: 18),
                        ),
                        ButtonSegment(
                          value: _CalView.week,
                          label: Text('Semana'),
                          icon: Icon(Icons.view_week_rounded, size: 18),
                        ),
                        ButtonSegment(
                          value: _CalView.month,
                          label: Text('Mes'),
                          icon: Icon(Icons.calendar_month_rounded, size: 18),
                        ),
                      ],
                      selected: {_view},
                      onSelectionChanged: (selection) {
                        setState(() => _view = selection.first);
                      },
                      style: ButtonStyle(
                        visualDensity: VisualDensity.compact,
                        textStyle: WidgetStatePropertyAll(
                          theme.textTheme.labelMedium,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppSizes.s8),

            // ── Date Selector Row ──
            SizedBox(
              height: 80,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding:
                    const EdgeInsets.symmetric(horizontal: AppSizes.s16),
                itemCount: _weekDays.length,
                itemBuilder: (context, index) {
                  final day = _weekDays[index];
                  final isSelected =
                      day.year == _selectedDate.year &&
                          day.month == _selectedDate.month &&
                          day.day == _selectedDate.day;
                  final isToday = AppDateUtils.isToday(day);

                  return _DayChip(
                    date: day,
                    isSelected: isSelected,
                    isToday: isToday,
                    reservationCount: _countReservationsForDay(
                        day, reservations),
                    onTap: () {
                      setState(() => _selectedDate = day);
                    },
                  );
                },
              ),
            ),

            const SizedBox(height: AppSizes.s8),

            // ── Day Summary Bar ──
            if (_isDayView)
              _buildDaySummary(theme, reservations),

            // ── View Content ──
            Expanded(
              child: AnimatedSwitcher(
                duration:
                    const Duration(milliseconds: AppSizes.animNormal),
                switchInCurve: Curves.easeInOut,
                switchOutCurve: Curves.easeInOut,
                child: _isDayView
                    ? _DayView(
                        key: ValueKey('day-${_selectedDate.toIso8601String()}'),
                        selectedDate: _selectedDate,
                        business: business,
                        reservations: reservations,
                        blockedSlots: businessBlocked,
                      )
                    : _isWeekView
                        ? _WeekView(
                            key: const ValueKey('week'),
                            weekDays: _weekDays,
                            selectedDate: _selectedDate,
                            reservations: reservations,
                            onDayTap: (day) {
                              setState(() {
                                _selectedDate = day;
                                _view = _CalView.day;
                              });
                            },
                          )
                        : _MonthView(
                            key: ValueKey(
                                'month-${_selectedDate.year}-${_selectedDate.month}'),
                            selectedDate: _selectedDate,
                            onDayTap: (day) =>
                                _showMonthDaySheet(day, reservations),
                          ),
              ),
            ),
          ],
        ),

        // ── FABs overlay (solo en vista Día) ──
        if (_isDayView)
          Positioned(
            right: AppSizes.s24,
            bottom: AppSizes.s24,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Mini-FAB: bloquear horario
                FloatingActionButton.small(
                  heroTag: 'calendar_fab_block',
                  backgroundColor:
                      Theme.of(context).colorScheme.surface,
                  foregroundColor:
                      Theme.of(context).colorScheme.onSurface,
                  elevation: 2,
                  onPressed: () =>
                      _showBlockTimeDialog(context, ref, business),
                  child: const Icon(Icons.block_rounded, size: 20),
                ),
                const SizedBox(height: AppSizes.s12),
                // FAB principal: agregar turno manual
                FloatingActionButton.extended(
                  heroTag: 'calendar_fab_add',
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  onPressed: () => _showManualReservationForm(_selectedDate),
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Agregar turno'),
                ),
              ],
            ),
          ),
        ],
      );
      },
    );
  }

  int _countReservationsForDay(
      DateTime day, List<Reservation> reservations) {
    final dayStart = DateTime(day.year, day.month, day.day);
    final dayEnd = dayStart.add(const Duration(days: 1));
    return reservations
        .where((r) =>
            r.status != ReservationStatus.cancelled &&
            r.startTime.isAfter(dayStart.subtract(const Duration(seconds: 1))) &&
            r.startTime.isBefore(dayEnd))
        .length;
  }

  /// Abre un popup (bottom sheet) al tocar un día en la vista Mes.
  /// Muestra las reservas de ese día y permite ir a la agenda o bloquear horario.
  void _showMonthDaySheet(
    DateTime day,
    List<Reservation> allReservations,
  ) {
    final dayReservations = allReservations.where((r) {
      return r.startTime.year == day.year &&
          r.startTime.month == day.month &&
          r.startTime.day == day.day;
    }).toList()
      ..sort((a, b) => a.startTime.compareTo(b.startTime));

    final df = DateFormat('EEEE d \'de\' MMMM', 'es');
    final dayLabel = df.format(day);
    final capitalized = dayLabel[0].toUpperCase() + dayLabel.substring(1);

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) {
        final theme = Theme.of(sheetCtx);
        return DraggableScrollableSheet(
          initialChildSize: 0.55,
          minChildSize: 0.3,
          maxChildSize: 0.9,
          expand: false,
          builder: (_, scrollController) {
            return Container(
              decoration: BoxDecoration(
                color: theme.scaffoldBackgroundColor,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
              ),
              child: Column(
                children: [
                  // Handle bar
                  Container(
                    margin: const EdgeInsets.only(top: 10, bottom: 8),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.outline.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  // Header con la fecha
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                            child: Text(
                              '${day.day}',
                              style: GoogleFonts.inter(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                capitalized,
                                style: GoogleFonts.inter(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                dayReservations.isEmpty
                                    ? 'Sin reservas'
                                    : '${dayReservations.length} reserva${dayReservations.length == 1 ? '' : 's'}',
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  color: theme.colorScheme.onSurface
                                      .withValues(alpha: 0.55),
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded),
                          onPressed: () => Navigator.of(sheetCtx).pop(),
                        ),
                      ],
                    ),
                  ),
                  Divider(
                    height: 1,
                    color: theme.colorScheme.outline.withValues(alpha: 0.1),
                  ),
                  // Lista de reservas o estado vacío
                  Expanded(
                    child: dayReservations.isEmpty
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.event_available_rounded,
                                    size: 48,
                                    color: theme.colorScheme.outline
                                        .withValues(alpha: 0.4),
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    'No hay reservas en este día',
                                    style: GoogleFonts.inter(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: theme.colorScheme.onSurface
                                          .withValues(alpha: 0.55),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : ListView.separated(
                            controller: scrollController,
                            padding: const EdgeInsets.all(16),
                            itemCount: dayReservations.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(height: 8),
                            itemBuilder: (_, i) {
                              final r = dayReservations[i];
                              final timeStr = DateFormat('HH:mm').format(
                                r.startTime,
                              );
                              return Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: theme.cardTheme.color,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: theme.colorScheme.outline
                                        .withValues(alpha: 0.1),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 4,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        color: AppColors.primary,
                                        borderRadius:
                                            BorderRadius.circular(2),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            timeStr,
                                            style: GoogleFonts.inter(
                                              fontSize: 15,
                                              fontWeight: FontWeight.w700,
                                              color: AppColors.primary,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            'Reserva',
                                            style: GoogleFonts.inter(
                                              fontSize: 13,
                                              color: theme.colorScheme.onSurface
                                                  .withValues(alpha: 0.7),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                  ),
                  // Botones de acción al pie
                  SafeArea(
                    top: false,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // CTA principal: agregar turno manual
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton.icon(
                              onPressed: () {
                                Navigator.of(sheetCtx).pop();
                                _showManualReservationForm(day);
                              },
                              icon: const Icon(Icons.add_rounded, size: 20),
                              label: const Text('Agregar turno'),
                              style: FilledButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                padding: const EdgeInsets.symmetric(
                                    vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                textStyle: GoogleFonts.inter(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          // Acciones secundarias
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () {
                                    Navigator.of(sheetCtx).pop();
                                    setState(() {
                                      _selectedDate = day;
                                      _view = _CalView.day;
                                    });
                                  },
                                  icon: const Icon(
                                      Icons.view_agenda_rounded,
                                      size: 18),
                                  label: const Text('Ver agenda'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: AppColors.primary,
                                    side: BorderSide(
                                        color: AppColors.primary
                                            .withValues(alpha: 0.5),
                                        width: 1),
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 12),
                                    shape: RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.circular(12),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () {
                                    Navigator.of(sheetCtx).pop();
                                    setState(() {
                                      _selectedDate = day;
                                      _view = _CalView.day;
                                    });
                                  },
                                  icon: const Icon(Icons.block_rounded,
                                      size: 18),
                                  label: const Text('Bloquear'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor:
                                        theme.colorScheme.onSurface
                                            .withValues(alpha: 0.7),
                                    side: BorderSide(
                                        color: theme.colorScheme.outline
                                            .withValues(alpha: 0.3),
                                        width: 1),
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 12),
                                    shape: RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.circular(12),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  /// Abre el formulario para agregar una reserva manual (cliente cargado
  /// a mano por el dueño — útil para turnos recibidos por WhatsApp,
  /// teléfono o en persona).
  void _showManualReservationForm(DateTime day) {
    final business = ref.read(currentBusinessProvider);
    if (business == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo cargar tu negocio.')),
      );
      return;
    }
    final servicesAsync = ref.read(businessServicesProvider(business.id));
    final services = servicesAsync.value ?? [];
    if (services.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Primero creá un servicio en la pestaña "Servicios".'),
        ),
      );
      return;
    }

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(sheetCtx).viewInsets.bottom,
          ),
          child: _ManualReservationForm(
            day: day,
            business: business,
            services: services,
            onCreated: () {
              // Refrescamos para que la nueva reserva aparezca
              ref.invalidate(businessReservationsProvider);
            },
          ),
        );
      },
    );
  }

  Widget _buildDaySummary(ThemeData theme, List<Reservation> reservations) {
    final dayStart = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);
    final dayEnd = dayStart.add(const Duration(days: 1));
    final dayRes = reservations.where((r) =>
      r.startTime.isAfter(dayStart.subtract(const Duration(seconds: 1))) &&
      r.startTime.isBefore(dayEnd)
    ).toList();

    final confirmed = dayRes.where((r) => r.status == ReservationStatus.confirmed).length;
    final pending = dayRes.where((r) => r.status == ReservationStatus.pending).length;
    final cancelled = dayRes.where((r) => r.status == ReservationStatus.cancelled).length;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.s24, vertical: AppSizes.s4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: AppSizes.s16, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.1)),
        ),
        child: Row(
          children: [
            Icon(Icons.summarize_rounded, size: 16, color: AppColors.primary),
            const SizedBox(width: AppSizes.s8),
            Text(
              '${dayRes.length} turnos',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.accent,
              ),
            ),
            const Spacer(),
            if (confirmed > 0) _summaryChip('$confirmed ✓', AppColors.statusConfirmed),
            if (pending > 0) ...[const SizedBox(width: 6), _summaryChip('$pending ⏳', AppColors.statusPending)],
            if (cancelled > 0) ...[const SizedBox(width: 6), _summaryChip('$cancelled ✕', AppColors.statusCancelled)],
          ],
        ),
      ),
    );
  }

  Widget _summaryChip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppSizes.radiusFull),
      ),
      child: Text(
        text,
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }

  void _showBlockTimeDialog(
      BuildContext context, WidgetRef ref, Business? business) {
    if (business == null) return;

    TimeOfDay startTime = business.openingTime;
    TimeOfDay endTime = TimeOfDay(
      hour: business.openingTime.hour + 1,
      minute: business.openingTime.minute,
    );
    final reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            final theme = Theme.of(ctx);
            return AlertDialog(
              title: const Text(AppStrings.blockTime),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Start time
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(
                      Icons.schedule_rounded,
                      color: theme.colorScheme.primary,
                    ),
                    title: const Text('Desde'),
                    trailing: TextButton(
                      onPressed: () async {
                        final picked = await showTimePicker(
                          context: ctx,
                          initialTime: startTime,
                        );
                        if (picked != null) {
                          setDialogState(() => startTime = picked);
                        }
                      },
                      child: Text(
                        AppDateUtils.timeOfDayToString(
                            startTime.hour, startTime.minute),
                      ),
                    ),
                  ),
                  // End time
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(
                      Icons.schedule_rounded,
                      color: theme.colorScheme.error,
                    ),
                    title: const Text('Hasta'),
                    trailing: TextButton(
                      onPressed: () async {
                        final picked = await showTimePicker(
                          context: ctx,
                          initialTime: endTime,
                        );
                        if (picked != null) {
                          setDialogState(() => endTime = picked);
                        }
                      },
                      child: Text(
                        AppDateUtils.timeOfDayToString(
                            endTime.hour, endTime.minute),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSizes.s8),
                  AppTextField(
                    controller: reasonController,
                    label: 'Motivo (opcional)',
                    prefixIcon: Icons.notes_rounded,
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text(AppStrings.cancel),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final startDt = DateTime(
                      _selectedDate.year,
                      _selectedDate.month,
                      _selectedDate.day,
                      startTime.hour,
                      startTime.minute,
                    );
                    final endDt = DateTime(
                      _selectedDate.year,
                      _selectedDate.month,
                      _selectedDate.day,
                      endTime.hour,
                      endTime.minute,
                    );

                    final blocked = BlockedSlot(
                      id: _uuid.v4(),
                      businessId: business.id,
                      startTime: startDt,
                      endTime: endDt,
                      reason: reasonController.text.trim().isNotEmpty
                          ? reasonController.text.trim()
                          : null,
                    );

                    try {
                      await BlockedSlotRepository().create(blocked);
                      ref.invalidate(blockedSlotsProvider);
                    } catch (_) {
                      // silently fail
                    }

                    if (dialogContext.mounted) {
                      Navigator.of(dialogContext).pop();
                    }
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Horario bloqueado correctamente'),
                        ),
                      );
                    }
                  },
                  child: const Text('Bloquear'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// DAY VIEW
// ─────────────────────────────────────────────────────────────────────────────

/// Vertical timeline for a single day showing reservations and blocked slots.
class _DayView extends ConsumerWidget {
  final DateTime selectedDate;
  final Business? business;
  final List<Reservation> reservations;
  final List<BlockedSlot> blockedSlots;

  const _DayView({
    super.key,
    required this.selectedDate,
    required this.business,
    required this.reservations,
    required this.blockedSlots,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    if (business == null) {
      return const EmptyState(
        icon: Icons.store_outlined,
        title: 'Sin negocio',
        subtitle: 'No se encontró información del negocio',
      );
    }

    final biz = business!;
    final startHour = biz.openingTime.hour;
    final endHour = biz.closingTime.hour +
        (biz.closingTime.minute > 0 ? 1 : 0);
    final hours = List.generate(endHour - startHour, (i) => startHour + i);

    // Filter reservations for selected day
    final dayStart = DateTime(
        selectedDate.year, selectedDate.month, selectedDate.day);
    final dayEnd = dayStart.add(const Duration(days: 1));

    final dayReservations = reservations.where((r) {
      return r.startTime
              .isAfter(dayStart.subtract(const Duration(seconds: 1))) &&
          r.startTime.isBefore(dayEnd);
    }).toList()
      ..sort((a, b) => a.startTime.compareTo(b.startTime));

    final dayBlocked = blockedSlots.where((b) {
      return b.startTime
              .isAfter(dayStart.subtract(const Duration(seconds: 1))) &&
          b.startTime.isBefore(dayEnd);
    }).toList();

    // Hour row height in pixels
    const hourHeight = 72.0;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.s16, vertical: AppSizes.s8),
      child: SizedBox(
        height: hours.length * hourHeight,
        child: Stack(
          children: [
            // ── Hour lines ──
            ...hours.asMap().entries.map((entry) {
              final index = entry.key;
              final hour = entry.value;

              return Positioned(
                top: index * hourHeight,
                left: 0,
                right: 0,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 50,
                      child: Text(
                        AppDateUtils.timeOfDayToString(hour, 0),
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: theme.colorScheme.outline,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Container(
                        height: 1,
                        margin: const EdgeInsets.only(top: 8),
                        color: theme.colorScheme.outline
                            .withValues(alpha: 0.15),
                      ),
                    ),
                  ],
                ),
              );
            }),

            // ── Blocked slots ──
            ...dayBlocked.map((blocked) {
              final topOffset = _timeToOffset(
                blocked.startTime,
                startHour,
                hourHeight,
              );
              final height = _durationToHeight(
                blocked.startTime,
                blocked.endTime,
                hourHeight,
              );

              return Positioned(
                top: topOffset,
                left: 58,
                right: 0,
                height: height.clamp(20.0, double.infinity),
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.statusBlocked.withValues(alpha: 0.12),
                    borderRadius:
                        BorderRadius.circular(AppSizes.radiusSm),
                    border: Border.all(
                      color:
                          AppColors.statusBlocked.withValues(alpha: 0.3),
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.s12,
                    vertical: AppSizes.s6,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.block_rounded,
                        size: 14,
                        color: AppColors.statusBlocked,
                      ),
                      const SizedBox(width: AppSizes.s6),
                      Expanded(
                        child: Text(
                          blocked.reason ?? 'Bloqueado',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppColors.statusBlocked,
                            fontWeight: FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),

            // ── Reservation blocks ──
            ...dayReservations.asMap().entries.map((entry) {
              final res = entry.value;
              final topOffset =
                  _timeToOffset(res.startTime, startHour, hourHeight);
              final height = _durationToHeight(
                res.startTime,
                res.endTime,
                hourHeight,
              );
              final color = _reservationColor(res.status);

              return Positioned(
                top: topOffset,
                left: 58,
                right: 0,
                height: height.clamp(28.0, double.infinity),
                child: GestureDetector(
                  onTap: () =>
                      _showReservationDetails(context, ref, res),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          color.withValues(alpha: 0.15),
                          color.withValues(alpha: 0.04),
                        ],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                      border: Border.all(
                        color: color.withValues(alpha: 0.3),
                        width: 1.2,
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSizes.s12,
                      vertical: AppSizes.s6,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          res.clientName ?? 'Cliente',
                          style:
                              theme.textTheme.labelMedium?.copyWith(
                            color: color,
                            fontWeight: FontWeight.w700,
                            decoration:
                                res.status == ReservationStatus.cancelled
                                    ? TextDecoration.lineThrough
                                    : null,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (height > 36)
                          Text(
                            '${res.serviceName ?? ''} • ${AppDateUtils.formatTimeRange(res.startTime, res.endTime)}',
                            style:
                                theme.textTheme.bodySmall?.copyWith(
                              color: color.withValues(alpha: 0.8),
                              fontSize: 10,
                              decoration: res.status ==
                                      ReservationStatus.cancelled
                                  ? TextDecoration.lineThrough
                                  : null,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                ),
              );
            }),

            // ── Current time indicator ──
            if (AppDateUtils.isToday(selectedDate))
              Positioned(
                top: _timeToOffset(DateTime.now(), startHour, hourHeight),
                left: 46,
                right: 0,
                child: Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.error,
                        shape: BoxShape.circle,
                      ),
                    ),
                    Expanded(
                      child: Container(
                        height: 2,
                        color: theme.colorScheme.error,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  double _timeToOffset(DateTime time, int startHour, double hourHeight) {
    final minutesSinceStart =
        (time.hour - startHour) * 60 + time.minute;
    return minutesSinceStart / 60 * hourHeight;
  }

  double _durationToHeight(
      DateTime start, DateTime end, double hourHeight) {
    final durationMinutes = end.difference(start).inMinutes;
    return durationMinutes / 60 * hourHeight;
  }

  Color _reservationColor(ReservationStatus status) {
    switch (status) {
      case ReservationStatus.confirmed:
        return AppColors.statusConfirmed;
      case ReservationStatus.pending:
        return AppColors.statusPending;
      case ReservationStatus.cancelled:
        return AppColors.statusCancelled;
      case ReservationStatus.completed:
        return AppColors.statusCompleted;
    }
  }

  void _showReservationDetails(
      BuildContext context, WidgetRef ref, Reservation reservation) {
    final theme = Theme.of(context);
    final color = _reservationColor(reservation.status);
    final statusLabel = _statusLabel(reservation.status);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSizes.radiusXl),
        ),
      ),
      builder: (sheetContext) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
            AppSizes.s24,
            AppSizes.s24,
            AppSizes.s24,
            AppSizes.s24 + MediaQuery.of(sheetContext).viewInsets.bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.outline.withValues(alpha: 0.3),
                    borderRadius:
                        BorderRadius.circular(AppSizes.radiusFull),
                  ),
                ),
              ),
              const SizedBox(height: AppSizes.s20),

              // Header
              Row(
                children: [
                  Text(
                    'Detalle de reserva',
                    style: theme.textTheme.headlineMedium,
                  ),
                  const Spacer(),
                  StatusBadge(label: statusLabel, color: color),
                ],
              ),
              const SizedBox(height: AppSizes.s20),

              // Client
              _DetailRow(
                icon: Icons.person_rounded,
                label: 'Cliente',
                value: reservation.clientName ?? 'Sin nombre',
              ),
              const SizedBox(height: AppSizes.s12),

              // Service
              _DetailRow(
                icon: Icons.spa_rounded,
                label: 'Servicio',
                value: reservation.serviceName ?? 'Sin servicio',
              ),
              const SizedBox(height: AppSizes.s12),

              // Time
              _DetailRow(
                icon: Icons.schedule_rounded,
                label: 'Horario',
                value: AppDateUtils.formatTimeRange(
                    reservation.startTime, reservation.endTime),
              ),

              if (reservation.notes != null) ...[
                const SizedBox(height: AppSizes.s12),
                _DetailRow(
                  icon: Icons.notes_rounded,
                  label: 'Notas',
                  value: reservation.notes!,
                ),
              ],

              const SizedBox(height: AppSizes.s24),

              // Actions
              if (reservation.status == ReservationStatus.pending) ...[
                Row(
                  children: [
                    Expanded(
                      child: AppButton(
                        label: AppStrings.confirm,
                        icon: Icons.check_rounded,
                        onPressed: () {
                          _updateStatus(
                            ref,
                            reservation,
                            ReservationStatus.confirmed,
                          );
                          Navigator.of(sheetContext).pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Reserva confirmada'),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: AppSizes.s12),
                    Expanded(
                      child: AppButton(
                        label: AppStrings.cancel,
                        icon: Icons.close_rounded,
                        isOutlined: true,
                        onPressed: () {
                          _updateStatus(
                            ref,
                            reservation,
                            ReservationStatus.cancelled,
                          );
                          Navigator.of(sheetContext).pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Reserva cancelada'),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ] else if (reservation.status ==
                  ReservationStatus.confirmed) ...[
                AppButton(
                  label: AppStrings.cancelReservation,
                  icon: Icons.cancel_outlined,
                  backgroundColor: theme.colorScheme.error,
                  foregroundColor: Colors.white,
                  onPressed: () {
                    _updateStatus(
                      ref,
                      reservation,
                      ReservationStatus.cancelled,
                    );
                    Navigator.of(sheetContext).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Reserva cancelada'),
                      ),
                    );
                  },
                ),
              ],

              // WhatsApp button (for pending/confirmed)
              if (reservation.status == ReservationStatus.pending ||
                  reservation.status == ReservationStatus.confirmed)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        WhatsAppHelper.sendBusinessToClientReminder(
                          clientPhone: null,
                          clientName: reservation.clientName ?? 'Cliente',
                          businessName: reservation.businessName ?? 'Mi negocio',
                          serviceName: reservation.serviceName ?? 'Turno',
                          startTime: reservation.startTime,
                        );
                      },
                      icon: const Icon(Icons.message_rounded,
                          size: 18, color: Color(0xFF25D366)),
                      label: Text(
                        'Recordar por WhatsApp',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF25D366),
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFF25D366)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ),

              const SizedBox(height: AppSizes.s8),
            ],
          ),
        );
      },
    );
  }

  void _updateStatus(
      WidgetRef ref, Reservation reservation, ReservationStatus newStatus) async {
    try {
      await ReservationRepository().updateStatus(reservation.id, newStatus.name);
      ref.invalidate(businessReservationsProvider);

      // Send cancellation email if status changed to cancelled
      if (newStatus == ReservationStatus.cancelled) {
        final business = ref.read(currentBusinessProvider);
        ProfileRepository().getProfile(reservation.clientId).then((client) {
          if (client != null && business != null) {
            EmailService.enviarEmailCancelacionTurnoCliente(
              clientEmail: client.email,
              clientName: client.fullName,
              businessName: business.name,
              serviceName: reservation.serviceName ?? 'Servicio',
              startTime: reservation.startTime,
              cancelledBy: business.name,
            );
          }
        }).catchError((_) {});
      }
    } catch (_) {
      // silently fail — the UI will show stale data until next refresh
    }
  }

  String _statusLabel(ReservationStatus status) {
    switch (status) {
      case ReservationStatus.pending:
        return AppStrings.statusPending;
      case ReservationStatus.confirmed:
        return AppStrings.statusConfirmed;
      case ReservationStatus.cancelled:
        return AppStrings.statusCancelled;
      case ReservationStatus.completed:
        return AppStrings.statusCompleted;
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// WEEK VIEW
// ─────────────────────────────────────────────────────────────────────────────

/// Redesigned weekly calendar grid rendering a scrollable hourly time-grid.
class _WeekView extends ConsumerWidget {
  final List<DateTime> weekDays;
  final DateTime selectedDate;
  final List<Reservation> reservations;
  final void Function(DateTime) onDayTap;

  const _WeekView({
    super.key,
    required this.weekDays,
    required this.selectedDate,
    required this.reservations,
    required this.onDayTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    const startHour = 7;
    const endHour = 20;
    const hourHeight = 64.0;
    final hoursCount = endHour - startHour + 1;

    final dayNames = ['LUN', 'MAR', 'MIÉ', 'JUE', 'VIE', 'SÁB', 'DOM'];

    return Column(
      children: [
        // ── Cabecera de Días de la Semana ──
        Container(
          padding: const EdgeInsets.symmetric(vertical: AppSizes.s8),
          decoration: BoxDecoration(
            color: theme.cardTheme.color,
            border: Border(
              bottom: BorderSide(
                color: colorScheme.outline.withValues(alpha: 0.1),
              ),
            ),
          ),
          child: Row(
            children: [
              const SizedBox(width: 54), // Alineado con la columna de horas
              ...List.generate(7, (index) {
                final day = weekDays[index];
                final isCurrentDay = AppDateUtils.isToday(day);
                
                // Highlight the actual current day
                final highlight = isCurrentDay;

                return Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    decoration: highlight
                        ? BoxDecoration(
                            color: colorScheme.primary.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                          )
                        : null,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          dayNames[day.weekday - 1],
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: highlight
                                ? colorScheme.primary
                                : colorScheme.outline,
                            fontWeight: highlight ? FontWeight.w700 : FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: highlight
                                ? colorScheme.primary
                                : isCurrentDay
                                    ? colorScheme.primary.withValues(alpha: 0.15)
                                    : Colors.transparent,
                          ),
                          child: Center(
                            child: Text(
                              '${day.day}',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: highlight
                                    ? colorScheme.onPrimary
                                    : isCurrentDay
                                        ? colorScheme.primary
                                        : null,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ],
          ),
        ),

        // ── Grilla Horaria Scrollable ──
        Expanded(
          child: SingleChildScrollView(
            child: SizedBox(
              height: hoursCount * hourHeight,
              child: Stack(
                children: [
                  // 1. Líneas divisorias horizontales y etiquetas de hora
                  Column(
                    children: List.generate(hoursCount, (index) {
                      final hour = startHour + index;
                      return SizedBox(
                        height: hourHeight,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              width: 54,
                              child: Padding(
                                padding: const EdgeInsets.only(left: 8.0, top: 4.0),
                                child: Text(
                                  '${hour.toString().padLeft(2, '0')}:00',
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    // Horas más oscuras para que sean legibles
                                    // (antes usaba `outline` que era casi blanco).
                                    color: colorScheme.onSurface
                                        .withValues(alpha: 0.65),
                                    fontWeight: FontWeight.w700,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              child: Container(
                                height: 1,
                                color: colorScheme.outline.withValues(alpha: 0.1),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ),

                  // 2. Columnas con fondo suave y reservas superpuestas
                  Positioned.fill(
                    child: Row(
                      children: [
                        const SizedBox(width: 54),
                        ...List.generate(7, (dayIndex) {
                          final day = weekDays[dayIndex];
                          final isCurrentDay = AppDateUtils.isToday(day);

                          // Filtrar reservas para este día
                          final dayStart = DateTime(day.year, day.month, day.day);
                          final dayEnd = dayStart.add(const Duration(days: 1));
                          final dayReservations = reservations.where((r) {
                            return r.startTime.isAfter(dayStart.subtract(const Duration(seconds: 1))) &&
                                r.startTime.isBefore(dayEnd);
                          }).toList();

                          return Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                color: isCurrentDay
                                    ? colorScheme.primary.withValues(alpha: 0.03)
                                    : null,
                                border: Border(
                                  right: BorderSide(
                                    color: colorScheme.outline.withValues(alpha: 0.05),
                                    width: 1,
                                  ),
                                ),
                              ),
                              child: Stack(
                                children: [
                                  // Click en espacio vacío para ir al día
                                  Positioned.fill(
                                    child: GestureDetector(
                                      onTap: () => onDayTap(day),
                                      behavior: HitTestBehavior.opaque,
                                      child: const SizedBox(),
                                    ),
                                  ),
                                  // Reservas
                                  ...dayReservations.map((res) {
                                    final start = res.startTime;
                                    final end = res.endTime;

                                    if (start.hour < startHour || start.hour > endHour) {
                                      return const SizedBox();
                                    }

                                    final topOffset = ((start.hour - startHour) * 60 + start.minute) / 60 * hourHeight;
                                    final durationMin = end.difference(start).inMinutes;
                                    final height = (durationMin / 60) * hourHeight;
                                    final color = _reservationColor(res.status);

                                    return Positioned(
                                      top: topOffset,
                                      left: 2,
                                      right: 2,
                                      height: height.clamp(24.0, double.infinity),
                                      child: GestureDetector(
                                        onTap: () => _showReservationDetails(context, ref, res),
                                        child: Container(
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              colors: [
                                                color.withValues(alpha: 0.15),
                                                color.withValues(alpha: 0.04),
                                              ],
                                              begin: Alignment.centerLeft,
                                              end: Alignment.centerRight,
                                            ),
                                            borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                                            border: Border.all(
                                              color: color.withValues(alpha: 0.3),
                                              width: 1,
                                            ),
                                          ),
                                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Text(
                                                res.clientName ?? 'Cliente',
                                                style: theme.textTheme.labelSmall?.copyWith(
                                                  color: color,
                                                  fontWeight: FontWeight.w700,
                                                  fontSize: 9,
                                                  decoration: res.status == ReservationStatus.cancelled
                                                      ? TextDecoration.lineThrough
                                                      : null,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              if (height > 32)
                                                Text(
                                                  res.serviceName ?? 'Servicio',
                                                  style: TextStyle(
                                                    color: color.withValues(alpha: 0.8),
                                                    fontSize: 8,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    );
                                  }),
                                ],
                              ),
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Color _reservationColor(ReservationStatus status) {
    switch (status) {
      case ReservationStatus.confirmed:
        return AppColors.statusConfirmed;
      case ReservationStatus.pending:
        return AppColors.statusPending;
      case ReservationStatus.cancelled:
        return AppColors.statusCancelled;
      case ReservationStatus.completed:
        return AppColors.statusCompleted;
    }
  }

  void _showReservationDetails(
      BuildContext context, WidgetRef ref, Reservation reservation) {
    final theme = Theme.of(context);
    final color = _reservationColor(reservation.status);
    final statusLabel = _statusLabel(reservation.status);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSizes.radiusXl),
        ),
      ),
      builder: (sheetContext) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
            AppSizes.s24,
            AppSizes.s24,
            AppSizes.s24,
            AppSizes.s24 + MediaQuery.of(sheetContext).viewInsets.bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.outline.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(AppSizes.radiusFull),
                  ),
                ),
              ),
              const SizedBox(height: AppSizes.s20),
              Row(
                children: [
                  Text(
                    'Detalle de reserva',
                    style: theme.textTheme.headlineMedium,
                  ),
                  const Spacer(),
                  StatusBadge(label: statusLabel, color: color),
                ],
              ),
              const SizedBox(height: AppSizes.s20),
              _DetailRow(
                icon: Icons.person_rounded,
                label: 'Cliente',
                value: reservation.clientName ?? 'Sin nombre',
              ),
              const SizedBox(height: AppSizes.s12),
              _DetailRow(
                icon: Icons.spa_rounded,
                label: 'Servicio',
                value: reservation.serviceName ?? 'Sin servicio',
              ),
              const SizedBox(height: AppSizes.s12),
              _DetailRow(
                icon: Icons.schedule_rounded,
                label: 'Horario',
                value: AppDateUtils.formatTimeRange(
                    reservation.startTime, reservation.endTime),
              ),
              if (reservation.notes != null) ...[
                const SizedBox(height: AppSizes.s12),
                _DetailRow(
                  icon: Icons.notes_rounded,
                  label: 'Notas',
                  value: reservation.notes!,
                ),
              ],
              const SizedBox(height: AppSizes.s24),
              if (reservation.status == ReservationStatus.pending) ...[
                Row(
                  children: [
                    Expanded(
                      child: AppButton(
                        label: AppStrings.confirm,
                        icon: Icons.check_rounded,
                        onPressed: () {
                          _updateStatus(
                            ref,
                            reservation,
                            ReservationStatus.confirmed,
                          );
                          Navigator.of(sheetContext).pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Reserva confirmada'),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: AppSizes.s12),
                    Expanded(
                      child: AppButton(
                        label: AppStrings.cancel,
                        icon: Icons.close_rounded,
                        isOutlined: true,
                        onPressed: () {
                          _updateStatus(
                            ref,
                            reservation,
                            ReservationStatus.cancelled,
                          );
                          Navigator.of(sheetContext).pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Reserva cancelada'),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ] else if (reservation.status == ReservationStatus.confirmed) ...[
                AppButton(
                  label: AppStrings.cancelReservation,
                  icon: Icons.cancel_outlined,
                  backgroundColor: theme.colorScheme.error,
                  foregroundColor: Colors.white,
                  onPressed: () {
                    _updateStatus(
                      ref,
                      reservation,
                      ReservationStatus.cancelled,
                    );
                    Navigator.of(sheetContext).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Reserva cancelada'),
                      ),
                    );
                  },
                ),
              ],
              const SizedBox(height: AppSizes.s8),
            ],
          ),
        );
      },
    );
  }

  void _updateStatus(
      WidgetRef ref, Reservation reservation, ReservationStatus newStatus) async {
    try {
      await ReservationRepository().updateStatus(reservation.id, newStatus.name);
      ref.invalidate(businessReservationsProvider);

      // Send cancellation email if status changed to cancelled
      if (newStatus == ReservationStatus.cancelled) {
        final business = ref.read(currentBusinessProvider);
        ProfileRepository().getProfile(reservation.clientId).then((client) {
          if (client != null && business != null) {
            EmailService.enviarEmailCancelacionTurnoCliente(
              clientEmail: client.email,
              clientName: client.fullName,
              businessName: business.name,
              serviceName: reservation.serviceName ?? 'Servicio',
              startTime: reservation.startTime,
              cancelledBy: business.name,
            );
          }
        }).catchError((_) {});
      }
    } catch (_) {
      // silently fail — the UI will show stale data until next refresh
    }
  }

  String _statusLabel(ReservationStatus status) {
    switch (status) {
      case ReservationStatus.pending:
        return AppStrings.statusPending;
      case ReservationStatus.confirmed:
        return AppStrings.statusConfirmed;
      case ReservationStatus.cancelled:
        return AppStrings.statusCancelled;
      case ReservationStatus.completed:
        return AppStrings.statusCompleted;
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SHARED WIDGETS
// ─────────────────────────────────────────────────────────────────────────────

/// Horizontal day picker chip.
class _DayChip extends StatelessWidget {
  final DateTime date;
  final bool isSelected;
  final bool isToday;
  final int reservationCount;
  final VoidCallback onTap;

  const _DayChip({
    required this.date,
    required this.isSelected,
    required this.isToday,
    required this.reservationCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dayNames = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: AppSizes.animNormal),
        width: 56,
        margin: const EdgeInsets.symmetric(horizontal: AppSizes.s4),
        decoration: BoxDecoration(
          gradient: isSelected
              ? const LinearGradient(
                  colors: [AppColors.primary, AppColors.primaryDark],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: isSelected ? null : theme.cardTheme.color,
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          border: Border.all(
            color: isSelected
                ? AppColors.primaryDark.withValues(alpha: 0.5)
                : isToday
                    ? theme.colorScheme.primary
                    : theme.colorScheme.outline.withValues(alpha: 0.12),
            width: isToday && !isSelected ? 1.8 : 1.2,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: theme.colorScheme.primary
                        .withValues(alpha: 0.25),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              dayNames[date.weekday - 1],
              style: theme.textTheme.labelMedium?.copyWith(
                color: isSelected
                    ? theme.colorScheme.onPrimary.withValues(alpha: 0.8)
                    : theme.colorScheme.outline,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: AppSizes.s4),
            Text(
              '${date.day}',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: isSelected
                    ? theme.colorScheme.onPrimary
                    : null,
              ),
            ),
            if (reservationCount > 0) ...[
              const SizedBox(height: AppSizes.s4),
              Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  color: isSelected
                      ? theme.colorScheme.onPrimary
                          .withValues(alpha: 0.3)
                      : theme.colorScheme.primary
                          .withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '$reservationCount',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: isSelected
                          ? theme.colorScheme.onPrimary
                          : theme.colorScheme.primary,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Detail row used in the reservation bottom sheet.
class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Icon(icon, size: 20, color: theme.colorScheme.primary),
        const SizedBox(width: AppSizes.s12),
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
              Text(
                value,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// MONTH VIEW — Grilla del mes con días + contador de reservas
// ═══════════════════════════════════════════════════════════════════
class _MonthView extends ConsumerWidget {
  final DateTime selectedDate;
  final ValueChanged<DateTime> onDayTap;

  const _MonthView({
    super.key,
    required this.selectedDate,
    required this.onDayTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final monthLabel = DateFormat('MMMM yyyy', 'es').format(selectedDate);

    // Escuchamos el provider directo — así cuando se agrega una reserva
    // el chip de cantidad se actualiza solo (refresh automático).
    final reservations = ref.watch(businessReservationsProvider).value ?? [];

    // Primer día del mes y cuántos días tiene
    final firstOfMonth = DateTime(selectedDate.year, selectedDate.month, 1);
    final daysInMonth = DateUtils.getDaysInMonth(
      selectedDate.year,
      selectedDate.month,
    );

    // Día de la semana del primer día (1=lun ... 7=dom). Lo necesitamos
    // para empezar la grilla en el lugar correcto (lunes-domingo).
    final firstWeekday = firstOfMonth.weekday; // 1 = lunes

    // Contamos reservas por día del mes (clave = día)
    final reservationCountByDay = <int, int>{};
    for (final r in reservations) {
      if (r.startTime.year == selectedDate.year &&
          r.startTime.month == selectedDate.month) {
        reservationCountByDay[r.startTime.day] =
            (reservationCountByDay[r.startTime.day] ?? 0) + 1;
      }
    }

    const dayLabels = ['L', 'M', 'M', 'J', 'V', 'S', 'D'];
    final today = DateTime.now();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSizes.s16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Título del mes
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: AppSizes.s12),
            child: Text(
              monthLabel[0].toUpperCase() + monthLabel.substring(1),
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),

          // Cabecera de días de la semana (L M M J V S D)
          Row(
            children: dayLabels.map((d) {
              return Expanded(
                child: Center(
                  child: Text(
                    d,
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: colorScheme.onSurface.withValues(alpha: 0.5),
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: AppSizes.s8),

          // Grilla del mes
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 6,
              crossAxisSpacing: 6,
              childAspectRatio: 0.9,
            ),
            // Slots vacíos antes del día 1 + días del mes
            itemCount: (firstWeekday - 1) + daysInMonth,
            itemBuilder: (context, index) {
              final dayNumber = index - (firstWeekday - 1) + 1;
              if (dayNumber < 1) return const SizedBox.shrink();

              final dayDate = DateTime(
                  selectedDate.year, selectedDate.month, dayNumber);
              final count = reservationCountByDay[dayNumber] ?? 0;
              final isSelected = dayDate.year == selectedDate.year &&
                  dayDate.month == selectedDate.month &&
                  dayDate.day == selectedDate.day;
              final isToday = dayDate.year == today.year &&
                  dayDate.month == today.month &&
                  dayDate.day == today.day;
              final hasReservations = count > 0;

              return InkWell(
                borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                onTap: () => onDayTap(dayDate),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primary
                        : isToday
                            ? AppColors.primary.withValues(alpha: 0.10)
                            : Colors.transparent,
                    borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.primary
                          : colorScheme.outline.withValues(alpha: 0.12),
                      width: isSelected ? 0 : 1,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '$dayNumber',
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: isSelected
                              ? Colors.white
                              : isToday
                                  ? AppColors.primary
                                  : colorScheme.onSurface
                                      .withValues(alpha: 0.85),
                        ),
                      ),
                      const SizedBox(height: 4),
                      // Indicador de reservas
                      if (hasReservations)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 1),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Colors.white.withValues(alpha: 0.25)
                                : AppColors.primary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '$count',
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: isSelected
                                  ? Colors.white
                                  : AppColors.primary,
                            ),
                          ),
                        )
                      else
                        const SizedBox(height: 14),
                    ],
                  ),
                ),
              );
            },
          ),

          const SizedBox(height: AppSizes.s16),

          // Leyenda
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  'Hoy',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
                const SizedBox(width: 16),
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  'Día seleccionado',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// FORM: Agregar reserva manual (cliente cargado a mano por el dueño)
// ═══════════════════════════════════════════════════════════════════
class _ManualReservationForm extends StatefulWidget {
  final DateTime day;
  final Business business;
  final List<ServiceModel> services;
  final VoidCallback onCreated;

  const _ManualReservationForm({
    required this.day,
    required this.business,
    required this.services,
    required this.onCreated,
  });

  @override
  State<_ManualReservationForm> createState() =>
      _ManualReservationFormState();
}

class _ManualReservationFormState extends State<_ManualReservationForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  ServiceModel? _selectedService;
  TimeOfDay _selectedTime = const TimeOfDay(hour: 9, minute: 0);
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    if (widget.services.isNotEmpty) {
      _selectedService = widget.services.first;
    }
    // Por defecto: la hora de apertura del negocio
    _selectedTime = widget.business.openingTime;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null && mounted) {
      setState(() => _selectedTime = picked);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final svc = _selectedService;
    if (svc == null) return;

    setState(() => _isSaving = true);
    try {
      final startTime = DateTime(
        widget.day.year,
        widget.day.month,
        widget.day.day,
        _selectedTime.hour,
        _selectedTime.minute,
      );
      final endTime =
          startTime.add(Duration(minutes: svc.durationMinutes));

      // Nota descriptiva con los datos del cliente manual
      final clientName = _nameCtrl.text.trim();
      final clientPhone = _phoneCtrl.text.trim();
      final extraNotes = _notesCtrl.text.trim();
      final notesParts = <String>[
        'Cliente: $clientName',
        if (clientPhone.isNotEmpty) 'Tel: $clientPhone',
        if (extraNotes.isNotEmpty) 'Notas: $extraNotes',
      ];

      // Como cliente manual, usamos al dueño del negocio como clientId
      // (workaround para no romper la FK a profiles). El nombre real
      // del cliente va en notes y en clientName.
      final reservation = Reservation(
        id: '',
        businessId: widget.business.id,
        clientId: widget.business.ownerId,
        serviceId: svc.id,
        startTime: startTime,
        endTime: endTime,
        status: ReservationStatus.confirmed,
        notes: notesParts.join(' · '),
        createdAt: DateTime.now(),
        clientName: clientName,
        serviceName: svc.name,
      );

      await ReservationRepository().create(reservation);

      widget.onCreated();
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.success,
          content: Text('Turno agregado: $clientName a las '
              '${_selectedTime.format(context)}'),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.error,
          content: Text('Error al guardar: $e'),
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final df = DateFormat('EEEE d \'de\' MMMM', 'es');
    final dayLabel = df.format(widget.day);
    final capitalized = dayLabel[0].toUpperCase() + dayLabel.substring(1);

    return Container(
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius:
            const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle bar
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color:
                          theme.colorScheme.outline.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.add_rounded,
                          color: AppColors.primary, size: 20),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Agregar turno',
                            style: GoogleFonts.inter(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            capitalized,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: theme.colorScheme.onSurface
                                  .withValues(alpha: 0.6),
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Nombre del cliente (obligatorio)
                TextFormField(
                  controller: _nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Nombre del cliente *',
                    hintText: 'Ej: Juan Pérez',
                    prefixIcon: Icon(Icons.person_outline_rounded),
                    border: OutlineInputBorder(),
                  ),
                  textInputAction: TextInputAction.next,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Ingresá el nombre del cliente';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                // Teléfono (opcional)
                TextFormField(
                  controller: _phoneCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Teléfono (opcional)',
                    hintText: 'Ej: 0981 123 456',
                    prefixIcon: Icon(Icons.phone_outlined),
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 12),
                // Servicio (dropdown)
                DropdownButtonFormField<ServiceModel>(
                  initialValue: _selectedService,
                  decoration: const InputDecoration(
                    labelText: 'Servicio *',
                    prefixIcon: Icon(Icons.design_services_outlined),
                    border: OutlineInputBorder(),
                  ),
                  items: widget.services.map((s) {
                    return DropdownMenuItem(
                      value: s,
                      child: Text(
                        '${s.name} (${s.durationMinutes} min)',
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }).toList(),
                  onChanged: (v) => setState(() => _selectedService = v),
                  validator: (v) =>
                      v == null ? 'Elegí un servicio' : null,
                ),
                const SizedBox(height: 12),
                // Hora (tile clickeable que abre TimePicker)
                InkWell(
                  onTap: _pickTime,
                  borderRadius: BorderRadius.circular(8),
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Hora del turno *',
                      prefixIcon: Icon(Icons.schedule_rounded),
                      border: OutlineInputBorder(),
                    ),
                    child: Text(
                      _selectedTime.format(context),
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // Notas (opcional)
                TextFormField(
                  controller: _notesCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Notas (opcional)',
                    hintText: 'Detalles del turno',
                    prefixIcon: Icon(Icons.notes_rounded),
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 18),
                // Botón guardar
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _isSaving ? null : _save,
                    icon: _isSaving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.check_rounded),
                    label: Text(_isSaving ? 'Guardando...' : 'Guardar turno'),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      textStyle: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
