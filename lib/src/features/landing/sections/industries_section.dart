import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:reservpy/src/features/landing/landing_theme.dart';

/// Target-industry pills section.
class IndustriesSection extends StatelessWidget {
  const IndustriesSection({super.key});

  static const _industries = [
    ('✂️', 'Peluquerías'),
    ('🧠', 'Psicólogos'),
    ('💆', 'Estética'),
    ('🥗', 'Nutricionistas'),
    ('💪', 'Entrenadores'),
    ('🦷', 'Odontólogos'),
    ('💅', 'Manicuristas'),
    ('🩺', 'Kinesiólogos'),
  ];

  @override
  Widget build(BuildContext context) {
    final mobile = isMobile(context);

    return Container(
      width: double.infinity,
      color: LandingColors.bgWhite,
      padding: EdgeInsets.symmetric(
        horizontal: 24,
        vertical: mobile ? 56 : 80,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: Column(
            children: [
              Text(
                'Ideal para profesionales y negocios\nde todos los rubros',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: mobile ? 24 : 32,
                  fontWeight: FontWeight.w700,
                  color: LandingColors.textPrimary,
                  height: 1.25,
                ),
              )
                  .animate()
                  .fadeIn(duration: 500.ms)
                  .slideY(begin: 0.12, end: 0, duration: 500.ms),

              const SizedBox(height: 40),

              Wrap(
                alignment: WrapAlignment.center,
                spacing: 12,
                runSpacing: 12,
                children: List.generate(_industries.length, (i) {
                  final (emoji, label) = _industries[i];
                  return _IndustryPill(emoji: emoji, label: label)
                      .animate()
                      .fadeIn(
                        delay: (100 * i).ms,
                        duration: 400.ms,
                      )
                      .slideY(
                        begin: 0.15,
                        end: 0,
                        delay: (100 * i).ms,
                        duration: 400.ms,
                      );
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _IndustryPill extends StatefulWidget {
  const _IndustryPill({required this.emoji, required this.label});

  final String emoji;
  final String label;

  @override
  State<_IndustryPill> createState() => _IndustryPillState();
}

class _IndustryPillState extends State<_IndustryPill> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        transform: _hovered
            ? Matrix4.translationValues(0.0, -2.0, 0.0)
            : Matrix4.identity(),
        decoration: BoxDecoration(
          color: LandingColors.bgWhite,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: _hovered ? LandingColors.primary : LandingColors.border,
            width: 1.5,
          ),
          boxShadow: _hovered
              ? [
                  const BoxShadow(
                    color: LandingColors.shadowPrimary,
                    blurRadius: 12,
                    offset: Offset(0, 4),
                  ),
                ]
              : [
                  const BoxShadow(
                    color: LandingColors.shadowLight,
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(widget.emoji, style: const TextStyle(fontSize: 18)),
            const SizedBox(width: 8),
            Text(
              widget.label,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: _hovered
                    ? LandingColors.primary
                    : LandingColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
