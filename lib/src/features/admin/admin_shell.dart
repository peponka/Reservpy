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
                try {
                  await AuthRepository().signOut();
                } catch (_) {}
                ref.read(isLoggedInProvider.notifier).state = false;
                ref.read(currentUserProvider.notifier).state = null;
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
      height:  64,
      decoration: BoxDecoration(
        color: AC.surface,
        border: const Border(bottom: BorderSide(color: AC.border)),
        boxShadow: [
          BoxShadow(
            color:      const Color(0x06000020),
            blurRadius: 12,
            offset:     const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Row(
        children: [
          Text(
            _navItems[currentIndex].label,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 19, fontWeight: FontWeight.w700, color: AC.text,
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color:        AC.success.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(20),
              border:       Border.all(color: AC.success.withValues(alpha: 0.2)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 7, height: 7,
                  decoration: const BoxDecoration(color: AC.success, shape: BoxShape.circle),
                ).animate(onPlay: (c) => c.repeat())
                    .then(delay: 1000.ms)
                    .fade(begin: 1, end: 0.3, duration: 800.ms)
                    .then()
                    .fade(begin: 0.3, end: 1, duration: 800.ms),
                const SizedBox(width: 7),
                Text('Sistema operativo', style: GoogleFonts.inter(
                  fontSize: 12, fontWeight: FontWeight.w500, color: AC.success,
                )),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AC.violet.withValues(alpha: 0.1),
                  AC.violet.withValues(alpha: 0.06),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AC.violet.withValues(alpha: 0.2)),
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
        color: AC.surface,
        boxShadow: [
          BoxShadow(
            color:      Color(0x08000028),
            blurRadius: 24,
            offset:     Offset(4, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          // ── Logo ──────────────────────────────────────────
          Container(
            padding:     const EdgeInsets.fromLTRB(20, 24, 20, 20),
            decoration:  const BoxDecoration(
              border: Border(bottom: BorderSide(color: AC.border)),
            ),
            child: Row(
              children: [
                Container(
                  width:  40, height: 40,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    gradient: const LinearGradient(
                      colors: AC.gradViolet,
                      begin: Alignment.topLeft,
                      end:   Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color:      AC.violet.withValues(alpha: 0.3),
                        blurRadius: 10,
                        offset:     const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.asset('assets/images/icon.png', fit: BoxFit.cover),
                  ),
                ),
                const SizedBox(width: 11),
                Text.rich(TextSpan(children: [
                  TextSpan(text: 'Reserv', style: GoogleFonts.spaceGrotesk(
                    fontSize: 18, fontWeight: FontWeight.w800, color: AC.text,
                  )),
                  TextSpan(text: 'Py', style: GoogleFonts.spaceGrotesk(
                    fontSize: 18, fontWeight: FontWeight.w800, color: AC.violet,
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
                        margin:   const EdgeInsets.only(bottom: 3),
                        padding:  const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                        decoration: BoxDecoration(
                          color: active
                              ? AC.violet.withValues(alpha: 0.08)
                              : hov
                                  ? AC.surfaceHigh
                                  : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                          border: active
                              ? Border.all(color: AC.violet.withValues(alpha: 0.18))
                              : null,
                          boxShadow: active
                              ? [BoxShadow(
                                  color: AC.violet.withValues(alpha: 0.08),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                )]
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
