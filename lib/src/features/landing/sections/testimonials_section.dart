import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:reservpy/src/features/landing/landing_theme.dart';

class TestimonialsSection extends StatelessWidget {
  const TestimonialsSection({super.key});

  static const _testimonials = [
    _Testimonial(
      quote:
          'Desde que uso ReservPy, mis pacientes reservan solos y yo dejé de atender WhatsApp todo el día. Es simple, rápido y mis pacientes lo aman.',
      name: 'Sofía Rodríguez',
      title: 'Psicóloga',
      city: 'Asunción',
      initials: 'SR',
      gradientStart: LandingColors.primary,
      gradientEnd: LandingColors.primaryLight,
    ),
    _Testimonial(
      quote:
          'Configuré mi barbería en 5 minutos. Ahora mis clientes eligen el servicio, el horario y listo. No volvería al cuaderno nunca más.',
      name: 'Martín González',
      title: 'Dueño de peluquería',
      city: 'Ciudad del Este',
      initials: 'MG',
      gradientStart: LandingColors.primaryDark,
      gradientEnd: LandingColors.primary,
    ),
    _Testimonial(
      quote:
          'El panel de control me da toda la información que necesito. Veo mis turnos del día, los ingresos de la semana y las cancelaciones. Todo clarísimo.',
      name: 'Laura Martínez',
      title: 'Nutricionista',
      city: 'Encarnación',
      initials: 'LM',
      gradientStart: LandingColors.primaryLight,
      gradientEnd: LandingColors.primaryTint,
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
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Column(
            children: [
              Text(
                'Lo que dicen nuestros usuarios',
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
              const SizedBox(height: 56),
              mobile
                  ? Column(
                      children: _testimonials.asMap().entries.map((entry) {
                        return Padding(
                          padding: EdgeInsets.only(
                            bottom:
                                entry.key < _testimonials.length - 1 ? 24 : 0,
                          ),
                          child: _TestimonialCard(
                            testimonial: entry.value,
                          )
                              .animate()
                              .fadeIn(
                                duration: 500.ms,
                                delay: (150 * entry.key).ms,
                              )
                              .slideY(begin: 0.2, end: 0),
                        );
                      }).toList(),
                    )
                  : Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: _testimonials.asMap().entries.map((entry) {
                        return Expanded(
                          child: Padding(
                            padding: EdgeInsets.only(
                              left: entry.key == 0 ? 0 : 12,
                              right: entry.key == _testimonials.length - 1
                                  ? 0
                                  : 12,
                            ),
                            child: _TestimonialCard(
                              testimonial: entry.value,
                            )
                                .animate()
                                .fadeIn(
                                  duration: 500.ms,
                                  delay: (200 * entry.key).ms,
                                )
                                .slideY(begin: 0.2, end: 0),
                          ),
                        );
                      }).toList(),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TestimonialCard extends StatefulWidget {
  const _TestimonialCard({required this.testimonial});

  final _Testimonial testimonial;

  @override
  State<_TestimonialCard> createState() => _TestimonialCardState();
}

class _TestimonialCardState extends State<_TestimonialCard> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
        transform: Matrix4.translationValues(0, _hovering ? -6 : 0, 0),
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: LandingColors.bgWhite,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: LandingColors.border),
          boxShadow: [
            BoxShadow(
              color: _hovering
                  ? LandingColors.shadowPrimary
                  : LandingColors.shadowLight,
              blurRadius: _hovering ? 24 : 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Quote icon
            Icon(
              Icons.format_quote_rounded,
              size: 40,
              color: LandingColors.primary,
            ),
            const SizedBox(height: 16),
            // Quote text
            Text(
              '"${widget.testimonial.quote}"',
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w400,
                color: LandingColors.textSecondary,
                height: 1.7,
              ),
            ),
            const SizedBox(height: 20),
            // Divider
            Container(
              height: 1,
              color: LandingColors.border,
            ),
            const SizedBox(height: 20),
            // Avatar + info
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        widget.testimonial.gradientStart,
                        widget.testimonial.gradientEnd,
                      ],
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    widget.testimonial.initials,
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: LandingColors.textWhite,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.testimonial.name,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: LandingColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${widget.testimonial.title}, ${widget.testimonial.city}',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w400,
                          color: LandingColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Testimonial {
  const _Testimonial({
    required this.quote,
    required this.name,
    required this.title,
    required this.city,
    required this.initials,
    required this.gradientStart,
    required this.gradientEnd,
  });

  final String quote;
  final String name;
  final String title;
  final String city;
  final String initials;
  final Color gradientStart;
  final Color gradientEnd;
}
