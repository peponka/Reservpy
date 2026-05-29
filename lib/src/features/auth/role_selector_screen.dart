import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:reservpy/src/shared/models/models.dart';
import 'package:reservpy/src/shared/providers/providers.dart';
import 'package:reservpy/src/core/constants/app_colors.dart';

/// Screen shown after login when user has multiple roles.
/// Lets them choose which role to enter with.
class RoleSelectorScreen extends ConsumerWidget {
  const RoleSelectorScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final roles = user?.roles ?? [UserRole.client];

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFF0FDF4),
              Color(0xFFECFDF5),
              Colors.white,
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(32),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Avatar
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        user?.initials ?? '?',
                        style: GoogleFonts.inter(
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary,
                        ),
                      ),
                    )
                        .animate()
                        .fadeIn(duration: 400.ms)
                        .scale(begin: const Offset(0.8, 0.8), end: const Offset(1, 1), duration: 400.ms),

                    const SizedBox(height: 24),

                    Text(
                      '¡Hola, ${user?.firstName ?? ''}!',
                      style: GoogleFonts.inter(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF1A1A2E),
                      ),
                    )
                        .animate()
                        .fadeIn(delay: 100.ms, duration: 400.ms),

                    const SizedBox(height: 8),

                    Text(
                      '¿Cómo deseas ingresar hoy?',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        color: Colors.grey.shade500,
                        fontWeight: FontWeight.w500,
                      ),
                    )
                        .animate()
                        .fadeIn(delay: 150.ms, duration: 400.ms),

                    const SizedBox(height: 40),

                    // Role cards
                    ...roles.asMap().entries.map((entry) {
                      final index = entry.key;
                      final role = entry.value;
                      // Skip the legacy 'business' alias
                      if (role == UserRole.business) return const SizedBox.shrink();
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: _RoleCard(
                          role: role,
                          delay: 200 + (index * 100),
                          onTap: () {
                            ref.read(activeRoleProvider.notifier).state = role;
                            switch (role) {
                              case UserRole.businessOwner:
                              case UserRole.business:
                                context.go('/business');
                                break;
                              case UserRole.employee:
                                context.go('/business'); // employees see business view
                                break;
                              case UserRole.admin:
                                context.go('/business'); // admin sees business view for now
                                break;
                              case UserRole.client:
                                context.go('/client');
                                break;
                            }
                          },
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RoleCard extends StatefulWidget {
  const _RoleCard({
    required this.role,
    required this.delay,
    required this.onTap,
  });

  final UserRole role;
  final int delay;
  final VoidCallback onTap;

  @override
  State<_RoleCard> createState() => _RoleCardState();
}

class _RoleCardState extends State<_RoleCard> {
  bool _hovered = false;

  IconData get _icon {
    switch (widget.role) {
      case UserRole.businessOwner:
      case UserRole.business:
        return Icons.storefront_rounded;
      case UserRole.employee:
        return Icons.badge_rounded;
      case UserRole.admin:
        return Icons.admin_panel_settings_rounded;
      case UserRole.client:
        return Icons.person_rounded;
    }
  }

  String get _title {
    switch (widget.role) {
      case UserRole.businessOwner:
      case UserRole.business:
        return 'Entrar como Negocio';
      case UserRole.employee:
        return 'Entrar como Empleado';
      case UserRole.admin:
        return 'Entrar como Administrador';
      case UserRole.client:
        return 'Entrar como Cliente';
    }
  }

  String get _subtitle {
    switch (widget.role) {
      case UserRole.businessOwner:
      case UserRole.business:
        return 'Gestioná tu negocio, turnos y equipo';
      case UserRole.employee:
        return 'Mirá tu agenda y turnos asignados';
      case UserRole.admin:
        return 'Panel de administración del sistema';
      case UserRole.client:
        return 'Reservá turnos en negocios disponibles';
    }
  }

  Color get _color {
    switch (widget.role) {
      case UserRole.businessOwner:
      case UserRole.business:
        return const Color(0xFF00C896);
      case UserRole.employee:
        return const Color(0xFF6366F1);
      case UserRole.admin:
        return const Color(0xFFF59E0B);
      case UserRole.client:
        return const Color(0xFF0EA5E9);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: _hovered ? _color.withValues(alpha: 0.08) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _hovered ? _color.withValues(alpha: 0.4) : Colors.grey.shade200,
              width: _hovered ? 2 : 1,
            ),
            boxShadow: [
              if (_hovered)
                BoxShadow(
                  color: _color.withValues(alpha: 0.15),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(_icon, color: _color, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _title,
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1A1A2E),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _subtitle,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: Colors.grey.shade500,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 16,
                color: _hovered ? _color : Colors.grey.shade300,
              ),
            ],
          ),
        ),
      ),
    )
        .animate()
        .fadeIn(delay: Duration(milliseconds: widget.delay), duration: 400.ms)
        .slideX(begin: 0.1, end: 0, delay: Duration(milliseconds: widget.delay), duration: 400.ms);
  }
}
