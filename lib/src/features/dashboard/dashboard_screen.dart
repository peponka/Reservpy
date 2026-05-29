import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:reservpy/src/core/constants/app_colors.dart';
import 'package:reservpy/src/core/constants/app_sizes.dart';
import 'package:reservpy/src/shared/models/models.dart';
import 'package:reservpy/src/shared/providers/providers.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  late Timer _clockTimer;
  DateTime _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    _clockTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _clockTimer.cancel();
    super.dispose();
  }

  String _greeting() {
    final hour = _now.hour;
    if (hour < 12) return 'BUENOS DÍAS';
    if (hour < 19) return 'BUENAS TARDES';
    return 'BUENAS NOCHES';
  }

  String _greetingTitle() {
    final hour = _now.hour;
    if (hour < 12) return 'Buenos días';
    if (hour < 19) return 'Buenas tardes';
    return 'Buenas noches';
  }

  String _formattedClock() {
    final hour = _now.hour;
    final minute = _now.minute.toString().padLeft(2, '0');
    final period = hour < 12 ? 'a.m.' : 'p.m.';
    final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    return '$displayHour:$minute $period';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final user = ref.watch(currentUserProvider);
    final stats = ref.watch(enhancedDashboardStatsProvider);
    final allReservations = ref.watch(businessReservationsProvider).value ?? [];

    final userName = user?.firstName ?? 'Usuario';
    final reservationCount = allReservations.length;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth > AppSizes.breakpointTablet;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(AppSizes.s24),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: constraints.maxHeight - 48,
              maxWidth: constraints.maxWidth - 48,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ═══════════════════════════════════════════════════
                // 1. GREETING HEADER
                // ═══════════════════════════════════════════════════
                _buildGreetingHeader(theme, colorScheme, userName, isDesktop),
                const SizedBox(height: AppSizes.s24),

                // ═══════════════════════════════════════════════════
                // 2. KPI CARDS ROW
                // ═══════════════════════════════════════════════════
                _buildKpiSection(theme, colorScheme, stats, isDesktop),
                const SizedBox(height: AppSizes.s24),

                // ═══════════════════════════════════════════════════
                // 3. TWO-COLUMN: UPCOMING + TODAY AGENDA
                // ═══════════════════════════════════════════════════
                _buildContentSection(theme, colorScheme, stats, isDesktop),
                const SizedBox(height: AppSizes.s24),

                // ═══════════════════════════════════════════════════
                // 4. PLAN FREE BANNER
                // ═══════════════════════════════════════════════════
                _buildPlanBanner(theme, colorScheme, reservationCount),
              ],
            ),
          ),
        );
      },
    );
  }

  // ─────────────────────────────────────────────────────────────────
  // 1. GREETING HEADER
  // ─────────────────────────────────────────────────────────────────
  Widget _buildGreetingHeader(
    ThemeData theme,
    ColorScheme colorScheme,
    String userName,
    bool isDesktop,
  ) {
    final greetingColumn = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _greeting(),
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: AppColors.primary,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: AppSizes.s4),
        Text(
          '${_greetingTitle()}, $userName',
          style: GoogleFonts.inter(
            fontSize: isDesktop ? 28 : 22,
            fontWeight: FontWeight.w700,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: AppSizes.s4),
        Text(
          'Bienvenido. Gestioná tus turnos del día.',
          style: GoogleFonts.inter(
            fontSize: 14,
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );

    final clockCard = Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.s24,
        vertical: 14.0,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withValues(alpha: 0.08),
            AppColors.primary.withValues(alpha: 0.01),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.25),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _formattedClock(),
            style: GoogleFonts.inter(
              fontSize: isDesktop ? 34 : 26,
              fontWeight: FontWeight.w800,
              color: AppColors.primary,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: AppSizes.s2),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                'HORA LOCAL',
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary.withValues(alpha: 0.7),
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
        ],
      ),
    );

    if (isDesktop) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(child: greetingColumn),
          const SizedBox(width: AppSizes.s16),
          clockCard,
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        greetingColumn,
        const SizedBox(height: AppSizes.s16),
        Align(alignment: Alignment.centerLeft, child: clockCard),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────────
  // 2. KPI CARDS
  // ─────────────────────────────────────────────────────────────────
  Widget _buildKpiSection(
    ThemeData theme,
    ColorScheme colorScheme,
    EnhancedDashboardStats stats,
    bool isDesktop,
  ) {
    final kpis = [
      _KpiData(
        label: 'Turnos hoy',
        value: '${stats.reservationsToday}',
        icon: Icons.calendar_today_rounded,
        color: AppColors.primary,
        trendPercent: 12.5,
        trendPoints: const [3, 5, 4, 7, 6, 8, 9],
      ),
      _KpiData(
        label: 'Esta semana',
        value: '${stats.reservationsThisWeek}',
        icon: Icons.date_range_rounded,
        color: AppColors.info,
        trendPercent: 8.2,
        trendPoints: const [20, 24, 22, 28, 32, 30, 35],
      ),
      _KpiData(
        label: 'Pendientes',
        value: '${stats.pendingCount}',
        icon: Icons.hourglass_empty_rounded,
        color: stats.pendingCount > 0 ? AppColors.warning : AppColors.textMuted,
        trendPercent: stats.pendingCount > 0 ? -15.0 : 0.0,
        trendPoints: stats.pendingCount > 0 ? const [10, 8, 9, 6, 5, 4, 2] : const [],
      ),
      _KpiData(
        label: 'Ingresos est.',
        value: 'Gs. ${NumberFormat('#,###', 'es').format(stats.estimatedRevenue)}',
        icon: Icons.attach_money_rounded,
        color: AppColors.success,
        trendPercent: 24.1,
        trendPoints: const [150, 180, 210, 200, 240, 270, 310],
      ),
    ];

    if (isDesktop) {
      return Row(
        children: kpis.asMap().entries.map((entry) {
          return Expanded(
            child: Padding(
              padding: EdgeInsets.only(
                left: entry.key == 0 ? 0 : AppSizes.s6,
                right: entry.key == kpis.length - 1 ? 0 : AppSizes.s6,
              ),
              child: _buildKpiCard(theme, colorScheme, entry.value),
            ),
          );
        }).toList(),
      );
    }

    // Mobile: 2x2 grid
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _buildKpiCard(theme, colorScheme, kpis[0])),
            const SizedBox(width: AppSizes.s12),
            Expanded(child: _buildKpiCard(theme, colorScheme, kpis[1])),
          ],
        ),
        const SizedBox(height: AppSizes.s12),
        Row(
          children: [
            Expanded(child: _buildKpiCard(theme, colorScheme, kpis[2])),
            const SizedBox(width: AppSizes.s12),
            Expanded(child: _buildKpiCard(theme, colorScheme, kpis[3])),
          ],
        ),
      ],
    );
  }

  Widget _buildKpiCard(ThemeData theme, ColorScheme colorScheme, _KpiData data) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.s16),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        gradient: LinearGradient(
          colors: [
            theme.cardTheme.color ?? Colors.white,
            data.color.withValues(alpha: 0.02),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
          color: data.color.withValues(alpha: 0.15),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: data.color.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSizes.s8),
                decoration: BoxDecoration(
                  color: data.color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                ),
                child: Icon(data.icon, color: data.color, size: 18),
              ),
              const SizedBox(width: AppSizes.s8),
              Expanded(
                child: Text(
                  data.label,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.s12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data.value,
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: colorScheme.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (data.trendPercent != 0.0) ...[
                      const SizedBox(height: 4),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            data.trendPercent > 0
                                ? Icons.arrow_upward_rounded
                                : Icons.arrow_downward_rounded,
                            size: 12,
                            color: data.trendPercent > 0
                                ? AppColors.success
                                : AppColors.error,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            '${data.trendPercent > 0 ? '+' : ''}${data.trendPercent}%',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: data.trendPercent > 0
                                  ? AppColors.success
                                  : AppColors.error,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              if (data.trendPoints.isNotEmpty)
                SizedBox(
                  width: 56,
                  height: 28,
                  child: _AnimatedSparkline(
                    values: data.trendPoints,
                    color: data.color,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────
  // 3. CONTENT SECTION (Upcoming + Today)
  // ─────────────────────────────────────────────────────────────────
  Widget _buildContentSection(
    ThemeData theme,
    ColorScheme colorScheme,
    EnhancedDashboardStats stats,
    bool isDesktop,
  ) {
    final upcomingCard = _buildUpcomingCard(theme, colorScheme, stats.upcomingReservations);
    final todayCard = _buildTodayAgendaCard(theme, colorScheme, stats.todayReservations);

    if (isDesktop) {
      return IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 2, child: upcomingCard),
            const SizedBox(width: AppSizes.s20),
            Expanded(flex: 1, child: todayCard),
          ],
        ),
      );
    }

    return Column(
      children: [
        upcomingCard,
        const SizedBox(height: AppSizes.s20),
        todayCard,
      ],
    );
  }

  // ── Upcoming Reservations Card ──
  Widget _buildUpcomingCard(
    ThemeData theme,
    ColorScheme colorScheme,
    List<Reservation> upcoming,
  ) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.s20),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.08),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.04),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.event_note_rounded, size: 20, color: AppColors.primary),
              const SizedBox(width: AppSizes.s8),
              Text(
                'Próximos turnos',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.s4),
          Text(
            'Próximos 14 días',
            style: GoogleFonts.inter(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSizes.s20),
          if (upcoming.isEmpty)
            _buildEmptyUpcoming(theme, colorScheme)
          else
            ...upcoming.take(5).map(
              (r) => _buildReservationTile(theme, colorScheme, r),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyUpcoming(ThemeData theme, ColorScheme colorScheme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: AppSizes.s32),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colorScheme.outline.withValues(alpha: 0.02),
            colorScheme.outline.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        border: Border.all(
          color: colorScheme.outline.withValues(alpha: 0.06),
          width: 1.5,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.calendar_today_rounded,
              color: AppColors.primary,
              size: 24,
            ),
          ),
          const SizedBox(height: AppSizes.s16),
          Text(
            'Sin turnos próximos',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: AppSizes.s4),
          Text(
            'Reservá un turno y aparecerá acá',
            style: GoogleFonts.inter(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReservationTile(
    ThemeData theme,
    ColorScheme colorScheme,
    Reservation r,
  ) {
    final timeStr =
        '${DateFormat('HH:mm').format(r.startTime)} – ${DateFormat('HH:mm').format(r.endTime)}';
    final dateStr = DateFormat("EEE d MMM", 'es').format(r.startTime);

    return Container(
      margin: const EdgeInsets.only(bottom: AppSizes.s8),
      padding: const EdgeInsets.all(AppSizes.s12),
      decoration: BoxDecoration(
        color: colorScheme.outline.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        border: Border.all(
          color: colorScheme.outline.withValues(alpha: 0.06),
        ),
      ),
      child: Row(
        children: [
          // Avatar circle
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                (r.clientName?.isNotEmpty == true)
                    ? r.clientName![0].toUpperCase()
                    : 'C',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSizes.s12),
          // Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  r.clientName ?? 'Cliente',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppSizes.s2),
                Text(
                  '${r.serviceName ?? 'Servicio'} · $timeStr',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSizes.s8),
          // Date + Status
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                dateStr,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppSizes.s4),
              _buildStatusBadge(r.status),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(ReservationStatus status) {
    final Color color;
    final String label;
    switch (status) {
      case ReservationStatus.pending:
        color = AppColors.statusPending;
        label = 'Pendiente';
      case ReservationStatus.confirmed:
        color = AppColors.statusConfirmed;
        label = 'Confirmado';
      case ReservationStatus.cancelled:
        color = AppColors.statusCancelled;
        label = 'Cancelado';
      case ReservationStatus.completed:
        color = AppColors.statusCompleted;
        label = 'Completado';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }

  // ── Today Agenda Card ──
  Widget _buildTodayAgendaCard(
    ThemeData theme,
    ColorScheme colorScheme,
    List<Reservation> todayReservations,
  ) {
    final activeToday = todayReservations
        .where((r) => r.status != ReservationStatus.cancelled)
        .toList();

    final formattedToday =
        DateFormat("EEEE, d 'de' MMMM", 'es').format(DateTime.now());
    final capitalizedDate =
        formattedToday[0].toUpperCase() + formattedToday.substring(1);

    return Container(
      padding: const EdgeInsets.all(AppSizes.s20),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        border: Border.all(
          color: AppColors.info.withValues(alpha: 0.08),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.info.withValues(alpha: 0.04),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.today_rounded, size: 20, color: AppColors.info),
              const SizedBox(width: AppSizes.s8),
              Expanded(
                child: Text(
                  'Agenda de hoy',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: colorScheme.onSurface,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.s4),
          Text(
            capitalizedDate,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSizes.s20),
          if (activeToday.isEmpty)
            _buildEmptyAgenda(theme, colorScheme)
          else
            ...activeToday.map(
              (r) => _buildAgendaTimelineItem(theme, colorScheme, r, r == activeToday.last),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyAgenda(ThemeData theme, ColorScheme colorScheme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSizes.s20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colorScheme.outline.withValues(alpha: 0.02),
            colorScheme.outline.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        border: Border.all(
          color: colorScheme.outline.withValues(alpha: 0.06),
          width: 1.5,
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.beach_access_rounded,
            size: 36,
            color: colorScheme.outline.withValues(alpha: 0.35),
          ),
          const SizedBox(height: AppSizes.s12),
          Text(
            'Tu agenda está vacía',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: AppSizes.s4),
          Text(
            'Reservá tu primer turno en segundos.\nSin llamadas, sin esperas.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: AppSizes.s16),
          OutlinedButton.icon(
            onPressed: () {
              ref.read(businessNavIndexProvider.notifier).state = 2; // Reservations tab
            },
            icon: const Icon(Icons.add_rounded, size: 18),
            label: Text(
              'Nuevo turno',
              style: GoogleFonts.inter(fontWeight: FontWeight.w600),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: const BorderSide(color: AppColors.primary, width: 1.5),
              padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.s16,
                vertical: AppSizes.s8,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSizes.radiusMd),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAgendaTimelineItem(
    ThemeData theme,
    ColorScheme colorScheme,
    Reservation r,
    bool isLast,
  ) {
    final timeStr = DateFormat('HH:mm').format(r.startTime);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Timeline dot & line
        SizedBox(
          width: 24,
          child: Column(
            children: [
              const SizedBox(height: 4),
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: _statusColor(r.status),
                  shape: BoxShape.circle,
                ),
              ),
              if (!isLast)
                Container(
                  width: 2,
                  height: 44,
                  color: colorScheme.outline.withValues(alpha: 0.12),
                ),
            ],
          ),
        ),
        const SizedBox(width: AppSizes.s8),
        // Content
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: AppSizes.s12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  timeStr,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: AppSizes.s2),
                Text(
                  r.clientName ?? 'Cliente',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  r.serviceName ?? 'Servicio',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Color _statusColor(ReservationStatus status) {
    switch (status) {
      case ReservationStatus.pending:
        return AppColors.statusPending;
      case ReservationStatus.confirmed:
        return AppColors.statusConfirmed;
      case ReservationStatus.cancelled:
        return AppColors.statusCancelled;
      case ReservationStatus.completed:
        return AppColors.statusCompleted;
    }
  }

  // ─────────────────────────────────────────────────────────────────
  // 4. PLAN FREE BANNER
  // ─────────────────────────────────────────────────────────────────
  Widget _buildPlanBanner(
    ThemeData theme,
    ColorScheme colorScheme,
    int reservationCount,
  ) {
    final usage = (reservationCount / 10).clamp(0.0, 1.0);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.s24,
        vertical: AppSizes.s20,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary,
            isDark ? AppColors.accent : AppColors.accentLight,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppSizes.radiusXl),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.2),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSizes.s8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                ),
                child: const Icon(
                  Icons.workspace_premium_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: AppSizes.s16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Plan Free · $reservationCount/10 reservas usadas',
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: AppSizes.s4),
                    Text(
                      'Actualizá a Pro para turnos ilimitados y funciones premium',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                    ),
                    const SizedBox(height: AppSizes.s12),
                    ClipRRect(
                      borderRadius:
                          BorderRadius.circular(AppSizes.radiusFull),
                      child: LinearProgressIndicator(
                        value: usage,
                        backgroundColor: Colors.white.withValues(alpha: 0.2),
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          Colors.white,
                        ),
                        minHeight: 8,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.s16),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton(
              onPressed: () {
                ref.read(businessNavIndexProvider.notifier).state = 7;
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: AppColors.accent,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.s20,
                  vertical: 10.0,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                ),
                elevation: 0,
              ),
              child: Text(
                'Actualizar a Pro',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w700,
                  color: AppColors.accent,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Helper data class for KPI cards
// ─────────────────────────────────────────────────────────────────
class _KpiData {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final double trendPercent;
  final List<double> trendPoints;

  const _KpiData({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.trendPercent = 0.0,
    this.trendPoints = const [],
  });
}

class _AnimatedSparkline extends StatefulWidget {
  final List<double> values;
  final Color color;

  const _AnimatedSparkline({
    required this.values,
    required this.color,
  });

  @override
  State<_AnimatedSparkline> createState() => _AnimatedSparklineState();
}

class _AnimatedSparklineState extends State<_AnimatedSparkline>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutQuint,
    );
    _controller.forward();
  }

  @override
  void didUpdateWidget(covariant _AnimatedSparkline oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.values != widget.values) {
      _controller.reset();
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _animation,
      builder: (context, _) {
        return CustomPaint(
          size: Size.infinite,
          painter: _SparklinePainter(
            values: widget.values,
            color: widget.color,
            animationValue: _animation.value,
          ),
        );
      },
    );
  }
}

class _SparklinePainter extends CustomPainter {
  final List<double> values;
  final Color color;
  final double animationValue;

  _SparklinePainter({
    required this.values,
    required this.color,
    required this.animationValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty || values.length < 2) return;

    final maxVal = values.reduce(math.max);
    final minVal = values.reduce(math.min);
    final valRange = maxVal - minVal == 0 ? 1.0 : maxVal - minVal;

    final width = size.width;
    final height = size.height;

    final List<Offset> points = [];
    final double stepX = width / (values.length - 1);

    for (int i = 0; i < values.length; i++) {
      final double x = i * stepX;
      final double normalized = (values[i] - minVal) / valRange;
      final double y = height - (normalized * (height - 8) + 4);
      points.add(Offset(x, y));
    }

    final path = Path();
    path.moveTo(points[0].dx, points[0].dy);

    for (int i = 0; i < points.length - 1; i++) {
      final p0 = points[i];
      final p1 = points[i + 1];
      final controlX = (p0.dx + p1.dx) / 2;
      path.cubicTo(
        controlX, p0.dy,
        controlX, p1.dy,
        p1.dx, p1.dy,
      );
    }

    final animatedPath = Path();
    final pathMetrics = path.computeMetrics();
    for (final metric in pathMetrics) {
      final length = metric.length * animationValue;
      animatedPath.addPath(metric.extractPath(0, length), Offset.zero);
    }

    if (animatedPath.getBounds().width > 0) {
      final fillPath = Path.from(animatedPath);
      final double lastX = width * animationValue;
      
      fillPath.lineTo(lastX, height);
      fillPath.lineTo(0, height);
      fillPath.close();

      final fillGradient = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          color.withValues(alpha: 0.15),
          color.withValues(alpha: 0.0),
        ],
      );
      final fillPaint = Paint()
        ..shader = fillGradient.createShader(Rect.fromLTWH(0, 0, width, height))
        ..style = PaintingStyle.fill;
      canvas.drawPath(fillPath, fillPaint);
    }

    final linePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(animatedPath, linePaint);

    if (animationValue > 0.9) {
      final lastPoint = points.last;
      
      final glowPaint = Paint()
        ..color = color.withValues(alpha: 0.3)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(lastPoint, 5.0, glowPaint);

      final dotPaint = Paint()
        ..color = color
        ..style = PaintingStyle.fill;
      canvas.drawCircle(lastPoint, 2.5, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _SparklinePainter old) =>
      old.animationValue != animationValue ||
      old.values != values ||
      old.color != color;
}
