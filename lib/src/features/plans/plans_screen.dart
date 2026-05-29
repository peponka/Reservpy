import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:reservpy/src/core/constants/app_sizes.dart';
import 'package:reservpy/src/core/constants/app_colors.dart';

class PlansScreen extends ConsumerWidget {
  const PlansScreen({super.key});

  static const _amberBrand = Color(0xFFF59E0B);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < AppSizes.breakpointMobile;

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
                // ── Header ──────────────────────────────────
                _buildHeader(theme),
                const SizedBox(height: AppSizes.s24),

                // ── Current plan banner ─────────────────────
                _buildCurrentPlanBanner(theme, colorScheme),
                const SizedBox(height: AppSizes.s32),

                // ── Plan cards ──────────────────────────────
                _buildPlanCards(theme, colorScheme, isMobile),
                const SizedBox(height: AppSizes.s32),

                // ── Footer ──────────────────────────────────
                _buildFooter(theme),
              ],
            ),
          ),
        );
      },
    );
  }

  // ─── Header ─────────────────────────────────────────────────
  Widget _buildHeader(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Planes',
          style: GoogleFonts.inter(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: AppColors.accent,
          ),
        ),
        const SizedBox(height: AppSizes.s8),
        Text(
          'Elegí el plan que mejor se adapta a tu negocio',
          style: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w400,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  // ─── Current plan banner ────────────────────────────────────
  Widget _buildCurrentPlanBanner(ThemeData theme, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.s16,
        vertical: AppSizes.s12,
      ),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.15),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.settings_outlined,
            size: AppSizes.iconMd,
            color: AppColors.primary,
          ),
          const SizedBox(width: AppSizes.s12),
          Expanded(
            child: Text.rich(
              TextSpan(
                text: 'Plan actual: ',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary,
                ),
                children: [
                  TextSpan(
                    text: 'Free',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Plan cards ─────────────────────────────────────────────
  Widget _buildPlanCards(
    ThemeData theme,
    ColorScheme colorScheme,
    bool isMobile,
  ) {
    final freeCard = _buildFreeCard(theme, colorScheme);
    final proCard = _buildProCard(theme, colorScheme);

    if (isMobile) {
      return Column(
        children: [
          freeCard,
          const SizedBox(height: AppSizes.s20),
          proCard,
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: freeCard),
        const SizedBox(width: AppSizes.s20),
        Expanded(child: proCard),
      ],
    );
  }

  // ─── FREE card ──────────────────────────────────────────────
  Widget _buildFreeCard(ThemeData theme, ColorScheme colorScheme) {
    const features = [
      '1 miembro del equipo',
      'Hasta 10 reservas/mes',
      'Página pública de reservas',
      'Gestión de servicios',
    ];

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: theme.cardTheme.color ?? Colors.white,
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        border: Border.all(
          color: colorScheme.outline.withValues(alpha: 0.08),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Container(
        decoration: const BoxDecoration(
          border: Border(
            left: BorderSide(color: AppColors.primary, width: 2),
          ),
        ),
        padding: const EdgeInsets.all(AppSizes.s24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Badge
            _buildBadge('Tu plan', AppColors.primary, Colors.white),
            const SizedBox(height: AppSizes.s16),

            // Icon
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(AppSizes.radiusMd),
              ),
              child: const Icon(
                Icons.settings_outlined,
                color: AppColors.primary,
                size: AppSizes.iconLg,
              ),
            ),
            const SizedBox(height: AppSizes.s16),

            // Title
            Text(
              'Free',
              style: GoogleFonts.inter(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: AppColors.accent,
              ),
            ),
            const SizedBox(height: AppSizes.s8),

            // Price
            Text(
              'Gratis',
              style: GoogleFonts.inter(
                fontSize: 32,
                fontWeight: FontWeight.w800,
                color: AppColors.accent,
              ),
            ),
            const SizedBox(height: AppSizes.s24),

            // Features
            ...features.map((f) => _buildFeatureRow(f)),
            const SizedBox(height: AppSizes.s24),

            // Button – disabled / active style
            SizedBox(
              width: double.infinity,
              height: AppSizes.buttonMd,
              child: OutlinedButton(
                onPressed: null,
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.textMuted),
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(AppSizes.radiusMd),
                  ),
                  disabledForegroundColor: AppColors.textMuted,
                ),
                child: Text(
                  'Plan activo',
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── PRO card ───────────────────────────────────────────────
  Widget _buildProCard(ThemeData theme, ColorScheme colorScheme) {
    const features = [
      'Equipo ilimitado',
      'Reservas ilimitadas',
      'Página pública de reservas',
      'Emails de confirmación',
      'Recordatorios 24hs automáticos',
      'Reportes avanzados',
      'Soporte prioritario',
    ];

    return Container(
      decoration: BoxDecoration(
        color: theme.cardTheme.color ?? Colors.white,
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        border: Border.all(
          color: _amberBrand.withValues(alpha: 0.35),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.s24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Badge
            _buildBadge('Recomendado', _amberBrand, Colors.white),
            const SizedBox(height: AppSizes.s16),

            // Icon
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: _amberBrand.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(AppSizes.radiusMd),
              ),
              child: Icon(
                Icons.workspace_premium_outlined,
                color: _amberBrand,
                size: AppSizes.iconLg,
              ),
            ),
            const SizedBox(height: AppSizes.s16),

            // Title
            Text(
              'Pro',
              style: GoogleFonts.inter(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: AppColors.accent,
              ),
            ),
            const SizedBox(height: AppSizes.s8),

            // Price
            Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: 'Gs. 99.000',
                    style: GoogleFonts.inter(
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      color: AppColors.accent,
                    ),
                  ),
                  TextSpan(
                    text: ' /mes',
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w400,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSizes.s24),

            // Features
            ...features.map((f) => _buildFeatureRow(f)),
            const SizedBox(height: AppSizes.s24),

            // Button – filled primary
            SizedBox(
              width: double.infinity,
              height: AppSizes.buttonMd,
              child: ElevatedButton(
                onPressed: () {
                  // TODO: navigate to MercadoPago checkout
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(AppSizes.radiusMd),
                  ),
                ),
                child: Text(
                  'Suscribirse a Pro',
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Shared: Feature row ────────────────────────────────────
  Widget _buildFeatureRow(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSizes.s12),
      child: Row(
        children: [
          const Icon(
            Icons.check_circle,
            color: AppColors.primary,
            size: AppSizes.iconMd,
          ),
          const SizedBox(width: AppSizes.s12),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Shared: Badge pill ─────────────────────────────────────
  Widget _buildBadge(String label, Color bgColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(AppSizes.radiusFull),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }

  // ─── Footer ─────────────────────────────────────────────────
  Widget _buildFooter(ThemeData theme) {
    return Center(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.lock_outline,
            size: AppSizes.iconSm,
            color: AppColors.textMuted,
          ),
          const SizedBox(width: AppSizes.s8),
          Flexible(
            child: Text(
              'Los pagos son procesados de forma segura por MercadoPago. '
              'Podés cancelar en cualquier momento.',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w400,
                color: AppColors.textMuted,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}
