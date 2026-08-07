import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../../data/repositories/business_repository.dart';
import '../../data/services/email_service.dart';
import '../../shared/providers/providers.dart';

/// Demo activation screen used until Bancard credentials are connected.
class BancardPaymentScreen extends ConsumerStatefulWidget {
  const BancardPaymentScreen({super.key});

  @override
  ConsumerState<BancardPaymentScreen> createState() =>
      _BancardPaymentScreenState();
}

class _BancardPaymentScreenState extends ConsumerState<BancardPaymentScreen> {
  bool _isProcessing = false;

  Future<void> _activateProDemo() async {
    setState(() => _isProcessing = true);

    final business = ref.read(currentBusinessProvider);
    if (business == null) {
      setState(() => _isProcessing = false);
      return;
    }

    try {
      await BusinessRepository().upgradeToPro(business.id);
      ref.invalidate(ownerBusinessProvider);
      ref.invalidate(currentBusinessProvider);
      ref.invalidate(businessesProvider);

      final user = ref.read(currentUserProvider);
      if (user != null) {
        await EmailService.enviarEmailPlanUpgraded(
          ownerEmail: user.email,
          ownerName: user.firstName,
          businessName: business.name,
          planName: 'Pro',
          amount: 'Gs. 99.000',
        );
      }

      if (!mounted) return;
      context.go('/upgrade/success');
    } catch (e) {
      if (!mounted) return;
      setState(() => _isProcessing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No se pudo activar el plan Pro: $e'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final business = ref.watch(currentBusinessProvider);

    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: () => context.pop()),
        title: const Text('Activacion Pro'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSizes.s24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(AppSizes.s20),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.primary.withOpacity(0.16),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.workspace_premium_rounded,
                    color: Color(0xFFFFA000),
                    size: 28,
                  ),
                  const SizedBox(width: AppSizes.s12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          business?.name ?? 'Tu negocio',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Plan Pro - Gs. 99.000 por mes',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSizes.s24),
            Container(
              padding: const EdgeInsets.all(AppSizes.s20),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF8E1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFFFE082)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.info_outline_rounded, color: Color(0xFFFFA000)),
                      const SizedBox(width: AppSizes.s10),
                      Text(
                        'Estado de la integracion',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSizes.s12),
                  Text(
                    'Esta pantalla no esta conectada todavia a un checkout real de Bancard. Para no simular un cobro inexistente, no se solicitan datos de tarjeta en este entorno.',
                    style: theme.textTheme.bodyMedium?.copyWith(height: 1.4),
                  ),
                  const SizedBox(height: AppSizes.s12),
                  Text(
                    'Si continuas, ReservPy activara el plan Pro en modo demo para probar el flujo completo del negocio.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.7),
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSizes.s24),
            _InfoRow(
              icon: Icons.check_circle_outline_rounded,
              text: 'Se habilitan reportes, recordatorios y reservas ilimitadas.',
            ),
            const SizedBox(height: AppSizes.s12),
            _InfoRow(
              icon: Icons.mail_outline_rounded,
              text: 'Si hay email del negocio, se envia la confirmacion de activacion.',
            ),
            const SizedBox(height: AppSizes.s12),
            _InfoRow(
              icon: Icons.warning_amber_rounded,
              text: 'Falta conectar las credenciales reales de Bancard para cobrar de verdad.',
            ),
            const SizedBox(height: AppSizes.s32),
            FilledButton.icon(
              onPressed: _isProcessing ? null : _activateProDemo,
              icon: _isProcessing
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.rocket_launch_rounded),
              label: Text(
                _isProcessing ? 'Activando Pro...' : 'Activar Pro para pruebas',
              ),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
            const SizedBox(height: AppSizes.s12),
            OutlinedButton(
              onPressed: _isProcessing ? null : () => context.pop(),
              child: const Text('Volver'),
            ),
          ],
        ),
      ),
    );
  }
}

class PaymentSuccessScreen extends StatelessWidget {
  const PaymentSuccessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.s32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              Center(
                child: Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_circle_rounded,
                    size: 56,
                    color: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(height: AppSizes.s24),
              Text(
                'Plan Pro activado',
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AppSizes.s12),
              Text(
                'La activacion se completo en este entorno de prueba y tu negocio ya puede usar las funciones Pro.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
              const SizedBox(height: AppSizes.s16),
              Container(
                padding: const EdgeInsets.all(AppSizes.s16),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.workspace_premium_rounded, color: Color(0xFFFFA000)),
                    SizedBox(width: 8),
                    Text(
                      'Funciones Pro disponibles',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFFFA000),
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              FilledButton(
                onPressed: () => context.go('/business'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
                  'Ir a mi negocio',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: AppColors.primary),
        const SizedBox(width: AppSizes.s10),
        Expanded(
          child: Text(
            text,
            style: theme.textTheme.bodySmall?.copyWith(height: 1.35),
          ),
        ),
      ],
    );
  }
}
