import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'package:reservpy/src/data/repositories/admin_repository.dart';
import 'admin_theme.dart';
import 'admin_client_detail_screen.dart';

// ── Providers ─────────────────────────────────────────────────────────────────

final adminClientsProvider = FutureProvider<List<AdminBusiness>>((ref) async {
  return AdminRepository().getAllBusinesses();
});

// ── Screen ────────────────────────────────────────────────────────────────────

class AdminClientsScreen extends ConsumerStatefulWidget {
  const AdminClientsScreen({super.key});

  @override
  ConsumerState<AdminClientsScreen> createState() => _AdminClientsScreenState();
}

class _AdminClientsScreenState extends ConsumerState<AdminClientsScreen> {
  String _search = '';
  String _filter = 'all'; // all | active | inactive | overdue
  String _planFilter = 'all';

  @override
  Widget build(BuildContext context) {
    final clientsAsync = ref.watch(adminClientsProvider);

    return Scaffold(
      backgroundColor: AC.bg,
      body: Column(
        children: [
          // ── Toolbar ──────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(28, 24, 28, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AdminSectionHeader(
                  title:    'Clientes',
                  subtitle: 'Negocios registrados en la plataforma',
                  trailing: OutlinedButton.icon(
                    onPressed: () => ref.invalidate(adminClientsProvider),
                    icon: const Icon(Icons.refresh_rounded, size: 15),
                    label: const Text('Actualizar'),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: TextField(
                        onChanged: (v) => setState(() => _search = v.toLowerCase()),
                        style: GoogleFonts.inter(fontSize: 13, color: AC.text),
                        decoration: InputDecoration(
                          hintText:   'Buscar por nombre, email o plan…',
                          prefixIcon: const Icon(Icons.search_rounded, size: 16, color: AC.textSec),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    _FilterDrop(
                      value: _filter,
                      items: const {
                        'all': 'Todos', 'active': 'Activos',
                        'inactive': 'Inactivos',
                      },
                      onChanged: (v) => setState(() => _filter = v),
                    ),
                    const SizedBox(width: 8),
                    _FilterDrop(
                      value: _planFilter,
                      items: const {
                        'all': 'Todos los planes', 'free': 'Gratuito',
                        'basic': 'Básico', 'pro': 'Pro', 'enterprise': 'Enterprise',
                      },
                      onChanged: (v) => setState(() => _planFilter = v),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ── Table header ──────────────────────────────────
          _TableHeader(),
          const Divider(height: 1, color: AC.border),

          // ── List ─────────────────────────────────────────
          Expanded(
            child: clientsAsync.when(
              loading: () => ListView.separated(
                padding: EdgeInsets.zero,
                itemCount: 8,
                separatorBuilder: (_, __) => const Divider(height: 1, color: AC.border),
                itemBuilder: (_, __) => const _RowSkeleton(),
              ),
              error:   (e, _) => Center(child: Text('Error: $e',
                  style: GoogleFonts.inter(color: AC.textSec))),
              data: (clients) {
                final filtered = clients.where((c) {
                  final matchSearch = _search.isEmpty ||
                      c.name.toLowerCase().contains(_search) ||
                      c.email.toLowerCase().contains(_search) ||
                      c.plan.toLowerCase().contains(_search);
                  final matchStatus = _filter == 'all' ||
                      (_filter == 'active' && c.isActive) ||
                      (_filter == 'inactive' && !c.isActive);
                  final matchPlan = _planFilter == 'all' || c.plan == _planFilter;
                  return matchSearch && matchStatus && matchPlan;
                }).toList();

                if (filtered.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.storefront_rounded, size: 52, color: AC.textMut),
                        const SizedBox(height: 12),
                        Text('Sin resultados', style: GoogleFonts.inter(
                            fontSize: 15, color: AC.textSec)),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  itemCount: filtered.length,
                  padding:   EdgeInsets.zero,
                  separatorBuilder: (_, __) => const Divider(height: 1, color: AC.border),
                  itemBuilder: (_, i) => _ClientRow(
                    client:  filtered[i],
                    onTap:   () => _openDetail(filtered[i]),
                    onToggle: () => _toggleActive(filtered[i]),
                  ).animate(delay: Duration(milliseconds: 20 * i))
                      .fadeIn(duration: 200.ms),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _openDetail(AdminBusiness client) {
    Navigator.of(context).push(PageRouteBuilder(
      pageBuilder: (_, anim, __) => Theme(
        data: adminTheme(),
        child: AdminClientDetailScreen(businessId: client.id),
      ),
      transitionsBuilder: (_, anim, __, child) => FadeTransition(opacity: anim, child: child),
      transitionDuration: const Duration(milliseconds: 250),
    ));
  }

  Future<void> _toggleActive(AdminBusiness client) async {
    await AdminRepository().setBusinessActive(client.id, !client.isActive);
    ref.invalidate(adminClientsProvider);
  }
}

// ── Table Header ─────────────────────────────────────────────────────────────

class _TableHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    const style = TextStyle(
      fontSize: 11, fontWeight: FontWeight.w600,
      color: AC.textSec, letterSpacing: 0.5,
    );
    return Container(
      color: AC.surface,
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 10),
      child: Row(
        children: [
          const SizedBox(width: 44),
          const Expanded(flex: 3, child: Text('NEGOCIO', style: style)),
          const Expanded(flex: 2, child: Text('PLAN', style: style)),
          const Expanded(flex: 2, child: Text('REGISTRO', style: style)),
          const Expanded(flex: 2, child: Text('ESTADO', style: style)),
          const SizedBox(width: 100),
        ],
      ),
    );
  }
}

// ── Client Row ────────────────────────────────────────────────────────────────

class _ClientRow extends StatefulWidget {
  const _ClientRow({required this.client, required this.onTap, required this.onToggle});
  final AdminBusiness client;
  final VoidCallback onTap;
  final VoidCallback onToggle;

  @override
  State<_ClientRow> createState() => _ClientRowState();
}

class _ClientRowState extends State<_ClientRow> {
  bool _hovered = false;

  static const _planColors = <String, Color>{
    'free':       Color(0xFF4A4A6A),
    'basic':      Color(0xFF0EA5E9),
    'pro':        AC.violet,
    'enterprise': AC.warning,
  };
  static const _planLabels = <String, String>{
    'free': 'Gratuito', 'basic': 'Básico',
    'pro': 'Pro', 'enterprise': 'Enterprise',
  };

  @override
  Widget build(BuildContext context) {
    final c    = widget.client;
    final fmt  = DateFormat('dd/MM/yyyy');
    final pc   = _planColors[c.plan] ?? AC.textSec;
    final pl   = _planLabels[c.plan] ?? c.plan;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit:  (_) => setState(() => _hovered = false),
      cursor:  SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          color: _hovered ? AC.surfaceHigh : Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
          child: Row(
            children: [
              // Avatar
              Container(
                width: 34, height: 34,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [pc.withValues(alpha: 0.8), pc.withValues(alpha: 0.4)],
                    begin: Alignment.topLeft, end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(c.initials, style: GoogleFonts.spaceGrotesk(
                      fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white)),
                ),
              ),
              const SizedBox(width: 10),

              // Name + email
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(c.name, style: GoogleFonts.inter(
                        fontSize: 13, fontWeight: FontWeight.w600, color: AC.text)),
                    Text(c.email, style: GoogleFonts.inter(
                        fontSize: 11, color: AC.textSec)),
                  ],
                ),
              ),

              // Plan badge
              Expanded(
                flex: 2,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(
                    color:        pc.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                    border:       Border.all(color: pc.withValues(alpha: 0.25)),
                  ),
                  child: Text(pl, style: GoogleFonts.inter(
                      fontSize: 11, fontWeight: FontWeight.w600, color: pc)),
                  constraints: const BoxConstraints(maxWidth: 100),
                ),
              ),

              // Date
              Expanded(
                flex: 2,
                child: Text(fmt.format(c.createdAt), style: GoogleFonts.inter(
                    fontSize: 12, color: AC.textSec)),
              ),

              // Status
              Expanded(
                flex: 2,
                child: StatusBadge(status: c.isActive ? 'active' : 'inactive'),
              ),

              // Actions
              SizedBox(
                width: 100,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (_hovered) ...[
                      _IconBtn(
                        icon: Icons.open_in_new_rounded,
                        color: AC.violet,
                        tooltip: 'Ver detalle',
                        onTap: widget.onTap,
                      ),
                      const SizedBox(width: 4),
                      _IconBtn(
                        icon: c.isActive
                            ? Icons.pause_circle_outline_rounded
                            : Icons.play_circle_outline_rounded,
                        color: c.isActive ? AC.warning : AC.success,
                        tooltip: c.isActive ? 'Desactivar' : 'Activar',
                        onTap: widget.onToggle,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Row Skeleton ──────────────────────────────────────────────────────────────

class _RowSkeleton extends StatelessWidget {
  const _RowSkeleton();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
      child: Row(
        children: [
          const AdminShimmer(width: 34, height: 34, radius: 10),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              AdminShimmer(width: 140, height: 13),
              SizedBox(height: 5),
              AdminShimmer(width: 100, height: 11),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Filter Dropdown ───────────────────────────────────────────────────────────

class _FilterDrop extends StatelessWidget {
  const _FilterDrop({
    required this.value,
    required this.items,
    required this.onChanged,
  });
  final String value;
  final Map<String, String> items;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color:  AC.surfaceHigh,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AC.border),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value:        value,
          dropdownColor: AC.surface,
          style:        GoogleFonts.inter(fontSize: 13, color: AC.text),
          icon:         const Icon(Icons.keyboard_arrow_down_rounded,
              size: 16, color: AC.textSec),
          items: items.entries.map((e) => DropdownMenuItem(
            value: e.key,
            child: Text(e.value),
          )).toList(),
          onChanged: (v) { if (v != null) onChanged(v); },
        ),
      ),
    );
  }
}

class _IconBtn extends StatelessWidget {
  const _IconBtn({
    required this.icon,
    required this.color,
    required this.tooltip,
    required this.onTap,
  });
  final IconData icon;
  final Color color;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 28, height: 28,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(7),
          ),
          child: Icon(icon, size: 14, color: color),
        ),
      ),
    );
  }
}
