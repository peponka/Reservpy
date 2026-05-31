import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:reservpy/src/features/landing/landing_theme.dart';

class SeoBlock extends StatelessWidget {
  const SeoBlock({super.key});

  static const _sections = <_SeoSection>[
    _SeoSection(
      title: '¿Qué es ReservPy? — La app de turnos de Paraguay',
      body:
          'ReservPy es la primera plataforma 100% paraguaya para gestionar turnos y reservas '
          'online. Nacida en Asunción, pensada para emprendedores de todo el país — desde '
          'Fernando de la Mora hasta Ciudad del Este. Con diseño moderno, panel intuitivo y '
          'soporte en español paraguayo, tu negocio recibe reservas las 24 horas sin perder '
          'ni un minuto en WhatsApp.',
    ),
    _SeoSection(
      title: 'Chau cuaderno, chau WhatsApp — hola ReservPy',
      body:
          'En Paraguay, 8 de cada 10 negocios todavía agendan por WhatsApp o en un cuaderno. '
          'Eso significa turnos perdidos, clientes que no llegan y cero control de tu agenda. '
          'ReservPy cambia eso: tus clientes eligen el horario que les conviene, reciben '
          'confirmación automática y vos te olvidás de perseguir a nadie. Funciona 24/7, '
          'incluso cuando estás atendiendo o tomando tereré.',
    ),
    _SeoSection(
      title: 'Paraguay se digitaliza — no te quedes atrás',
      body:
          'Los negocios paraguayos que digitalizan su agenda ahorran hasta 5 horas por semana '
          'y reducen cancelaciones un 40%. ReservPy te muestra métricas de ocupación, ingresos '
          'y rendimiento del equipo. Empezá gratis con hasta 10 reservas por mes y escalá '
          'cuando tu negocio lo necesite. Ya hay emprendedores en Asunción, Encarnación, Luque '
          'y CDE que lo usan — ¿vas a ser el próximo?',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final desktop = isDesktop(context);
    final mobile = isMobile(context);

    return Container(
      width: double.infinity,
      color: LandingColors.bgAlt,
      padding: EdgeInsets.symmetric(
        vertical: mobile ? 56 : 80,
        horizontal: mobile ? 16 : 24,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: desktop
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: List.generate(_sections.length, (i) {
                    return Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(
                          right: i < _sections.length - 1 ? 32 : 0,
                        ),
                        child: _buildColumn(_sections[i], i),
                      ),
                    );
                  }),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: List.generate(_sections.length, (i) {
                    return Padding(
                      padding: EdgeInsets.only(
                        bottom: i < _sections.length - 1 ? 32 : 0,
                      ),
                      child: _buildColumn(_sections[i], i),
                    );
                  }),
                ),
        ),
      ),
    );
  }

  Widget _buildColumn(_SeoSection section, int index) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          section.title,
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: LandingColors.textPrimary,
            height: 1.3,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          section.body,
          style: GoogleFonts.inter(
            fontSize: 14,
            color: LandingColors.textSecondary,
            height: 1.75,
          ),
        ),
      ],
    )
        .animate()
        .fadeIn(duration: 500.ms, delay: (200 + index * 150).ms)
        .slideY(begin: 0.12, end: 0);
  }
}

class _SeoSection {
  final String title;
  final String body;
  const _SeoSection({required this.title, required this.body});
}
