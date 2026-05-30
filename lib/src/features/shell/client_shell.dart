import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:reservpy/src/core/constants/app_sizes.dart';
import 'package:reservpy/src/core/constants/app_colors.dart';
import 'package:reservpy/src/shared/providers/providers.dart';
import 'package:reservpy/src/shared/models/models.dart';
import 'package:reservpy/src/features/dashboard/client_dashboard_screen.dart';
import 'package:reservpy/src/features/reservations/search_business_screen.dart';
import 'package:reservpy/src/features/reservations/my_reservations_screen.dart';
import 'package:reservpy/src/features/map/explore_map_screen.dart';
import 'package:reservpy/src/features/profile/profile_screen.dart';
import 'package:reservpy/src/features/notifications/notification_panel.dart';
import 'package:go_router/go_router.dart';

/// Client navigation shell with responsive layout:
/// - Desktop (>=800px): Left sidebar navigation
/// - Mobile (<800px): Bottom navigation bar
class ClientShell extends ConsumerWidget {
  const ClientShell({super.key});

  static const _navItems = <_NavItem>[
    _NavItem(icon: Icons.home_outlined, activeIcon: Icons.home_rounded, label: 'Inicio'),
    _NavItem(icon: Icons.add_circle_outline, activeIcon: Icons.add_circle_rounded, label: 'Sacar turnos'),
    _NavItem(icon: Icons.explore_outlined, activeIcon: Icons.explore_rounded, label: 'Explorar'),
    _NavItem(icon: Icons.calendar_today_outlined, activeIcon: Icons.calendar_today_rounded, label: 'Mis Reservas'),
    _NavItem(icon: Icons.person_outline_rounded, activeIcon: Icons.person_rounded, label: 'Perfil'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentIndex = ref.watch(clientNavIndexProvider);
    final theme = Theme.of(context);
    final isDesktop = MediaQuery.sizeOf(context).width >= 800;

    if (isDesktop) {
      return Scaffold(
        body: Row(
          children: [
            // ── Left Sidebar ──
            _ClientDesktopSidebar(
              currentIndex: currentIndex,
              onIndexChanged: (index) {
                ref.read(clientNavIndexProvider.notifier).state = index;
              },
            ),
            // ── Vertical Divider ──
            VerticalDivider(
              width: 1,
              thickness: 1,
              color: theme.colorScheme.outline.withValues(alpha: 0.08),
            ),
            // ── Main Content ──
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SizedBox(
                    width: constraints.maxWidth,
                    height: constraints.maxHeight,
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      switchInCurve: Curves.easeOutCubic,
                      switchOutCurve: Curves.easeInCubic,
                      transitionBuilder: (Widget child, Animation<double> animation) {
                        return FadeTransition(
                          opacity: animation,
                          child: SlideTransition(
                            position: Tween<Offset>(
                              begin: const Offset(0.0, 0.015),
                              end: Offset.zero,
                            ).animate(animation),
                            child: child,
                          ),
                        );
                      },
                      child: KeyedSubtree(
                        key: ValueKey<int>(currentIndex),
                        child: _buildActiveTab(currentIndex),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      );
    }

    // ── Mobile: Bottom Navigation ──
    return Scaffold(
      body: Column(
        children: [
          // ── "Volver a mi negocio" banner for business owners ──
          Builder(
            builder: (context) {
              final user = ref.watch(currentUserProvider);
              if (user != null && user.canBeBusiness) {
                return Material(
                  color: AppColors.primary.withValues(alpha: 0.06),
                  child: InkWell(
                    onTap: () {
                      ref.read(activeRoleProvider.notifier).state = UserRole.businessOwner;
                      context.go('/business');
                    },
                    child: SafeArea(
                      bottom: false,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        child: Row(
                          children: [
                            const Icon(Icons.store_rounded, size: 18, color: AppColors.primary),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Volver a mi negocio',
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                            const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.primary),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
          // ── Main content ──
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              transitionBuilder: (Widget child, Animation<double> animation) {
                return FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0.0, 0.015),
                      end: Offset.zero,
                    ).animate(animation),
                    child: child,
                  ),
                );
              },
              child: KeyedSubtree(
                key: ValueKey<int>(currentIndex),
                child: _buildActiveTab(currentIndex),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: (index) {
          ref.read(clientNavIndexProvider.notifier).state = index;
        },
        backgroundColor: theme.scaffoldBackgroundColor,
        indicatorColor: theme.colorScheme.primary.withValues(alpha: 0.12),
        surfaceTintColor: Colors.transparent,
        elevation: 3,
        shadowColor: theme.colorScheme.shadow,
        animationDuration: const Duration(milliseconds: AppSizes.animNormal),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: _navItems
            .map(
              (item) => NavigationDestination(
                icon: Icon(item.icon),
                selectedIcon: Icon(item.activeIcon, color: theme.colorScheme.primary),
                label: item.label,
              ),
            )
            .toList(),
      ),
    );
  }

  /// Returns only the widget for the currently selected tab.
  static Widget _buildActiveTab(int index) {
    switch (index) {
      case 0:
        return const ClientDashboardScreen();
      case 1:
        return const SearchBusinessScreen();
      case 2:
        return const ExploreMapScreen();
      case 3:
        return const MyReservationsScreen();
      case 4:
        return const ProfileScreen();
      default:
        return const ClientDashboardScreen();
    }
  }
}

/// Desktop left sidebar navigation for the client area.
class _ClientDesktopSidebar extends ConsumerWidget {
  final int currentIndex;
  final ValueChanged<int> onIndexChanged;

  const _ClientDesktopSidebar({
    required this.currentIndex,
    required this.onIndexChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      width: 220,
      color: theme.scaffoldBackgroundColor,
      child: Column(
        children: [
          // ── Brand Header ──
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: colorScheme.primary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.calendar_month_rounded, color: Colors.white, size: 18),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ReservPy',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      Text(
                        'Panel de cliente',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          color: colorScheme.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const NotificationBell(),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // ── Navigation Items ──
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: ClientShell._navItems.length,
              itemBuilder: (context, index) {
                final item = ClientShell._navItems[index];
                final isActive = currentIndex == index;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Material(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                      onTap: () => onIndexChanged(index),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: isActive
                              ? colorScheme.primary.withValues(alpha: 0.08)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              isActive ? item.activeIcon : item.icon,
                              size: 20,
                              color: isActive
                                  ? colorScheme.primary
                                  : colorScheme.outline,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              item.label,
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                                color: isActive
                                    ? colorScheme.primary
                                    : colorScheme.onSurface.withValues(alpha: 0.7),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // ── Switch to business mode ──
          Builder(
            builder: (context) {
              final user = ref.watch(currentUserProvider);
              if (user != null && user.canBeBusiness) {
                return Padding(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                  child: TextButton.icon(
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                      alignment: Alignment.centerLeft,
                      minimumSize: const Size(double.infinity, 40),
                      backgroundColor: AppColors.primary.withValues(alpha: 0.08),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                      ),
                    ),
                    onPressed: () {
                      ref.read(activeRoleProvider.notifier).state = UserRole.businessOwner;
                      context.go('/business');
                    },
                    icon: const Icon(Icons.store_rounded, size: 18, color: AppColors.primary),
                    label: Text(
                      'Volver a mi negocio',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),

          // ── Bottom branding ──
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: colorScheme.outline.withValues(alpha: 0.08),
                ),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.favorite_rounded,
                  size: 14,
                  color: AppColors.primary.withValues(alpha: 0.5),
                ),
                const SizedBox(width: 6),
                Text(
                  'ReservPy',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface.withValues(alpha: 0.4),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Internal nav item model.
class _NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}
