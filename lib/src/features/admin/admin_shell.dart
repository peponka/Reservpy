import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:reservpy/src/core/constants/app_colors.dart';
import 'package:reservpy/src/data/repositories/auth_repository.dart';
import 'package:reservpy/src/shared/providers/providers.dart';

import 'admin_dashboard_screen.dart';
import 'admin_businesses_screen.dart';
import 'admin_users_screen.dart';
import 'admin_payments_screen.dart';
import 'admin_team_screen.dart';
import 'admin_audit_screen.dart';

// ── Provider ──────────────────────────────────────────────────────────────────

final adminNavIndexProvider = StateProvider<int>((ref) => 0);

// ── Shell ─────────────────────────────────────────────────────────────────────

class AdminShell extends ConsumerWidget {
  const AdminShell({super.key});

  static const _navItems = <_NavItem>[
    _NavItem(icon: Icons.dashboard_outlined,      activeIcon: Icons.dashboard_rounded,         label: 'Dashboard',     badge: null),
    _NavItem(icon: Icons.storefront_outlined,     activeIcon: Icons.storefront_rounded,        label: 'Negocios',      badge: null),
    _NavItem(icon: Icons.people_outline_rounded,  activeIcon: Icons.people_rounded,            label: 'Usuarios',      badge: null),
    _NavItem(icon: Icons.receipt_long_outlined,   activeIcon: Icons.receipt_long_rounded,      label: 'Pagos',         badge: null),
    _NavItem(icon: Icons.group_outlined,          activeIcon: Icons.group_rounded,             label: 'Equipo',        badge: null),
    _NavItem(icon: Icons.history_outlined,        activeIcon: Icons.history_rounded,           label: 'Auditoría',     badge: null),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final index = ref.watch(adminNavIndexProvider);
    final theme  = Theme.of(context);
    final isWide = MediaQuery.of(context).size.width > 900;

    final screens = [
      const AdminDashboardScreen(),
      const AdminBusinessesScreen(),
      const AdminUsersScreen(),
      const AdminPaymentsScreen(),
      const AdminTeamScreen(),
      const AdminAuditScreen(),
    ];

    if (isWide) {
      // ── Wide layout: sidebar + content ─────────────────────────────
      return Scaffold(
        backgroundColor: theme.colorScheme.surface,
        body: Row(
          children: [
            _AdminSidebar(
              currentIndex: index,
              items: _navItems,
              onTap: (i) => ref.read(adminNavIndexProvider.notifier).state = i,
              onLogout: () async {
                await AuthRepository().signOut();
                if (context.mounted) context.go('/');
              },
            ),
            Expanded(child: screens[index]),
          ],
        ),
      );
    } else {
      // ── Narrow layout: bottom nav ───────────────────────────────────
      return Scaffold(
        backgroundColor: theme.colorScheme.surface,
        body: screens[index],
        bottomNavigationBar: NavigationBar(
          selectedIndex: index,
          onDestinationSelected: (i) => ref.read(adminNavIndexProvider.notifier).state = i,
          labelBehavior: NavigationDestinationLabelBehavior.alwaysHide,
          destinations: _navItems.map((item) => NavigationDestination(
            icon:          Icon(item.icon),
            selectedIcon:  Icon(item.activeIcon),
            label:         item.label,
          )).toList(),
        ),
      );
    }
  }
}

// ── Sidebar ───────────────────────────────────────────────────────────────────

class _AdminSidebar extends ConsumerWidget {
  const _AdminSidebar({
    required this.currentIndex,
    required this.items,
    required this.onTap,
    required this.onLogout,
  });

  final int currentIndex;
  final List<_NavItem> items;
  final ValueChanged<int> onTap;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final user  = ref.watch(currentUserProvider);

    return Container(
      width: 228,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(right: BorderSide(color: theme.dividerColor.withValues(alpha: 0.3))),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(2, 0),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Logo ─────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 6),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.asset('assets/images/icon.png', width: 36, height: 36, fit: BoxFit.cover),
                ),
                const SizedBox(width: 10),
                Text.rich(TextSpan(children: [
                  TextSpan(
                    text: 'Reserv',
                    style: GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.w800,
                        color: theme.colorScheme.onSurface),
                  ),
                  TextSpan(
                    text: 'Py',
                    style: GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.w800,
                        color: AppColors.primary),
                  ),
                ])),
              ],
            ),
          ),

          // ── Admin badge ───────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'Panel de Administración',
                style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.primary),
              ),
            ),
          ),

          Divider(height: 1, color: theme.dividerColor.withValues(alpha: 0.3)),
          const SizedBox(height: 8),

          // ── Nav items ─────────────────────────────────────
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              itemCount: items.length,
              itemBuilder: (_, i) {
                final item   = items[i];
                final active = i == currentIndex;
                return _SidebarTile(
                  icon:   active ? item.activeIcon : item.icon,
                  label:  item.label,
                  active: active,
                  onTap:  () => onTap(i),
                );
              },
            ),
          ),

          Divider(height: 1, color: theme.dividerColor.withValues(alpha: 0.3)),

          // ── User + logout ─────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 17,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                  child: Text(
                    user?.initials ?? 'A',
                    style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primary),
                  ),
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        user?.fullName ?? 'Admin',
                        style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600,
                            color: theme.colorScheme.onSurface),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'Administrador',
                        style: GoogleFonts.inter(fontSize: 10, color: AppColors.primary),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  iconSize: 17,
                  icon: const Icon(Icons.logout_rounded),
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                  tooltip: 'Cerrar sesión',
                  onPressed: onLogout,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Sidebar tile ─────────────────────────────────────────────────────────────

class _SidebarTile extends StatelessWidget {
  const _SidebarTile({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Material(
        color: active ? AppColors.primary.withValues(alpha: 0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Icon(icon, size: 19,
                  color: active ? AppColors.primary : theme.colorScheme.onSurface.withValues(alpha: 0.5)),
                const SizedBox(width: 11),
                Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                    color: active ? AppColors.primary : theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Model ─────────────────────────────────────────────────────────────────────

class _NavItem {
  const _NavItem({required this.icon, required this.activeIcon, required this.label, this.badge});
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final int? badge;
}
