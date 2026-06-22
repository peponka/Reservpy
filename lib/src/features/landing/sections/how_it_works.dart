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
      color: LandingColors.bgAlt,
      padding: EdgeInsets.symmetric(
        vertical: mobile ? 80 : 112,
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
              SizedBox(height: mobile ? 40 : 56),
              // ── Steps ──
              desktop ? _buildDesktopSteps() : _buildMobileSteps(),
              SizedBox(height: mobile ? 48 : 64),
              // ── Phone mockup ──
              const _PhoneMockupRow()
                  .animate()
                  .fadeIn(duration: 600.ms, delay: 400.ms)
                  .slideY(begin: 0.1, end: 0),
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

// ── Phone Mockup Row ──

class _PhoneMockupRow extends StatelessWidget {
  const _PhoneMockupRow();

  @override
  Widget build(BuildContext context) {
    final mobile = isMobile(context);
    final screens = [_phoneScreenBusiness(), _phoneScreenSlots(), _phoneScreenConfirm()];

    if (mobile) {
      return _PhoneFrame(child: screens[1]);
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Opacity(
          opacity: 0.6,
          child: Transform.scale(scale: 0.82, alignment: Alignment.bottomCenter,
            child: _PhoneFrame(child: screens[0])),
        ),
        const SizedBox(width: 24),
        _PhoneFrame(child: screens[1]),
        const SizedBox(width: 24),
        Opacity(
          opacity: 0.6,
          child: Transform.scale(scale: 0.82, alignment: Alignment.bottomCenter,
            child: _PhoneFrame(child: screens[2])),
        ),
      ],
    );
  }

  static Widget _phoneScreenBusiness() {
    return _MockScreen(
      title: 'Elegí el servicio',
      child: Column(
        children: [
          _MockServiceTile(name: 'Corte de cabello', price: '₲ 60.000', mins: '30 min'),
          const SizedBox(height: 8),
          _MockServiceTile(name: 'Corte + barba', price: '₲ 90.000', mins: '45 min', selected: true),
          const SizedBox(height: 8),
          _MockServiceTile(name: 'Afeitado clásico', price: '₲ 45.000', mins: '20 min'),
        ],
      ),
    );
  }

  static Widget _phoneScreenSlots() {
    return _MockScreen(
      title: 'Elegí el horario',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Lunes 23 jun', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: LandingColors.textPrimary)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: ['09:00', '09:30', '10:00', '10:30', '11:00', '14:00']
                .asMap()
                .entries
                .map((e) => _MockSlot(time: e.value, selected: e.key == 2))
                .toList(),
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: LandingColors.primary,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text('Confirmar turno', textAlign: TextAlign.center,
              style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white)),
          ),
        ],
      ),
    );
  }

  static Widget _phoneScreenConfirm() {
    return _MockScreen(
      title: '¡Turno confirmado!',
      child: Column(
        children: [
          Container(
            width: 48, height: 48,
            decoration: const BoxDecoration(color: LandingColors.primary, shape: BoxShape.circle),
            child: const Icon(Icons.check_rounded, color: Colors.white, size: 28),
          ),
          const SizedBox(height: 12),
          Text('Lunes 23 jun — 10:00', textAlign: TextAlign.center,
            style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: LandingColors.textPrimary)),
          const SizedBox(height: 4),
          Text('Corte + barba · 45 min', textAlign: TextAlign.center,
            style: GoogleFonts.inter(fontSize: 11, color: LandingColors.textSecondary)),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: LandingColors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: LandingColors.primary.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                const Icon(Icons.email_outlined, size: 14, color: LandingColors.primary),
                const SizedBox(width: 8),
                Expanded(child: Text('Confirmación enviada a tu email',
                  style: GoogleFonts.inter(fontSize: 10, color: LandingColors.primary))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PhoneFrame extends StatelessWidget {
  final Widget child;
  const _PhoneFrame({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 200,
      height: 360,
      decoration: BoxDecoration(
        color: LandingColors.bgWhite,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFF1A1A2E), width: 6),
        boxShadow: [
          BoxShadow(
            color: LandingColors.primary.withValues(alpha: 0.15),
            blurRadius: 32,
            offset: const Offset(0, 12),
          ),
          const BoxShadow(
            color: Color(0x1A000000),
            blurRadius: 16,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Column(
          children: [
            // Status bar
            Container(
              height: 24,
              color: const Color(0xFF1A1A2E),
              child: Center(
                child: Container(
                  width: 48, height: 6,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            ),
            Expanded(child: child),
          ],
        ),
      ),
    );
  }
}

class _MockScreen extends StatelessWidget {
  final String title;
  final Widget child;
  const _MockScreen({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 24, height: 24,
                decoration: const BoxDecoration(color: LandingColors.primary, shape: BoxShape.circle),
                child: Center(
                  child: Text('R', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.white)),
                ),
              ),
              const SizedBox(width: 6),
              Text('ReservPy', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, color: LandingColors.primary)),
            ],
          ),
          const SizedBox(height: 12),
          Text(title, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: LandingColors.textPrimary)),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _MockServiceTile extends StatelessWidget {
  final String name;
  final String price;
  final String mins;
  final bool selected;
  const _MockServiceTile({required this.name, required this.price, required this.mins, this.selected = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: selected ? LandingColors.primary.withValues(alpha: 0.08) : LandingColors.bgAlt,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: selected ? LandingColors.primary : LandingColors.border,
          width: selected ? 1.5 : 1,
        ),
      ),
      child: Row(
        children: [
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name, style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600,
                color: selected ? LandingColors.primary : LandingColors.textPrimary)),
              Text('$mins · $price', style: GoogleFonts.inter(fontSize: 9, color: LandingColors.textSecondary)),
            ],
          )),
          if (selected)
            const Icon(Icons.check_circle_rounded, color: LandingColors.primary, size: 14),
        ],
      ),
    );
  }
}

class _MockSlot extends StatelessWidget {
  final String time;
  final bool selected;
  const _MockSlot({required this.time, this.selected = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: selected ? LandingColors.primary : LandingColors.bgAlt,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: selected ? LandingColors.primary : LandingColors.border),
      ),
      child: Text(time, style: GoogleFonts.inter(
        fontSize: 10, fontWeight: FontWeight.w600,
        color: selected ? Colors.white : LandingColors.textPrimary,
      )),
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
