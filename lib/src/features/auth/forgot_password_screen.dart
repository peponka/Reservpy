import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;

import 'package:reservpy/src/core/widgets/widgets.dart';
import 'package:reservpy/src/core/constants/app_sizes.dart';
import 'package:reservpy/src/core/constants/app_strings.dart';
import 'package:reservpy/src/core/utils/validators.dart';
import 'package:reservpy/src/data/repositories/auth_repository.dart';

/// Forgot-password screen.
///
/// Displays a lock icon, explanation text, and an email field.
/// On submit, calls Supabase Auth to send a real password reset link.
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _authRepo = AuthRepository();
  bool _isLoading = false;
  bool _emailSent = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _handleSendLink() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await _authRepo.resetPassword(_emailController.text.trim());

      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _emailSent = true;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
              const SizedBox(width: AppSizes.s8),
              Expanded(
                child: Text(
                  'Te enviamos un enlace a ${_emailController.text.trim()}',
                ),
              ),
            ],
          ),
          duration: const Duration(seconds: 4),
        ),
      );
    } on AuthException catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.message.contains('not found')
                ? 'No encontramos una cuenta con ese email'
                : 'Error: ${e.message}',
          ),
          backgroundColor: Colors.red.shade600,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error de conexión: $e'),
          backgroundColor: Colors.red.shade600,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.go('/login'),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSizes.s24,
            vertical: AppSizes.s16,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: AppSizes.s32),

                    // ─── Lock Icon ───────────────────────────────
                    Center(
                      child: Container(
                        width: 88,
                        height: 88,
                        decoration: BoxDecoration(
                          color: colorScheme.primary.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.lock_reset_rounded,
                          size: 44,
                          color: colorScheme.primary,
                        ),
                      ),
                    )
                        .animate()
                        .fadeIn(duration: 500.ms)
                        .scale(begin: const Offset(0.8, 0.8), end: const Offset(1, 1), duration: 500.ms, curve: Curves.easeOut),

                    const SizedBox(height: AppSizes.s24),

                    // ─── Title ───────────────────────────────────
                    Text(
                      AppStrings.resetPassword,
                      style: theme.textTheme.headlineLarge,
                      textAlign: TextAlign.center,
                    )
                        .animate()
                        .fadeIn(delay: 100.ms, duration: 400.ms),

                    const SizedBox(height: AppSizes.s8),

                    Text(
                      'Ingresá tu correo electrónico y te enviaremos un enlace para restablecer tu contraseña.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                      textAlign: TextAlign.center,
                    )
                        .animate()
                        .fadeIn(delay: 150.ms, duration: 400.ms),

                    const SizedBox(height: AppSizes.s32),

                    if (_emailSent) ...[
                      // ─── Success State ─────────────────────────
                      Container(
                        padding: const EdgeInsets.all(AppSizes.s20),
                        decoration: BoxDecoration(
                          color: colorScheme.primary.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                          border: Border.all(
                            color: colorScheme.primary.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              Icons.mark_email_read_rounded,
                              size: 48,
                              color: colorScheme.primary,
                            ),
                            const SizedBox(height: AppSizes.s12),
                            Text(
                              '¡Enlace enviado!',
                              style: theme.textTheme.titleLarge?.copyWith(
                                color: colorScheme.primary,
                              ),
                            ),
                            const SizedBox(height: AppSizes.s8),
                            Text(
                              'Revisá tu bandeja de entrada en ${_emailController.text.trim()}',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: colorScheme.onSurface.withValues(alpha: 0.7),
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      )
                          .animate()
                          .fadeIn(duration: 500.ms)
                          .scale(begin: const Offset(0.95, 0.95), duration: 500.ms),

                      const SizedBox(height: AppSizes.s24),

                      // Allow re-sending.
                      AppButton(
                        label: 'Reenviar enlace',
                        icon: Icons.refresh_rounded,
                        isOutlined: true,
                        onPressed: () {
                          setState(() => _emailSent = false);
                        },
                      ),
                    ] else ...[
                      // ─── Email Field ───────────────────────────
                      AppTextField(
                        controller: _emailController,
                        label: AppStrings.email,
                        hint: 'tu@email.com',
                        prefixIcon: Icons.email_outlined,
                        keyboardType: TextInputType.emailAddress,
                        validator: Validators.email,
                      )
                          .animate()
                          .fadeIn(delay: 250.ms, duration: 400.ms)
                          .slideY(begin: 0.1, end: 0, delay: 250.ms, duration: 400.ms),

                      const SizedBox(height: AppSizes.s24),

                      // ─── Send Link Button ─────────────────────
                      AppButton(
                        label: 'Enviar enlace',
                        icon: Icons.send_rounded,
                        isLoading: _isLoading,
                        onPressed: _isLoading ? null : _handleSendLink,
                      )
                          .animate()
                          .fadeIn(delay: 350.ms, duration: 400.ms)
                          .slideY(begin: 0.1, end: 0, delay: 350.ms, duration: 400.ms),
                    ],

                    const SizedBox(height: AppSizes.s32),

                    // ─── Back to Login ────────────────────────────
                    Center(
                      child: TextButton.icon(
                        onPressed: () => context.go('/login'),
                        icon: const Icon(Icons.arrow_back_rounded, size: 18),
                        label: const Text('Volver a iniciar sesión'),
                      ),
                    )
                        .animate()
                        .fadeIn(delay: 450.ms, duration: 400.ms),

                    const SizedBox(height: AppSizes.s32),
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
