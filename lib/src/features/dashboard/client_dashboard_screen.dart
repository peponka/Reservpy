import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:reservpy/src/core/constants/app_sizes.dart';
import 'package:reservpy/src/core/constants/app_colors.dart';
import 'package:reservpy/src/shared/providers/providers.dart';
import 'package:reservpy/src/shared/models/models.dart';

class ClientDashboardScreen extends ConsumerStatefulWidget {
  const ClientDashboardScreen({super.key});

  @override
  ConsumerState<ClientDashboardScreen> createState() =>
      _ClientDashboardScreenState();
}

class _ClientDashboardScreenState extends ConsumerState<ClientDashboardScreen> {
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

  // ── Greeting helpers ──────────────────────────────────────────────
  String _greetingLabel() {
    final h = _now.hour;
    if (h < 12) return 'BUENOS DÍAS';
    if (h < 19) return 'BUENAS TARDES';
    return 'BUENAS NOCHES';
  }

  String _greetingTitle() {
    final h = _now.hour;
    if (h < 12) return 'Buenos días';
    if (h < 19) return 'Buenas tardes';
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
    final allReservations = ref.watch(clientReservationsProvider).value ?? [];

    final userName = user?.firstName ?? 'Usuario';

    // Filter reservations for this client — already filtered by provider
    final myReservations = allReservations;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));

    final upcoming = myReservations
        .where((r) =>
            r.startTime.isAfter(now) &&
            r.status != ReservationStatus.cancelled)
        .toList()
      ..sort((a, b) => a.startTime.compareTo(b.startTime));

    final completedCount =
        myReservations.where((r) => r.status == ReservationStatus.completed).length;

    final todayReservations = myReservations
        .where((r) =>
            r.startTime.isAfter(today) &&
            r.startTime.isBefore(tomorrow) &&
            r.status != ReservationStatus.cancelled)
        .toList()
      ..sort((a, b) => a.startTime.compareTo(b.startTime));

    return LayoutBuilder(
      builder: (context, constraints) {
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
                // ═══════════════════════════════════════════════════════════
                // 1. GREETING HEADER — green gradient card
                // ═══════════════════════════════════════════════════════════
                _buildGreetingHeader(theme, colorScheme, userName),
                const SizedBox(height: AppSizes.s24),

                // ═══════════════════════════════════════════════════════════
                // 2. STATS ROW — 3 KPI cards
                // ═══════════════════════════════════════════════════════════
                _buildStatsRow(
                  theme,
                  colorScheme,
                  upcomingCount: upcoming.length,
                  completedCount: completedCount,
                  totalCount: myReservations.length,
                ),
                const SizedBox(height: AppSizes.s24),

                // ═══════════════════════════════════════════════════════════
                // 3. PRÓXIMOS TURNOS
                // ═══════════════════════════════════════════════════════════
                _buildUpcomingCard(theme, colorScheme, upcoming),
                const SizedBox(height: AppSizes.s20),

                // ═══════════════════════════════════════════════════════════
                // 4. AGENDA DE HOY
                // ═══════════════════════════════════════════════════════════
                _buildTodayAgendaCard(theme, colorScheme, todayReservations),
                const SizedBox(height: AppSizes.s20),

                // ═══════════════════════════════════════════════════════════
                // 5. QUICK ACTIONS
                // ═══════════════════════════════════════════════════════════
                _buildQuickActions(theme, colorScheme),
                const SizedBox(height: AppSizes.s32),
              ],
            ),
          ),
        );
      },
    );
  }

  // ───────────────────────────────────────────────────────────────────
  // 1. GREETING HEADER
  // ───────────────────────────────────────────────────────────────────
  Widget _buildGreetingHeader(
    ThemeData theme,
    ColorScheme colorScheme,
    String userName,
  ) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppSizes.radiusXl),
      child: Stack(
        children: [
          // Gradient background
          Container(
            padding: const EdgeInsets.all(AppSizes.s24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  Color(0xFF00C896),
                  Color(0xFF00A67E),
                  Color(0xFF0A2540),
                ],
                stops: [0.0, 0.45, 1.0],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.30),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth > 520;

                final greeting = Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSizes.s12,
                        vertical: AppSizes.s4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(AppSizes.radiusFull),
                      ),
                      child: Text(
                        _greetingLabel(),
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: 1.4,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSizes.s12),
                    Text(
                      '${_greetingTitle()}, 👋 $userName',
                      style: GoogleFonts.inter(
                        fontSize: isWide ? 30 : 22,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: AppSizes.s8),
                    Text(
                      'Bienvenido. Reservá tu primer turno en segundos.',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: Colors.white.withValues(alpha: 0.82),
                        height: 1.4,
                      ),
                    ),
                  ],
                );

                final clock = Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.s20,
                    vertical: AppSizes.s16,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.20),
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _formattedClock(),
                        style: GoogleFonts.inter(
                          fontSize: isWide ? 34 : 26,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: AppSizes.s4),
                      Text(
                        'HORA LOCAL',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: Colors.white.withValues(alpha: 0.70),
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                );

                if (isWide) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(child: greeting),
                      const SizedBox(width: AppSizes.s24),
                      clock,
                    ],
                  );
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    greeting,
                    const SizedBox(height: AppSizes.s16),
                    Align(alignment: Alignment.centerLeft, child: clock),
                  ],
                );
              },
            ),
          ),
          // Decorative circle — top right
          Positioned(
            top: -30,
            right: -30,
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.06),
              ),
            ),
          ),
          // Decorative circle — bottom left
          Positioned(
            bottom: -20,
            left: -20,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.04),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────
  // 2. STATS ROW
  // ───────────────────────────────────────────────────────────────────
  Widget _buildStatsRow(
    ThemeData theme,
    ColorScheme colorScheme, {
    required int upcomingCount,
    required int completedCount,
    required int totalCount,
  }) {
    final items = [
      _StatItem(
        label: 'PRÓXIMOS',
        value: '$upcomingCount',
        icon: Icons.calendar_today_rounded,
        color: AppColors.primary,
      ),
      _StatItem(
        label: 'COMPLETADOS',
        value: '$completedCount',
        icon: Icons.star_rounded,
        color: AppColors.warning,
      ),
      _StatItem(
        label: 'TOTAL',
        value: '$totalCount',
        icon: Icons.receipt_long_rounded,
        color: AppColors.info,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth > 560) {
          return Row(
            children: items.asMap().entries.map((entry) {
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                    left: entry.key == 0 ? 0 : AppSizes.s8,
                    right: entry.key == items.length - 1 ? 0 : AppSizes.s8,
                  ),
                  child:
                      _buildStatCard(theme, colorScheme, entry.value),
                ),
              );
            }).toList(),
          );
        }
        // Stack vertically on narrow screens
        return Column(
          children: items
              .map((item) => Padding(
                    padding: const EdgeInsets.only(bottom: AppSizes.s12),
                    child: _buildStatCard(theme, colorScheme, item),
                  ))
              .toList(),
        );
      },
    );
  }

  Widget _buildStatCard(
    ThemeData theme,
    ColorScheme colorScheme,
    _StatItem item,
  ) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.s20),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        border: Border.all(
          color: colorScheme.outline.withValues(alpha: 0.08),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.label,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textSecondary,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: AppSizes.s8),
                    Text(
                      item.value,
                      style: GoogleFonts.inter(
                        fontSize: 36,
                        fontWeight: FontWeight.w900,
                        color: colorScheme.onSurface,
                        height: 1.0,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(AppSizes.s12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [item.color, item.color.withValues(alpha: 0.7)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                  boxShadow: [
                    BoxShadow(
                      color: item.color.withValues(alpha: 0.25),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Icon(item.icon, color: Colors.white, size: 24),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.s12),
          Container(
            height: 4,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  item.color.withValues(alpha: 0.4),
                  item.color.withValues(alpha: 0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ],
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────
  // 3. UPCOMING RESERVATIONS CARD
  // ───────────────────────────────────────────────────────────────────
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
          color: colorScheme.outline.withValues(alpha: 0.08),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSizes.s8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                ),
                child: const Icon(Icons.event_note_rounded,
                    size: 20, color: AppColors.primary),
              ),
              const SizedBox(width: AppSizes.s12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Próximos turnos',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Próximos 14 días',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.s20),
          if (upcoming.isEmpty)
            _buildEmptyUpcoming(theme, colorScheme)
          else
            ...upcoming
                .take(5)
                .map((r) => _buildUpcomingTile(theme, colorScheme, r)),
        ],
      ),
    );
  }

  Widget _buildEmptyUpcoming(ThemeData theme, ColorScheme colorScheme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        vertical: AppSizes.s32,
        horizontal: AppSizes.s20,
      ),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        border: Border.all(
          color: AppColors.warning.withValues(alpha: 0.15),
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.warning.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.calendar_today_rounded,
              color: AppColors.warning,
              size: 24,
            ),
          ),
          const SizedBox(height: AppSizes.s16),
          Text(
            'Sin turnos próximos',
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w700,
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
          const SizedBox(height: AppSizes.s20),
          SizedBox(
            height: AppSizes.buttonMd,
            child: ElevatedButton.icon(
              onPressed: () {
                ref.read(clientNavIndexProvider.notifier).state = 1;
              },
              icon: const Icon(Icons.search_rounded, size: 18),
              label: Text(
                'Reservar ahora',
                style: GoogleFonts.inter(fontWeight: FontWeight.w700),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: AppSizes.s24),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUpcomingTile(
    ThemeData theme,
    ColorScheme colorScheme,
    Reservation r,
  ) {
    final timeStr =
        '${DateFormat('HH:mm').format(r.startTime)} – ${DateFormat('HH:mm').format(r.endTime)}';
    final dateStr = DateFormat("EEE d MMM", 'es').format(r.startTime);

    return Container(
      margin: const EdgeInsets.only(bottom: AppSizes.s8),
      padding: const EdgeInsets.all(AppSizes.s16),
      decoration: BoxDecoration(
        color: colorScheme.outline.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        border: Border.all(
          color: colorScheme.outline.withValues(alpha: 0.06),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Service icon circle
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primary.withValues(alpha: 0.15),
                      AppColors.primary.withValues(alpha: 0.08),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                ),
                child: const Icon(
                  Icons.spa_rounded,
                  color: AppColors.primary,
                  size: 22,
                ),
              ),
              const SizedBox(width: AppSizes.s12),
              // Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      r.serviceName ?? 'Servicio',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: colorScheme.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      r.businessName ?? 'Negocio',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSizes.s8),
              // Date + Status badge
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    dateStr,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: AppSizes.s4),
                  _buildStatusBadge(r.status),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppSizes.s12),
          // Bottom row: time + action
          Row(
            children: [
              Icon(Icons.access_time_rounded,
                  size: 14, color: AppColors.textMuted),
              const SizedBox(width: AppSizes.s4),
              Text(
                timeStr,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
              const Spacer(),
              InkWell(
                onTap: () {
                  // Navigate to reservations detail
                  ref.read(clientNavIndexProvider.notifier).state = 3;
                },
                borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.s8,
                    vertical: AppSizes.s4,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Ver detalle',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: AppSizes.s4),
                      const Icon(Icons.arrow_forward_ios_rounded,
                          size: 11, color: AppColors.primary),
                    ],
                  ),
                ),
              ),
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
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

  // ───────────────────────────────────────────────────────────────────
  // 4. TODAY'S AGENDA CARD
  // ───────────────────────────────────────────────────────────────────
  Widget _buildTodayAgendaCard(
    ThemeData theme,
    ColorScheme colorScheme,
    List<Reservation> todayReservations,
  ) {
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
          color: colorScheme.outline.withValues(alpha: 0.08),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSizes.s8),
                decoration: BoxDecoration(
                  color: AppColors.info.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                ),
                child: const Icon(Icons.today_rounded,
                    size: 20, color: AppColors.info),
              ),
              const SizedBox(width: AppSizes.s12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Agenda de hoy',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      capitalizedDate,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.s20),
          if (todayReservations.isEmpty)
            _buildEmptyAgenda(theme, colorScheme)
          else
            ...todayReservations.map(
              (r) => _buildAgendaTimelineItem(
                theme,
                colorScheme,
                r,
                r == todayReservations.last,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyAgenda(ThemeData theme, ColorScheme colorScheme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        vertical: AppSizes.s32,
        horizontal: AppSizes.s20,
      ),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.12),
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.10),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.calendar_month_rounded,
              color: AppColors.primary,
              size: 26,
            ),
          ),
          const SizedBox(height: AppSizes.s16),
          Text(
            'Tu agenda está vacía',
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: AppSizes.s8),
          Text(
            'Reservá tu primer turno en segundos.\nSin llamadas, sin esperas.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
          const SizedBox(height: AppSizes.s20),
          SizedBox(
            height: AppSizes.buttonMd,
            child: ElevatedButton.icon(
              onPressed: () {
                ref.read(clientNavIndexProvider.notifier).state = 1;
              },
              icon: const Icon(Icons.bolt_rounded, size: 18),
              label: Text(
                'Reservar mi primer turno',
                style: GoogleFonts.inter(fontWeight: FontWeight.w700),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.warning,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: AppSizes.s24),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                ),
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
    final endStr = DateFormat('HH:mm').format(r.endTime);

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
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: _statusColor(r.status),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: _statusColor(r.status).withValues(alpha: 0.3),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
              ),
              if (!isLast)
                Container(
                  width: 2,
                  height: 52,
                  margin: const EdgeInsets.only(top: 4),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        _statusColor(r.status).withValues(alpha: 0.3),
                        colorScheme.outline.withValues(alpha: 0.08),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(width: AppSizes.s12),
        // Content
        Expanded(
          child: Container(
            margin: const EdgeInsets.only(bottom: AppSizes.s12),
            padding: const EdgeInsets.all(AppSizes.s12),
            decoration: BoxDecoration(
              color: colorScheme.outline.withValues(alpha: 0.03),
              borderRadius: BorderRadius.circular(AppSizes.radiusSm),
              border: Border.all(
                color: colorScheme.outline.withValues(alpha: 0.06),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSizes.s8,
                        vertical: AppSizes.s2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.10),
                        borderRadius:
                            BorderRadius.circular(AppSizes.radiusSm),
                      ),
                      child: Text(
                        '$timeStr – $endStr',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    const Spacer(),
                    _buildStatusBadge(r.status),
                  ],
                ),
                const SizedBox(height: AppSizes.s8),
                Text(
                  r.serviceName ?? 'Servicio',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  r.businessName ?? 'Negocio',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
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

  // ───────────────────────────────────────────────────────────────────
  // 5. QUICK ACTIONS
  // ───────────────────────────────────────────────────────────────────
  Widget _buildQuickActions(ThemeData theme, ColorScheme colorScheme) {
    final actions = [
      _QuickAction(
        icon: Icons.search_rounded,
        label: 'Buscar negocios',
        subtitle: 'Encontrá tu servicio ideal',
        color: AppColors.primary,
        tabIndex: 1,
      ),
      _QuickAction(
        icon: Icons.explore_rounded,
        label: 'Explorar mapa',
        subtitle: 'Descubrí cerca de vos',
        color: AppColors.info,
        tabIndex: 2,
      ),
      _QuickAction(
        icon: Icons.calendar_today_rounded,
        label: 'Mis reservas',
        subtitle: 'Historial completo',
        color: AppColors.accent,
        tabIndex: 3,
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: AppSizes.s16),
          child: Text(
            'Acceso rápido',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: colorScheme.onSurface,
            ),
          ),
        ),
        LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth > 560) {
              return Row(
                children: actions.asMap().entries.map((entry) {
                  return Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(
                        left: entry.key == 0 ? 0 : AppSizes.s8,
                        right:
                            entry.key == actions.length - 1 ? 0 : AppSizes.s8,
                      ),
                      child: _buildQuickActionCard(
                          theme, colorScheme, entry.value),
                    ),
                  );
                }).toList(),
              );
            }
            return Column(
              children: actions
                  .map((a) => Padding(
                        padding: const EdgeInsets.only(bottom: AppSizes.s12),
                        child:
                            _buildQuickActionCard(theme, colorScheme, a),
                      ))
                  .toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _buildQuickActionCard(
    ThemeData theme,
    ColorScheme colorScheme,
    _QuickAction action,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          ref.read(clientNavIndexProvider.notifier).state = action.tabIndex;
        },
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        child: Container(
          padding: const EdgeInsets.all(AppSizes.s20),
          decoration: BoxDecoration(
            color: theme.cardTheme.color,
            borderRadius: BorderRadius.circular(AppSizes.radiusLg),
            border: Border.all(
              color: action.color.withValues(alpha: 0.3),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSizes.s12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [action.color, action.color.withValues(alpha: 0.7)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                  boxShadow: [
                    BoxShadow(
                      color: action.color.withValues(alpha: 0.25),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Icon(action.icon, color: Colors.white, size: 22),
              ),
              const SizedBox(width: AppSizes.s16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      action.label,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      action.subtitle,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 14,
                color: action.color,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════
// PRIVATE DATA CLASSES
// ═════════════════════════════════════════════════════════════════════

class _StatItem {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatItem({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });
}

class _QuickAction {
  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final int tabIndex;

  const _QuickAction({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
    required this.tabIndex,
  });
}
