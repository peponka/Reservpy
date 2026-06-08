import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import 'package:reservpy/src/core/constants/app_colors.dart';
import 'package:reservpy/src/shared/models/models.dart';
import 'package:reservpy/src/data/repositories/admin_repository.dart';

// ── Provider ──────────────────────────────────────────────────────────────────

final _adminSubsProvider = FutureProvider<List<Business>>((ref) async {
  return AdminRepository().getAllBusinessesAdmin();
});

// ── Screen ────────────────────────────────────────────────────────────────────

class AdminSubscriptionsScreen extends ConsumerStatefulWidget {
  const AdminSubscriptionsScreen({super.key});

  @override
  ConsumerState<AdminSubscriptionsScreen> createState() => _AdminSubscriptionsScreenState();
}

class _AdminSubscriptionsScreenState extends ConsumerState<AdminSubscriptionsScreen> {
  String _planFilter = 'all';

  static const _planColors = <String, Color>{
    'free':       Color(0xFF6B7280),
    'basic':      Color(0xFF3B82F6),
    'pro':        AppColors.primary,
    'enterprise': Color(0xFFF59E0B),
  };
  static const _planLabels = <String, String>{
    'free': 'Gratuito', 'basic': 'Básico', 'pro': 'Pro', 'enterprise': 'Empresarial',
  };

  @override
  Widget build(BuildContext context) {
    final bizAsync = ref.watch(_adminSubsProvider);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──────────────────────────────────
            Row(
              children: [
                Text('Suscripciones',
                    style: GoogleFonts.inter(fontSize: 26, fontWeight: FontWeight.w800,
                        color: theme.colorScheme.onSurface)),
                const Spacer(),
                IconButton(
                  onPressed: () => ref.invalidate(_adminSubsProvider),
                  icon: const Icon(Icons.refresh_rounded),
                  color: AppColors.primary,
                  tooltip: 'Actualizar',
                ),
              ],
            ),
            const SizedBox(height: 20),

            // ── Plan filter tabs ──────────────────────────
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _PlanTab(label: 'Todos', value: 'all', selected: _planFilter == 'all',
                      color: theme.colorScheme.onSurface, onTap: () => setState(() => _planFilter = 'all')),
                  const SizedBox(width: 8),
                  ..._planColors.entries.map((e) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: _PlanTab(
                      label: _planLabels[e.key] ?? e.key,
                      value: e.key,
                      selected: _planFilter == e.key,
                      color: e.value,
                      onTap: () => setState(() => _planFilter = e.key),
                    ),
                  )),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ── Cards ─────────────────────────────────────
            Expanded(
              child: bizAsync.when(
                loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
                error: (e, _) => Center(child: Text('Error: $e')),
                data: (businesses) {
                  final filtered = businesses.where((b) =>
                    _planFilter == 'all' || b.plan == _planFilter,
                  ).toList();

                  if (filtered.isEmpty) {
                    return Center(
                      child: Text('No hay negocios con este plan',
                          style: GoogleFonts.inter(color: theme.colorScheme.onSurface.withValues(alpha: 0.4))),
                    );
                  }

                  return GridView.builder(
                    gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 360,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 1.8,
                    ),
                    itemCount: filtered.length,
                    itemBuilder: (_, i) => _SubCard(business: filtered[i]),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SubCard extends StatelessWidget {
  const _SubCard({required this.business});
  final Business business;

  static const _planColors = <String, Color>{
    'free':       Color(0xFF6B7280),
    'basic':      Color(0xFF3B82F6),
    'pro':        AppColors.primary,
    'enterprise': Color(0xFFF59E0B),
  };
  static const _planLabels = <String, String>{
    'free': 'Gratuito', 'basic': 'Básico', 'pro': 'Pro', 'enterprise': 'Empresarial',
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = _planColors[business.plan] ?? AppColors.primary;
    final planLabel = _planLabels[business.plan] ?? business.plan;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: color.withValues(alpha: 0.12),
                backgroundImage: business.logoUrl != null ? NetworkImage(business.logoUrl!) : null,
                child: business.logoUrl == null
                    ? Text(business.name[0].toUpperCase(),
                        style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: color))
                    : null,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(business.name,
                    style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700,
                        color: theme.colorScheme.onSurface),
                    overflow: TextOverflow.ellipsis),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(planLabel,
                    style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: color)),
              ),
            ],
          ),
          const Spacer(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Activo desde',
                      style: GoogleFonts.inter(fontSize: 10,
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.4))),
                  Text(
                    business.planActivatedAt != null
                        ? DateFormat('dd/MM/yyyy').format(business.planActivatedAt!)
                        : DateFormat('dd/MM/yyyy').format(business.createdAt),
                    style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurface),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: business.isActive
                      ? AppColors.primary.withValues(alpha: 0.1)
                      : Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  business.isActive ? '● Activo' : '● Inactivo',
                  style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600,
                      color: business.isActive ? AppColors.primary : Colors.red),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PlanTab extends StatelessWidget {
  const _PlanTab({
    required this.label, required this.value, required this.selected,
    required this.color, required this.onTap,
  });
  final String label;
  final String value;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? color : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? color : color.withValues(alpha: 0.3)),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 13, fontWeight: FontWeight.w500,
            color: selected ? Colors.white : color,
          ),
        ),
      ),
    );
  }
}
