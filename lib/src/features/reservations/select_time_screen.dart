import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:go_router/go_router.dart';
import 'package:table_calendar/table_calendar.dart';

import 'package:reservpy/src/shared/models/models.dart';
import 'package:reservpy/src/shared/providers/providers.dart';
import 'package:reservpy/src/core/widgets/widgets.dart';
import 'package:reservpy/src/core/constants/app_sizes.dart';
import 'package:reservpy/src/core/constants/app_strings.dart';
import 'package:reservpy/src/core/utils/date_utils.dart';
import 'package:reservpy/src/data/repositories/reservation_repository.dart';

/// Time slot selection screen with calendar and slot grid.
class SelectTimeScreen extends ConsumerStatefulWidget {
  final String businessId;
  final String serviceId;

  const SelectTimeScreen({
    super.key,
    required this.businessId,
    required this.serviceId,
  });

  @override
  ConsumerState<SelectTimeScreen> createState() => _SelectTimeScreenState();
}

class _SelectTimeScreenState extends ConsumerState<SelectTimeScreen> {
  late DateTime _focusedDay;
  late DateTime _selectedDay;
  DateTime? _selectedSlot;
  CalendarFormat _calendarFormat = CalendarFormat.month;
  List<Reservation> _dayReservations = [];

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _focusedDay = now;
    _selectedDay = DateTime(now.year, now.month, now.day);
    _fetchDayReservations();
  }

  Future<void> _fetchDayReservations() async {
    try {
      final data = await ReservationRepository()
          .getByBusinessAndDate(widget.businessId, _selectedDay);
      if (mounted) setState(() => _dayReservations = data);
    } catch (_) {
      if (mounted) setState(() => _dayReservations = []);
    }
  }

  /// Generates time slots for the selected day based on business hours.
  List<DateTime> _generateSlots(Business business) {
    return AppDateUtils.generateSlots(
      _selectedDay,
      business.openingTime.hour,
      business.openingTime.minute,
      business.closingTime.hour,
      business.closingTime.minute,
      business.slotDurationMinutes,
    );
  }

  /// Checks whether a slot is occupied by an existing reservation.
  bool _isSlotOccupied(DateTime slot, List<Reservation> reservations, int durationMinutes) {
    final slotEnd = slot.add(Duration(minutes: durationMinutes));
    return reservations.any((r) {
      if (r.status == ReservationStatus.cancelled) return false;
      return slot.isBefore(r.endTime) && slotEnd.isAfter(r.startTime);
    });
  }

  /// Checks whether a slot overlaps with a blocked period.
  bool _isSlotBlocked(DateTime slot, List<BlockedSlot> blockedSlots, int durationMinutes) {
    final slotEnd = slot.add(Duration(minutes: durationMinutes));
    return blockedSlots.any((b) {
      return slot.isBefore(b.endTime) && slotEnd.isAfter(b.startTime);
    });
  }

  /// Returns true if the slot is in the past.
  bool _isSlotInPast(DateTime slot) {
    return slot.isBefore(DateTime.now());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final businesses = ref.watch(businessesProvider).valueOrNull ?? [];
    final blockedSlots = ref.watch(blockedSlotsProvider).valueOrNull ?? [];

    final business = businesses.where((b) => b.id == widget.businessId).firstOrNull;
    if (business == null) {
      return Scaffold(
        appBar: AppBar(title: const Text(AppStrings.selectTime)),
        body: const EmptyState(
          icon: Icons.error_outline_rounded,
          title: 'Negocio no encontrado',
        ),
      );
    }

    // Resolve the selected service(s) — puede ser una lista separada por
    // comas (selección múltiple) — y sumar la duración total.
    final services = ref.watch(businessServicesProvider(widget.businessId)).valueOrNull ?? [];
    final selectedIds = widget.serviceId.split(',');
    final selectedServices =
        services.where((s) => selectedIds.contains(s.id)).toList();
    final serviceDuration = selectedServices.isEmpty
        ? business.slotDurationMinutes
        : selectedServices.fold<int>(
            0, (sum, s) => sum + s.durationMinutes);

    // Use pre-fetched day reservations
    final dayReservations = _dayReservations;

    // Filter blocked slots for selected day
    final dayStart = DateTime(_selectedDay.year, _selectedDay.month, _selectedDay.day);
    final dayEnd = dayStart.add(const Duration(days: 1));
    final dayBlocked = blockedSlots.where((b) {
      return b.businessId == widget.businessId &&
          b.startTime.isAfter(dayStart.subtract(const Duration(seconds: 1))) &&
          b.startTime.isBefore(dayEnd);
    }).toList();

    final slots = _generateSlots(business);

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.selectTime),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: AppSizes.s24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Calendar ──
            Container(
              margin: const EdgeInsets.symmetric(horizontal: AppSizes.s8),
              decoration: BoxDecoration(
                color: theme.cardTheme.color,
                borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                boxShadow: [
                  BoxShadow(
                    color: theme.colorScheme.shadow,
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TableCalendar<Reservation>(
                firstDay: DateTime.now().subtract(const Duration(days: 1)),
                lastDay: DateTime.now().add(const Duration(days: 90)),
                focusedDay: _focusedDay,
                calendarFormat: _calendarFormat,
                startingDayOfWeek: StartingDayOfWeek.monday,
                locale: 'es',
                selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                onDaySelected: (selectedDay, focusedDay) {
                  setState(() {
                    _selectedDay = DateTime(
                      selectedDay.year,
                      selectedDay.month,
                      selectedDay.day,
                    );
                    _focusedDay = focusedDay;
                    _selectedSlot = null;
                  });
                  _fetchDayReservations();
                },
                onFormatChanged: (format) {
                  setState(() => _calendarFormat = format);
                },
                onPageChanged: (focusedDay) {
                  _focusedDay = focusedDay;
                },
                enabledDayPredicate: (day) {
                  final today = DateTime.now();
                  final dayOnly = DateTime(day.year, day.month, day.day);
                  final todayOnly = DateTime(today.year, today.month, today.day);
                  return !dayOnly.isBefore(todayOnly);
                },
                calendarStyle: CalendarStyle(
                  todayDecoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  todayTextStyle: TextStyle(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                  selectedDecoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    shape: BoxShape.circle,
                  ),
                  selectedTextStyle: TextStyle(
                    color: theme.colorScheme.onPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                  outsideDaysVisible: false,
                  weekendTextStyle: TextStyle(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                  disabledTextStyle: TextStyle(
                    color: theme.colorScheme.outline.withValues(alpha: 0.3),
                  ),
                ),
                headerStyle: HeaderStyle(
                  formatButtonVisible: false,
                  titleCentered: true,
                  titleTextStyle: theme.textTheme.titleMedium!.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  leftChevronIcon: Icon(
                    Icons.chevron_left_rounded,
                    color: theme.colorScheme.primary,
                  ),
                  rightChevronIcon: Icon(
                    Icons.chevron_right_rounded,
                    color: theme.colorScheme.primary,
                  ),
                ),
                daysOfWeekStyle: DaysOfWeekStyle(
                  weekdayStyle: theme.textTheme.labelMedium!.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.outline,
                  ),
                  weekendStyle: theme.textTheme.labelMedium!.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.outline.withValues(alpha: 0.6),
                  ),
                ),
              ),
            ),

            const SizedBox(height: AppSizes.s16),

            // ── Slot label ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSizes.s20),
              child: Row(
                children: [
                  Text(
                    'Horarios disponibles',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    AppDateUtils.formatDayMonth(_selectedDay),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppSizes.s12),

            // ── Legend ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSizes.s20),
              child: Row(
                children: [
                  _LegendDot(
                    color: theme.colorScheme.primary,
                    label: 'Disponible',
                  ),
                  const SizedBox(width: AppSizes.s16),
                  _LegendDot(
                    color: theme.colorScheme.outline.withValues(alpha: 0.4),
                    label: 'Ocupado',
                  ),
                  const SizedBox(width: AppSizes.s16),
                  _LegendDot(
                    color: theme.colorScheme.error.withValues(alpha: 0.4),
                    label: 'Bloqueado',
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppSizes.s12),

            // ── Slot Grid ──
            if (slots.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: AppSizes.s32),
                child: EmptyState(
                  icon: Icons.event_busy_rounded,
                  title: 'Sin horarios',
                  subtitle: 'No hay horarios disponibles para este día',
                ),
              )
            else
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.s16,
                  vertical: AppSizes.s4,
                ),
                gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  childAspectRatio: 2.2,
                  crossAxisSpacing: AppSizes.s8,
                  mainAxisSpacing: AppSizes.s8,
                ),
                itemCount: slots.length,
                itemBuilder: (context, index) {
                  final slot = slots[index];
                  final isPast = _isSlotInPast(slot);
                  final isOccupied = _isSlotOccupied(
                    slot,
                    dayReservations,
                    serviceDuration,
                  );
                  final isBlocked = _isSlotBlocked(
                    slot,
                    dayBlocked,
                    serviceDuration,
                  );
                  final isDisabled =
                      isPast || isOccupied || isBlocked;
                  final isSelected = _selectedSlot != null &&
                      _selectedSlot!.isAtSameMomentAs(slot);

                  return _SlotChip(
                    time: AppDateUtils.formatTime(slot),
                    isSelected: isSelected,
                    isDisabled: isDisabled,
                    isBlocked: isBlocked,
                    delay: index,
                    onTap: isDisabled
                        ? null
                        : () {
                            setState(() => _selectedSlot = slot);
                          },
                  );
                },
              ),

            const SizedBox(height: AppSizes.s16),

            // ── Bottom button ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSizes.s24),
              child: AppButton(
                label: AppStrings.next,
                icon: Icons.arrow_forward_rounded,
                onPressed: _selectedSlot != null
                    ? () {
                        final timestamp = _selectedSlot!.millisecondsSinceEpoch;
                        context.push(
                          '/reserve/${widget.businessId}/confirm/${widget.serviceId}/$timestamp',
                        );
                      }
                    : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Single time slot chip.
class _SlotChip extends StatelessWidget {
  final String time;
  final bool isSelected;
  final bool isDisabled;
  final bool isBlocked;
  final int delay;
  final VoidCallback? onTap;

  const _SlotChip({
    required this.time,
    required this.isSelected,
    required this.isDisabled,
    required this.isBlocked,
    required this.delay,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Color bgColor;
    Color textColor;
    Color borderColor;

    if (isSelected) {
      bgColor = theme.colorScheme.primary;
      textColor = theme.colorScheme.onPrimary;
      borderColor = theme.colorScheme.primary;
    } else if (isBlocked) {
      bgColor = theme.colorScheme.error.withValues(alpha: 0.08);
      textColor = theme.colorScheme.outline.withValues(alpha: 0.5);
      borderColor = theme.colorScheme.error.withValues(alpha: 0.2);
    } else if (isDisabled) {
      bgColor = theme.colorScheme.outline.withValues(alpha: 0.06);
      textColor = theme.colorScheme.outline.withValues(alpha: 0.4);
      borderColor = theme.colorScheme.outline.withValues(alpha: 0.15);
    } else {
      bgColor = theme.colorScheme.primary.withValues(alpha: 0.06);
      textColor = theme.colorScheme.primary;
      borderColor = theme.colorScheme.primary.withValues(alpha: 0.3);
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: AppSizes.animNormal),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(AppSizes.radiusSm),
        border: Border.all(color: borderColor, width: isSelected ? 2 : 1),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppSizes.radiusSm),
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isSelected) ...[
                  Icon(
                    Icons.check_rounded,
                    size: 14,
                    color: textColor,
                  ),
                  const SizedBox(width: AppSizes.s4),
                ],
                Text(
                  time,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: textColor,
                    fontWeight:
                        isSelected ? FontWeight.w700 : FontWeight.w500,
                    decoration: isBlocked
                        ? TextDecoration.lineThrough
                        : null,
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

/// Small legend dot with label.
class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: AppSizes.s4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}
