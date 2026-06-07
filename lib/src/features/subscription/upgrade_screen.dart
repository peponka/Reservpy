import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';

/// Plan upgrade screen — shows Pro plan features and price.
class UpgradeScreen extends StatelessWidget {
  const UpgradeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        leading: BackButton(onPressed: () => context.pop()),
        title: const Text('Actualizar plan'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSizes.s24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Header ─────────────────────────────────────────
            Center(
              child: Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFFA000), Color(0xFFFFD54F)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFFA000).withOpacity(0.35),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: const Icon(Icons.workspace_premium_rounded,
                    size: 36, color: Colors.white),
              ),
            ),
            const SizedBox(height: AppSizes.s16),
            Text('Plan Pro',
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: AppSizes.s8),
            Text('Desbloqueá todo el potencial de tu negocio',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.6))),
            const SizedBox(height: AppSizes.s32),

            // ── Price card ─────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(AppSizes.s24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1A1A2E), Color(0xFF16213E)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.18),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                children: [
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.star_rounded,
                          color: Color(0xFFFFD54F), size: 18),
                      SizedBox(width: 6),
                      Text('PRO',
                          style: TextStyle(
                              color: Color(0xFFFFD54F),
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              letterSpacing: 2)),
                    ],
                  ),
                  const SizedBox(height: AppSizes.s12),
                  RichText(
                    textAlign: TextAlign.center,
                    text: const TextSpan(
                      children: [
                        TextSpan(
                          text: 'Gs. 99.000',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        TextSpan(
                          text: ' / mes',
                          style: TextStyle(
                              color: Colors.white60, fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSizes.s8),
                  const Text('Renovación mensual · Cancelá cuando quieras',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: Colors.white38, fontSize: 12)),
                ],
              ),
            ),
            const SizedBox(height: AppSizes.s32),

            // ── Features list ──────────────────────────────────
            Text('¿Qué incluye el Plan Pro?',
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: AppSizes.s16),
            _Feature(icon: Icons.all_inclusive_rounded,
                label: 'Reservas ilimitadas'),
            _Feature(icon: Icons.people_rounded,
                label: 'Equipo ilimitado (empleados)'),
            _Feature(icon: Icons.trending_up_rounded,
                label: 'Reportes y métricas avanzadas'),
            _Feature(icon: Icons.download_rounded,
                label: 'Exportar a Excel para tu contador'),
            _Feature(icon: Icons.notifications_active_rounded,
                label: 'Recordatorios automáticos a clientes'),
            _Feature(icon: Icons.support_agent_rounded,
                label: 'Soporte prioritario'),
            const SizedBox(height: AppSizes.s32),

            // ── CTA ────────────────────────────────────────────
            FilledButton.icon(
              onPressed: () => context.push('/upgrade/payment'),
              icon: const Icon(Icons.credit_card_rounded),
              label: const Text('Pagar con Bancard'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                textStyle: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.bold),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
            ),
            const SizedBox(height: AppSizes.s12),
            Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.lock_outline_rounded,
                      size: 14,
                      color: theme.colorScheme.onSurface.withOpacity(0.4)),
                  const SizedBox(width: 4),
                  Text('Pago seguro procesado por Bancard',
                      style: theme.textTheme.bodySmall?.copyWith(
                          color:
                              theme.colorScheme.onSurface.withOpacity(0.4))),
                ],
              ),
            ),
            const SizedBox(height: AppSizes.s24),
          ],
        ),
      ),
    );
  }
}

class _Feature extends StatelessWidget {
  final IconData icon;
  final String label;
  const _Feature({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: AppColors.primary),
          ),
          const SizedBox(width: 14),
          Expanded(
              child: Text(label,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500))),
          const Icon(Icons.check_circle_rounded,
              size: 18, color: AppColors.primary),
        ],
      ),
    );
  }
}
