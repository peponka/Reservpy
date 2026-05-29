import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:reservpy/src/features/landing/landing_theme.dart';

class FaqSection extends StatelessWidget {
  const FaqSection({super.key});

  static const _faqs = [
    _FaqItem(
      question: '¿Necesito conocimientos técnicos?',
      answer:
          'Para nada. Reservly está diseñado para que cualquier persona pueda configurar su negocio en menos de 5 minutos. No necesitás saber de programación ni de diseño.',
    ),
    _FaqItem(
      question: '¿Mis clientes necesitan una app?',
      answer:
          'No. Tus clientes reservan desde cualquier navegador, sin descargar nada. Les compartís tu link personalizado y listo.',
    ),
    _FaqItem(
      question: '¿Qué pasa al llegar al límite del plan gratis?',
      answer:
          'Al alcanzar las 10 reservas mensuales del plan gratuito, podés actualizar al plan Pro (Gs. 99.000/mes) o esperar al mes siguiente. Nunca perderás tus datos. El plan Pro incluye reservas ilimitadas, Reservbot con IA y soporte prioritario.',
    ),
    _FaqItem(
      question: '¿Puedo cancelar la suscripción?',
      answer:
          'Sí, podés cancelar en cualquier momento desde tu panel. No hay contratos ni permanencia mínima.',
    ),
    _FaqItem(
      question: '¿Mis datos están seguros?',
      answer:
          'Absolutamente. Usamos encriptación de nivel bancario y servidores seguros. Tu información y la de tus clientes está protegida. Reservly cumple con estándares internacionales de seguridad, adaptados al mercado paraguayo.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final mobile = isMobile(context);

    return Container(
      width: double.infinity,
      color: LandingColors.bgAlt,
      padding: EdgeInsets.symmetric(
        vertical: mobile ? 64 : 96,
        horizontal: mobile ? 20 : 24,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Column(
            children: [
              Text(
                'Preguntas frecuentes',
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
              const SizedBox(height: 48),
              Container(
                decoration: BoxDecoration(
                  color: LandingColors.bgWhite,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: LandingColors.border),
                  boxShadow: [
                    BoxShadow(
                      color: LandingColors.shadowLight,
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Column(
                    children: _faqs.asMap().entries.map((entry) {
                      final isLast = entry.key == _faqs.length - 1;
                      return _FaqTile(
                        item: entry.value,
                        showBorder: !isLast,
                      )
                          .animate()
                          .fadeIn(
                            duration: 400.ms,
                            delay: (100 * entry.key).ms,
                          )
                          .slideY(begin: 0.08, end: 0);
                    }).toList(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  Single FAQ accordion tile
// ═══════════════════════════════════════════════════════════════
class _FaqTile extends StatefulWidget {
  const _FaqTile({required this.item, required this.showBorder});

  final _FaqItem item;
  final bool showBorder;

  @override
  State<_FaqTile> createState() => _FaqTileState();
}

class _FaqTileState extends State<_FaqTile>
    with SingleTickerProviderStateMixin {
  bool _expanded = false;
  late final AnimationController _iconController;

  @override
  void initState() {
    super.initState();
    _iconController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
  }

  @override
  void dispose() {
    _iconController.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() {
      _expanded = !_expanded;
      if (_expanded) {
        _iconController.forward();
      } else {
        _iconController.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: _toggle,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 22),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.item.question,
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: LandingColors.textPrimary,
                        height: 1.4,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  AnimatedBuilder(
                    animation: _iconController,
                    builder: (context, _) {
                      return Transform.rotate(
                        angle: _iconController.value * 3.14159,
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: _expanded
                                ? LandingColors.primaryTint
                                : LandingColors.bgAlt,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.expand_more_rounded,
                            size: 20,
                            color: _expanded
                                ? LandingColors.primary
                                : LandingColors.textSecondary,
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
        AnimatedCrossFade(
          firstChild: const SizedBox.shrink(),
          secondChild: Padding(
            padding: const EdgeInsets.only(left: 28, right: 28, bottom: 22),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                widget.item.answer,
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w400,
                  color: LandingColors.textSecondary,
                  height: 1.7,
                ),
              ),
            ),
          ),
          crossFadeState:
              _expanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 250),
          sizeCurve: Curves.easeOut,
        ),
        if (widget.showBorder)
          Container(
            height: 1,
            margin: const EdgeInsets.symmetric(horizontal: 28),
            color: LandingColors.border,
          ),
      ],
    );
  }
}

class _FaqItem {
  const _FaqItem({required this.question, required this.answer});
  final String question;
  final String answer;
}
