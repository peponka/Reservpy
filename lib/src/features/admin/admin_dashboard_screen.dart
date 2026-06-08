import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import 'package:reservpy/src/core/constants/app_colors.dart';
import 'package:reservpy/src/core/constants/app_sizes.dart';
import 'package:reservpy/src/data/repositories/admin_repository.dart';

// ── Providers ─────────────────────────────────────────────────────────────────

final _adminStatsProvider = FutureProvider<_AdminStats>((ref) async {
  final repo = AdminRepository();
  final results = await Future.wait([
    repo.getTotalBusinesses(),
    repo.getActiveBusinesses(),
    repo.getTotalUsers(),
    repo.getTotalReservations(),
    repo.getReservationsThisMonth(),
    repo.getBusinessesByPlan(),
  ]);
  return _AdminStats(
    totalBusinesses: results[0] as int,
    activeBusinesses: results[1] as int,
    totalUsers: results[2] as int,
    totalReservations: results[3] as int,
    reservationsThisMonth: results[4] as int,
    businessesByPlan: results[5] as Map<String, int>,
  );
});

class _AdminStats {
  const _AdminStats({
    required this.totalBusinesses,
    required this.activeBusinesses,
    required this.totalUsers,
    required this.totalReservations,
    required this.reservationsThisMonth,
    required this.businessesByPlan,
  });
  final int totalBusinesses;
  final int activeBusinesses;
  final int totalUsers;
  final int totalReservations;
  final int reservationsThisMonth;
  final Map<String, int> businessesByPlan;
}

// ── Screen ────────────────────────────────────────────────────────────────────

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(_adminStatsProvider);
    final theme = Theme.of(context);
    final now = DateTime.now();

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──────────────────────────────────────
            Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Panel de Administración',
                      style: GoogleFonts.inter(fontSize: 26, fontWeight: FontWeight.w800,
                          color: theme.colorScheme.onSurface),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      DateFormat("EEEE d 'de' MMMM yyyy", 'es').format(now),
                      style: GoogleFonts.inter(fontSize: 14,
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.5)),
                    ),
                  ],
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => ref.invalidate(_adminStatsProvider),
                  icon: const Icon(Icons.refresh_rounded),
                  tooltip: 'Actualizar',
                  color: AppColors.primary,
                ),
              ],
            ),

            const SizedBox(height: 32),

            // ── Stats ────────────────────────────────────────
            statsAsync.when(
              loading: () => const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
              error: (e, _) => _ErrorCard(message: e.toString()),
              data: (stats) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // KPI row
                  LayoutBuilder(builder: (_, constraints) {
                    final cols = constraints.maxWidth > 900 ? 4 : 2;
                    return GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: cols,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 1.6,
                      children: [
                        _KpiCard(
                          icon: Icons.storefront_rounded,
                          label: 'Negocios totales',
                          value: '${stats.totalBusinesses}',
                          sub: '${stats.activeBusinesses} activos',
                          color: AppColors.primary,
                        ),
                        _KpiCard(
                          icon: Icons.people_rounded,
                          label: 'Usuarios',
                          value: '${stats.totalUsers}',
                          sub: 'Registrados',
                          color: const Color(0xFF6366F1),
                        ),
                        _KpiCard(
                          icon: Icons.event_available_rounded,
                          label: 'Reservas totales',
                          value: '${stats.totalReservations}',
                          sub: '${stats.reservationsThisMonth} este mes',
                          color: const Color(0xFFF59E0B),
                        ),
                        _KpiCard(
                          icon: Icons.trending_up_rounded,
                          label: 'Este mes',
                          value: '${stats.reservationsThisMonth}',
                          sub: 'Reservas nuevas',
                          color: const Color(0xFFEC4899),
                        ),
                      ],
                    );
                  }),

                  const SizedBox(height: 32),

                  // Plans breakdown
                  Text(
                    'Negocios por plan',
                    style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700,
                        color: theme.colorScheme.onSurface),
                  ),
                  const SizedBox(height: 16),
                  _PlansCard(planCounts: stats.businessesByPlan, total: stats.totalBusinesses),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Widgets ───────────────────────────────────────────────────────────────────

class _KpiCard extends StatelessWidget {
  const _KpiCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.sub,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final String sub;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 20, color: color),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: GoogleFonts.inter(fontSize: 28, fontWeight: FontWeight.w800,
                    color: theme.colorScheme.onSurface),
              ),
              Text(
                label,
                style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6)),
              ),
              Text(
                sub,
                style: GoogleFonts.inter(fontSize: 11, color: color, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PlansCard extends StatelessWidget {
  const _PlansCard({required this.planCounts, required this.total});

  final Map<String, int> planCounts;
  final int total;

  static const _planColors = <String, Color>{
    'free':       Color(0xFF6B7280),
    'basic':      Color(0xFF3B82F6),
    'pro':        AppColors.primary,
    'enterprise': Color(0xFFF59E0B),
  };

  static const _planLabels = <String, String>{
    'free':       'Gratuito',
    'basic':      'Básico',
    'pro':        'Pro',
    'enterprise': 'Empresarial',
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final plans = ['free', 'basic', 'pro', 'enterprise'];

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        children: plans.map((plan) {
          final count = planCounts[plan] ?? 0;
          final pct = total > 0 ? count / total : 0.0;
          final color = _planColors[plan] ?? AppColors.primary;
          final label = _planLabels[plan] ?? plan;
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(label, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurface)),
                    Text('$count negocios (${(pct * 100).toStringAsFixed(0)}%)',
                        style: GoogleFonts.inter(fontSize: 12, color: theme.colorScheme.onSurface.withValues(alpha: 0.5))),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: pct,
                    minHeight: 8,
                    backgroundColor: color.withValues(alpha: 0.12),
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.red),
          const SizedBox(width: 12),
          Expanded(child: Text(message, style: GoogleFonts.inter(fontSize: 13, color: Colors.red))),
        ],
      ),
    );
  }
}
