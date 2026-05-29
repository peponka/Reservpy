import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:go_router/go_router.dart';
import 'package:reservpy/src/core/constants/app_colors.dart';
import 'package:reservpy/src/core/constants/app_sizes.dart';
import 'package:reservpy/src/core/constants/app_strings.dart';
import 'package:reservpy/src/core/widgets/widgets.dart';
import 'package:reservpy/src/shared/models/models.dart';
import 'package:reservpy/src/shared/providers/providers.dart';
import 'package:reservpy/src/data/repositories/auth_repository.dart';


/// User profile screen shared by both client and business shells.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final themeMode = ref.watch(themeModeProvider);
    final theme = Theme.of(context);
    final isDark = themeMode == ThemeMode.dark;

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(AppSizes.s24),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: constraints.maxHeight - 48,
                            maxWidth: constraints.maxWidth,
                          ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
              const SizedBox(height: AppSizes.s16),

              // ── Avatar ──
              UserAvatar(
                initials: user?.initials ?? '??',
                imageUrl: user?.avatarUrl,
                size: 96,
              ),
              const SizedBox(height: AppSizes.s16),

              // ── Full Name ──
              Text(
                user?.fullName ?? 'Usuario',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSizes.s8),

              // ── Email ──
              _InfoRow(
                icon: Icons.email_outlined,
                value: user?.email ?? 'sin correo',
              ),
              const SizedBox(height: AppSizes.s6),

              // ── Phone ──
              _InfoRow(
                icon: Icons.phone_outlined,
                value: user?.phone ?? 'sin teléfono',
              ),
              const SizedBox(height: AppSizes.s12),

              // ── Role badge ──
              _RoleBadge(role: user?.role ?? UserRole.client),

              const SizedBox(height: AppSizes.s24),
              Divider(color: theme.colorScheme.outline.withValues(alpha: 0.15)),
              const SizedBox(height: AppSizes.s16),

              // ── Settings Section ──
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Configuración',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: AppSizes.s12),

              // Dark mode toggle
              _SettingsRow(
                icon: Icons.dark_mode_outlined,
                label: 'Modo oscuro',
                trailing: Switch.adaptive(
                  value: isDark,
                  activeThumbColor: theme.colorScheme.primary,
                  activeTrackColor: theme.colorScheme.primary.withValues(alpha: 0.5),
                  onChanged: (value) {
                    ref.read(themeModeProvider.notifier).state =
                        value ? ThemeMode.dark : ThemeMode.light;
                  },
                ),
              ),

              // Language row
              _SettingsRow(
                icon: Icons.language_rounded,
                label: 'Idioma',
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Español',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.outline,
                      ),
                    ),
                    const SizedBox(width: AppSizes.s4),
                    Icon(
                      Icons.chevron_right_rounded,
                      size: AppSizes.iconMd,
                      color: theme.colorScheme.outline,
                    ),
                  ],
                ),
              ),

              // Notifications row
              _SettingsRow(
                icon: Icons.notifications_outlined,
                label: 'Notificaciones',
                trailing: Icon(
                  Icons.chevron_right_rounded,
                  size: AppSizes.iconMd,
                  color: theme.colorScheme.outline,
                ),
              ),

              const SizedBox(height: AppSizes.s16),
              Divider(color: theme.colorScheme.outline.withValues(alpha: 0.15)),
              const SizedBox(height: AppSizes.s16),

              // ── Logout Button ──
              SizedBox(
                width: double.infinity,
                child: TextButton.icon(
                  onPressed: () => _handleLogout(context, ref),
                  icon: const Icon(Icons.logout_rounded, size: AppSizes.iconMd),
                  label: const Text(AppStrings.logout),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.error,
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSizes.s12,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: AppSizes.s32),

              // ── Cambiar de vista ──
              Divider(color: theme.colorScheme.outline.withValues(alpha: 0.15)),
              const SizedBox(height: AppSizes.s12),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Cambiar de vista',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: AppSizes.s4),
              Text(
                'Usá la misma cuenta como cliente o como negocio',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.outline,
                ),
              ),
              const SizedBox(height: AppSizes.s12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    final currentRole = ref.read(activeRoleProvider);
                    final isBusiness = currentRole == UserRole.businessOwner || currentRole == UserRole.business;
                    
                    // Switch role view (same user, different view)
                    final newRole = isBusiness ? UserRole.client : UserRole.businessOwner;
                    ref.read(activeRoleProvider.notifier).state = newRole;
                    
                    // Navigate to new shell
                    context.go(isBusiness ? '/client' : '/business');
                  },
                  icon: Icon(
                    (user?.canBeBusiness ?? false)
                        ? (ref.watch(activeRoleProvider) == UserRole.businessOwner || ref.watch(activeRoleProvider) == UserRole.business)
                            ? Icons.person_rounded
                            : Icons.store_rounded
                        : Icons.store_rounded,
                    size: 20,
                  ),
                  label: Text(
                    (ref.watch(activeRoleProvider) == UserRole.businessOwner || ref.watch(activeRoleProvider) == UserRole.business)
                        ? 'Cambiar a modo Cliente →'
                        : 'Cambiar a modo Negocio →',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: (ref.watch(activeRoleProvider) == UserRole.businessOwner || ref.watch(activeRoleProvider) == UserRole.business)
                        ? AppColors.info
                        : AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
              const SizedBox(height: AppSizes.s8),
              Text(
                'Misma cuenta, múltiples roles',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.outline.withValues(alpha: 0.5),
                  fontStyle: FontStyle.italic,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: AppSizes.s24),

              // ── Version ──
              Text(
                'ReservPy v1.0.0',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.outline.withValues(alpha: 0.5),
                ),
              ),
              const SizedBox(height: AppSizes.s16),
              ],
            ),
          ),
        );
      },
    );
  }

  void _handleLogout(BuildContext context, WidgetRef ref) {
    showDialog<void>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizes.radiusLg),
          ),
          title: const Text(AppStrings.logout),
          content: const Text('¿Estás seguro que querés cerrar sesión?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text(AppStrings.cancel),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(ctx).pop();

                // Sign out from Supabase
                try {
                  await AuthRepository().signOut();
                } catch (_) {
                  // Continue with local cleanup even if Supabase fails
                }

                // Reset ALL providers to clean state
                ref.read(currentUserProvider.notifier).state = null;
                ref.read(isLoggedInProvider.notifier).state = false;
                ref.read(selectedRoleProvider.notifier).state = UserRole.client;
                ref.read(businessNavIndexProvider.notifier).state = 0;

                if (context.mounted) {
                  context.go('/login');
                }
              },
              style: TextButton.styleFrom(foregroundColor: AppColors.error),
              child: const Text(AppStrings.logout),
            ),
          ],
        );
      },
    );
  }
}

/// Compact info row with icon and text (for email/phone).
class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String value;

  const _InfoRow({required this.icon, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: theme.colorScheme.outline),
        const SizedBox(width: AppSizes.s6),
        Text(
          value,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.outline,
          ),
        ),
      ],
    );
  }
}

/// Role badge pill.
class _RoleBadge extends StatelessWidget {
  final UserRole role;

  const _RoleBadge({required this.role});

  String get _label {
    switch (role) {
      case UserRole.client:
        return AppStrings.roleClient;
      case UserRole.business:
      case UserRole.businessOwner:
        return AppStrings.roleBusiness;
      case UserRole.employee:
        return 'Empleado';
      case UserRole.admin:
        return AppStrings.roleAdmin;
    }
  }

  Color get _color {
    switch (role) {
      case UserRole.client:
        return AppColors.info;
      case UserRole.business:
      case UserRole.businessOwner:
        return AppColors.primary;
      case UserRole.employee:
        return const Color(0xFF6366F1);
      case UserRole.admin:
        return AppColors.warning;
    }
  }

  @override
  Widget build(BuildContext context) {
    return StatusBadge(label: _label, color: _color);
  }
}

/// Settings row with leading icon, label, and a trailing widget.
class _SettingsRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final Widget trailing;

  const _SettingsRow({
    required this.icon,
    required this.label,
    required this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSizes.s6),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(AppSizes.radiusSm),
            ),
            child: Icon(icon, size: AppSizes.iconMd, color: theme.colorScheme.primary),
          ),
          const SizedBox(width: AppSizes.s12),
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.bodyLarge,
            ),
          ),
          trailing,
        ],
      ),
    );
  }
}
