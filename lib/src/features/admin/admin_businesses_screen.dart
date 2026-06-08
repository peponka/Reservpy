import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import 'package:reservpy/src/core/constants/app_colors.dart';
import 'package:reservpy/src/shared/models/models.dart';
import 'package:reservpy/src/data/repositories/admin_repository.dart';

// ── Provider ──────────────────────────────────────────────────────────────────

final _adminBusinessesProvider = FutureProvider<List<Business>>((ref) async {
  return AdminRepository().getAllBusinessesAdmin();
});

// ── Screen ────────────────────────────────────────────────────────────────────

class AdminBusinessesScreen extends ConsumerStatefulWidget {
  const AdminBusinessesScreen({super.key});

  @override
  ConsumerState<AdminBusinessesScreen> createState() => _AdminBusinessesScreenState();
}

class _AdminBusinessesScreenState extends ConsumerState<AdminBusinessesScreen> {
  String _search = '';
  String _filter = 'all'; // all | active | inactive

  @override
  Widget build(BuildContext context) {
    final bizAsync = ref.watch(_adminBusinessesProvider);
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
                Text(
                  'Negocios',
                  style: GoogleFonts.inter(fontSize: 26, fontWeight: FontWeight.w800,
                      color: theme.colorScheme.onSurface),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => ref.invalidate(_adminBusinessesProvider),
                  icon: const Icon(Icons.refresh_rounded),
                  color: AppColors.primary,
                  tooltip: 'Actualizar',
                ),
              ],
            ),
            const SizedBox(height: 20),

            // ── Search + filter ──────────────────────────
            Row(
              children: [
                Expanded(
                  child: TextField(
                    onChanged: (v) => setState(() => _search = v.toLowerCase()),
                    decoration: InputDecoration(
                      hintText: 'Buscar negocio...',
                      hintStyle: GoogleFonts.inter(fontSize: 14),
                      prefixIcon: const Icon(Icons.search_rounded, size: 20),
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: theme.dividerColor),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: theme.dividerColor.withValues(alpha: 0.4)),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                _FilterChip(label: 'Todos', value: 'all', selected: _filter == 'all',
                    onTap: () => setState(() => _filter = 'all')),
                const SizedBox(width: 6),
                _FilterChip(label: 'Activos', value: 'active', selected: _filter == 'active',
                    onTap: () => setState(() => _filter = 'active')),
                const SizedBox(width: 6),
                _FilterChip(label: 'Inactivos', value: 'inactive', selected: _filter == 'inactive',
                    onTap: () => setState(() => _filter = 'inactive')),
              ],
            ),
            const SizedBox(height: 20),

            // ── Table ────────────────────────────────────
            Expanded(
              child: bizAsync.when(
                loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
                error: (e, _) => Center(child: Text('Error: $e')),
                data: (businesses) {
                  final filtered = businesses.where((b) {
                    final matchSearch = _search.isEmpty || b.name.toLowerCase().contains(_search);
                    final matchFilter = _filter == 'all'
                        ? true
                        : _filter == 'active' ? b.isActive : !b.isActive;
                    return matchSearch && matchFilter;
                  }).toList();

                  if (filtered.isEmpty) {
                    return Center(
                      child: Text('No hay negocios',
                          style: GoogleFonts.inter(color: theme.colorScheme.onSurface.withValues(alpha: 0.4))),
                    );
                  }

                  return Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: theme.dividerColor.withValues(alpha: 0.3)),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: SingleChildScrollView(
                        child: Table(
                          columnWidths: const {
                            0: FlexColumnWidth(3),
                            1: FlexColumnWidth(2),
                            2: FlexColumnWidth(1.5),
                            3: FlexColumnWidth(1.5),
                            4: FlexColumnWidth(1),
                          },
                          children: [
                            // Header
                            TableRow(
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.06),
                              ),
                              children: ['Negocio', 'Plan', 'Creado', 'Estado', 'Acciones']
                                  .map((h) => _TableHeader(h))
                                  .toList(),
                            ),
                            // Rows
                            ...filtered.map((b) => TableRow(
                              decoration: BoxDecoration(
                                color: theme.colorScheme.surface,
                                border: Border(
                                  bottom: BorderSide(color: theme.dividerColor.withValues(alpha: 0.2)),
                                ),
                              ),
                              children: [
                                _TableCell(
                                  child: Row(
                                    children: [
                                      CircleAvatar(
                                        radius: 16,
                                        backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                                        backgroundImage: b.logoUrl != null ? NetworkImage(b.logoUrl!) : null,
                                        child: b.logoUrl == null
                                            ? Text(b.name[0].toUpperCase(),
                                                style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700,
                                                    color: AppColors.primary))
                                            : null,
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(b.name,
                                            style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600,
                                                color: theme.colorScheme.onSurface),
                                            overflow: TextOverflow.ellipsis),
                                      ),
                                    ],
                                  ),
                                ),
                                _TableCell(child: _PlanBadge(plan: b.plan)),
                                _TableCell(
                                  child: Text(
                                    DateFormat('dd/MM/yyyy').format(b.createdAt),
                                    style: GoogleFonts.inter(fontSize: 12,
                                        color: theme.colorScheme.onSurface.withValues(alpha: 0.6)),
                                  ),
                                ),
                                _TableCell(
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: b.isActive
                                          ? AppColors.primary.withValues(alpha: 0.1)
                                          : Colors.red.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      b.isActive ? 'Activo' : 'Inactivo',
                                      style: GoogleFonts.inter(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: b.isActive ? AppColors.primary : Colors.red,
                                      ),
                                    ),
                                  ),
                                ),
                                _TableCell(
                                  child: Switch.adaptive(
                                    value: b.isActive,
                                    activeColor: AppColors.primary,
                                    onChanged: (val) async {
                                      await AdminRepository().setBusinessActive(b.id, val);
                                      ref.invalidate(_adminBusinessesProvider);
                                    },
                                  ),
                                ),
                              ],
                            )),
                          ],
                        ),
                      ),
                    ),
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

// ── Helper widgets ────────────────────────────────────────────────────────────

class _TableHeader extends StatelessWidget {
  const _TableHeader(this.label);
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Text(
        label,
        style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700,
            color: AppColors.primary),
      ),
    );
  }
}

class _TableCell extends StatelessWidget {
  const _TableCell({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: child,
    );
  }
}

class _PlanBadge extends StatelessWidget {
  const _PlanBadge({required this.plan});
  final String plan;

  static const _colors = <String, Color>{
    'free':       Color(0xFF6B7280),
    'basic':      Color(0xFF3B82F6),
    'pro':        AppColors.primary,
    'enterprise': Color(0xFFF59E0B),
  };

  static const _labels = <String, String>{
    'free': 'Gratuito', 'basic': 'Básico', 'pro': 'Pro', 'enterprise': 'Empresarial',
  };

  @override
  Widget build(BuildContext context) {
    final color = _colors[plan] ?? AppColors.primary;
    final label = _labels[plan] ?? plan;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: color)),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({required this.label, required this.value, required this.selected, required this.onTap});
  final String label;
  final String value;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? AppColors.primary : Colors.grey.withValues(alpha: 0.3)),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: selected ? Colors.white : Colors.grey,
          ),
        ),
      ),
    );
  }
}
