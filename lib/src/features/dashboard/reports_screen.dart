import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:math' as math;
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as dart_ui;
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../../core/widgets/widgets.dart';
import '../../shared/models/models.dart';
import '../../shared/providers/providers.dart';



// ─── Period enum for segmented selector ────────────────────
enum _ReportPeriod { week, month, quarter }

int _periodToDays(_ReportPeriod p) {
  switch (p) {
    case _ReportPeriod.week:
      return 7;
    case _ReportPeriod.month:
      return 30;
    case _ReportPeriod.quarter:
      return 90;
  }
}

// ─── Providers local to this screen ────────────────────────
final _selectedPeriodProvider =
    StateProvider<_ReportPeriod>((ref) => _ReportPeriod.week);

/// Reports & Analytics screen for business owners.
class ReportsScreen extends ConsumerWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final business = ref.watch(currentBusinessProvider);

    // ── Premium gate ──────────────────────────────────────────
    if (business != null && !business.isPro) {
      return const _PremiumGate();
    }

    final period = ref.watch(_selectedPeriodProvider);
    final periodDays = _periodToDays(period);
    final reportsAsync = ref.watch(reportsDataProvider(periodDays));

    return reportsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.s24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: AppColors.error),
              const SizedBox(height: AppSizes.s16),
              Text('Error al cargar los reportes',
                  style: Theme.of(context).textTheme.titleMedium),
            ],
          ),
        ),
      ),
      data: (data) => _ReportsBody(
        period: period,
        reservations: data.reservations,
        services: data.services,
      ),
    );
  }
}

// ─── Premium Gate ─────────────────────────────────────────────
class _PremiumGate extends StatelessWidget {
  const _PremiumGate();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSizes.s24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: AppSizes.s32),
          // Icon
          Center(
            child: Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: const Color(0xFFFFF8E1),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFFFE082), width: 2),
              ),
              child: const Icon(Icons.lock_outline_rounded,
                  size: 40, color: Color(0xFFFFA000)),
            ),
          ),
          const SizedBox(height: AppSizes.s24),
          Text('Reportes y Métricas',
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineSmall
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: AppSizes.s8),
          Text(
            'Esta sección es exclusiva del plan Pro.\nUplgradá para acceder a todos tus reportes, métricas de ingresos, clientes frecuentes y más.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium
                ?.copyWith(color: theme.colorScheme.onSurface.withOpacity(0.6)),
          ),
          const SizedBox(height: AppSizes.s32),
          // Feature list
          _FeatureRow(icon: Icons.trending_up_rounded, label: 'Ingresos y gráficos por período'),
          _FeatureRow(icon: Icons.star_rounded, label: 'Servicios más populares'),
          _FeatureRow(icon: Icons.access_time_rounded, label: 'Horarios pico de tu negocio'),
          _FeatureRow(icon: Icons.people_outline_rounded, label: 'Clientes frecuentes y nuevos'),
          _FeatureRow(icon: Icons.download_rounded, label: 'Exportar a Excel para tu contador'),
          const SizedBox(height: AppSizes.s32),
          // CTA button
          FilledButton.icon(
            onPressed: () {
              // TODO: navegar a pantalla de upgrade cuando esté disponible
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('¡Próximamente podrás upgradear desde la app!'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            icon: const Icon(Icons.rocket_launch_rounded),
            label: const Text('Upgradear a Pro'),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFFFA000),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              textStyle: const TextStyle(
                  fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: AppSizes.s16),
          Center(
            child: Text(
              'Plan Pro — Reservas ilimitadas + reportes + soporte prioritario',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.onSurface.withOpacity(0.45)),
            ),
          ),
        ],
      ),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  final IconData icon;
  final String label;
  const _FeatureRow({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 16, color: AppColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(label,
                style: Theme.of(context).textTheme.bodyMedium),
          ),
          const Icon(Icons.check_circle_rounded,
              size: 18, color: AppColors.primary),
        ],
      ),
    );
  }
}

class _PremiumFeatureChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _PremiumFeatureChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFFFE082)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: const Color(0xFFFFA500)),
          const SizedBox(width: 6),
          Text(label,
              style: const TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFFE65100))),
        ],
      ),
    );
  }
}

/// Inner body rendered when data is loaded.
class _ReportsBody extends ConsumerWidget {
  final _ReportPeriod period;
  final List<Reservation> reservations;
  final List<ServiceModel> services;

  const _ReportsBody({
    required this.period,
    required this.reservations,
    required this.services,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Build enriched data sets for each section.
    final revenueData = _computeRevenueData(reservations, services, period);
    final popularServices = _computePopularServices(reservations, services);
    final heatmapData = _computeHeatmap(reservations);
    final clientStats = _computeClientStats(reservations, period);
    final topClients = _computeTopClients(reservations, services);

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(AppSizes.s16),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: constraints.maxHeight - 32,
              maxWidth: constraints.maxWidth - 32,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── 1. Header + period selector ──
                _Header(period: period),
                const SizedBox(height: AppSizes.s16),

                // ── Export Excel/CSV ──
                _ExportSection(reservations: reservations, services: services),
                const SizedBox(height: AppSizes.s24),

                // ── 2. Revenue Overview ──
                _RevenueSection(data: revenueData),
                const SizedBox(height: AppSizes.s24),

                // ── 3. Popular Services ──
                _PopularServicesSection(services: popularServices),
                const SizedBox(height: AppSizes.s24),

                // ── 4. Peak Hours Heatmap ──
                _PeakHoursSection(heatmap: heatmapData),
                const SizedBox(height: AppSizes.s24),

                // ── 5. Client Stats ──
                _ClientStatsSection(stats: clientStats),
                const SizedBox(height: AppSizes.s24),

                // ── 6. Top Clients ──
                _TopClientsSection(clients: topClients),
                const SizedBox(height: AppSizes.s40),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════
//  1. HEADER
// ═══════════════════════════════════════════════════════════

class _Header extends ConsumerWidget {
  final _ReportPeriod period;
  const _Header({required this.period});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Reportes y métricas',
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: AppSizes.s4),
        Text(
          'Analizá el rendimiento de tu negocio',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.outline,
          ),
        ),
        const SizedBox(height: AppSizes.s16),
        SizedBox(
          width: double.infinity,
          child: SegmentedButton<_ReportPeriod>(
            segments: const [
              ButtonSegment(
                value: _ReportPeriod.week,
                label: Text('Semana'),
                icon: Icon(Icons.view_week_rounded, size: 18),
              ),
              ButtonSegment(
                value: _ReportPeriod.month,
                label: Text('Mes'),
                icon: Icon(Icons.calendar_month_rounded, size: 18),
              ),
              ButtonSegment(
                value: _ReportPeriod.quarter,
                label: Text('3 Meses'),
                icon: Icon(Icons.date_range_rounded, size: 18),
              ),
            ],
            selected: {period},
            onSelectionChanged: (v) =>
                ref.read(_selectedPeriodProvider.notifier).state = v.first,
            style: ButtonStyle(
              visualDensity: VisualDensity.compact,
              shape: WidgetStatePropertyAll(
                RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════
//  2. REVENUE OVERVIEW
// ═══════════════════════════════════════════════════════════

class _RevenueData {
  final double totalRevenue;
  final double trendPercent; // positive = up, negative = down
  final List<double> dailyRevenue; // 7 values
  const _RevenueData({
    required this.totalRevenue,
    required this.trendPercent,
    required this.dailyRevenue,
  });
}

class _RevenueSection extends StatelessWidget {
  final _RevenueData data;
  const _RevenueSection({required this.data});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isUp = data.trendPercent >= 0;
    final trendColor = isUp ? AppColors.success : AppColors.error;

    return AppCard(
      padding: const EdgeInsets.all(AppSizes.s20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSizes.s8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                ),
                child: const Icon(Icons.trending_up_rounded,
                    color: AppColors.primary, size: AppSizes.iconLg),
              ),
              const SizedBox(width: AppSizes.s12),
              Text(
                'Ingresos del período',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.s16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _formatGuaranies(data.totalRevenue),
                style: theme.textTheme.headlineLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppColors.accent,
                ),
              ),
              const SizedBox(width: AppSizes.s12),
              if (data.trendPercent != 0)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.s8,
                    vertical: AppSizes.s4,
                  ),
                  decoration: BoxDecoration(
                    color: trendColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppSizes.radiusFull),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isUp
                            ? Icons.arrow_upward_rounded
                            : Icons.arrow_downward_rounded,
                        size: 14,
                        color: trendColor,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        '${data.trendPercent.abs().toStringAsFixed(1)}%',
                        style: TextStyle(
                          color: trendColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSizes.s24),
          SizedBox(
            height: 160,
            child: _AnimatedBarChart(values: data.dailyRevenue),
          ),
          const SizedBox(height: AppSizes.s8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: const ['L', 'M', 'M', 'J', 'V', 'S', 'D']
                .map(
                  (d) => SizedBox(
                    width: 28,
                    child: Text(
                      d,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}

/// Animated bar chart widget that uses a CustomPainter with gradient bars.
class _AnimatedBarChart extends StatefulWidget {
  final List<double> values;
  const _AnimatedBarChart({required this.values});

  @override
  State<_AnimatedBarChart> createState() => _AnimatedBarChartState();
}

class _AnimatedBarChartState extends State<_AnimatedBarChart>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic);
    // Start animation after short delay so it syncs with card entrance.
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) _controller.forward();
    });
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
          painter: _BarChartPainter(
            values: widget.values,
            animationValue: _animation.value,
            barColor: AppColors.primary,
            barColorEnd: AppColors.primaryLight,
            gridColor: AppColors.divider,
          ),
        );
      },
    );
  }
}

class _BarChartPainter extends CustomPainter {
  final List<double> values;
  final double animationValue;
  final Color barColor;
  final Color barColorEnd;
  final Color gridColor;

  _BarChartPainter({
    required this.values,
    required this.animationValue,
    required this.barColor,
    required this.barColorEnd,
    required this.gridColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;

    final maxVal = values.reduce(math.max);
    if (maxVal == 0) return;

    final barCount = values.length;
    final spacing = 10.0;
    final barWidth = (size.width - (barCount + 1) * spacing) / barCount;
    final chartHeight = size.height - 4; // small bottom padding

    // Draw subtle grid lines.
    final gridPaint = Paint()
      ..color = gridColor.withValues(alpha: 0.5)
      ..strokeWidth = 0.5;
    for (var i = 0; i < 4; i++) {
      final y = chartHeight * i / 3;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // Draw bars.
    for (var i = 0; i < barCount; i++) {
      final normalised = values[i] / maxVal;
      final barHeight = normalised * chartHeight * animationValue;
      final x = spacing + i * (barWidth + spacing);
      final y = chartHeight - barHeight;

      final rect = RRect.fromRectAndCorners(
        Rect.fromLTWH(x, y, barWidth, barHeight),
        topLeft: const Radius.circular(6),
        topRight: const Radius.circular(6),
      );

      final gradient = LinearGradient(
        begin: Alignment.bottomCenter,
        end: Alignment.topCenter,
        colors: [barColor, barColorEnd],
      );
      final paint = Paint()
        ..shader = gradient.createShader(
          Rect.fromLTWH(x, y, barWidth, barHeight),
        );

      canvas.drawRRect(rect, paint);

      // Value label on top if bar is tall enough.
      if (barHeight > 24 && animationValue > 0.6) {
        final tp = TextPainter(
          text: TextSpan(
            text: _formatCompact(values[i]),
            style: TextStyle(
              color: barColor,
              fontSize: 9,
              fontWeight: FontWeight.w700,
            ),
          ),
          textDirection: dart_ui.TextDirection.ltr,
        )..layout();
        tp.paint(
          canvas,
          Offset(x + (barWidth - tp.width) / 2, y - tp.height - 4),
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _BarChartPainter old) =>
      old.animationValue != animationValue;

  String _formatCompact(double v) {
    if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(1)}M';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(0)}k';
    return v.toStringAsFixed(0);
  }
}

// ═══════════════════════════════════════════════════════════
//  3. POPULAR SERVICES
// ═══════════════════════════════════════════════════════════

class _PopularServiceRow {
  final int rank;
  final String name;
  final int bookings;
  final double revenue;
  final double percent;
  const _PopularServiceRow({
    required this.rank,
    required this.name,
    required this.bookings,
    required this.revenue,
    required this.percent,
  });
}

class _PopularServicesSection extends StatelessWidget {
  final List<_PopularServiceRow> services;
  const _PopularServicesSection({required this.services});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (services.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(title: 'Servicios populares'),
          const SizedBox(height: AppSizes.s8),
          AppCard(
            padding: const EdgeInsets.all(AppSizes.s24),
            child: Center(
              child: Column(
                children: [
                  Icon(Icons.category_outlined, size: 40,
                      color: theme.colorScheme.outline.withValues(alpha: 0.5)),
                  const SizedBox(height: AppSizes.s12),
                  Text(
                    'Sin datos de servicios aún',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.outline,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: 'Servicios populares'),
        const SizedBox(height: AppSizes.s8),
        ...services.map((svc) {
          return AppCard(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSizes.s16,
              vertical: AppSizes.s12,
            ),
            child: Row(
              children: [
                // Rank badge
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: svc.rank <= 3
                          ? [AppColors.primary, AppColors.primaryLight]
                          : [AppColors.textMuted, AppColors.textMuted],
                    ),
                    borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '#${svc.rank}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: AppSizes.s12),

                // Service info + progress
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: Text(
                              svc.name,
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            _formatGuaranies(svc.revenue),
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSizes.s6),
                      Row(
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius:
                                  BorderRadius.circular(AppSizes.radiusFull),
                              child: SizedBox(
                                height: 6,
                                child: CustomPaint(
                                  size: const Size(double.infinity, 6),
                                  painter: _GradientProgressPainter(
                                    progress: svc.percent,
                                    startColor: AppColors.primary,
                                    endColor: AppColors.primaryLight,
                                    backgroundColor:
                                        AppColors.divider.withValues(alpha: 0.5),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: AppSizes.s12),
                          Text(
                            '${svc.bookings} reservas',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: AppColors.textSecondary,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}

/// Paints a gradient progress bar.
class _GradientProgressPainter extends CustomPainter {
  final double progress; // 0..1
  final Color startColor;
  final Color endColor;
  final Color backgroundColor;

  _GradientProgressPainter({
    required this.progress,
    required this.startColor,
    required this.endColor,
    required this.backgroundColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Background track.
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.width, size.height),
        const Radius.circular(99),
      ),
      Paint()..color = backgroundColor,
    );

    // Foreground gradient.
    final fillWidth = size.width * progress.clamp(0.0, 1.0);
    if (fillWidth > 0) {
      final gradient =
          LinearGradient(colors: [startColor, endColor]);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(0, 0, fillWidth, size.height),
          const Radius.circular(99),
        ),
        Paint()
          ..shader =
              gradient.createShader(Rect.fromLTWH(0, 0, fillWidth, size.height)),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _GradientProgressPainter old) =>
      old.progress != progress;
}

// ═══════════════════════════════════════════════════════════
//  4. PEAK HOURS HEATMAP
// ═══════════════════════════════════════════════════════════

/// 15 hours (7..21) × 7 days matrix.
class _PeakHoursSection extends StatelessWidget {
  final List<List<int>> heatmap; // [hour][day]
  const _PeakHoursSection({required this.heatmap});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    // Calculate a responsive height based on the available width to keep cells balanced.
    // For narrow screens, we scale the height down slightly so they don't look overly tall,
    // and for wide screens, we scale it up.
    // Base width is around 360px where height of 300px works great (ratio ~ 0.83).
    // Let's cap the responsive height between 220px and 450px.
    final responsiveHeight = (screenWidth * 0.83).clamp(220.0, 450.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: 'Horas pico'),
        const SizedBox(height: AppSizes.s8),
        AppCard(
          padding: const EdgeInsets.all(AppSizes.s16),
          child: Column(
            children: [
              // Day labels
              Padding(
                padding: const EdgeInsets.only(left: 36),
                child: Row(
                  children: const ['L', 'M', 'M', 'J', 'V', 'S', 'D']
                      .map(
                        (d) => Expanded(
                          child: Text(
                            d,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
              const SizedBox(height: AppSizes.s8),
              SizedBox(
                height: responsiveHeight,
                child: _HeatmapGrid(data: heatmap),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _HeatmapGrid extends StatelessWidget {
  final List<List<int>> data; // [hourIndex][dayIndex]
  const _HeatmapGrid({required this.data});

  @override
  Widget build(BuildContext context) {
    final maxVal = data.expand((r) => r).fold<int>(0, math.max);
    final hours = data.length;

    return LayoutBuilder(
      builder: (context, constraints) {
        final cellH = constraints.maxHeight / hours;

        return Column(
          children: List.generate(hours, (hi) {
            final hourLabel = '${7 + hi}';
            return SizedBox(
              height: cellH,
              child: Row(
                children: [
                  SizedBox(
                    width: 36,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        '${hourLabel.padLeft(2, '0')}:00',
                        style: const TextStyle(
                          fontSize: 9,
                          color: AppColors.textMuted,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        softWrap: false,
                      ),
                    ),
                  ),
                  ...List.generate(7, (di) {
                    final val = data[hi][di];
                    final intensity =
                        maxVal > 0 ? (val / maxVal).clamp(0.0, 1.0) : 0.0;
                    return Expanded(
                      child: Container(
                        margin: const EdgeInsets.all(1.5),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(3),
                          color: _heatColor(intensity),
                        ),
                        alignment: Alignment.center,
                        child: intensity > 0.3
                            ? FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 1.0),
                                  child: Text(
                                    '$val',
                                    style: TextStyle(
                                      fontSize: 8,
                                      fontWeight: FontWeight.w700,
                                      color: intensity > 0.6
                                          ? Colors.white
                                          : AppColors.accent,
                                    ),
                                    maxLines: 1,
                                    softWrap: false,
                                  ),
                                ),
                              )
                            : null,
                      ),
                    );
                  }),
                ],
              ),
            );
          }),
        );
      },
    );
  }

  Color _heatColor(double t) {
    if (t <= 0) return AppColors.primary.withValues(alpha: 0.06);
    // Lerp from very light green to deep primary green.
    return Color.lerp(
      AppColors.primary.withValues(alpha: 0.12),
      AppColors.primaryDark,
      t,
    )!;
  }
}

// ═══════════════════════════════════════════════════════════
//  5. CLIENT STATS
// ═══════════════════════════════════════════════════════════

class _ClientStatsData {
  final int newClients;
  final int returningClients;
  final double cancellationRate;
  const _ClientStatsData({
    required this.newClients,
    required this.returningClients,
    required this.cancellationRate,
  });
}

class _ClientStatsSection extends StatelessWidget {
  final _ClientStatsData stats;
  const _ClientStatsSection({required this.stats});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: 'Estadísticas de clientes'),
        const SizedBox(height: AppSizes.s8),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: AppSizes.s12,
          mainAxisSpacing: AppSizes.s4,
          childAspectRatio: 1.45,
          children: [
            _StatMiniCard(
              icon: Icons.person_add_rounded,
              color: AppColors.info,
              label: 'Nuevos clientes',
              value: '${stats.newClients}',
            ),
            _StatMiniCard(
              icon: Icons.replay_rounded,
              color: AppColors.success,
              label: 'Recurrentes',
              value: '${stats.returningClients}',
            ),
            _StatMiniCard(
              icon: Icons.cancel_outlined,
              color: AppColors.error,
              label: 'Tasa cancelación',
              value: '${stats.cancellationRate.toStringAsFixed(1)}%',
              showIndicator: true,
              indicatorValue: stats.cancellationRate / 100,
              indicatorColor: AppColors.error,
            ),
            _StatMiniCard(
              icon: Icons.groups_rounded,
              color: AppColors.primary,
              label: 'Total clientes',
              value: '${stats.newClients + stats.returningClients}',
            ),
          ],
        ),
      ],
    );
  }
}

class _StatMiniCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String value;
  final bool showIndicator;
  final double indicatorValue;
  final Color? indicatorColor;

  const _StatMiniCard({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
    this.showIndicator = false,
    this.indicatorValue = 0,
    this.indicatorColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppCard(
      padding: const EdgeInsets.all(AppSizes.s16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSizes.s6),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              const Spacer(),
              Text(
                value,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const Spacer(),
          if (showIndicator) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(AppSizes.radiusFull),
              child: LinearProgressIndicator(
                value: indicatorValue.clamp(0, 1),
                minHeight: 4,
                backgroundColor: (indicatorColor ?? color).withValues(alpha: 0.15),
                valueColor: AlwaysStoppedAnimation(indicatorColor ?? color),
              ),
            ),
            const SizedBox(height: AppSizes.s4),
          ],
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
//  6. TOP CLIENTS
// ═══════════════════════════════════════════════════════════

class _TopClientRow {
  final String name;
  final String initials;
  final int visits;
  final double totalSpent;
  const _TopClientRow({
    required this.name,
    required this.initials,
    required this.visits,
    required this.totalSpent,
  });
}

class _TopClientsSection extends StatelessWidget {
  final List<_TopClientRow> clients;
  const _TopClientsSection({required this.clients});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (clients.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(title: 'Mejores clientes'),
          const SizedBox(height: AppSizes.s8),
          AppCard(
            padding: const EdgeInsets.all(AppSizes.s24),
            child: Center(
              child: Column(
                children: [
                  Icon(Icons.people_outline, size: 40,
                      color: theme.colorScheme.outline.withValues(alpha: 0.5)),
                  const SizedBox(height: AppSizes.s12),
                  Text(
                    'Sin clientes aún',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.outline,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: 'Mejores clientes'),
        const SizedBox(height: AppSizes.s8),
        ...clients.asMap().entries.map((entry) {
          final i = entry.key;
          final c = entry.value;
          final avatarColors = [
            AppColors.primary,
            AppColors.info,
            AppColors.success,
            AppColors.warning,
            AppColors.error,
          ];

          return AppCard(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSizes.s16,
              vertical: AppSizes.s12,
            ),
            child: Row(
              children: [
                UserAvatar(
                  initials: c.initials,
                  size: 44,
                  backgroundColor: avatarColors[i % avatarColors.length]
                      .withValues(alpha: 0.15),
                ),
                const SizedBox(width: AppSizes.s12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        c.name,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: AppSizes.s2),
                      Text(
                        '${c.visits} visitas',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      _formatGuaranies(c.totalSpent),
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: AppSizes.s2),
                    Text(
                      'gastado',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontSize: 10,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════
//  DATA HELPERS
// ═══════════════════════════════════════════════════════════

String _formatGuaranies(double value) {
  if (value == 0) return '0 Gs.';
  final parts = value.toStringAsFixed(0).split('');
  final buffer = StringBuffer();
  var count = 0;
  for (var i = parts.length - 1; i >= 0; i--) {
    buffer.write(parts[i]);
    count++;
    if (count % 3 == 0 && i > 0) buffer.write('.');
  }
  return '${buffer.toString().split('').reversed.join('')} Gs.';
}

_RevenueData _computeRevenueData(
  List<Reservation> reservations,
  List<ServiceModel> services,
  _ReportPeriod period,
) {
  final serviceMap = {for (final s in services) s.id: s};

  // Compute daily revenue from real data grouped by weekday.
  final daily = List<double>.filled(7, 0);
  for (final r in reservations) {
    if (r.status == ReservationStatus.cancelled) continue;
    final dow = r.startTime.weekday - 1; // 0=Mon..6=Sun
    final svc = serviceMap[r.serviceId];
    if (svc != null) {
      daily[dow] += svc.price ?? 0;
    }
  }

  final total = daily.reduce((a, b) => a + b);

  // Trend: compare first half vs second half of the period.
  double trendPercent = 0;
  if (reservations.isNotEmpty) {
    reservations.sort((a, b) => a.startTime.compareTo(b.startTime));
    final mid = reservations.length ~/ 2;
    double firstHalf = 0;
    double secondHalf = 0;
    for (var i = 0; i < reservations.length; i++) {
      if (reservations[i].status == ReservationStatus.cancelled) continue;
      final svc = serviceMap[reservations[i].serviceId];
      final price = svc?.price ?? 0;
      if (i < mid) {
        firstHalf += price;
      } else {
        secondHalf += price;
      }
    }
    if (firstHalf > 0) {
      trendPercent = ((secondHalf - firstHalf) / firstHalf * 100);
    }
  }

  return _RevenueData(
    totalRevenue: total,
    trendPercent: trendPercent,
    dailyRevenue: daily,
  );
}

List<_PopularServiceRow> _computePopularServices(
  List<Reservation> reservations,
  List<ServiceModel> services,
) {
  final serviceMap = {for (final s in services) s.id: s};
  final bookingCount = <String, int>{};
  final bookingRevenue = <String, double>{};

  for (final r in reservations) {
    if (r.status == ReservationStatus.cancelled) continue;
    bookingCount[r.serviceId] = (bookingCount[r.serviceId] ?? 0) + 1;
    final svc = serviceMap[r.serviceId];
    bookingRevenue[r.serviceId] =
        (bookingRevenue[r.serviceId] ?? 0) + (svc?.price ?? 0);
  }

  if (bookingCount.isEmpty) return [];

  final maxBookings =
      bookingCount.values.fold<int>(0, math.max).clamp(1, 999999);

  final sorted = bookingCount.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));

  return sorted.take(5).toList().asMap().entries.map((e) {
    final sid = e.value.key;
    final svc = serviceMap[sid];
    return _PopularServiceRow(
      rank: e.key + 1,
      name: svc?.name ?? 'Servicio ${e.key + 1}',
      bookings: e.value.value,
      revenue: bookingRevenue[sid] ?? 0,
      percent: e.value.value / maxBookings,
    );
  }).toList();
}

/// Builds a 15×7 matrix (hours 7-21 × Mon-Sun) from real data only.
List<List<int>> _computeHeatmap(List<Reservation> reservations) {
  final hours = 15; // 7..21
  final data = List.generate(hours, (_) => List.filled(7, 0));

  for (final r in reservations) {
    if (r.status == ReservationStatus.cancelled) continue;
    final h = r.startTime.hour;
    final d = r.startTime.weekday - 1; // 0=Mon
    if (h >= 7 && h <= 21 && d >= 0 && d < 7) {
      data[h - 7][d]++;
    }
  }

  return data;
}

_ClientStatsData _computeClientStats(
  List<Reservation> reservations,
  _ReportPeriod period,
) {
  if (reservations.isEmpty) {
    return const _ClientStatsData(
      newClients: 0,
      returningClients: 0,
      cancellationRate: 0,
    );
  }

  final now = DateTime.now();
  final periodDays = _periodToDays(period);
  final cutoff = now.subtract(Duration(days: periodDays));

  final inPeriod =
      reservations.where((r) => r.createdAt.isAfter(cutoff)).toList();
  final allClientIds = inPeriod.map((r) => r.clientId).whereType<String>().toSet();

  // Consider "new" if the client has no reservations before the cutoff.
  final prePeriod = reservations.where((r) => r.createdAt.isBefore(cutoff));
  final oldClientIds = prePeriod.map((r) => r.clientId).whereType<String>().toSet();

  final newClients =
      allClientIds.where((id) => !oldClientIds.contains(id)).length;
  final returning = allClientIds.length - newClients;

  final totalInPeriod = inPeriod.length.clamp(1, 999999);
  final cancelledInPeriod = inPeriod
      .where((r) => r.status == ReservationStatus.cancelled)
      .length;
  final cancellationRate = cancelledInPeriod / totalInPeriod * 100;

  return _ClientStatsData(
    newClients: newClients,
    returningClients: returning,
    cancellationRate: cancellationRate,
  );
}

List<_TopClientRow> _computeTopClients(
  List<Reservation> reservations,
  List<ServiceModel> services,
) {
  final serviceMap = {for (final s in services) s.id: s};
  final visits = <String, int>{};
  final spent = <String, double>{};
  final names = <String, String>{};

  for (final r in reservations) {
    if (r.status == ReservationStatus.cancelled) continue;
    // Reservas manuales (clientId null) se excluyen del ranking de clientes
    final cid = r.clientId;
    if (cid == null) continue;
    visits[cid] = (visits[cid] ?? 0) + 1;
    final svc = serviceMap[r.serviceId];
    spent[cid] = (spent[cid] ?? 0) + (svc?.price ?? 0);
    if (r.clientName != null) names[cid] = r.clientName!;
  }

  if (visits.isEmpty) return [];

  final sorted = visits.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));

  final results = <_TopClientRow>[];
  for (var i = 0; i < math.min(sorted.length, 5); i++) {
    final id = sorted[i].key;
    final name = names[id] ?? 'Cliente';
    results.add(_TopClientRow(
      name: name,
      initials: _extractInitials(name),
      visits: sorted[i].value,
      totalSpent: spent[id] ?? 0,
    ));
  }

  return results;
}

String _extractInitials(String name) {
  final parts = name.trim().split(' ');
  if (parts.length >= 2) {
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }
  return name.isNotEmpty ? name[0].toUpperCase() : '?';
}

// ═══════════════════════════════════════════════════════════
//  7. EXPORT EXCEL/CSV
// ═══════════════════════════════════════════════════════════

class _ExportSection extends StatelessWidget {
  final List<Reservation> reservations;
  final List<ServiceModel> services;

  const _ExportSection({
    required this.reservations,
    required this.services,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppCard(
      padding: const EdgeInsets.all(AppSizes.s20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSizes.s8),
                decoration: BoxDecoration(
                  color: const Color(0xFF217346).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                ),
                child: const Icon(Icons.table_chart_rounded,
                    color: Color(0xFF217346), size: AppSizes.iconLg),
              ),
              const SizedBox(width: AppSizes.s12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Exportar para tu contador',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Descargá un archivo CSV compatible con Excel',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.outline,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.s16),

          // Export buttons row
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 44,
                  child: ElevatedButton.icon(
                    onPressed: () => _exportCsv(context, reservations, services),
                    icon: const Icon(Icons.download_rounded, size: 18),
                    label: const Text('Exportar Reservas',
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF217346),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSizes.s12),
              Expanded(
                child: SizedBox(
                  height: 44,
                  child: OutlinedButton.icon(
                    onPressed: () => _exportServicesSummary(context, reservations, services),
                    icon: const Icon(Icons.summarize_rounded, size: 18),
                    label: const Text('Resumen Servicios',
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF217346),
                      side: const BorderSide(color: Color(0xFF217346)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSizes.s12),
          Row(
            children: [
              Icon(Icons.info_outline_rounded,
                  size: 14, color: theme.colorScheme.outline.withValues(alpha: 0.6)),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  '${reservations.length} registros en el período seleccionado',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.outline,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Generate and download a CSV with all reservation details.
  Future<void> _exportCsv(
    BuildContext context,
    List<Reservation> reservations,
    List<ServiceModel> services,
  ) async {
    try {
      final dateFormat = DateFormat('dd/MM/yyyy');
      final timeFormat = DateFormat('HH:mm');

      // Build a price map from services
      final priceMap = <String, double>{};
      for (final s in services) {
        if (s.price != null) priceMap[s.id] = s.price!;
      }

      // BOM for Excel UTF-8 compatibility
      final bom = '\uFEFF';
      final header = 'Fecha,Hora Inicio,Hora Fin,Cliente,Servicio,Empleado,Estado,Monto (Gs.)';
      final rows = reservations.map((r) {
        final price = priceMap[r.serviceId] ?? 0;
        final status = _statusLabel(r.status);
        return [
          dateFormat.format(r.startTime),
          timeFormat.format(r.startTime),
          timeFormat.format(r.endTime),
          _escapeCsv(r.clientName ?? 'N/A'),
          _escapeCsv(r.serviceName ?? 'N/A'),
          _escapeCsv(r.employeeName ?? 'Sin asignar'),
          status,
          price.toStringAsFixed(0),
        ].join(',');
      }).join('\n');

      final csvContent = '$bom$header\n$rows';
      final bytes = utf8.encode(csvContent);
      final base64Data = base64Encode(bytes);
      final dataUri = 'data:text/csv;charset=utf-8;base64,$base64Data';

      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/reservas_reporte.csv');
      await file.writeAsBytes(bytes);
      await Share.shareXFiles([XFile(file.path)], text: 'Reporte de reservas');

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Archivo CSV listo para compartir'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al exportar: $e')),
      );
    }
  }

  /// Generate a summary CSV grouped by service.
  Future<void> _exportServicesSummary(
    BuildContext context,
    List<Reservation> reservations,
    List<ServiceModel> services,
  ) async {
    try {
      final priceMap = <String, double>{};
      for (final s in services) {
        if (s.price != null) priceMap[s.id] = s.price!;
      }

      // Aggregate by service
      final serviceStats = <String, _ServiceExportRow>{};
      for (final r in reservations.where((r) => r.status != ReservationStatus.cancelled)) {
        final name = r.serviceName ?? 'Sin servicio';
        final price = priceMap[r.serviceId] ?? 0;
        final existing = serviceStats[name];
        if (existing != null) {
          serviceStats[name] = _ServiceExportRow(
            name: name,
            count: existing.count + 1,
            revenue: existing.revenue + price,
          );
        } else {
          serviceStats[name] = _ServiceExportRow(
            name: name,
            count: 1,
            revenue: price,
          );
        }
      }

      final sorted = serviceStats.values.toList()
        ..sort((a, b) => b.revenue.compareTo(a.revenue));

      final totalRevenue = sorted.fold<double>(0, (s, r) => s + r.revenue);
      final totalCount = sorted.fold<int>(0, (s, r) => s + r.count);

      final bom = '\uFEFF';
      final header = 'Servicio,Cantidad,Ingresos (Gs.),% del Total';
      final rows = sorted.map((s) {
        final pct = totalRevenue > 0 ? (s.revenue / totalRevenue * 100).toStringAsFixed(1) : '0';
        return [
          _escapeCsv(s.name),
          s.count.toString(),
          s.revenue.toStringAsFixed(0),
          '$pct%',
        ].join(',');
      }).join('\n');

      final totalRow = 'TOTAL,$totalCount,${totalRevenue.toStringAsFixed(0)},100%';
      final csvContent = '$bom$header\n$rows\n\n$totalRow';
      final bytes = utf8.encode(csvContent);
      final base64Data = base64Encode(bytes);
      final dataUri = 'data:text/csv;charset=utf-8;base64,$base64Data';

      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/resumen_servicios.csv');
      await file.writeAsBytes(bytes);
      await Share.shareXFiles([XFile(file.path)], text: 'Resumen de servicios');

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Resumen de servicios listo para compartir'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al exportar: $e')),
      );
    }
  }

  String _escapeCsv(String value) {
    if (value.contains(',') || value.contains('"') || value.contains('\n')) {
      return '"${value.replaceAll('"', '""')}"';
    }
    return value;
  }

  String _statusLabel(ReservationStatus s) {
    switch (s) {
      case ReservationStatus.pending:
        return 'Pendiente';
      case ReservationStatus.confirmed:
        return 'Confirmada';
      case ReservationStatus.completed:
        return 'Completada';
      case ReservationStatus.cancelled:
        return 'Cancelada';
    }
  }
}

class _ServiceExportRow {
  final String name;
  final int count;
  final double revenue;
  const _ServiceExportRow({
    required this.name,
    required this.count,
    required this.revenue,
  });
}
