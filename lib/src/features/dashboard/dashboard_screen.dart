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
    final allReservations =
        ref.watch(businessReservationsProvider).value ?? [];

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
                // 1. GREETING HEADER
                _buildGreetingHeader(
                    theme, colorScheme, userName, isDesktop),
                const SizedBox(height: AppSizes.s24),

                // 2. KPI CARDS ROW
                _buildKpiSection(
                    theme, colorScheme, stats, isDesktop),
                const SizedBox(height: AppSizes.s24),

                // 3. ALERTS / PENDING ACTIONS
                if (stats.pendingCount > 0) ...[
                  _buildPendingAlert(theme, stats),
                  const SizedBox(height: AppSizes.s24),
                ],

                // 4. CHARTS + AGENDA ROW
                _buildChartsAndAgenda(
                    theme, colorScheme, stats, isDesktop),
                const SizedBox(height: AppSizes.s24),

                // 5. BOTTOM: Popular services + Plan banner
                _buildBottomSection(
                    theme, colorScheme, stats, reservationCount, isDesktop),
              ],
            ),
          ),
        );
      },
    );
  }

  // -----------------------------------------------------------
  // 1. GREETING HEADER (rediseño premium)
  //   - Saludo + nombre con avatar circular con la inicial
  //   - Sin badge redundante, sin reloj (ya está en la barra del teléfono)
  // -----------------------------------------------------------
  Widget _buildGreetingHeader(
    ThemeData theme,
    ColorScheme colorScheme,
    String userName,
    bool isDesktop,
  ) {
    final initial =
        userName.trim().isNotEmpty ? userName.trim()[0].toUpperCase() : '?';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
          AppSizes.s24, AppSizes.s24, AppSizes.s24, AppSizes.s24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF0A2540),
            Color(0xFF143866),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0A2540).withValues(alpha: 0.25),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Acento decorativo
          Positioned(
            top: -40,
            right: -40,
            child: IgnorePointer(
              child: Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primary.withValues(alpha: 0.10),
                ),
              ),
            ),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${_greetingTitle()},',
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: Colors.white.withValues(alpha: 0.7),
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: AppSizes.s4),
                    Text(
                      userName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: isDesktop ? 30 : 26,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        height: 1.1,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: AppSizes.s8),
                    Text(
                      'Gestioná tus turnos del día',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: Colors.white.withValues(alpha: 0.65),
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSizes.s12),
              // Avatar circular con la inicial del usuario (toque humano)
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      AppColors.primary,
                      Color(0xFF198A6C),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.4),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    initial,
                    style: GoogleFonts.inter(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // -----------------------------------------------------------
  // 2. KPI CARDS
  // -----------------------------------------------------------
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
      ),
      _KpiData(
        label: 'Esta semana',
        value: '${stats.reservationsThisWeek}',
        icon: Icons.date_range_rounded,
        color: AppColors.info,
      ),
      _KpiData(
        label: 'Ocupación',
        value: '${stats.occupancyPercent.round()}%',
        icon: Icons.pie_chart_rounded,
        color: stats.occupancyPercent > 70
            ? AppColors.success
            : stats.occupancyPercent > 30
                ? AppColors.warning
                : AppColors.error,
      ),
      _KpiData(
        label: 'Ingresos est.',
        value:
            'Gs. ${NumberFormat('#,###', 'es').format(stats.estimatedRevenue)}',
        icon: Icons.attach_money_rounded,
        color: AppColors.success,
      ),
    ];

    if (isDesktop) {
      return Row(
        children: kpis.asMap().entries.map((entry) {
          return Expanded(
            child: Padding(
              padding: EdgeInsets.only(
                left: entry.key == 0 ? 0 : AppSizes.s6,
                right:
                    entry.key == kpis.length - 1 ? 0 : AppSizes.s6,
              ),
              child: _buildKpiCard(theme, colorScheme, entry.value),
            ),
          );
        }).toList(),
      );
    }

    return Column(
      children: [
        Row(
          children: [
            Expanded(
                child: _buildKpiCard(theme, colorScheme, kpis[0])),
            const SizedBox(width: AppSizes.s12),
            Expanded(
                child: _buildKpiCard(theme, colorScheme, kpis[1])),
          ],
        ),
        const SizedBox(height: AppSizes.s12),
        Row(
          children: [
            Expanded(
                child: _buildKpiCard(theme, colorScheme, kpis[2])),
            const SizedBox(width: AppSizes.s12),
            Expanded(
                child: _buildKpiCard(theme, colorScheme, kpis[3])),
          ],
        ),
      ],
    );
  }

  Widget _buildKpiCard(
      ThemeData theme, ColorScheme colorScheme, _KpiData data) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.s16),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: [
            theme.cardTheme.color ?? Colors.white,
            data.color.withValues(alpha: 0.03),
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
                  gradient: LinearGradient(
                    colors: [
                      data.color,
                      data.color.withValues(alpha: 0.7),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius:
                      BorderRadius.circular(AppSizes.radiusSm),
                  boxShadow: [
                    BoxShadow(
                      color: data.color.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(data.icon, color: Colors.white, size: 18),
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
          // FittedBox + scaleDown: si el valor es muy largo (Gs. 1.234.567)
          // se achica solo en vez de cortarse.
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              data.value,
              style: GoogleFonts.inter(
                fontSize: 26,
                fontWeight: FontWeight.w900,
                color: colorScheme.onSurface,
              ),
              maxLines: 1,
            ),
          ),
          const SizedBox(height: AppSizes.s12),
          // Colored accent bar at the bottom
          Container(
            height: 4,
            decoration: BoxDecoration(
              color: data.color.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ],
      ),
    );
  }

  // -----------------------------------------------------------
  // 3. PENDING ALERT
  // -----------------------------------------------------------
  Widget _buildPendingAlert(ThemeData theme, EnhancedDashboardStats stats) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.s16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.warning.withValues(alpha: 0.15),
            AppColors.warning.withValues(alpha: 0.03),
          ],
        ),
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        border: Border.all(
          color: AppColors.warning.withValues(alpha: 0.25),
        ),
      ),
      child: Row(
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 1.0, end: 1.15),
            duration: const Duration(milliseconds: 800),
            curve: Curves.easeInOut,
            builder: (context, scale, child) {
              return TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 1.15, end: 1.0),
                duration: const Duration(milliseconds: 800),
                curve: Curves.easeInOut,
                builder: (context, reverseScale, child) {
                  return Transform.scale(
                    scale: scale < 1.15 ? scale : reverseScale,
                    child: child,
                  );
                },
                child: child,
              );
            },
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.notifications_active_rounded,
                  color: AppColors.warning, size: 22),
            ),
          ),
          const SizedBox(width: AppSizes.s16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${stats.pendingCount} reserva${stats.pendingCount > 1 ? 's' : ''} pendiente${stats.pendingCount > 1 ? 's' : ''}',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.accent,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Confirmá o cancelá para mantener tu agenda al día',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSizes.s12),
          SizedBox(
            height: 36,
            width: 70,
            child: ElevatedButton(
              onPressed: () {
                ref.read(businessNavIndexProvider.notifier).state = 1;
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.warning,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: AppSizes.s16),
                shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(AppSizes.radiusMd),
                ),
                elevation: 0,
              ),
              child: Text(
                'Ver',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // -----------------------------------------------------------
  // 4. CHARTS + AGENDA
  // -----------------------------------------------------------
  Widget _buildChartsAndAgenda(
    ThemeData theme,
    ColorScheme colorScheme,
    EnhancedDashboardStats stats,
    bool isDesktop,
  ) {
    final weekChart =
        _buildWeeklyChart(theme, colorScheme, stats);
    final agendaCard = _buildTodayAgendaCard(
        theme, colorScheme, stats.todayReservations);

    if (isDesktop) {
      return IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 3, child: weekChart),
            const SizedBox(width: AppSizes.s20),
            Expanded(flex: 2, child: agendaCard),
          ],
        ),
      );
    }

    return Column(
      children: [
        weekChart,
        const SizedBox(height: AppSizes.s20),
        agendaCard,
      ],
    );
  }

  // -- Weekly Bar Chart --
  Widget _buildWeeklyChart(
    ThemeData theme,
    ColorScheme colorScheme,
    EnhancedDashboardStats stats,
  ) {
    final dayNames = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];
    final breakdown = stats.weeklyBreakdown;
    final maxVal = breakdown.isEmpty
        ? 1
        : breakdown.reduce(math.max).clamp(1, double.maxFinite.toInt());
    final todayIndex = DateTime.now().weekday - 1;

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
          // Header
          Row(
            children: [
              Icon(Icons.bar_chart_rounded,
                  size: 20, color: AppColors.primary),
              const SizedBox(width: AppSizes.s8),
              Text(
                'Reservas de la semana',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: colorScheme.onSurface,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  borderRadius:
                      BorderRadius.circular(AppSizes.radiusFull),
                ),
                child: Text(
                  '${stats.reservationsThisWeek} total',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.s24),

          // Bar chart
          SizedBox(
            height: 160,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(7, (i) {
                final val = i < breakdown.length ? breakdown[i] : 0;
                final heightFraction = val / maxVal;
                final isToday = i == todayIndex;

                return Expanded(
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 4),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        // Value label
                        Text(
                          '$val',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: isToday
                                ? AppColors.primary
                                : AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        // Bar
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 600),
                          curve: Curves.easeOutQuint,
                          height: (heightFraction * 110)
                              .clamp(6.0, 110.0),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: isToday
                                  ? [
                                      AppColors.primary,
                                      AppColors.primary
                                          .withValues(alpha: 0.7),
                                    ]
                                  : [
                                      AppColors.primary
                                          .withValues(alpha: 0.3),
                                      AppColors.primary
                                          .withValues(alpha: 0.15),
                                    ],
                            ),
                            borderRadius: BorderRadius.circular(
                                AppSizes.radiusSm),
                          ),
                        ),
                        const SizedBox(height: 8),
                        // Day label
                        Text(
                          dayNames[i],
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: isToday
                                ? FontWeight.w700
                                : FontWeight.w500,
                            color: isToday
                                ? AppColors.primary
                                : AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  // -- Today Agenda Card --
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
              (r) => _buildAgendaTimelineItem(
                  theme, colorScheme, r, r == activeToday.last),
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
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.beach_access_rounded,
              color: AppColors.primary,
              size: 24,
            ),
          ),
          const SizedBox(height: AppSizes.s16),
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
            'No hay turnos para hoy.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: AppColors.textSecondary,
              height: 1.4,
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

  // -----------------------------------------------------------
  // 5. BOTTOM: Services + Plan Banner
  // -----------------------------------------------------------
  Widget _buildBottomSection(
    ThemeData theme,
    ColorScheme colorScheme,
    EnhancedDashboardStats stats,
    int reservationCount,
    bool isDesktop,
  ) {
    final servicesCard =
        _buildTopServicesCard(theme, colorScheme, stats);
    final planBanner =
        _buildPlanBanner(theme, colorScheme, reservationCount);

    if (isDesktop) {
      return IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 2, child: servicesCard),
            const SizedBox(width: AppSizes.s20),
            Expanded(flex: 3, child: planBanner),
          ],
        ),
      );
    }

    return Column(
      children: [
        servicesCard,
        const SizedBox(height: AppSizes.s20),
        planBanner,
      ],
    );
  }

  // -- Top Services Card --
  Widget _buildTopServicesCard(
    ThemeData theme,
    ColorScheme colorScheme,
    EnhancedDashboardStats stats,
  ) {
    final topServices = stats.topServices;
    final totalCount = topServices.fold<int>(0, (s, e) => s + e.value);
    final colors = [
      AppColors.primary,
      AppColors.info,
      AppColors.success,
      AppColors.warning,
      AppColors.error,
    ];

    return Container(
      padding: const EdgeInsets.all(AppSizes.s20),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        border: Border.all(
          color: AppColors.success.withValues(alpha: 0.08),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.success.withValues(alpha: 0.04),
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
              Icon(Icons.trending_up_rounded,
                  size: 20, color: AppColors.success),
              const SizedBox(width: AppSizes.s8),
              Text(
                'Servicios más populares',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.s20),
          if (topServices.isEmpty)
            Center(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: AppSizes.s16),
                child: Text(
                  'Aún no hay reservas con servicios.',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            )
          else
            ...topServices.take(5).toList().asMap().entries.map((entry) {
              final i = entry.key;
              final e = entry.value;
              final pct = totalCount > 0
                  ? (e.value / totalCount * 100).round()
                  : 0;
              final barColor = colors[i % colors.length];

              return Padding(
                padding: const EdgeInsets.only(bottom: AppSizes.s12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            e.key,
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: colorScheme.onSurface,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          '${e.value} ($pct%)',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: barColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(
                          AppSizes.radiusFull),
                      child: LinearProgressIndicator(
                        value: totalCount > 0
                            ? e.value / totalCount
                            : 0,
                        backgroundColor:
                            barColor.withValues(alpha: 0.08),
                        valueColor:
                            AlwaysStoppedAnimation<Color>(barColor),
                        minHeight: 8,
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  // -- Plan Banner --
  Widget _buildPlanBanner(
    ThemeData theme,
    ColorScheme colorScheme,
    int reservationCount,
  ) {
    final business = ref.watch(currentBusinessProvider);
    final isPro = business?.isPro ?? false;
    final isDark = theme.brightness == Brightness.dark;

    // -- Pro plan: show active badge --
    if (isPro) {
      return Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.s24,
          vertical: AppSizes.s20,
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color(0xFFF59E0B),
              isDark ? const Color(0xFFD97706) : const Color(0xFFFBBF24),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(AppSizes.radiusXl),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFF59E0B).withValues(alpha: 0.25),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppSizes.s8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(AppSizes.radiusMd),
              ),
              child: const Icon(
                Icons.workspace_premium_rounded,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: AppSizes.s16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Plan Pro activo ?',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: AppSizes.s4),
                  Text(
                    'Reservas y equipo ilimitados',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                      color: Colors.white.withValues(alpha: 0.85),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // -- Free plan: show upgrade banner --
    final usage = (reservationCount / 10).clamp(0.0, 1.0);

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
                  borderRadius:
                      BorderRadius.circular(AppSizes.radiusMd),
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
                      'Plan Free · $reservationCount/10 reservas',
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: AppSizes.s4),
                    Text(
                      'Actualizá a Pro para turnos ilimitados',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                    ),
                    const SizedBox(height: AppSizes.s12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(
                          AppSizes.radiusFull),
                      child: LinearProgressIndicator(
                        value: usage,
                        backgroundColor:
                            Colors.white.withValues(alpha: 0.2),
                        valueColor:
                            const AlwaysStoppedAnimation<Color>(
                                Colors.white),
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
            child: SizedBox(
              height: 38,
              width: 170,
              child: ElevatedButton(
                onPressed: () {
                  ref.read(businessNavIndexProvider.notifier).state =
                      7;
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: AppColors.accent,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.s20,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(AppSizes.radiusLg),
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
          ),
        ],
      ),
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
}

// --- Helper data class -----------------------------------
class _KpiData {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _KpiData({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });
}
