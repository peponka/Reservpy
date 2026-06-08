import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'package:reservpy/src/data/repositories/auth_repository.dart';
import 'package:reservpy/src/shared/providers/providers.dart';
import 'admin_theme.dart';
import 'admin_dashboard_screen.dart';
import 'admin_clients_screen.dart';
import 'admin_payments_screen.dart';
import 'admin_team_screen.dart';
import 'admin_audit_screen.dart';
import 'admin_settings_screen.dart';

// ── Providers ─────────────────────────────────────────────────────────────────

final adminNavIndexProvider = StateProvider<int>((ref) => 0);

// ── Nav items ─────────────────────────────────────────────────────────────────

class _NavItem {
  const _NavItem({required this.icon, required this.label, this.badge = 0});
  final IconData icon;
  final String label;
  final int badge;
}

const _navItems = <_NavItem>[
  _NavItem(icon: Icons.space_dashboard_rounded,    label: 'Dashboard'),
  _NavItem(icon: Icons.storefront_rounded,          label: 'Clientes'),
  _NavItem(icon: Icons.receipt_long_rounded,        label: 'Pagos'),
  _NavItem(icon: Icons.group_rounded,               label: 'Equipo'),
  _NavItem(icon: Icons.history_rounded,             label: 'Auditoría'),
  _NavItem(icon: Icons.settings_rounded,            label: 'Configuración'),
];

// ── Shell ─────────────────────────────────────────────────────────────────────

class AdminShell extends ConsumerWidget {
  const AdminShell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final index = ref.watch(adminNavIndexProvider);

    final screens = [
      const AdminDashboardScreen(),
      const AdminClientsScreen(),
      const AdminPaymentsScreen(),
      const AdminTeamScreen(),
      const AdminAuditScreen(),
      const AdminSettingsScreen(),
    ];

    // Force dark admin theme regardless of app theme
    return Theme(
      data: adminTheme(),
      child: Scaffold(
        backgroundColor: AC.bg,
        body: Row(
          children: [
            _AdminSidebar(
              currentIndex: index,
              onTap: (i) => ref.read(adminNavIndexProvider.notifier).state = i,
              onLogout: () async {
                await AuthRepository().signOut();
                if (context.mounted) context.go('/');
              },
              ref: ref,
            ),
            Expanded(
              child: Column(
                children: [
                  _AdminTopBar(currentIndex: index),
                  Expanded(child: screens[index]),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Top Bar ───────────────────────────────────────────────────────────────────

class _AdminTopBar extends ConsumerWidget {
  const _AdminTopBar({required this.currentIndex});
  final int currentIndex;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      height:      64,
      decoration:  const BoxDecoration(
        color:  AC.surface,
        border: Border(bottom: BorderSide(color: AC.border)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Row(
        children: [
          Text(
            _navItems[currentIndex].label,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 18, fontWeight: FontWeight.w600, color: AC.text,
            ),
          ),
          const Spacer(),
          // Pulse indicator
          Container(
            width: 8, height: 8,
            decoration: const BoxDecoration(color: AC.success, shape: BoxShape.circle),
          ).animate(onPlay: (c) => c.repeat())
              .then(delay: 1000.ms)
              .fade(begin: 1, end: 0.2, duration: 800.ms)
              .then()
              .fade(begin: 0.2, end: 1, duration: 800.ms),
          const SizedBox(width: 8),
          Text('Sistema operativo', style: GoogleFonts.inter(fontSize: 12, color: AC.textSec)),
          const SizedBox(width: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color:        AC.violet.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
              border:       Border.all(color: AC.violet.withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.admin_panel_settings_rounded, size: 14, color: AC.violet),
                const SizedBox(width: 6),
                Text('Super Admin', style: GoogleFonts.inter(
                  fontSize: 12, fontWeight: FontWeight.w600, color: AC.violet,
                )),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Sidebar ───────────────────────────────────────────────────────────────────

class _AdminSidebar extends ConsumerStatefulWidget {
  const _AdminSidebar({
    required this.currentIndex,
    required this.onTap,
    required this.onLogout,
    required this.ref,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;
  final VoidCallback onLogout;
  final WidgetRef ref;

  @override
  ConsumerState<_AdminSidebar> createState() => _AdminSidebarState();
}

class _AdminSidebarState extends ConsumerState<_AdminSidebar> {
  int? _hovered;

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);

    return Container(
      width: 240,
      decoration: const BoxDecoration(
        color:  AC.surface,
        border: Border(right: BorderSide(color: AC.border)),
      ),
      child: Column(
        children: [
          // ── Logo ──────────────────────────────────────────
          Container(
            padding:     const EdgeInsets.fromLTRB(20, 22, 20, 18),
            decoration:  const BoxDecoration(
              border: Border(bottom: BorderSide(color: AC.border)),
            ),
            child: Row(
              children: [
                Container(
                  width:  36, height: 36,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    gradient: const LinearGradient(
                      colors: AC.gradViolet,
                      begin: Alignment.topLeft,
                      end:   Alignment.bottomRight,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.asset('assets/images/icon.png', fit: BoxFit.cover),
                  ),
                ),
                const SizedBox(width: 10),
                Text.rich(TextSpan(children: [
                  TextSpan(text: 'Reserv', style: GoogleFonts.spaceGrotesk(
                    fontSize: 17, fontWeight: FontWeight.w800, color: AC.text,
                  )),
                  TextSpan(text: 'Py', style: GoogleFonts.spaceGrotesk(
                    fontSize: 17, fontWeight: FontWeight.w800, color: AC.violet,
                  )),
                ])),
              ],
            ),
          ),

          // ── Nav ───────────────────────────────────────────
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
              child: Column(
                children: List.generate(_navItems.length, (i) {
                  final item   = _navItems[i];
                  final active = i == widget.currentIndex;
                  final hov    = _hovered == i;
                  return MouseRegion(
                    onEnter: (_) => setState(() => _hovered = i),
                    onExit:  (_) => setState(() => _hovered = null),
                    cursor:  SystemMouseCursors.click,
                    child: GestureDetector(
                      onTap: () => widget.onTap(i),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        margin:   const EdgeInsets.only(bottom: 2),
                        padding:  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: active
                              ? AC.violet.withValues(alpha: 0.15)
                              : hov
                                  ? AC.surfaceHigh
                                  : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                          border: active
                              ? Border.all(color: AC.violet.withValues(alpha: 0.3))
                              : null,
                        ),
                        child: Row(
                          children: [
                            Icon(item.icon, size: 18,
                              color: active ? AC.violet : hov ? AC.text : AC.textSec),
                            const SizedBox(width: 11),
                            Expanded(
                              child: Text(item.label, style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                                color: active ? AC.violet : hov ? AC.text : AC.textSec,
                              )),
                            ),
                            if (item.badge > 0) ...[
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color:        AC.danger,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text('${item.badge}', style: GoogleFonts.inter(
                                  fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white,
                                )),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),

          // ── User / Logout ─────────────────────────────────
          Container(
            padding:    const EdgeInsets.all(14),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: AC.border)),
            ),
            child: Row(
              children: [
                Container(
                  width: 34, height: 34,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: AC.gradViolet),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Text(
                      user?.initials ?? 'A',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        user?.fullName ?? 'Admin',
                        style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AC.text),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text('Super Admin',
                          style: GoogleFonts.inter(fontSize: 10, color: AC.violet)),
                    ],
                  ),
                ),
                IconButton(
                  iconSize: 16,
                  icon: const Icon(Icons.logout_rounded),
                  color: AC.textSec,
                  tooltip: 'Cerrar sesión',
                  onPressed: widget.onLogout,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
