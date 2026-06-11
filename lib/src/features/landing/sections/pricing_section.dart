import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:reservpy/src/features/landing/landing_theme.dart';

class PricingSection extends StatelessWidget {
  const PricingSection({super.key});

  @override
  Widget build(BuildContext context) {
    final mobile = isMobile(context);

    return Container(
      width: double.infinity,
      color: LandingColors.bgWhite,
      padding: EdgeInsets.symmetric(
        vertical: mobile ? 80 : 112,
        horizontal: mobile ? 20 : 24,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Column(
            children: [
              // ── Title ─────────────────────────────────────
              Text(
                'Elegí el plan que mejor se adapte a tu negocio',
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: mobile ? 30 : 44,
                  fontWeight: FontWeight.w800,
                  color: LandingColors.textPrimary,
                  height: 1.15,
                ),
              )
                  .animate()
                  .fadeIn(duration: 500.ms)
                  .slideY(begin: 0.15, end: 0),
              const SizedBox(height: 12),
              Text(
                'Empezá gratis y actualizá cuando necesites más',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: mobile ? 16 : 18,
                  fontWeight: FontWeight.w400,
                  color: LandingColors.textSecondary,
                  height: 1.5,
                ),
              )
                  .animate()
                  .fadeIn(duration: 500.ms, delay: 100.ms)
                  .slideY(begin: 0.15, end: 0),
              const SizedBox(height: 56),

              // ── Cards ─────────────────────────────────────
              mobile
                  ? Column(
                      children: [
                        _FreePlanCard()
                            .animate()
                            .fadeIn(duration: 500.ms, delay: 200.ms)
                            .slideY(begin: 0.2, end: 0),
                        const SizedBox(height: 24),
                        _ProPlanCard()
                            .animate()
                            .fadeIn(duration: 500.ms, delay: 350.ms)
                            .slideY(begin: 0.2, end: 0),
                      ],
                    )
                  : Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: _FreePlanCard()
                              .animate()
                              .fadeIn(duration: 500.ms, delay: 200.ms)
                              .slideX(begin: -0.1, end: 0),
                        ),
                        const SizedBox(width: 24),
                        Expanded(
                          child: _ProPlanCard()
                              .animate()
                              .fadeIn(duration: 500.ms, delay: 350.ms)
                              .slideX(begin: 0.1, end: 0),
                        ),
                      ],
                    ),

              const SizedBox(height: 40),

              // ── Footer note ───────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.lock_outline_rounded,
                      size: 16, color: LandingColors.textMuted),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      'Pagos procesados de forma segura por Bancard / Pagopar · Cancelá cuando quieras',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                        color: LandingColors.textMuted,
                      ),
                    ),
                  ),
                ],
              ).animate().fadeIn(duration: 500.ms, delay: 500.ms),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  FREE Plan Card
// ═══════════════════════════════════════════════════════════════
class _FreePlanCard extends StatefulWidget {
  @override
  State<_FreePlanCard> createState() => _FreePlanCardState();
}

class _FreePlanCardState extends State<_FreePlanCard> {
  bool _hovering = false;

  static const _features = [
    '1 miembro del equipo',
    '10 reservas por mes',
    'Página pública de reservas',
    'Gestión de servicios',
    'Recordatorios básicos',
    'Reportes de actividad',
    'Soporte por email',
  ];

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
        transform: Matrix4.diagonal3Values(_hovering ? 1.02 : 1.0, _hovering ? 1.02 : 1.0, 1.0),
        transformAlignment: Alignment.center,
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: LandingColors.bgWhite,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: _hovering ? LandingColors.primary.withValues(alpha: 0.5) : LandingColors.border,
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: _hovering ? LandingColors.primary.withValues(alpha: 0.08) : LandingColors.shadowLight,
              blurRadius: _hovering ? 24 : 16,
              offset: Offset(0, _hovering ? 8 : 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: LandingColors.bgAlt,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: LandingColors.border),
              ),
              child: Text(
                'FREE',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: LandingColors.textPrimary,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Price
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'Gratis',
                  style: GoogleFonts.inter(
                    fontSize: 44,
                    fontWeight: FontWeight.w800,
                    color: LandingColors.textPrimary,
                    height: 1,
                  ),
                ),
                const SizedBox(width: 8),
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text(
                    'para siempre',
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w400,
                      color: LandingColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),

            // Features
            ..._features.map((f) => _FeatureRow(text: f)),

            const SizedBox(height: 32),

            // CTA
            SizedBox(
              width: double.infinity,
              height: 52,
              child: OutlinedButton(
                onPressed: () => context.go('/register'),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(
                    color: _hovering ? LandingColors.primary : LandingColors.primary.withValues(alpha: 0.6),
                    width: 2,
                  ),
                  backgroundColor: _hovering ? LandingColors.primary.withValues(alpha: 0.04) : Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                child: Text(
                  'Empezar gratis',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: LandingColors.primary,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  PRO Plan Card (highlighted)
// ═══════════════════════════════════════════════════════════════
class _ProPlanCard extends StatefulWidget {
  @override
  State<_ProPlanCard> createState() => _ProPlanCardState();
}

class _ProPlanCardState extends State<_ProPlanCard> {
  bool _hovering = false;

  static const _features = [
    'Equipo ilimitado',
    'Reservas ilimitadas',
    'Emails de confirmación automáticos',
    'Reservbot (asistente IA) incluido',
    'Recordatorios 24hs antes',
    'Reportes avanzados',
    'Soporte prioritario',
  ];

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
        transform: Matrix4.diagonal3Values(_hovering ? 1.025 : 1.0, _hovering ? 1.025 : 1.0, 1.0),
        transformAlignment: Alignment.center,
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: LandingColors.bgWhite,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: LandingColors.primary,
            width: _hovering ? 2.5 : 2.0,
          ),
          boxShadow: [
            BoxShadow(
              color: LandingColors.primary.withValues(alpha: _hovering ? 0.35 : 0.18),
              blurRadius: _hovering ? 36 : 24,
              offset: Offset(0, _hovering ? 12 : 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Badge row
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: LandingColors.primaryTint,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: LandingColors.primary),
                  ),
                  child: Text(
                    'PRO',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: LandingColors.primary,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    color: LandingColors.primary,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    'Recomendado',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: LandingColors.textWhite,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Price
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'Gs. 99.000',
                  style: GoogleFonts.inter(
                    fontSize: 44,
                    fontWeight: FontWeight.w800,
                    color: LandingColors.textPrimary,
                    height: 1,
                  ),
                ),
                const SizedBox(width: 8),
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text(
                    '/mes',
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w400,
                      color: LandingColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),

            // Features
            ..._features.map((f) => _FeatureRow(text: f)),

            const SizedBox(height: 32),

            // CTA
            SizedBox(
              width: double.infinity,
              height: 52,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                transform: Matrix4.diagonal3Values(_hovering ? 1.02 : 1.0, _hovering ? 1.02 : 1.0, 1.0),
                transformAlignment: Alignment.center,
                child: ElevatedButton(
                  onPressed: () => context.go('/register'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: LandingColors.primary,
                    foregroundColor: LandingColors.textWhite,
                    elevation: _hovering ? 8 : 0,
                    shadowColor: LandingColors.primary.withValues(alpha: 0.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  child: Text(
                    'Suscribirse',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: LandingColors.textWhite,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  Shared feature row
// ═══════════════════════════════════════════════════════════════
class _FeatureRow extends StatelessWidget {
  const _FeatureRow({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              color: LandingColors.successBg,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_rounded,
              size: 14,
              color: LandingColors.success,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: LandingColors.textPrimary,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
