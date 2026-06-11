import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:reservpy/src/core/constants/app_colors.dart';
import 'package:reservpy/src/core/constants/app_sizes.dart';
import 'package:reservpy/src/shared/providers/providers.dart';
import 'package:reservpy/src/data/repositories/auth_repository.dart';
import 'package:reservpy/src/shared/models/models.dart';
import 'package:reservpy/src/features/dashboard/dashboard_screen.dart';
import 'package:reservpy/src/features/calendar/calendar_screen.dart';
import 'package:reservpy/src/features/plans/plans_screen.dart';
import 'package:reservpy/src/features/settings/settings_screen.dart';
import 'package:reservpy/src/features/business/employees_screen.dart';
import 'package:reservpy/src/features/profile/profile_screen.dart';
import 'package:reservpy/src/features/business/clients_screen.dart';
import 'package:reservpy/src/features/business/services_screen.dart';
import 'package:reservpy/src/features/business/availability_screen.dart';
import 'package:reservpy/src/features/dashboard/reports_screen.dart';
import 'package:reservpy/src/features/notifications/notification_panel.dart';

/// Business owner navigation shell with responsive layout:
/// - Desktop (>=800px): Left sidebar navigation (like ReservPy)
/// - Mobile (<800px): Bottom navigation bar
class BusinessShell extends ConsumerWidget {
  const BusinessShell({super.key});

  /// All navigation items matching ReservPy's sidebar layout.
  static const _sidebarItems = <_SidebarNavItem>[
    _SidebarNavItem(icon: Icons.grid_view_outlined, activeIcon: Icons.grid_view_rounded, label: 'Dashboard'),
    _SidebarNavItem(icon: Icons.people_outline_rounded, activeIcon: Icons.people_rounded, label: 'Clientes'),
    _SidebarNavItem(icon: Icons.storefront_outlined, activeIcon: Icons.storefront_rounded, label: 'Servicios'),
    _SidebarNavItem(icon: Icons.schedule_outlined, activeIcon: Icons.schedule_rounded, label: 'Disponibilidad'),
    _SidebarNavItem(icon: Icons.calendar_today_outlined, activeIcon: Icons.calendar_today_rounded, label: 'Calendario'),
    _SidebarNavItem(icon: Icons.groups_outlined, activeIcon: Icons.groups_rounded, label: 'Equipo'),
    _SidebarNavItem(icon: Icons.bar_chart_outlined, activeIcon: Icons.bar_chart_rounded, label: 'Reportes'),
    _SidebarNavItem(icon: Icons.credit_card_outlined, activeIcon: Icons.credit_card_rounded, label: 'Planes'),
    _SidebarNavItem(icon: Icons.settings_outlined, activeIcon: Icons.settings_rounded, label: 'Configuración'),
  ];

  /// Mobile-only bottom nav items (subset of sidebar for compact display).
  static const _mobileNavItems = <_SidebarNavItem>[
    _SidebarNavItem(icon: Icons.grid_view_outlined, activeIcon: Icons.grid_view_rounded, label: 'Dashboard'),
    _SidebarNavItem(icon: Icons.calendar_today_outlined, activeIcon: Icons.calendar_today_rounded, label: 'Calendario'),
    _SidebarNavItem(icon: Icons.people_outline_rounded, activeIcon: Icons.people_rounded, label: 'Clientes'),
    _SidebarNavItem(icon: Icons.storefront_outlined, activeIcon: Icons.storefront_rounded, label: 'Servicios'),
    _SidebarNavItem(icon: Icons.menu_rounded, activeIcon: Icons.menu_rounded, label: 'Más'),
  ];

  /// Maps mobile nav index to sidebar index (index 4 = "Más" handled separately).
  static const _mobileToSidebarIndex = [0, 4, 1, 2]; // Dashboard, Calendario, Clientes, Servicios

  /// Items shown inside the "Más" bottom sheet, with their _buildActiveTab indices.
  static const _moreSheetItems = <({IconData icon, String label, int tabIndex, Color color})>[
    (icon: Icons.event_available_rounded, label: 'Disponibilidad', tabIndex: 3, color: Color(0xFF0EA5E9)),
    (icon: Icons.groups_rounded, label: 'Equipo', tabIndex: 5, color: Color(0xFF6366F1)),
    (icon: Icons.bar_chart_rounded, label: 'Reportes', tabIndex: 6, color: Color(0xFFF59E0B)),
    (icon: Icons.diamond_rounded, label: 'Planes', tabIndex: 7, color: Color(0xFFEC4899)),
    (icon: Icons.settings_rounded, label: 'Configuración', tabIndex: 8, color: Color(0xFF8B5CF6)),
    (icon: Icons.person_rounded, label: 'Perfil', tabIndex: 9, color: Color(0xFF14B8A6)),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentIndex = ref.watch(businessNavIndexProvider);
    final theme = Theme.of(context);
    final isDesktop = MediaQuery.sizeOf(context).width >= 800;

    // Wait for business data to load before deciding
    final ownerBizAsync = ref.watch(ownerBusinessProvider);
    if (ownerBizAsync.isLoading) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(color: AppColors.primary),
              const SizedBox(height: AppSizes.s16),
              Text(
                'Cargando tu negocio...',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Show error with retry — prevents false "Crear mi negocio" on network failure
    if (ownerBizAsync.hasError) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.cloud_off, size: 64, color: theme.colorScheme.onSurface.withValues(alpha: 0.3)),
              const SizedBox(height: AppSizes.s16),
              Text(
                'Error al cargar tu negocio',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: AppSizes.s8),
              Text(
                'Verificá tu conexión a internet e intentá de nuevo.',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSizes.s16),
              ElevatedButton.icon(
                onPressed: () => ref.invalidate(ownerBusinessProvider),
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: Text(
                  'Reintentar',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                  ),
                  elevation: 0,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final currentBusiness = ref.watch(currentBusinessProvider);

    // No business found ? show create business prompt
    if (currentBusiness == null) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSizes.s32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSizes.s24),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.store_rounded,
                    size: 64,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: AppSizes.s24),
                Text(
                  '¡Bienvenido a ReservPy!',
                  style: GoogleFonts.inter(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: AppSizes.s12),
                Text(
                  'Todavía no tenés un negocio creado.\nConfigurá tu negocio para empezar a recibir reservas.',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSizes.s32),
                SizedBox(
                  width: 280,
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: () => context.push('/onboarding'),
                    icon: const Icon(Icons.add_business_rounded),
                    label: Text(
                      'Crear mi negocio',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                      ),
                      elevation: 0,
                    ),
                  ),
                ),
                const SizedBox(height: AppSizes.s16),
                TextButton(
                  onPressed: () {
                    ref.read(activeRoleProvider.notifier).state = UserRole.client;
                    GoRouter.of(context).go('/client');
                  },
                  child: Text(
                    'Explorar como cliente ?',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(height: AppSizes.s8),
                TextButton.icon(
                  onPressed: () async {
                    await AuthRepository().signOut();
                    ref.read(isLoggedInProvider.notifier).state = false;
                    ref.read(currentUserProvider.notifier).state = null;
                    if (context.mounted) context.go('/login');
                  },
                  icon: const Icon(Icons.logout_rounded, size: 18, color: AppColors.error),
                  label: Text(
                    'Cerrar sesión',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.error,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (isDesktop) {
      return Scaffold(
        body: Row(
          children: [
            // -- Left Sidebar --
            _DesktopSidebar(
              currentIndex: currentIndex,
              onIndexChanged: (index) {
                ref.read(businessNavIndexProvider.notifier).state = index;
              },
            ),
            // -- Vertical Divider --
            VerticalDivider(
              width: 1,
              thickness: 1,
              color: theme.colorScheme.outline.withValues(alpha: 0.08),
            ),
            // -- Main Content --
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SizedBox(
                    width: constraints.maxWidth,
                    height: constraints.maxHeight,
                    child: Column(
                      children: [
                        // Notification bar
                        Padding(
                          padding: const EdgeInsets.only(right: 12, top: 8),
                          child: Row(
                            children: [
                              const Spacer(),
                              const NotificationBell(),
                            ],
                          ),
                        ),
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
                              child: _buildActiveTab(currentIndex, ref),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      );
    }

    // -- Mobile: Bottom Navigation --
    // Map sidebar index back to mobile nav index
    final mobileIndex = _mobileToSidebarIndex.indexOf(currentIndex);
    // If currentIndex is from a "Más" sheet item, highlight the "Más" tab (index 4)
    final isFromMoreSheet = _moreSheetItems.any((item) => item.tabIndex == currentIndex);
    final safeMobileIndex = mobileIndex >= 0 ? mobileIndex : (isFromMoreSheet ? 4 : 0);

    return Scaffold(
      body: SafeArea(
        bottom: false,
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
            child: _buildActiveTab(currentIndex, ref),
          ),
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: safeMobileIndex,
        onDestinationSelected: (index) {
          if (index == 4) {
            // "Más" tapped ? show bottom sheet with hidden sections
            _showMoreSheet(context, ref, currentIndex);
          } else {
            ref.read(businessNavIndexProvider.notifier).state = _mobileToSidebarIndex[index];
          }
        },
        backgroundColor: theme.scaffoldBackgroundColor,
        indicatorColor: theme.colorScheme.primary.withValues(alpha: 0.12),
        surfaceTintColor: Colors.transparent,
        elevation: 3,
        shadowColor: theme.colorScheme.shadow,
        animationDuration: const Duration(milliseconds: AppSizes.animNormal),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: _mobileNavItems
            .map(
              (item) => NavigationDestination(
                icon: Icon(item.icon, size: 22),
                selectedIcon: Icon(item.activeIcon, color: theme.colorScheme.primary, size: 22),
                label: item.label,
              ),
            )
            .toList(),
      ),
    );
  }

  /// Shows the "Más" modal bottom sheet with hidden navigation sections.
  void _showMoreSheet(BuildContext context, WidgetRef ref, int currentIndex) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) {
        return Container(
          decoration: BoxDecoration(
            color: theme.scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // -- Drag Handle --
                Padding(
                  padding: const EdgeInsets.only(top: 12, bottom: 4),
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: colorScheme.outline.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                // -- Header --
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
                  child: Row(
                    children: [
                      Text(
                        'Más opciones',
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: () => Navigator.of(sheetContext).pop(),
                        icon: Icon(
                          Icons.close_rounded,
                          size: 20,
                          color: colorScheme.outline,
                        ),
                        style: IconButton.styleFrom(
                          backgroundColor: colorScheme.outline.withValues(alpha: 0.08),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                // -- Navigation Items --
                ..._moreSheetItems.map((item) {
                  final isActive = currentIndex == item.tabIndex;
                  return Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        Navigator.of(sheetContext).pop();
                        ref.read(businessNavIndexProvider.notifier).state = item.tabIndex;
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                        child: Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: (isActive ? colorScheme.primary : item.color).withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                item.icon,
                                size: 20,
                                color: isActive ? colorScheme.primary : item.color,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Text(
                                item.label,
                                style: GoogleFonts.inter(
                                  fontSize: 15,
                                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                                  color: isActive
                                      ? colorScheme.primary
                                      : colorScheme.onSurface.withValues(alpha: 0.85),
                                ),
                              ),
                            ),
                            if (isActive)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: colorScheme.primary.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  'Actual',
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: colorScheme.primary,
                                  ),
                                ),
                              )
                            else
                              Icon(
                                Icons.chevron_right_rounded,
                                size: 20,
                                color: colorScheme.outline.withValues(alpha: 0.4),
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Returns only the widget for the currently selected tab.
  Widget _buildActiveTab(int index, WidgetRef ref) {
    switch (index) {
      case 0:
        return const DashboardScreen();
      case 1:
        return const ClientsScreen();
      case 2:
        return const ServicesScreen();
      case 3:
        return const AvailabilityScreen();
      case 4:
        return const CalendarScreen();
      case 5:
        return const EmployeesScreen();
      case 6:
        return const ReportsScreen();
      case 7:
        return const PlansScreen();
      case 8:
        return const SettingsScreen();
      case 9:
        return const ProfileScreen();
      default:
        return const DashboardScreen();
    }
  }
}

/// Desktop left sidebar navigation matching ReservPy's admin panel.
class _DesktopSidebar extends ConsumerWidget {
  final int currentIndex;
  final ValueChanged<int> onIndexChanged;

  const _DesktopSidebar({
    required this.currentIndex,
    required this.onIndexChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final user = ref.watch(currentUserProvider);

    return Container(
      width: 220,
      color: theme.scaffoldBackgroundColor,
      child: Column(
        children: [
          // -- Brand Header --
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
            child: Row(
              children: [
                // -- Logo branded --
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.asset(
                    'assets/images/logo.png',
                    width: 42,
                    height: 42,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: 'Reserv',
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: colorScheme.onSurface,
                            ),
                          ),
                          TextSpan(
                            text: 'Py',
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      'Gestión de turnos',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        color: colorScheme.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // -- Navigation Items --
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: BusinessShell._sidebarItems.length,
              itemBuilder: (context, index) {
                final item = BusinessShell._sidebarItems[index];
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

          // -- User Info & Logout --
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: colorScheme.outline.withValues(alpha: 0.08),
                ),
              ),
            ),
            child: Column(
              children: [
                // User profile row
                InkWell(
                  borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                  onTap: () => onIndexChanged(9), // Profile
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 16,
                          backgroundColor: colorScheme.primary,
                          child: Text(
                            user?.initials ?? '??',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                user?.fullName ?? 'Usuario',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: colorScheme.onSurface,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                user?.email ?? '',
                                style: GoogleFonts.inter(
                                  fontSize: 10,
                                  color: colorScheme.outline,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                // -- Role switcher --
                Builder(builder: (context) {
                  final user = ref.watch(currentUserProvider);
                  final currentRole = ref.watch(activeRoleProvider);
                  if (user == null || !user.isMultiRole) {
                    // Single role ? simple button to switch to client
                    return TextButton.icon(
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                        alignment: Alignment.centerLeft,
                        minimumSize: const Size(double.infinity, 40),
                        backgroundColor: const Color(0xFF20A482).withValues(alpha: 0.08),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                        ),
                      ),
                      onPressed: () {
                        ref.read(activeRoleProvider.notifier).state = UserRole.client;
                        GoRouter.of(context).go('/client');
                      },
                      icon: const Icon(Icons.person_search_rounded, size: 18, color: Color(0xFF20A482)),
                      label: Text(
                        'Ver como cliente',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: const Color(0xFF20A482),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    );
                  }
                  // Multi-role ? show dropdown
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF20A482).withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Perfil activo',
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            color: Colors.grey.shade500,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        ...user.roles.where((r) => r != UserRole.business).map((role) {
                          final isActive = (role == UserRole.businessOwner && (currentRole == UserRole.businessOwner || currentRole == UserRole.business)) ||
                              (role == currentRole);
                          return InkWell(
                            onTap: isActive ? null : () {
                              ref.read(activeRoleProvider.notifier).state = role;
                              if (role == UserRole.businessOwner || role == UserRole.business) {
                                GoRouter.of(context).go('/business');
                              } else {
                                GoRouter.of(context).go('/client');
                              }
                            },
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                              decoration: BoxDecoration(
                                color: isActive ? const Color(0xFF20A482).withValues(alpha: 0.15) : Colors.transparent,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    role == UserRole.businessOwner ? Icons.storefront_rounded :
                                    role == UserRole.employee ? Icons.badge_rounded :
                                    role == UserRole.admin ? Icons.admin_panel_settings_rounded :
                                    Icons.person_rounded,
                                    size: 16,
                                    color: isActive ? const Color(0xFF20A482) : Colors.grey.shade400,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    role.label,
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                                      color: isActive ? const Color(0xFF20A482) : Colors.grey.shade600,
                                    ),
                                  ),
                                  if (isActive) ...[
                                    const Spacer(),
                                    const Icon(Icons.check_rounded, size: 14, color: Color(0xFF20A482)),
                                  ],
                                ],
                              ),
                            ),
                          );
                        }),
                      ],
                    ),
                  );
                }),
                const SizedBox(height: 4),
                // Logout button
                TextButton.icon(
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                    alignment: Alignment.centerLeft,
                    minimumSize: const Size(double.infinity, 40),
                  ),
                  onPressed: () async {
                    // Sign out from Supabase
                    try {
                      await AuthRepository().signOut();
                    } catch (_) {
                      // Continue with local cleanup even if Supabase fails
                    }

                    // Reset ALL providers
                    ref.read(isLoggedInProvider.notifier).state = false;
                    ref.read(currentUserProvider.notifier).state = null;
                    ref.read(activeRoleProvider.notifier).state = UserRole.client;
                    ref.read(businessNavIndexProvider.notifier).state = 0;

                    if (context.mounted) {
                      context.go('/');
                    }
                  },
                  icon: Icon(Icons.logout_rounded, size: 18, color: colorScheme.error),
                  label: Text(
                    'Cerrar sesión',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: colorScheme.error,
                      fontWeight: FontWeight.w500,
                    ),
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


/// Internal sidebar nav item model.
class _SidebarNavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;

  const _SidebarNavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}
