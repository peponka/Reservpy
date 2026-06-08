import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:reservpy/src/core/constants/app_colors.dart';
import 'package:reservpy/src/core/constants/app_sizes.dart';
import 'package:reservpy/src/data/repositories/auth_repository.dart';
import 'package:reservpy/src/shared/providers/providers.dart';

import 'admin_dashboard_screen.dart';
import 'admin_businesses_screen.dart';
import 'admin_users_screen.dart';
import 'admin_subscriptions_screen.dart';

// ── Provider ──────────────────────────────────────────────────────────────────

final adminNavIndexProvider = StateProvider<int>((ref) => 0);

// ── Shell ─────────────────────────────────────────────────────────────────────

class AdminShell extends ConsumerWidget {
  const AdminShell({super.key});

  static const _navItems = <_NavItem>[
    _NavItem(icon: Icons.dashboard_outlined,      activeIcon: Icons.dashboard_rounded,       label: 'Dashboard'),
    _NavItem(icon: Icons.storefront_outlined,     activeIcon: Icons.storefront_rounded,      label: 'Negocios'),
    _NavItem(icon: Icons.people_outline_rounded,  activeIcon: Icons.people_rounded,          label: 'Usuarios'),
    _NavItem(icon: Icons.card_membership_outlined,activeIcon: Icons.card_membership_rounded, label: 'Suscripciones'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final index = ref.watch(adminNavIndexProvider);
    final theme = Theme.of(context);

    final screens = [
      const AdminDashboardScreen(),
      const AdminBusinessesScreen(),
      const AdminUsersScreen(),
      const AdminSubscriptionsScreen(),
    ];

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: Row(
        children: [
          // ── Sidebar ──────────────────────────────────
          _AdminSidebar(
            currentIndex: index,
            items: _navItems,
            onTap: (i) => ref.read(adminNavIndexProvider.notifier).state = i,
            onLogout: () async {
              await AuthRepository().signOut();
              if (context.mounted) context.go('/');
            },
          ),
          // ── Content ──────────────────────────────────
          Expanded(child: screens[index]),
        ],
      ),
    );
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
    final user = ref.watch(currentUserProvider);

    return Container(
      width: 240,
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
          // ── Logo ──────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.asset('assets/images/icon.png', width: 38, height: 38, fit: BoxFit.cover),
                ),
                const SizedBox(width: 10),
                Text.rich(
                  TextSpan(children: [
                    TextSpan(
                      text: 'Reserv',
                      style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w800,
                          color: theme.colorScheme.onSurface),
                    ),
                    TextSpan(
                      text: 'Py',
                      style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w800,
                          color: AppColors.primary),
                    ),
                  ]),
                ),
              ],
            ),
          ),

          // ── Admin badge ───────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'Panel Admin',
                style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.primary),
              ),
            ),
          ),

          const Divider(height: 1),
          const SizedBox(height: 8),

          // ── Nav items ─────────────────────
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              itemCount: items.length,
              itemBuilder: (_, i) {
                final item = items[i];
                final active = i == currentIndex;
                return _SidebarTile(
                  icon: active ? item.activeIcon : item.icon,
                  label: item.label,
                  active: active,
                  onTap: () => onTap(i),
                );
              },
            ),
          ),

          const Divider(height: 1),

          // ── User info + logout ─────────────
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                  child: Text(
                    user?.initials ?? 'A',
                    style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.primary),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user?.fullName ?? 'Admin',
                        style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600,
                            color: theme.colorScheme.onSurface),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'Administrador',
                        style: GoogleFonts.inter(fontSize: 11, color: AppColors.primary),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.logout_rounded, size: 18),
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                  tooltip: 'Salir',
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
                Icon(icon,
                  size: 20,
                  color: active ? AppColors.primary : theme.colorScheme.onSurface.withValues(alpha: 0.5),
                ),
                const SizedBox(width: 12),
                Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 14,
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

class _NavItem {
  const _NavItem({required this.icon, required this.activeIcon, required this.label});
  final IconData icon;
  final IconData activeIcon;
  final String label;
}
