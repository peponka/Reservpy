import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

const _uuid = Uuid();

/// Business owner's calendar view with Day/Week toggle.
class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  /// Whether viewing in day (true) or week (false) mode.
  bool _isDayView = true;

  /// Currently selected date.
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedDate = DateTime(now.year, now.month, now.day);
  }

  /// Generates the 7-day range starting from today.
  List<DateTime> get _weekDays {
    final today = DateTime.now();
    return List.generate(
      7,
      (i) => DateTime(today.year, today.month, today.day + i),
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
              child: Row(
                children: [
                  Text(
                    AppStrings.calendar,
                    style: theme.textTheme.headlineLarge,
                  ),
                  const Spacer(),
                  // Day/Week toggle
                  SegmentedButton<bool>(
                    segments: const [
                      ButtonSegment(
                        value: true,
                        label: Text(AppStrings.dayView),
                        icon: Icon(Icons.view_day_rounded, size: 18),
                      ),
                      ButtonSegment(
                        value: false,
                        label: Text(AppStrings.weekView),
                        icon: Icon(Icons.view_week_rounded, size: 18),
                      ),
                    ],
                    selected: {_isDayView},
                    onSelectionChanged: (selection) {
                      setState(() => _isDayView = selection.first);
                    },
                    style: ButtonStyle(
                      visualDensity: VisualDensity.compact,
                      textStyle: WidgetStatePropertyAll(
                        theme.textTheme.labelMedium,
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
                    : _WeekView(
                        key: const ValueKey('week'),
                        weekDays: _weekDays,
                        selectedDate: _selectedDate,
                        reservations: reservations,
                        onDayTap: (day) {
                          setState(() {
                            _selectedDate = day;
                            _isDayView = true;
                          });
                        },
                      ),
              ),
            ),
          ],
        ),

        // ── FAB overlay ──
        if (_isDayView)
          Positioned(
            right: AppSizes.s24,
            bottom: AppSizes.s24,
            child: FloatingActionButton.extended(
              heroTag: 'calendar_fab',
              onPressed: () => _showBlockTimeDialog(
                  context, ref, business),
              icon: const Icon(Icons.block_rounded),
              label: const Text(AppStrings.blockTime),
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
                final isToday = AppDateUtils.isToday(day);
                final isWednesday = day.weekday == DateTime.wednesday;
                
                // Si es miércoles 27 (o miércoles en general), destacamos en Teal como el mockup
                final highlight = isWednesday;

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
                                : isToday
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
                                    : isToday
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
                                    color: colorScheme.outline,
                                    fontWeight: FontWeight.w600,
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
                          final isWednesday = day.weekday == DateTime.wednesday;

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
                                color: isWednesday
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
