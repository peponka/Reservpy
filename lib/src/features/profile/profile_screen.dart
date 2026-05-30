import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:reservpy/src/core/constants/app_colors.dart';
import 'package:reservpy/src/core/constants/app_sizes.dart';
import 'package:reservpy/src/core/constants/app_strings.dart';
import 'package:reservpy/src/core/widgets/widgets.dart';
import 'package:reservpy/src/shared/models/models.dart';
import 'package:reservpy/src/shared/providers/providers.dart';
import 'package:reservpy/src/data/repositories/auth_repository.dart';
import 'package:reservpy/src/data/repositories/profile_repository.dart';

/// User profile screen shared by both client and business shells.
class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _isEditing = false;
  bool _isSaving = false;

  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _phoneController;

  @override
  void initState() {
    super.initState();
    _firstNameController = TextEditingController();
    _lastNameController = TextEditingController();
    _phoneController = TextEditingController();
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _enterEditMode(AppUser user) {
    _firstNameController.text = user.firstName;
    _lastNameController.text = user.lastName;
    _phoneController.text = user.phone ?? '';
    setState(() => _isEditing = true);
  }

  void _cancelEdit() {
    setState(() => _isEditing = false);
  }

  Future<void> _saveProfile(AppUser user) async {
    if (_firstNameController.text.trim().isEmpty ||
        _lastNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(children: [
            const Icon(Icons.warning_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Text('Nombre y apellido son obligatorios',
                style: GoogleFonts.inter(fontWeight: FontWeight.w500)),
          ]),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final updated = user.copyWith(
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        phone: _phoneController.text.trim().isEmpty
            ? null
            : _phoneController.text.trim(),
      );

      await ProfileRepository().updateProfile(updated);

      // Update local state
      ref.read(currentUserProvider.notifier).state = updated;

      if (mounted) {
        setState(() {
          _isEditing = false;
          _isSaving = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(children: [
              const Icon(Icons.check_circle_rounded,
                  color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Text('Perfil actualizado',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w500)),
            ]),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(children: [
              const Icon(Icons.error_rounded, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text('Error al guardar: $e',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w500)),
              ),
            ]),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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

                // ── Avatar with edit overlay ──
                Stack(
                  alignment: Alignment.center,
                  children: [
                    UserAvatar(
                      initials: user?.initials ?? '??',
                      imageUrl: user?.avatarUrl,
                      size: 96,
                    ),
                    if (!_isEditing)
                      Positioned(
                        bottom: 0,
                        right: constraints.maxWidth / 2 - 48 + 64,
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withValues(alpha: 0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Icon(Icons.camera_alt_rounded,
                              size: 16, color: Colors.white),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: AppSizes.s16),

                // ── Edit / View Mode ──
                if (_isEditing && user != null) ...[
                  // Edit form
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.15),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Editar perfil',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 20),

                        // First Name
                        _EditField(
                          controller: _firstNameController,
                          label: 'Nombre',
                          icon: Icons.person_outline_rounded,
                        ),
                        const SizedBox(height: 14),

                        // Last Name
                        _EditField(
                          controller: _lastNameController,
                          label: 'Apellido',
                          icon: Icons.person_outline_rounded,
                        ),
                        const SizedBox(height: 14),

                        // Phone
                        _EditField(
                          controller: _phoneController,
                          label: 'Teléfono',
                          icon: Icons.phone_outlined,
                          keyboardType: TextInputType.phone,
                        ),
                        const SizedBox(height: 14),

                        // Email (read-only)
                        _EditField(
                          controller:
                              TextEditingController(text: user.email),
                          label: 'Email (no editable)',
                          icon: Icons.email_outlined,
                          enabled: false,
                        ),

                        const SizedBox(height: 24),

                        // Action buttons
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: _isSaving ? null : _cancelEdit,
                                icon: const Icon(Icons.close_rounded, size: 18),
                                label: const Text('Cancelar'),
                                style: OutlinedButton.styleFrom(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(
                                    borderRadius:
                                        BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed:
                                    _isSaving ? null : () => _saveProfile(user),
                                icon: _isSaving
                                    ? const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Icon(Icons.check_rounded, size: 18),
                                label: Text(_isSaving
                                    ? 'Guardando...'
                                    : 'Guardar'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: Colors.white,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(
                                    borderRadius:
                                        BorderRadius.circular(12),
                                  ),
                                  elevation: 0,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  // View mode
                  Text(
                    user?.fullName ?? 'Usuario',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSizes.s8),

                  _InfoRow(
                    icon: Icons.email_outlined,
                    value: user?.email ?? 'sin correo',
                  ),
                  const SizedBox(height: AppSizes.s6),

                  _InfoRow(
                    icon: Icons.phone_outlined,
                    value: user?.phone ?? 'sin teléfono',
                  ),
                  const SizedBox(height: AppSizes.s12),

                  _RoleBadge(role: user?.role ?? UserRole.client),

                  const SizedBox(height: AppSizes.s16),

                  // ── Edit Profile Button ──
                  Center(
                    child: ElevatedButton.icon(
                      onPressed: user != null ? () => _enterEditMode(user) : null,
                      icon: const Icon(Icons.edit_rounded, size: 18),
                      label: const Text('Editar perfil'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 28, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: AppSizes.s24),
                Divider(
                    color: theme.colorScheme.outline.withValues(alpha: 0.15)),
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
                    activeTrackColor:
                        theme.colorScheme.primary.withValues(alpha: 0.5),
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
                Divider(
                    color: theme.colorScheme.outline.withValues(alpha: 0.15)),
                const SizedBox(height: AppSizes.s16),

                // ── Logout Button ──
                SizedBox(
                  width: double.infinity,
                  child: TextButton.icon(
                    onPressed: () => _handleLogout(context, ref),
                    icon:
                        const Icon(Icons.logout_rounded, size: AppSizes.iconMd),
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
                Divider(
                    color: theme.colorScheme.outline.withValues(alpha: 0.15)),
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
                      final isBusiness = currentRole ==
                              UserRole.businessOwner ||
                          currentRole == UserRole.business;

                      final newRole = isBusiness
                          ? UserRole.client
                          : UserRole.businessOwner;
                      ref.read(activeRoleProvider.notifier).state = newRole;

                      context.go(isBusiness ? '/client' : '/business');
                    },
                    icon: Icon(
                      (user?.canBeBusiness ?? false)
                          ? (ref.watch(activeRoleProvider) ==
                                      UserRole.businessOwner ||
                                  ref.watch(activeRoleProvider) ==
                                      UserRole.business)
                              ? Icons.person_rounded
                              : Icons.store_rounded
                          : Icons.store_rounded,
                      size: 20,
                    ),
                    label: Text(
                      (ref.watch(activeRoleProvider) ==
                                  UserRole.businessOwner ||
                              ref.watch(activeRoleProvider) ==
                                  UserRole.business)
                          ? 'Cambiar a modo Cliente →'
                          : 'Cambiar a modo Negocio →',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: (ref.watch(activeRoleProvider) ==
                                  UserRole.businessOwner ||
                              ref.watch(activeRoleProvider) ==
                                  UserRole.business)
                          ? AppColors.info
                          : AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(AppSizes.radiusMd),
                      ),
                      elevation: 0,
                    ),
                  ),
                ),
                const SizedBox(height: AppSizes.s8),
                Text(
                  'Misma cuenta, múltiples roles',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color:
                        theme.colorScheme.outline.withValues(alpha: 0.5),
                    fontStyle: FontStyle.italic,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: AppSizes.s24),

                // ── Version ──
                Text(
                  'ReservPy v1.0.0',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color:
                        theme.colorScheme.outline.withValues(alpha: 0.5),
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

                try {
                  await AuthRepository().signOut();
                } catch (_) {}

                ref.read(currentUserProvider.notifier).state = null;
                ref.read(isLoggedInProvider.notifier).state = false;
                ref.read(selectedRoleProvider.notifier).state =
                    UserRole.client;
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

// ═════════════════════════════════════════════════════════════
// ─── Edit Field ──────────────────────────────────────────────
// ═════════════════════════════════════════════════════════════
class _EditField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final TextInputType keyboardType;
  final bool enabled;

  const _EditField({
    required this.controller,
    required this.label,
    required this.icon,
    this.keyboardType = TextInputType.text,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      enabled: enabled,
      style: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: enabled
            ? theme.colorScheme.onSurface
            : theme.colorScheme.outline,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.inter(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: theme.colorScheme.outline,
        ),
        prefixIcon: Icon(icon, size: 20, color: AppColors.primary),
        filled: true,
        fillColor: enabled
            ? theme.colorScheme.surface
            : theme.colorScheme.outline.withValues(alpha: 0.05),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: theme.colorScheme.outline.withValues(alpha: 0.15),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: theme.colorScheme.outline.withValues(alpha: 0.15),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: theme.colorScheme.outline.withValues(alpha: 0.08),
          ),
        ),
      ),
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
            child: Icon(icon,
                size: AppSizes.iconMd, color: theme.colorScheme.primary),
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
