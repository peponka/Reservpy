import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'package:reservpy/src/data/repositories/admin_repository.dart';
import 'admin_theme.dart';

// ── Provider ──────────────────────────────────────────────────────────────────

final adminStatsProvider = FutureProvider<AdminStats>((ref) async {
  return AdminRepository().getStats();
});

// ── Screen ────────────────────────────────────────────────────────────────────

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(adminStatsProvider);
    return Scaffold(
      backgroundColor: AC.bg,
      body: statsAsync.when(
        loading: () => const _DashboardSkeleton(),
        error:   (e, _) => Center(
          child: Text('Error cargando datos: $e',
              style: GoogleFonts.inter(color: AC.textSec)),
        ),
        data: (stats) => _DashboardBody(stats: stats),
      ),
    );
  }
}

// ── Skeleton ──────────────────────────────────────────────────────────────────

class _DashboardSkeleton extends StatelessWidget {
  const _DashboardSkeleton();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AdminShimmer(width: 200, height: 32, radius: 8),
          const SizedBox(height: 8),
          const AdminShimmer(width: 160, height: 16),
          const SizedBox(height: 32),
          Wrap(spacing: 16, runSpacing: 16, children: List.generate(4, (_) =>
            const AdminShimmer(width: 220, height: 110, radius: 16))),
          const SizedBox(height: 32),
          const AdminShimmer(height: 260, radius: 16),
        ],
      ),
    );
  }
}

// ── Body ──────────────────────────────────────────────────────────────────────

class _DashboardBody extends ConsumerWidget {
  const _DashboardBody({required this.stats});
  final AdminStats stats;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fmt = NumberFormat('#,###', 'es_PY');

    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Bienvenido de nuevo 👋', style: GoogleFonts.spaceGrotesk(
                    fontSize: 30, fontWeight: FontWeight.w700, color: AC.text,
                  )),
                  const SizedBox(height: 5),
                  Text(
                    DateFormat("EEEE d 'de' MMMM, yyyy", 'es').format(DateTime.now()),
                    style: GoogleFonts.inter(fontSize: 14, color: AC.textSec),
                  ),
                ],
              ),
              const Spacer(),
              OutlinedButton.icon(
                onPressed: () => ref.invalidate(adminStatsProvider),
                icon: const Icon(Icons.refresh_rounded, size: 15),
                label: const Text('Actualizar'),
              ),
            ],
          ).animate().fadeIn(duration: 400.ms),
          const SizedBox(height: 32),

          // Overdue alert
          if (stats.overdueCount > 0)
            _OverdueAlert(count: stats.overdueCount).animate()
                .fadeIn(duration: 300.ms).slideY(begin: -0.1, end: 0),

          // ── KPI cards ─────────────────────────────────────
          Wrap(
            spacing: 20,
            runSpacing: 20,
            children: [
              _KpiCard(
                label:    'Ingresos del mes',
                value:    stats.revenueThisMonth.toDouble(),
                prefix:   '₲ ',
                icon:     Icons.trending_up_rounded,
                gradient: AC.gradTeal,
                fmt:      fmt,
              ),
              _KpiCard(
                label:    'Clientes activos',
                value:    stats.activeBusinesses.toDouble(),
                icon:     Icons.storefront_rounded,
                gradient: AC.gradViolet,
                fmt:      fmt,
              ),
              _KpiCard(
                label:    'Reservas este mes',
                value:    stats.reservationsThisMonth.toDouble(),
                icon:     Icons.calendar_month_rounded,
                gradient: [const Color(0xFF0EA5E9), const Color(0xFF0284C7)],
                fmt:      fmt,
              ),
              _KpiCard(
                label:    'Tasa de completadas',
                value:    stats.completionRate,
                suffix:   '%',
                icon:     Icons.task_alt_rounded,
                gradient: [AC.success, const Color(0xFF059669)],
                fmt:      NumberFormat('#.#'),
                isSmall:  true,
              ),
            ].asMap().entries.map((e) =>
              e.value.animate(delay: Duration(milliseconds: 80 * e.key))
                  .fadeIn(duration: 350.ms).slideY(begin: 0.15, end: 0)).toList(),
          ),
          const SizedBox(height: 32),

          // ── Revenue chart ─────────────────────────────────
          if (stats.monthlyRevenue.isNotEmpty)
            _RevenueChart(data: stats.monthlyRevenue, fmt: fmt)
                .animate(delay: 300.ms).fadeIn(duration: 400.ms),

          const SizedBox(height: 24),

          // ── Bottom grid ───────────────────────────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _PlanDonut(byPlan: stats.businessesByPlan, fmt: fmt)
                  .animate(delay: 400.ms).fadeIn(duration: 400.ms)),
              const SizedBox(width: 20),
              Expanded(child: _SecondaryKpis(stats: stats, fmt: fmt)
                  .animate(delay: 450.ms).fadeIn(duration: 400.ms)),
            ],
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

// ── Overdue alert banner ──────────────────────────────────────────────────────

class _OverdueAlert extends StatelessWidget {
  const _OverdueAlert({required this.count});
  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin:  const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color:  AC.danger.withValues(alpha: 0.08),
        border: Border.all(color: AC.danger.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: AC.danger, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '$count cliente${count > 1 ? 's' : ''} con pagos vencidos. '
              'Tomá acción para evitar suspensiones.',
              style: GoogleFonts.inter(fontSize: 13, color: AC.danger),
            ),
          ),
          TextButton(
            onPressed: () {},
            child: Text('Ver ahora',
                style: GoogleFonts.inter(fontSize: 12, color: AC.danger,
                    fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

// ── KPI Card ─────────────────────────────────────────────────────────────────

class _KpiCard extends StatelessWidget {
  const _KpiCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.gradient,
    required this.fmt,
    this.prefix = '',
    this.suffix = '',
    this.isSmall = false,
  });

  final String label;
  final double value;
  final IconData icon;
  final List<Color> gradient;
  final NumberFormat fmt;
  final String prefix;
  final String suffix;
  final bool isSmall;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 272,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: AC.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AC.border),
        boxShadow: const [
          BoxShadow(
            color:      Color(0x09000030),
            blurRadius: 28,
            offset:     Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: gradient,
                begin: Alignment.topLeft,
                end:   Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color:      gradient.first.withValues(alpha: 0.28),
                  blurRadius: 14,
                  offset:     const Offset(0, 5),
                ),
              ],
            ),
            child: Icon(icon, size: 22, color: Colors.white),
          ),
          const SizedBox(height: 22),
          CountUpValue(
            value:  value,
            prefix: prefix,
            suffix: suffix,
            style:  GoogleFonts.spaceGrotesk(
              fontSize:   isSmall ? 38 : 42,
              fontWeight: FontWeight.w700,
              color:      AC.text,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 6),
          Text(label, style: GoogleFonts.inter(
            fontSize: 13, color: AC.textSec, fontWeight: FontWeight.w500,
          )),
        ],
      ),
    );
  }
}

// ── Revenue Chart ─────────────────────────────────────────────────────────────

class _RevenueChart extends StatefulWidget {
  const _RevenueChart({required this.data, required this.fmt});
  final List<MonthlyRevenue> data;
  final NumberFormat fmt;

  @override
  State<_RevenueChart> createState() => _RevenueChartState();
}

class _RevenueChartState extends State<_RevenueChart> {
  int? _touchedIndex;

  @override
  Widget build(BuildContext context) {
    final sorted = [...widget.data]..sort((a, b) => a.month.compareTo(b.month));
    final spots  = sorted.asMap().entries.map((e) =>
        FlSpot(e.key.toDouble(), e.value.total)).toList();

    final maxY = spots.isEmpty ? 100000.0
        : (spots.map((s) => s.y).reduce((a, b) => a > b ? a : b) * 1.2);

    return AdminCard(
      gradient: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Ingresos por Mes', style: GoogleFonts.spaceGrotesk(
                    fontSize: 16, fontWeight: FontWeight.w700, color: AC.text,
                  )),
                  Text('Pagos confirmados en PYG', style: GoogleFonts.inter(
                    fontSize: 12, color: AC.textSec,
                  )),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 200,
            child: spots.isEmpty
                ? Center(child: Text('Sin datos de pagos aún',
                    style: GoogleFonts.inter(color: AC.textSec, fontSize: 13)))
                : LineChart(
                    LineChartData(
                      minY:         0,
                      maxY:         maxY,
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        getDrawingHorizontalLine: (_) => FlLine(
                          color: AC.border, strokeWidth: 1,
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      titlesData: FlTitlesData(
                        leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        topTitles:   const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles:   true,
                            reservedSize: 28,
                            getTitlesWidget: (value, meta) {
                              final idx = value.toInt();
                              if (idx < 0 || idx >= sorted.length) return const SizedBox.shrink();
                              return Text(
                                DateFormat('MMM', 'es').format(sorted[idx].month),
                                style: GoogleFonts.inter(fontSize: 11, color: AC.textSec),
                              );
                            },
                          ),
                        ),
                      ),
                      lineTouchData: LineTouchData(
                        touchTooltipData: LineTouchTooltipData(
                          getTooltipColor: (_) => AC.text,
                          getTooltipItems: (spots) => spots.map((s) => LineTooltipItem(
                            '₲ ${widget.fmt.format(s.y)}',
                            GoogleFonts.spaceGrotesk(
                              fontSize: 13, fontWeight: FontWeight.w600, color: AC.teal,
                            ),
                          )).toList(),
                        ),
                      ),
                      lineBarsData: [
                        LineChartBarData(
                          spots:           spots,
                          isCurved:        true,
                          curveSmoothness: 0.35,
                          color:           AC.teal,
                          barWidth:        3,
                          dotData: FlDotData(
                            show: true,
                            getDotPainter: (spot, pct, bar, idx) => FlDotCirclePainter(
                              radius:      _touchedIndex == idx ? 6 : 4,
                              color:       AC.teal,
                              strokeColor: AC.surface,
                              strokeWidth: 2.5,
                            ),
                          ),
                          belowBarData: BarAreaData(
                            show: true,
                            gradient: LinearGradient(
                              colors: [
                                AC.teal.withValues(alpha: 0.15),
                                AC.teal.withValues(alpha: 0.0),
                              ],
                              begin: Alignment.topCenter,
                              end:   Alignment.bottomCenter,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

// ── Plan Donut ────────────────────────────────────────────────────────────────

class _PlanDonut extends StatelessWidget {
  const _PlanDonut({required this.byPlan, required this.fmt});
  final Map<String, int> byPlan;
  final NumberFormat fmt;

  static const _colors = {
    'free':       Color(0xFFCBD5E1),
    'basic':      Color(0xFF0EA5E9),
    'pro':        AC.violet,
    'enterprise': AC.warning,
  };
  static const _labels = {
    'free': 'Gratuito', 'basic': 'Básico',
    'pro': 'Pro', 'enterprise': 'Enterprise',
  };

  @override
  Widget build(BuildContext context) {
    final total = byPlan.values.fold(0, (a, b) => a + b);
    if (total == 0) return const SizedBox.shrink();

    final sections = byPlan.entries.where((e) => e.value > 0).map((e) {
      final color = _colors[e.key] ?? AC.textSec;
      return PieChartSectionData(
        value:          e.value.toDouble(),
        color:          color,
        radius:         50,
        title:          '',
        showTitle:      false,
      );
    }).toList();

    return AdminCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Distribución por Plan', style: GoogleFonts.spaceGrotesk(
            fontSize: 16, fontWeight: FontWeight.w700, color: AC.text,
          )),
          const SizedBox(height: 4),
          Text('Clientes por tipo de suscripción', style: GoogleFonts.inter(
            fontSize: 12, color: AC.textSec,
          )),
          const SizedBox(height: 24),
          Row(
            children: [
              SizedBox(
                width: 130, height: 130,
                child: PieChart(PieChartData(
                  sections:          sections,
                  centerSpaceRadius: 36,
                  sectionsSpace:     3,
                )),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: Column(
                  children: byPlan.entries.where((e) => e.value > 0).map((e) {
                    final color = _colors[e.key] ?? AC.textSec;
                    final label = _labels[e.key] ?? e.key;
                    final pct   = (e.value / total * 100).toStringAsFixed(0);
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        children: [
                          Container(
                            width: 10, height: 10,
                            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                          ),
                          const SizedBox(width: 10),
                          Expanded(child: Text(label,
                              style: GoogleFonts.inter(fontSize: 13, color: AC.textSec,
                                  fontWeight: FontWeight.w500))),
                          Text('${e.value}', style: GoogleFonts.spaceGrotesk(
                              fontSize: 14, fontWeight: FontWeight.w700, color: AC.text)),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text('$pct%', style: GoogleFonts.inter(
                                fontSize: 11, color: color,
                                fontWeight: FontWeight.w600)),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Secondary KPIs ────────────────────────────────────────────────────────────

class _SecondaryKpis extends StatelessWidget {
  const _SecondaryKpis({required this.stats, required this.fmt});
  final AdminStats stats;
  final NumberFormat fmt;

  @override
  Widget build(BuildContext context) {
    return AdminCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Métricas Clave', style: GoogleFonts.spaceGrotesk(
            fontSize: 16, fontWeight: FontWeight.w700, color: AC.text,
          )),
          const SizedBox(height: 4),
          Text('Indicadores de rendimiento del negocio', style: GoogleFonts.inter(
            fontSize: 12, color: AC.textSec,
          )),
          const SizedBox(height: 20),
          _MetricRow(label: 'MRR', value: '₲ ${fmt.format(stats.mrr)}',
              color: AC.teal),
          _MetricRow(label: 'ARR proyectado', value: '₲ ${fmt.format(stats.arr)}',
              color: AC.violet),
          _MetricRow(label: 'Churn rate',
              value: '${stats.churnRatePercent.toStringAsFixed(1)}%',
              color: stats.churnRatePercent > 15 ? AC.danger : AC.warning),
          _MetricRow(label: 'Nuevos negocios (mes)', value: '${stats.newBusinessesThisMonth}',
              color: AC.success),
          _MetricRow(label: 'Pagos vencidos', value: '${stats.overdueCount}',
              color: stats.overdueCount > 0 ? AC.danger : AC.success),
          _MetricRow(label: 'Reservas canceladas', value: '${stats.cancelledReservations}',
              color: AC.warning, isLast: true),
        ],
      ),
    );
  }
}

class _MetricRow extends StatelessWidget {
  const _MetricRow({
    required this.label,
    required this.value,
    required this.color,
    this.isLast = false,
  });
  final String label;
  final String value;
  final Color color;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: isLast ? null : BoxDecoration(
        border: Border(bottom: BorderSide(color: AC.border, width: 0.8)),
      ),
      child: Row(
        children: [
          Container(
            width: 4, height: 32,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(child: Text(label,
              style: GoogleFonts.inter(fontSize: 13, color: AC.textSec,
                  fontWeight: FontWeight.w500))),
          Text(value, style: GoogleFonts.spaceGrotesk(
              fontSize: 15, fontWeight: FontWeight.w700, color: AC.text)),
        ],
      ),
    );
  }
}
