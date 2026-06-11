import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:reservpy/src/features/landing/landing_theme.dart';

/// Hero section with badge, gradient title, dual CTAs and guarantees.
class HeroSection extends StatelessWidget {
  const HeroSection({super.key});

  @override
  Widget build(BuildContext context) {
    final desktop = isDesktop(context);
    final mobile = isMobile(context);
    final titleSize = mobile ? 42.0 : (desktop ? 64.0 : 52.0);

    return CustomPaint(
      painter: _HeroBackgroundPainter(),
      child: Container(
        width: double.infinity,
        color: Colors.transparent,
        padding: EdgeInsets.symmetric(
          horizontal: 24,
          vertical: mobile ? 64 : 96,
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Column(
              children: [
                // ── Badge pill ─────────────────────────────────
                _BadgePill()
                    .animate()
                    .fadeIn(duration: 500.ms)
                    .slideY(begin: -0.2, end: 0, duration: 500.ms),

                const SizedBox(height: 28),

                // ── Title ──────────────────────────────────────
                _AnimatedGlowAura(
                  child: RichText(
                    textAlign: TextAlign.center,
                    text: TextSpan(
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: titleSize,
                        fontWeight: FontWeight.w800,
                        color: LandingColors.textPrimary,
                        height: 1.1,
                      ),
                      children: [
                        const TextSpan(
                          text: 'La forma más simple de\ngestionar turnos en ',
                        ),
                        TextSpan(
                          text: 'Paraguay 🇵🇾',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: titleSize,
                            fontWeight: FontWeight.w800,
                            height: 1.1,
                            foreground: Paint()
                              ..shader = const LinearGradient(
                                colors: [
                                  LandingColors.primary,
                                  LandingColors.primaryLight,
                                ],
                              ).createShader(
                                const Rect.fromLTWH(0, 0, 300, 70),
                              ),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
                    .animate()
                    .fadeIn(delay: 150.ms, duration: 600.ms)
                    .slideY(begin: 0.15, end: 0, duration: 600.ms),

                const SizedBox(height: 24),

                // ── Subtitle ───────────────────────────────────
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 620),
                  child: Text(
                    'Olvidate de agendar por WhatsApp. Tus clientes reservan online las 24 horas, vos controlás todo desde un panel profesional. La revolución de los turnos llegó a Paraguay.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: mobile ? 16 : 18,
                      height: 1.6,
                      color: LandingColors.textSecondary,
                    ),
                  ),
                )
                    .animate()
                    .fadeIn(delay: 350.ms, duration: 500.ms)
                    .slideY(begin: 0.15, end: 0, duration: 500.ms),

                const SizedBox(height: 36),

                // ── CTAs ───────────────────────────────────────
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _PrimaryCta(
                      label: 'Empezar gratis — es nuevo en PY 🇵🇾',
                      onTap: () => context.go('/register'),
                    ),
                    _OutlineCta(
                      label: 'Ver demo en vivo',
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Scrollá para ver cómo funciona'),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                    ),
                  ],
                )
                    .animate()
                    .fadeIn(delay: 550.ms, duration: 500.ms)
                    .slideY(begin: 0.15, end: 0, duration: 500.ms),

                const SizedBox(height: 32),

                // ── Guarantees ─────────────────────────────────
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 24,
                  runSpacing: 12,
                  children: const [
                    _Guarantee(text: '100% gratis para empezar'),
                    _Guarantee(text: 'Hecho en Paraguay 🇵🇾'),
                    _Guarantee(text: 'Soporte local en guaraní'),
                  ],
                )
                    .animate()
                    .fadeIn(delay: 750.ms, duration: 500.ms),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Internal widgets ──────────────────────────────────────────────────────────

class _BadgePill extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: LandingColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: LandingColors.primary.withValues(alpha: 0.18),
          width: 1.2,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: LandingColors.primary,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '🇵🇾 La 1ra plataforma de turnos hecha para Paraguay',
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: LandingColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}

class _PrimaryCta extends StatefulWidget {
  const _PrimaryCta({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  State<_PrimaryCta> createState() => _PrimaryCtaState();
}

class _PrimaryCtaState extends State<_PrimaryCta> {
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
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
          transformAlignment: Alignment.center,
          transform: Matrix4.diagonal3Values(_hovered ? 1.03 : 1.0, _hovered ? 1.03 : 1.0, 1.0),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            color: _hovered
                ? LandingColors.primaryDark
                : LandingColors.primary,
            boxShadow: [
              BoxShadow(
                color: LandingColors.primary.withValues(alpha: _hovered ? 0.35 : 0.15),
                blurRadius: _hovered ? 24 : 16,
                offset: Offset(0, _hovered ? 8 : 4),
              ),
            ],
          ),
          child: Text(
            widget.label,
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: LandingColors.textWhite,
            ),
          ),
        ),
      ),
    );
  }
}

class _OutlineCta extends StatefulWidget {
  const _OutlineCta({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  State<_OutlineCta> createState() => _OutlineCtaState();
}

class _OutlineCtaState extends State<_OutlineCta> {
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
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
          transformAlignment: Alignment.center,
          transform: Matrix4.diagonal3Values(_hovered ? 1.03 : 1.0, _hovered ? 1.03 : 1.0, 1.0),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color:
                  _hovered ? LandingColors.primary : LandingColors.border,
              width: 1.5,
            ),
            color: _hovered
                ? LandingColors.primary.withValues(alpha: 0.05)
                : Colors.transparent,
            boxShadow: _hovered
                ? [
                    BoxShadow(
                      color: LandingColors.primary.withValues(alpha: 0.08),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ]
                : [],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.play_circle_outline_rounded,
                size: 20,
                color: _hovered
                    ? LandingColors.primary
                    : LandingColors.textPrimary,
              ),
              const SizedBox(width: 8),
              Text(
                widget.label,
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: _hovered
                      ? LandingColors.primary
                      : LandingColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Guarantee extends StatelessWidget {
  const _Guarantee({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(
          Icons.check_circle_rounded,
          size: 18,
          color: LandingColors.success,
        ),
        const SizedBox(width: 6),
        Text(
          text,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: LandingColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _HeroBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..shader = LinearGradient(
        colors: [
          LandingColors.primary.withValues(alpha: 0.0),
          LandingColors.primary.withValues(alpha: 0.22),
          LandingColors.primary.withValues(alpha: 0.0),
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    // Spline 1: Smooth curve from top-left to bottom-right
    final path1 = Path()
      ..moveTo(0, size.height * 0.15)
      ..cubicTo(
        size.width * 0.25,
        size.height * 0.05,
        size.width * 0.45,
        size.height * 0.55,
        size.width * 0.85,
        size.height * 0.35,
      )
      ..cubicTo(
        size.width * 0.95,
        size.height * 0.3,
        size.width,
        size.height * 0.4,
        size.width,
        size.height * 0.45,
      );

    // Spline 2: Intersecting curve from bottom-left to top-right
    final path2 = Path()
      ..moveTo(0, size.height * 0.8)
      ..cubicTo(
        size.width * 0.3,
        size.height * 0.9,
        size.width * 0.55,
        size.height * 0.3,
        size.width * 0.8,
        size.height * 0.6,
      )
      ..cubicTo(
        size.width * 0.9,
        size.height * 0.7,
        size.width,
        size.height * 0.6,
        size.width,
        size.height * 0.55,
      );

    canvas.drawPath(path1, paint);
    canvas.drawPath(path2, paint);

    // Neon radial glow auras (behind title block)
    final glowPaint = Paint()
      ..style = PaintingStyle.fill
      ..shader = RadialGradient(
        colors: [
          LandingColors.primary.withValues(alpha: 0.08),
          LandingColors.primary.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromCircle(
        center: Offset(size.width * 0.5, size.height * 0.4),
        radius: size.width * 0.3,
      ));
    
    canvas.drawCircle(Offset(size.width * 0.5, size.height * 0.4), size.width * 0.3, glowPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _AnimatedGlowAura extends StatefulWidget {
  const _AnimatedGlowAura({required this.child});
  final Widget child;

  @override
  State<_AnimatedGlowAura> createState() => _AnimatedGlowAuraState();
}

class _AnimatedGlowAuraState extends State<_AnimatedGlowAura>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 6),
      vsync: this,
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.85, end: 1.15).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Stack(
          alignment: Alignment.center,
          children: [
            // Background glow that breathes/pulses
            Container(
              width: 360,
              height: 200,
              transform: Matrix4.diagonal3Values(_animation.value, _animation.value, 1.0),
              transformAlignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    LandingColors.primary.withValues(alpha: 0.12),
                    LandingColors.primary.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
            child!,
          ],
        );
      },
      child: widget.child,
    );
  }
}
