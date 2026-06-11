import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:reservpy/src/core/constants/app_sizes.dart';
import 'package:reservpy/src/core/constants/app_colors.dart';
import 'package:reservpy/src/data/repositories/reservation_repository.dart';
import 'package:reservpy/src/data/repositories/notification_repository.dart';
import 'package:reservpy/src/shared/providers/providers.dart';
import 'package:reservpy/src/shared/models/models.dart';
import 'package:reservpy/src/features/reviews/review_widgets.dart';
import 'package:reservpy/src/data/repositories/review_repository.dart';
import 'package:reservpy/src/data/repositories/profile_repository.dart';
import 'package:reservpy/src/data/services/email_service.dart';

// ─── Filter enum ─────────────────────────────────────────
enum _ReservationFilter { all, upcoming, completed, cancelled }

// ─── Local state ─────────────────────────────────────────
final _reservationFilterProvider =
    StateProvider.autoDispose<_ReservationFilter>(
  (ref) => _ReservationFilter.all,
);

/// Premium "Mis Reservas" screen for the client shell.
class MyReservationsScreen extends ConsumerWidget {
  const MyReservationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(_reservationFilterProvider);
    final allReservations = ref.watch(clientReservationsProvider).value ?? [];

    // ── Apply filter ──
    final now = DateTime.now();
    final filtered = allReservations.where((r) {
      switch (filter) {
        case _ReservationFilter.all:
          return true;
        case _ReservationFilter.upcoming:
          return r.startTime.isAfter(now) &&
              r.status != ReservationStatus.cancelled;
        case _ReservationFilter.completed:
          return r.status == ReservationStatus.completed;
        case _ReservationFilter.cancelled:
          return r.status == ReservationStatus.cancelled;
      }
    }).toList()
      ..sort((a, b) => b.startTime.compareTo(a.startTime));

    // ── Stats ──
    final upcoming = allReservations
        .where((r) =>
            r.startTime.isAfter(now) &&
            r.status != ReservationStatus.cancelled)
        .length;
    final completed = allReservations
        .where((r) => r.status == ReservationStatus.completed)
        .length;
    final cancelled = allReservations
        .where((r) => r.status == ReservationStatus.cancelled)
        .length;

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(AppSizes.s24),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: constraints.maxHeight - 48,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── 1. Header ──
                _buildHeader(),
                const SizedBox(height: AppSizes.s20),

                // ── 2. Stats Row ──
                _buildStatsRow(upcoming, completed, cancelled),
                const SizedBox(height: AppSizes.s20),

                // ── 3. Filter Chips ──
                _buildFilterChips(ref, filter),
                const SizedBox(height: AppSizes.s20),

                // ── 4. Content ──
                if (filtered.isEmpty)
                  _buildEmptyState(ref, filter)
                else
                  LayoutBuilder(
                    builder: (context, gridConstraints) {
                      const gap = AppSizes.s16;
                      final w = gridConstraints.maxWidth;
                      final cols = w > 900 ? 3 : w > 550 ? 2 : 1;
                      final cardWidth = (w - gap * (cols - 1)) / cols;
                      return Wrap(
                        spacing: gap,
                        runSpacing: gap,
                        children: filtered.map((r) => SizedBox(
                          width: cardWidth,
                          child: _ReservationCard(reservation: r),
                        )).toList(),
                      );
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ─── Header ────────────────────────────────────────────
  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Mis reservas',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            color: AppColors.accent,
            height: 1.2,
          ),
        ),
        const SizedBox(height: AppSizes.s4),
        Text(
          'Historial de todos tus turnos',
          style: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w400,
            color: AppColors.accent.withValues(alpha: 0.55),
          ),
        ),
      ],
    );
  }

  // ─── Stats Row ─────────────────────────────────────────
  Widget _buildStatsRow(int upcoming, int completed, int cancelled) {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            icon: Icons.upcoming_rounded,
            label: 'Próximos',
            value: '$upcoming',
            color: AppColors.primary,
          ),
        ),
        const SizedBox(width: AppSizes.s12),
        Expanded(
          child: _StatCard(
            icon: Icons.task_alt_rounded,
            label: 'Completados',
            value: '$completed',
            color: const Color(0xFF4A9EFF),
          ),
        ),
        const SizedBox(width: AppSizes.s12),
        Expanded(
          child: _StatCard(
            icon: Icons.cancel_outlined,
            label: 'Cancelados',
            value: '$cancelled',
            color: AppColors.error,
          ),
        ),
      ],
    );
  }

  // ─── Filter Chips ──────────────────────────────────────
  Widget _buildFilterChips(WidgetRef ref, _ReservationFilter current) {
    final chips = <_ChipData>[
      _ChipData('Todos', _ReservationFilter.all, Icons.list_rounded),
      _ChipData(
          'Próximos', _ReservationFilter.upcoming, Icons.upcoming_rounded),
      _ChipData('Completados', _ReservationFilter.completed,
          Icons.task_alt_rounded),
      _ChipData(
          'Cancelados', _ReservationFilter.cancelled, Icons.cancel_outlined),
    ];

    // Scroll horizontal en una sola fila — evita que los chips se partan
    // a una segunda fila en pantallas chicas.
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.zero,
        itemCount: chips.length,
        separatorBuilder: (_, _) => const SizedBox(width: AppSizes.s8),
        itemBuilder: (context, index) {
          final chip = chips[index];
          final isSelected = current == chip.filter;
          return FilterChip(
            selected: isSelected,
            label: Text(
              chip.label,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected
                    ? Colors.white
                    : AppColors.accent.withValues(alpha: 0.7),
              ),
            ),
            avatar: Icon(
              chip.icon,
              size: 16,
              color: isSelected
                  ? Colors.white
                  : AppColors.accent.withValues(alpha: 0.5),
            ),
            selectedColor: AppColors.primary,
            backgroundColor: Colors.white,
            side: BorderSide(
              color: isSelected
                  ? AppColors.primary
                  : AppColors.divider.withValues(alpha: 0.3),
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSizes.radiusFull),
            ),
            showCheckmark: false,
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            onSelected: (_) {
              ref.read(_reservationFilterProvider.notifier).state = chip.filter;
            },
          );
        },
      ),
    );
  }

  // ─── Empty State ───────────────────────────────────────
  Widget _buildEmptyState(WidgetRef ref, _ReservationFilter filter) {
    final isAllFilter = filter == _ReservationFilter.all;
    final emptyIcon = _emptyIcon(filter);
    final emptyColor = _emptyColor(filter);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.s32,
        vertical: AppSizes.s48,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            emptyColor.withValues(alpha: 0.06),
            emptyColor.withValues(alpha: 0.02),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: emptyColor.withValues(alpha: 0.12),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  emptyColor.withValues(alpha: 0.18),
                  emptyColor.withValues(alpha: 0.06),
                ],
              ),
              shape: BoxShape.circle,
            ),
            child: Icon(emptyIcon, size: 40, color: emptyColor),
          ),
          const SizedBox(height: AppSizes.s20),
          Text(
            _emptyTitle(filter),
            style: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.accent,
            ),
          ),
          const SizedBox(height: AppSizes.s8),
          SizedBox(
            width: 280,
            child: Text(
              _emptySubtitle(filter),
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: AppColors.accent.withValues(alpha: 0.55),
                height: 1.5,
              ),
            ),
          ),
          if (isAllFilter || filter == _ReservationFilter.upcoming) ...[
            const SizedBox(height: AppSizes.s24),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primary, AppColors.primaryDark],
                ),
                borderRadius: BorderRadius.circular(AppSizes.radiusFull),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ElevatedButton.icon(
                onPressed: () {
                  ref.read(clientNavIndexProvider.notifier).state = 1;
                },
                icon: const Icon(Icons.add_rounded, size: 20),
                label: Text(
                  'Reservar turno',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  foregroundColor: Colors.white,
                  shadowColor: Colors.transparent,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSizes.radiusFull),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _emptyTitle(_ReservationFilter filter) {
    switch (filter) {
      case _ReservationFilter.all:
        return 'Sin reservas aún';
      case _ReservationFilter.upcoming:
        return 'Sin turnos próximos';
      case _ReservationFilter.completed:
        return '¡Todo al día!';
      case _ReservationFilter.cancelled:
        return '¡Excelente!';
    }
  }

  String _emptySubtitle(_ReservationFilter filter) {
    switch (filter) {
      case _ReservationFilter.all:
        return 'Reservá tu primer turno y aparecerá aquí.';
      case _ReservationFilter.upcoming:
        return 'No tenés turnos por venir. ¡Reservá uno y aparecerá aquí!';
      case _ReservationFilter.completed:
        return 'Todavía no completaste ningún turno. Cuando asistas a uno, aparecerá aquí.';
      case _ReservationFilter.cancelled:
        return 'No tenés cancelaciones. ¡Seguí así!';
    }
  }

  IconData _emptyIcon(_ReservationFilter filter) {
    switch (filter) {
      case _ReservationFilter.all:
        return Icons.calendar_month_rounded;
      case _ReservationFilter.upcoming:
        return Icons.event_available_rounded;
      case _ReservationFilter.completed:
        return Icons.check_circle_outline_rounded;
      case _ReservationFilter.cancelled:
        return Icons.celebration_rounded;
    }
  }

  Color _emptyColor(_ReservationFilter filter) {
    switch (filter) {
      case _ReservationFilter.all:
        return AppColors.primary;
      case _ReservationFilter.upcoming:
        return AppColors.primary;
      case _ReservationFilter.completed:
        return AppColors.success;
      case _ReservationFilter.cancelled:
        return AppColors.success;
    }
  }
}

// ─── Chip data model ─────────────────────────────────────
class _ChipData {
  final String label;
  final _ReservationFilter filter;
  final IconData icon;
  const _ChipData(this.label, this.filter, this.icon);
}

// ─── Stat Card ───────────────────────────────────────────
class _StatCard extends StatefulWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  State<_StatCard> createState() => _StatCardState();
}

class _StatCardState extends State<_StatCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        clipBehavior: Clip.antiAlias,
        transform: _hovered
            ? Matrix4.diagonal3Values(1.03, 1.03, 1.0)
            : Matrix4.identity(),
        transformAlignment: Alignment.center,
        decoration: BoxDecoration(
          color: widget.color.withValues(alpha: _hovered ? 0.10 : 0.06),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: widget.color.withValues(alpha: _hovered ? 0.25 : 0.12),
            width: 1.5,
          ),
          boxShadow: _hovered
              ? [
                  BoxShadow(
                    color: widget.color.withValues(alpha: 0.15),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ]
              : [],
        ),
        // Layout VERTICAL: ícono arriba, número grande, label abajo.
        // Así el contenido cabe limpio aunque la card sea angosta en mobile.
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSizes.s12, AppSizes.s16, AppSizes.s12, AppSizes.s16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // ícono circular sutil
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: widget.color.withValues(alpha: 0.14),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(widget.icon, size: 18, color: widget.color),
                  ),
                  const SizedBox(height: AppSizes.s12),
                  // número grande
                  Text(
                    widget.value,
                    style: GoogleFonts.inter(
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      color: widget.color,
                      height: 1,
                    ),
                  ),
                  const SizedBox(height: AppSizes.s4),
                  // label — una sola línea, recorta con … si fuera muy largo
                  Text(
                    widget.label,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.accent.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
            // Barra inferior con gradiente del color del card
            Container(
              height: 4,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    widget.color,
                    widget.color.withValues(alpha: 0.1),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════
// Premium Reservation Card with expandable detail + actions
// ═════════════════════════════════════════════════════════
class _ReservationCard extends ConsumerStatefulWidget {
  final Reservation reservation;

  const _ReservationCard({required this.reservation});

  @override
  ConsumerState<_ReservationCard> createState() => _ReservationCardState();
}

class _ReservationCardState extends ConsumerState<_ReservationCard> {

  bool _isCancelling = false;
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final r = widget.reservation;
    final isCancelled = r.status == ReservationStatus.cancelled;
    final statusColor = _statusColor(r.status);
    final statusLabel = _statusLabel(r.status);
    final statusIcon = _statusIcon(r.status);
    final canCancel =
        r.status == ReservationStatus.pending ||
        r.status == ReservationStatus.confirmed;
    final isPast = r.startTime.isBefore(DateTime.now());
    final canReschedule = canCancel && !isPast;

    Widget card = MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        transform: _hovered
            ? Matrix4.diagonal3Values(1.02, 1.02, 1.0)
            : Matrix4.identity(),
        transformAlignment: Alignment.center,
        decoration: BoxDecoration(
          color: isCancelled ? const Color(0xFFF8F9FA) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: _hovered
                ? statusColor.withValues(alpha: 0.35)
                : (isCancelled
                    ? AppColors.divider.withValues(alpha: 0.3)
                    : statusColor.withValues(alpha: 0.15)),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: _hovered ? 0.08 : 0.04),
              blurRadius: _hovered ? 20 : 12,
              offset: Offset(0, _hovered ? 8 : 4),
            ),
            if (_hovered && !isCancelled)
              BoxShadow(
                color: statusColor.withValues(alpha: 0.12),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
          ],
        ),
        child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Top gradient bar ──
            Container(
              height: 5,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [statusColor, statusColor.withValues(alpha: 0.3)],
                ),
              ),
            ),

            // ── Card body ──
            Padding(
              padding: const EdgeInsets.all(AppSizes.s16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Status badge
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Avatar circle
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [statusColor, statusColor.withValues(alpha: 0.5)],
                          ),
                        ),
                        child: Center(
                          child: Text(
                            (r.businessName ?? 'N')[0].toUpperCase(),
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      // Badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(AppSizes.radiusFull),
                          border: Border.all(color: statusColor.withValues(alpha: 0.2)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(statusIcon, size: 11, color: statusColor),
                            const SizedBox(width: 3),
                            Text(statusLabel,
                              style: GoogleFonts.inter(
                                fontSize: 10, fontWeight: FontWeight.w700, color: statusColor)),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: AppSizes.s12),

                  // Business name
                  Text(
                    r.businessName ?? 'Negocio',
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.accent,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),

                  // Service name
                  Text(
                    r.serviceName ?? 'Servicio',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppColors.accent.withValues(alpha: 0.5),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),

                  const SizedBox(height: AppSizes.s16),

                  // Date row
                  Row(
                    children: [
                      Icon(Icons.calendar_today_rounded,
                        size: 13, color: AppColors.accent.withValues(alpha: 0.35)),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          _formatPremiumDate(r.startTime),
                          style: GoogleFonts.inter(
                            fontSize: 12, fontWeight: FontWeight.w600,
                            color: AppColors.accent.withValues(alpha: 0.65)),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),

                  // Time row
                  Row(
                    children: [
                      Icon(Icons.access_time_rounded,
                        size: 13, color: AppColors.primary.withValues(alpha: 0.5)),
                      const SizedBox(width: 6),
                      Text(
                        _formatTimeRange(r.startTime, r.endTime),
                        style: GoogleFonts.inter(
                          fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primary),
                      ),
                    ],
                  ),

                  const SizedBox(height: AppSizes.s16),

                  // Divider
                  Container(
                    height: 1,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.transparent,
                          AppColors.divider.withValues(alpha: 0.3),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: AppSizes.s12),

                  // ── Action buttons (compact) ──
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    alignment: WrapAlignment.center,
                    children: [
                      if (canReschedule)
                        _CompactActionBtn(
                          icon: Icons.edit_calendar_rounded,
                          label: 'Reprogramar',
                          color: AppColors.primary,
                          outlined: true,
                          onTap: () => context.push('/reserve/${r.businessId}/service'),
                        ),
                      if (canCancel)
                        _CompactActionBtn(
                          icon: Icons.cancel_outlined,
                          label: 'Cancelar',
                          color: AppColors.error,
                          outlined: false,
                          isLoading: _isCancelling,
                          onTap: () => _showCancelDialog(context, r),
                        ),
                      if (r.status != ReservationStatus.cancelled)
                        _CompactActionBtn(
                          icon: Icons.star_outline_rounded,
                          label: 'Calificar',
                          color: AppColors.primary,
                          filled: true,
                          onTap: () async {
                            final result = await showDialog<bool>(
                              context: context,
                              builder: (_) => ReviewDialog(
                                businessId: r.businessId,
                                businessName: r.businessName ?? 'Negocio',
                                reservationId: r.id,
                              ),
                            );
                            if (result == true && mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Row(children: [
                                    const Icon(Icons.star_rounded, color: Colors.white, size: 20),
                                    const SizedBox(width: 8),
                                    Text('¡Gracias por tu reseña!',
                                        style: GoogleFonts.inter(fontWeight: FontWeight.w500)),
                                  ]),
                                  backgroundColor: Colors.amber.shade700,
                                ),
                              );
                            }
                          },
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        ),
      ),
    );

    // Cancelled cards appear faded
    if (isCancelled) {
      return Opacity(opacity: 0.55, child: card);
    }
    return card;
  }

  // ─── Cancel Dialog ─────────────────────────────────────
  void _showCancelDialog(BuildContext context, Reservation r) {
    final reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizes.radiusLg),
          ),
          title: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.cancel_outlined,
                    color: AppColors.error, size: 22),
              ),
              const SizedBox(width: AppSizes.s12),
              Text(
                'Cancelar reserva',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.accent,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '¿Estás seguro que querés cancelar tu turno en ${r.businessName}?',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: AppSizes.s16),
              // Cancellation reason
              TextField(
                controller: reasonController,
                maxLines: 2,
                decoration: InputDecoration(
                  hintText: 'Motivo de cancelación (opcional)',
                  hintStyle: GoogleFonts.inter(
                    fontSize: 13,
                    color: AppColors.textMuted,
                  ),
                  filled: true,
                  fillColor: const Color(0xFFF7F8FA),
                  border: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(AppSizes.radiusMd),
                    borderSide: BorderSide(
                      color: AppColors.divider.withValues(alpha: 0.3),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(AppSizes.radiusMd),
                    borderSide: BorderSide(
                      color: AppColors.divider.withValues(alpha: 0.3),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(AppSizes.radiusMd),
                    borderSide: const BorderSide(
                      color: AppColors.error,
                    ),
                  ),
                  contentPadding: const EdgeInsets.all(AppSizes.s12),
                ),
              ),
              const SizedBox(height: AppSizes.s8),
              Container(
                padding: const EdgeInsets.all(AppSizes.s12),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                  border: Border.all(
                    color: AppColors.warning.withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded,
                        size: 18, color: AppColors.warning),
                    const SizedBox(width: AppSizes.s8),
                    Expanded(
                      child: Text(
                        'Esta acción no se puede deshacer.',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: AppColors.warning,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(
                'Volver',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            SizedBox(
              width: 140,
              height: 40,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                  _cancelReservation(r, reasonController.text.trim());
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.error,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(AppSizes.radiusMd),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  'Sí, cancelar',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // ─── Cancel reservation ────────────────────────────────
  Future<void> _cancelReservation(Reservation r, String reason) async {
    setState(() => _isCancelling = true);
    try {
      await ReservationRepository().updateStatus(
        r.id,
        ReservationStatus.cancelled.name,
        cancellationReason: reason.isNotEmpty ? reason : null,
      );
      ref.invalidate(clientReservationsProvider);

      // Notify business owner about cancellation
      final user = ref.read(currentUserProvider);
      if (user != null && r.businessId.isNotEmpty) {
        final businesses = ref.read(businessesProvider).value ?? [];
        final biz = businesses.where((b) => b.id == r.businessId).firstOrNull;
        if (biz != null) {
          NotificationRepository().create(
            userId: biz.ownerId,
            businessId: r.businessId,
            type: NotificationType.cancellation,
            title: 'Reserva cancelada',
            body: '${user.fullName} canceló ${r.serviceName ?? "un turno"} del ${DateFormat('dd/MM HH:mm', 'es').format(r.startTime)}',
            reservationId: r.id,
          ).catchError((_) {});

          // ── Send cancellation emails (fire-and-forget) ──
          // Email to client (current user)
          EmailService.enviarEmailCancelacionTurnoCliente(
            clientEmail: user.email,
            clientName: user.fullName,
            businessName: r.businessName ?? 'Negocio',
            serviceName: r.serviceName ?? 'Servicio',
            startTime: r.startTime,
            cancelledBy: user.fullName,
            reason: reason.isNotEmpty ? reason : null,
          );

          // Email to business owner
          ProfileRepository().getProfile(biz.ownerId).then((owner) {
            if (owner != null) {
              EmailService.enviarEmailCancelacionTurnoNegocio(
                businessEmail: owner.email,
                businessName: biz.name,
                clientName: user.fullName,
                serviceName: r.serviceName ?? 'Servicio',
                startTime: r.startTime,
                reason: reason.isNotEmpty ? reason : null,
              );
            }
          }).catchError((_) {});
        }
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded,
                    color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Reserva cancelada correctamente',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w500),
                ),
              ],
            ),
            backgroundColor: AppColors.primary,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSizes.radiusMd),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cancelar: $e'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isCancelling = false);
    }
  }

  // ─── Helpers ───────────────────────────────────────────

  String _formatPremiumDate(DateTime dt) {
    final dayName = _capitalize(DateFormat('EEEE', 'es').format(dt));
    final day = dt.day;
    final month = DateFormat('MMMM', 'es').format(dt);
    return '$dayName $day de $month';
  }

  String _formatTimeRange(DateTime start, DateTime end) {
    return '${DateFormat('HH:mm').format(start)} - ${DateFormat('HH:mm').format(end)}';
  }

  String _capitalize(String s) =>
      s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}';

  Color _statusColor(ReservationStatus status) {
    switch (status) {
      case ReservationStatus.pending:
        return const Color(0xFF5B8DEF);
      case ReservationStatus.confirmed:
        return AppColors.primary;
      case ReservationStatus.cancelled:
        return AppColors.error;
      case ReservationStatus.completed:
        return const Color(0xFF4A9EFF);
    }
  }

  IconData _statusIcon(ReservationStatus status) {
    switch (status) {
      case ReservationStatus.pending:
        return Icons.hourglass_top_rounded;
      case ReservationStatus.confirmed:
        return Icons.check_circle_rounded;
      case ReservationStatus.cancelled:
        return Icons.cancel_rounded;
      case ReservationStatus.completed:
        return Icons.task_alt_rounded;
    }
  }

  String _statusLabel(ReservationStatus status) {
    switch (status) {
      case ReservationStatus.pending:
        return 'Pendiente';
      case ReservationStatus.confirmed:
        return 'Confirmado';
      case ReservationStatus.cancelled:
        return 'Cancelado';
      case ReservationStatus.completed:
        return 'Completado';
    }
  }
}

// ─── Detail Info Row ─────────────────────────────────────
class _DetailInfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  const _DetailInfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.textMuted),
        const SizedBox(width: AppSizes.s8),
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppColors.textMuted,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: valueColor ?? AppColors.accent,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

// ─── Action Chip ─────────────────────────────────────────
class _ActionChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  final bool isLoading;

  const _ActionChip({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(AppSizes.radiusFull),
      child: InkWell(
        onTap: isLoading ? null : onTap,
        borderRadius: BorderRadius.circular(AppSizes.radiusFull),
        child: Padding(
          padding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isLoading)
                SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: color,
                  ),
                )
              else
                Icon(icon, size: 14, color: color),
              const SizedBox(width: 5),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Compact pill-shaped action button for grid cards.
class _CompactActionBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  final bool outlined;
  final bool filled;
  final bool isLoading;

  const _CompactActionBtn({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    this.outlined = false,
    this.filled = false,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final bg = filled
        ? null  // gradient used instead
        : outlined
            ? Colors.transparent
            : color.withValues(alpha: 0.1);
    final fg = filled ? Colors.white : color;

    Widget chip = Container(
      decoration: BoxDecoration(
        color: bg,
        gradient: filled
            ? LinearGradient(colors: [color, color.withValues(alpha: 0.75)])
            : null,
        borderRadius: BorderRadius.circular(AppSizes.radiusFull),
        border: outlined
            ? Border.all(color: color.withValues(alpha: 0.4), width: 1.2)
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isLoading ? null : onTap,
          borderRadius: BorderRadius.circular(AppSizes.radiusFull),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isLoading)
                  SizedBox(
                    width: 12, height: 12,
                    child: CircularProgressIndicator(strokeWidth: 2, color: fg),
                  )
                else
                  Icon(icon, size: 13, color: fg),
                const SizedBox(width: 4),
                Text(label,
                  style: GoogleFonts.inter(
                    fontSize: 11, fontWeight: FontWeight.w600, color: fg)),
              ],
            ),
          ),
        ),
      ),
    );

    return chip;
  }
}
