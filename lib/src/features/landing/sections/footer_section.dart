import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:reservpy/src/features/landing/landing_theme.dart';

class FooterSection extends StatelessWidget {
  const FooterSection({super.key});

  @override
  Widget build(BuildContext context) {
    final mobile = isMobile(context);

    return Container(
      width: double.infinity,
      color: LandingColors.bgWhite,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: mobile ? 20 : 24,
            ),
            child: Column(
              children: [
                // ── Divider ──
                Container(height: 1, color: LandingColors.border),
                SizedBox(height: mobile ? 40 : 56),

                // ── Logo row ──
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: LandingColors.primary,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.calendar_month_rounded,
                        size: 20,
                        color: LandingColors.textWhite,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Reservly',
                      style: GoogleFonts.inter(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: LandingColors.textPrimary,
                      ),
                    ),
                  ],
                ).animate().fadeIn(duration: 400.ms),
                const SizedBox(height: 12),

                // ── Tagline ──
                Text(
                  'La primera plataforma de turnos hecha en Paraguay, para Paraguay 🇵🇾',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: LandingColors.textSecondary,
                    height: 1.5,
                  ),
                ).animate().fadeIn(duration: 400.ms, delay: 100.ms),
                const SizedBox(height: 24),

                // ── Links ──
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  alignment: WrapAlignment.center,
                  children: [
                    _FooterLink(label: 'Funciones'),
                    _LinkDot(),
                    _FooterLink(label: 'Precios'),
                    _LinkDot(),
                    _FooterLink(label: 'Términos'),
                    _LinkDot(),
                    _FooterLink(label: 'Privacidad'),
                  ],
                ).animate().fadeIn(duration: 400.ms, delay: 200.ms),

                SizedBox(height: mobile ? 32 : 40),

                // ── Copyright ──
                Text(
                  '© 2026 Reservly Paraguay. Todos los derechos reservados.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    color: LandingColors.textMuted,
                  ),
                ).animate().fadeIn(duration: 400.ms, delay: 300.ms),
                SizedBox(height: mobile ? 32 : 48),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FooterLink extends StatefulWidget {
  const _FooterLink({required this.label});
  final String label;

  @override
  State<_FooterLink> createState() => _FooterLinkState();
}

class _FooterLinkState extends State<_FooterLink> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () {},
        child: AnimatedDefaultTextStyle(
          duration: const Duration(milliseconds: 200),
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: _hovering
                ? LandingColors.primary
                : LandingColors.textSecondary,
          ),
          child: Text(widget.label),
        ),
      ),
    );
  }
}

class _LinkDot extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Text(
        '·',
        style: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: LandingColors.textMuted,
        ),
      ),
    );
  }
}
