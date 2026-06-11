import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:reservpy/src/features/landing/landing_theme.dart';

class FinalCtaSection extends StatelessWidget {
  const FinalCtaSection({super.key});

  @override
  Widget build(BuildContext context) {
    final mobile = isMobile(context);

    return Container(
      width: double.infinity,
      color: LandingColors.bgWhite,
      padding: EdgeInsets.symmetric(
        vertical: mobile ? 48 : 80,
        horizontal: mobile ? 20 : 24,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Container(
            padding: EdgeInsets.symmetric(
              vertical: mobile ? 48 : 72,
              horizontal: mobile ? 24 : 56,
            ),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  LandingColors.primary,
                  LandingColors.primaryDark,
                ],
              ),
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: LandingColors.shadowPrimary.withValues(alpha: 0.4),
                  blurRadius: 40,
                  offset: const Offset(0, 16),
                ),
              ],
            ),
            child: Stack(
              children: [
                // ── Subtle glow circles ──
                Positioned(
                  top: -60,
                  right: -40,
                  child: Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.06),
                    ),
                  ),
                ),
                Positioned(
                  bottom: -80,
                  left: -30,
                  child: Container(
                    width: 260,
                    height: 260,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.04),
                    ),
                  ),
                ),
                // ── Content ──
                Column(
                  children: [
                    Text(
                      'Tu negocio en Paraguay merece un sistema de turnos profesional',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: mobile ? 30 : 44,
                        fontWeight: FontWeight.w800,
                        color: LandingColors.textWhite,
                        height: 1.15,
                      ),
                    )
                        .animate()
                        .fadeIn(duration: 500.ms)
                        .slideY(begin: 0.15, end: 0),
                    const SizedBox(height: 16),
                    Text(
                      'Más de 50 negocios paraguayos ya usan ReservPy. Creá tu cuenta gratis en 5 minutos y empezá a recibir reservas hoy mismo.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: mobile ? 16 : 18,
                        fontWeight: FontWeight.w400,
                        color: Colors.white.withValues(alpha: 0.8),
                        height: 1.6,
                      ),
                    )
                        .animate()
                        .fadeIn(duration: 500.ms, delay: 100.ms)
                        .slideY(begin: 0.15, end: 0),
                    const SizedBox(height: 36),
                    // Buttons
                    Wrap(
                      spacing: 16,
                      runSpacing: 12,
                      alignment: WrapAlignment.center,
                      children: [
                        _WhiteCtaButton(
                          label: 'Crear mi negocio gratis 🇵🇾',
                          onTap: () => context.go('/register'),
                        ),
                        _WhiteOutlineCtaButton(
                          label: 'Soy cliente, quiero reservar',
                          onTap: () => context.go('/register'),
                        ),
                      ],
                    )
                        .animate()
                        .fadeIn(duration: 500.ms, delay: 200.ms)
                        .slideY(begin: 0.15, end: 0),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Hover-Aware Premium CTA Buttons ──────────────────────────────────────────

class _WhiteCtaButton extends StatefulWidget {
  const _WhiteCtaButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  State<_WhiteCtaButton> createState() => _WhiteCtaButtonState();
}

class _WhiteCtaButtonState extends State<_WhiteCtaButton> {
  bool _hovered = false;

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
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
          transformAlignment: Alignment.center,
          transform: Matrix4.diagonal3Values(_hovered ? 1.03 : 1.0, _hovered ? 1.03 : 1.0, 1.0),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            color: _hovered ? Colors.white : Colors.white.withValues(alpha: 0.95),
            boxShadow: [
              BoxShadow(
                color: Colors.white.withValues(alpha: _hovered ? 0.35 : 0.15),
                blurRadius: _hovered ? 24 : 16,
                offset: Offset(0, _hovered ? 8 : 4),
              ),
            ],
          ),
          child: Text(
            widget.label,
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: LandingColors.primary,
            ),
          ),
        ),
      ),
    );
  }
}

class _WhiteOutlineCtaButton extends StatefulWidget {
  const _WhiteOutlineCtaButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  State<_WhiteOutlineCtaButton> createState() => _WhiteOutlineCtaButtonState();
}

class _WhiteOutlineCtaButtonState extends State<_WhiteOutlineCtaButton> {
  bool _hovered = false;

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
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
          transformAlignment: Alignment.center,
          transform: Matrix4.diagonal3Values(_hovered ? 1.03 : 1.0, _hovered ? 1.03 : 1.0, 1.0),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: _hovered ? Colors.white : Colors.white.withValues(alpha: 0.6),
              width: 2,
            ),
            color: _hovered ? Colors.white.withValues(alpha: 0.1) : Colors.transparent,
            boxShadow: _hovered
                ? [
                    BoxShadow(
                      color: Colors.white.withValues(alpha: 0.08),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ]
                : [],
          ),
          child: Text(
            widget.label,
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: LandingColors.textWhite,
            ),
          ),
        ),
      ),
    );
  }
}

