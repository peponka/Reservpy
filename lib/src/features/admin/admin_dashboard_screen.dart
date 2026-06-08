import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import 'package:reservpy/src/core/constants/app_colors.dart';
import 'package:reservpy/src/data/repositories/admin_repository.dart';

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
    final theme      = Theme.of(context);
    final fmt        = NumberFormat('#,###', 'es_PY');

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: statsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error:   (e, _) => Center(child: Text('Error: $e')),
        data:    (stats) => _DashboardBody(stats: stats, fmt: fmt),
      ),
    );
  }
}

// ── Body ──────────────────────────────────────────────────────────────────────

class _DashboardBody extends StatelessWidget {
  const _DashboardBody({required this.stats, required this.fmt});
  final AdminStats stats;
  final NumberFormat fmt;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ────────────────────────────────────────
          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Dashboard', style: GoogleFonts.inter(
                    fontSize: 26, fontWeight: FontWeight.w800,
                    color: theme.colorScheme.onSurface,
                  )),
                  Text(
                    DateFormat("EEEE d 'de' MMMM, yyyy", 'es').format(DateTime.now()),
                    style: GoogleFonts.inter(fontSize: 13, color: Colors.grey.shade500),
                  ),
                ],
              ),
              const Spacer(),
              _RefreshButton(),
            ],
          ),
          const SizedBox(height: 28),

          // ── Section: General ──────────────────────────────
          _SectionTitle(title: 'General', icon: Icons.bar_chart_rounded, color: AppColors.primary),
          const SizedBox(height: 14),
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              _KpiCard(label: 'Negocios totales',    value: stats.totalBusinesses.toString(),
                  icon: Icons.storefront_rounded,    color: AppColors.primary),
              _KpiCard(label: 'Negocios activos',    value: stats.activeBusinesses.toString(),
                  icon: Icons.check_circle_rounded,  color: const Color(0xFF10B981)),
              _KpiCard(label: 'Inactivos',            value: stats.inactiveBusinesses.toString(),
                  icon: Icons.pause_circle_rounded,  color: const Color(0xFFF59E0B)),
              _KpiCard(label: 'Nuevos hoy',           value: stats.newBusinessesToday.toString(),
                  icon: Icons.add_business_rounded,  color: const Color(0xFF6366F1)),
              _KpiCard(label: 'Nuevos este mes',      value: stats.newBusinessesThisMonth.toString(),
                  icon: Icons.trending_up_rounded,   color: const Color(0xFF0EA5E9)),
              _KpiCard(label: 'Usuarios totales',     value: stats.totalUsers.toString(),
                  icon: Icons.people_rounded,        color: const Color(0xFFEC4899)),
              _KpiCard(label: 'Usuarios nuevos hoy',  value: stats.newUsersToday.toString(),
                  icon: Icons.person_add_rounded,    color: const Color(0xFF8B5CF6)),
              _KpiCard(label: 'Nuevos este mes',      value: stats.newUsersThisMonth.toString(),
                  icon: Icons.person_search_rounded, color: const Color(0xFF14B8A6)),
            ],
          ),
          const SizedBox(height: 32),

          // ── Section: Financiero ───────────────────────────
          _SectionTitle(title: 'Financiero', icon: Icons.attach_money_rounded, color: const Color(0xFF10B981)),
          const SizedBox(height: 14),
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              _KpiCard(
                label: 'MRR',
                value: '₲ ${fmt.format(stats.mrr)}',
                sublabel: 'Ingresos Mensuales Recurrentes',
                icon: Icons.trending_up_rounded,
                color: const Color(0xFF10B981),
                wide: true,
              ),
              _KpiCard(
                label: 'ARR',
                value: '₲ ${fmt.format(stats.arr)}',
                sublabel: 'Ingresos Anuales Proyectados',
                icon: Icons.show_chart_rounded,
                color: AppColors.primary,
                wide: true,
              ),
              _KpiCard(
                label: 'Churn Rate',
                value: '${stats.churnRatePercent.toStringAsFixed(1)}%',
                sublabel: 'Tasa de negocios inactivos',
                icon: Icons.trending_down_rounded,
                color: stats.churnRatePercent > 15
                    ? const Color(0xFFEF4444)
                    : const Color(0xFFF59E0B),
              ),
            ],
          ),
          const SizedBox(height: 20),

          _PlanBreakdownCard(stats: stats, fmt: fmt),
          const SizedBox(height: 32),

          // ── Section: Operacional ─────────────────────────
          _SectionTitle(title: 'Operacional', icon: Icons.calendar_month_rounded, color: const Color(0xFF6366F1)),
          const SizedBox(height: 14),
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              _KpiCard(label: 'Reservas totales',  value: stats.totalReservations.toString(),
                  icon: Icons.event_note_rounded,  color: const Color(0xFF6366F1)),
              _KpiCard(label: 'Reservas hoy',       value: stats.reservationsToday.toString(),
                  icon: Icons.today_rounded,        color: const Color(0xFF0EA5E9)),
              _KpiCard(label: 'Reservas este mes',  value: stats.reservationsThisMonth.toString(),
                  icon: Icons.date_range_rounded,   color: AppColors.primary),
              _KpiCard(label: 'Completadas',        value: stats.completedReservations.toString(),
                  icon: Icons.task_alt_rounded,     color: const Color(0xFF10B981)),
              _KpiCard(label: 'Canceladas',         value: stats.cancelledReservations.toString(),
                  icon: Icons.cancel_rounded,       color: const Color(0xFFEF4444)),
              _KpiCard(
                label: 'Tasa completadas',
                value: stats.totalReservations > 0
                    ? '${(stats.completedReservations / stats.totalReservations * 100).toStringAsFixed(1)}%'
                    : '—',
                icon: Icons.percent_rounded,
                color: const Color(0xFF8B5CF6),
              ),
            ],
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

// ── Plan Breakdown ────────────────────────────────────────────────────────────

class _PlanBreakdownCard extends StatelessWidget {
  const _PlanBreakdownCard({required this.stats, required this.fmt});
  final AdminStats stats;
  final NumberFormat fmt;

  static const _plans = <(String, String, Color, int)>[
    ('free',       'Gratuito',   Color(0xFF9CA3AF), 0),
    ('basic',      'Básico', Color(0xFF0EA5E9), 25000),
    ('pro',        'Pro',        Color(0xFF8B5CF6), 75000),
    ('enterprise', 'Enterprise', Color(0xFFF59E0B), 200000),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final total = stats.totalBusinesses > 0 ? stats.totalBusinesses : 1;

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.3)),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Distribución por Plan',
              style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700,
                  color: theme.colorScheme.onSurface)),
          const SizedBox(height: 16),
          for (final (key, label, color, price) in _plans) ...[
            _PlanRow(
              label:   label,
              count:   stats.businessesByPlan[key] ?? 0,
              total:   total,
              color:   color,
              revenue: fmt.format((stats.businessesByPlan[key] ?? 0) * price),
            ),
            const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }
}

class _PlanRow extends StatelessWidget {
  const _PlanRow({
    required this.label,
    required this.count,
    required this.total,
    required this.color,
    required this.revenue,
  });

  final String label;
  final int count;
  final int total;
  final Color color;
  final String revenue;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pct   = count / total;

    return Row(
      children: [
        SizedBox(
          width: 88,
          child: Text(label, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.75))),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value:            pct,
              minHeight:        8,
              backgroundColor:  color.withValues(alpha: 0.12),
              valueColor:       AlwaysStoppedAnimation(color),
            ),
          ),
        ),
        const SizedBox(width: 12),
        SizedBox(
          width: 30,
          child: Text('$count',
              textAlign: TextAlign.right,
              style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface)),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 108,
          child: Text('₲ $revenue',
              textAlign: TextAlign.right,
              style: GoogleFonts.inter(fontSize: 11, color: Colors.grey.shade500)),
        ),
      ],
    );
  }
}

// ── KPI Card ─────────────────────────────────────────────────────────────────

class _KpiCard extends StatelessWidget {
  const _KpiCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.sublabel,
    this.wide = false,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final String? sublabel;
  final bool wide;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ConstrainedBox(
      constraints: BoxConstraints(
        minWidth: wide ? 250 : 155,
        maxWidth: wide ? 310 : 205,
      ),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: theme.dividerColor.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(value, style: GoogleFonts.inter(
                    fontSize: 21, fontWeight: FontWeight.w800,
                    color: theme.colorScheme.onSurface,
                  )),
                  const SizedBox(height: 2),
                  Text(label, style: GoogleFonts.inter(
                    fontSize: 12, color: Colors.grey.shade500, fontWeight: FontWeight.w500,
                  )),
                  if (sublabel != null) ...[
                    const SizedBox(height: 2),
                    Text(sublabel!, style: GoogleFonts.inter(
                      fontSize: 10, color: Colors.grey.shade400,
                    )),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Section Title ─────────────────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, required this.icon, required this.color});
  final String title;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: color),
        ),
        const SizedBox(width: 10),
        Text(title, style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700,
            color: theme.colorScheme.onSurface)),
        const SizedBox(width: 12),
        Expanded(child: Divider(color: theme.dividerColor.withValues(alpha: 0.4))),
      ],
    );
  }
}

// ── Refresh ───────────────────────────────────────────────────────────────────

class _RefreshButton extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return OutlinedButton.icon(
      onPressed: () => ref.invalidate(adminStatsProvider),
      icon: const Icon(Icons.refresh_rounded, size: 16),
      label: const Text('Actualizar'),
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primary,
        side: BorderSide(color: AppColors.primary.withValues(alpha: 0.4)),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        textStyle: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500),
      ),
    );
  }
}
