import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:reservpy/src/core/constants/app_sizes.dart';
import 'package:reservpy/src/core/constants/app_colors.dart';
import 'package:reservpy/src/shared/providers/providers.dart';
import 'package:reservpy/src/shared/models/models.dart';

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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
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
                _buildHeader(theme),
                const SizedBox(height: AppSizes.s24),

                // ── 2. Filter Chips ──
                _buildFilterChips(ref, filter, theme, colorScheme),
                const SizedBox(height: AppSizes.s24),

                // ── 3. Content ──
                if (filtered.isEmpty)
                  _buildEmptyState(theme, colorScheme, ref, filter)
                else
                  ...filtered.map(
                    (r) => Padding(
                      padding: const EdgeInsets.only(bottom: AppSizes.s16),
                      child: _ReservationCard(reservation: r),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ─── Header ────────────────────────────────────────────
  Widget _buildHeader(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Mis reservas',
          style: GoogleFonts.inter(
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

  // ─── Filter Chips ──────────────────────────────────────
  Widget _buildFilterChips(
    WidgetRef ref,
    _ReservationFilter current,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    final chips = <_ChipData>[
      _ChipData('Todos', _ReservationFilter.all, Icons.list_rounded),
      _ChipData('Próximos', _ReservationFilter.upcoming, Icons.upcoming_rounded),
      _ChipData('Completados', _ReservationFilter.completed, Icons.task_alt_rounded),
      _ChipData('Cancelados', _ReservationFilter.cancelled, Icons.cancel_outlined),
    ];

    return Wrap(
      spacing: AppSizes.s8,
      runSpacing: AppSizes.s8,
      children: chips.map((chip) {
        final isSelected = current == chip.filter;
        return FilterChip(
          selected: isSelected,
          label: Text(
            chip.label,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              color: isSelected ? Colors.white : AppColors.accent.withValues(alpha: 0.7),
            ),
          ),
          avatar: Icon(
            chip.icon,
            size: 16,
            color: isSelected ? Colors.white : AppColors.accent.withValues(alpha: 0.5),
          ),
          selectedColor: AppColors.primary,
          backgroundColor: Colors.white,
          side: BorderSide(
            color: isSelected
                ? AppColors.primary
                : colorScheme.outline.withValues(alpha: 0.15),
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
      }).toList(),
    );
  }

  // ─── Empty State ───────────────────────────────────────
  Widget _buildEmptyState(
    ThemeData theme,
    ColorScheme colorScheme,
    WidgetRef ref,
    _ReservationFilter filter,
  ) {
    final isAllFilter = filter == _ReservationFilter.all;

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
            AppColors.primary.withValues(alpha: 0.06),
            AppColors.warning.withValues(alpha: 0.04),
          ],
        ),
        borderRadius: BorderRadius.circular(AppSizes.radiusXl),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.12),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Icon circle
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.primary.withValues(alpha: 0.15),
                  AppColors.primary.withValues(alpha: 0.08),
                ],
              ),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.calendar_month_rounded,
              size: 36,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: AppSizes.s20),

          Text(
            isAllFilter ? 'Sin reservas aún' : _emptyTitle(filter),
            style: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.accent,
            ),
          ),
          const SizedBox(height: AppSizes.s8),

          Text(
            isAllFilter
                ? 'Reservá tu primer turno y aparecerá aquí.'
                : _emptySubtitle(filter),
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: AppColors.accent.withValues(alpha: 0.55),
              height: 1.5,
            ),
          ),

          if (isAllFilter) ...[
            const SizedBox(height: AppSizes.s24),
            ElevatedButton.icon(
              onPressed: () {
                ref.read(clientNavIndexProvider.notifier).state = 1;
              },
              icon: const Icon(Icons.calendar_today_rounded, size: 18),
              label: Text(
                'Reservar ahora',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.s24,
                  vertical: AppSizes.s12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSizes.radiusFull),
                ),
                elevation: 0,
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
        return 'Sin turnos completados';
      case _ReservationFilter.cancelled:
        return 'Sin cancelaciones';
    }
  }

  String _emptySubtitle(_ReservationFilter filter) {
    switch (filter) {
      case _ReservationFilter.all:
        return 'Reservá tu primer turno y aparecerá aquí.';
      case _ReservationFilter.upcoming:
        return 'No tenés turnos por venir. ¡Reservá uno!';
      case _ReservationFilter.completed:
        return 'Todavía no completaste ningún turno.';
      case _ReservationFilter.cancelled:
        return 'No cancelaste ningún turno.';
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

// ═════════════════════════════════════════════════════════
// Premium Reservation Card
// ═════════════════════════════════════════════════════════
class _ReservationCard extends StatelessWidget {
  final Reservation reservation;

  const _ReservationCard({required this.reservation});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final statusColor = _statusColor(reservation.status);
    final statusLabel = _statusLabel(reservation.status);

    return Container(
      decoration: BoxDecoration(
        color: theme.cardTheme.color ?? Colors.white,
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        border: Border.all(
          color: colorScheme.outline.withValues(alpha: 0.08),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
          BoxShadow(
            color: statusColor.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Left status indicator bar (3px) ──
              Container(
                width: 3,
                decoration: BoxDecoration(
                  color: statusColor,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(AppSizes.radiusLg),
                    bottomLeft: Radius.circular(AppSizes.radiusLg),
                  ),
                ),
              ),

              // ── Card content ──
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(AppSizes.s16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Row 1: Business name + badge ──
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  reservation.businessName ?? 'Negocio',
                                  style: GoogleFonts.inter(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.accent,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  reservation.serviceName ?? 'Servicio',
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w400,
                                    color: AppColors.accent.withValues(alpha: 0.55),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: AppSizes.s12),
                          // Status badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: statusColor.withValues(alpha: 0.1),
                              borderRadius:
                                  BorderRadius.circular(AppSizes.radiusFull),
                            ),
                            child: Text(
                              statusLabel,
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: statusColor,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: AppSizes.s12),

                      // ── Row 2: Date + Time ──
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSizes.s12,
                          vertical: AppSizes.s8,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF7F8FA),
                          borderRadius:
                              BorderRadius.circular(AppSizes.radiusSm),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.calendar_today_rounded,
                              size: 14,
                              color: AppColors.accent.withValues(alpha: 0.4),
                            ),
                            const SizedBox(width: AppSizes.s8),
                            Expanded(
                              child: Text(
                                _formatPremiumDate(reservation.startTime),
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.accent.withValues(alpha: 0.7),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: AppSizes.s12),

                      // ── Row 3: Ver detalle button ──
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () {
                            // TODO: Navigate to reservation detail
                          },
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.primary,
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSizes.s12,
                              vertical: AppSizes.s4,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(AppSizes.radiusSm),
                            ),
                            visualDensity: VisualDensity.compact,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Ver detalle',
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primary,
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Icon(
                                Icons.arrow_forward_ios_rounded,
                                size: 12,
                                color: AppColors.primary,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Helpers ───────────────────────────────────────────

  /// Formats: "Lunes 28 de mayo, 10:30 hs"
  String _formatPremiumDate(DateTime dt) {
    final dayName = _capitalize(DateFormat('EEEE', 'es').format(dt));
    final day = dt.day;
    final month = DateFormat('MMMM', 'es').format(dt);
    final time = DateFormat('HH:mm').format(dt);
    return '$dayName $day de $month, $time hs';
  }

  String _capitalize(String s) =>
      s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}';

  Color _statusColor(ReservationStatus status) {
    switch (status) {
      case ReservationStatus.pending:
        return AppColors.warning;
      case ReservationStatus.confirmed:
        return AppColors.primary;
      case ReservationStatus.cancelled:
        return AppColors.error;
      case ReservationStatus.completed:
        return const Color(0xFF4A9EFF); // premium blue
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
