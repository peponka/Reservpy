import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:reservpy/src/features/landing/landing_theme.dart';

class HowItWorksSection extends StatelessWidget {
  const HowItWorksSection({super.key});

  @override
  Widget build(BuildContext context) {
    final desktop = isDesktop(context);
    final mobile = isMobile(context);

    return Container(
      width: double.infinity,
      color: LandingColors.bgWhite,
      padding: EdgeInsets.symmetric(
        vertical: mobile ? 64 : 96,
        horizontal: mobile ? 16 : 24,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Column(
            children: [
              // ── Title ──
              Text(
                'Cómo funciona',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: mobile ? 28 : 40,
                  fontWeight: FontWeight.w800,
                  color: LandingColors.textPrimary,
                  height: 1.2,
                ),
              )
                  .animate()
                  .fadeIn(duration: 500.ms)
                  .slideY(begin: 0.15, end: 0),
              SizedBox(height: mobile ? 40 : 56),
              // ── Steps ──
              desktop ? _buildDesktopSteps() : _buildMobileSteps(),
              SizedBox(height: mobile ? 40 : 56),
              // ── CTA ──
              _HoverCta(label: 'Empezar ahora — 100% gratis 🇵🇾')
                  .animate()
                  .fadeIn(duration: 500.ms, delay: 700.ms)
                  .slideY(begin: 0.15, end: 0),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDesktopSteps() {
    return SizedBox(
      height: 280,
      child: Row(
        children: List.generate(5, (i) {
          if (i.isOdd) {
            // Connector
            return Expanded(
              child: _buildConnector()
                  .animate()
                  .fadeIn(duration: 400.ms, delay: (250 + i * 100).ms),
            );
          }
          final stepIndex = i ~/ 2;
          return Expanded(
            flex: 3,
            child: _HoverStepCard(step: _steps[stepIndex])
                .animate()
                .fadeIn(duration: 500.ms, delay: (200 + stepIndex * 200).ms)
                .slideY(begin: 0.15, end: 0),
          );
        }),
      ),
    );
  }

  Widget _buildMobileSteps() {
    return Column(
      children: List.generate(_steps.length, (i) {
        return Padding(
          padding: EdgeInsets.only(bottom: i < _steps.length - 1 ? 20 : 0),
          child: _HoverStepCard(step: _steps[i])
              .animate()
              .fadeIn(duration: 500.ms, delay: (200 + i * 150).ms)
              .slideY(begin: 0.15, end: 0),
        );
      }),
    );
  }

  Widget _buildConnector() {
    return Center(
      child: SizedBox(
        height: 2,
        child: Row(
          children: List.generate(7, (i) {
            return Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 2),
                decoration: BoxDecoration(
                  color: i.isEven
                      ? LandingColors.primary.withValues(alpha: 0.35)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  static final _steps = [
    _Step(
      number: '1',
      emoji: '🏢',
      title: 'Creás tu cuenta',
      description:
          'Registrate en 5 minutos, configurá tus servicios y horarios. Más rápido que hacer un pedido por Pedidos Ya.',
    ),
    _Step(
      number: '2',
      emoji: '🔗',
      title: 'Compartís el link',
      description:
          'Compartí tu link por WhatsApp, Instagram o en tu local. Tus clientes van a poder reservar al instante desde el celu.',
    ),
    _Step(
      number: '3',
      emoji: '📊',
      title: 'Gestionás todo',
      description:
          'Recibí reservas automáticas, confirmaciones por email y controlá todo desde tu celu o compu. Sin llamadas, sin papel.',
    ),
  ];
}

// ── Data ──

class _Step {
  final String number;
  final String emoji;
  final String title;
  final String description;

  const _Step({
    required this.number,
    required this.emoji,
    required this.title,
    required this.description,
  });
}

// ── Hover Step Card ──

class _HoverStepCard extends StatefulWidget {
  final _Step step;
  const _HoverStepCard({required this.step});

  @override
  State<_HoverStepCard> createState() => _HoverStepCardState();
}

class _HoverStepCardState extends State<_HoverStepCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
        transform: Matrix4.translationValues(0, _hovered ? -4 : 0, 0),
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: LandingColors.bgWhite,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: LandingColors.border),
          boxShadow: [
            BoxShadow(
              color: _hovered
                  ? LandingColors.shadowPrimary
                  : LandingColors.shadowLight,
              blurRadius: _hovered ? 24 : 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Number circle
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    LandingColors.primary,
                    LandingColors.primaryLight,
                  ],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: LandingColors.primary.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  widget.step.number,
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 18),
            // Emoji + Title
            Text(
              '${widget.step.emoji} ${widget.step.title}',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: LandingColors.textPrimary,
              ),
            ),
            const SizedBox(height: 10),
            // Description
            Text(
              widget.step.description,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: LandingColors.textSecondary,
                height: 1.6,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── CTA Button ──

class _HoverCta extends StatefulWidget {
  final String label;
  const _HoverCta({required this.label});

  @override
  State<_HoverCta> createState() => _HoverCtaState();
}

class _HoverCtaState extends State<_HoverCta> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        decoration: BoxDecoration(
          color: _hovered ? LandingColors.primaryDark : LandingColors.primary,
          borderRadius: BorderRadius.circular(999),
          boxShadow: _hovered
              ? const [
                  BoxShadow(
                    color: LandingColors.shadowPrimary,
                    blurRadius: 24,
                    offset: Offset(0, 8),
                  ),
                ]
              : const [
                  BoxShadow(
                    color: LandingColors.shadowLight,
                    blurRadius: 8,
                    offset: Offset(0, 4),
                  ),
                ],
        ),
        child: Text(
          widget.label,
          style: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
