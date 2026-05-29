import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:reservpy/src/features/landing/landing_theme.dart';

/// Big-number stats section (4 metrics).
class StatsSection extends StatelessWidget {
  const StatsSection({super.key});

  @override
  Widget build(BuildContext context) {
    final mobile = isMobile(context);

    return Container(
      width: double.infinity,
      color: LandingColors.bgAlt,
      padding: EdgeInsets.symmetric(
        horizontal: 24,
        vertical: mobile ? 56 : 80,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final crossAxisCount = mobile ? 2 : 4;
              const spacing = 20.0;
              final itemWidth =
                  (constraints.maxWidth - spacing * (crossAxisCount - 1)) /
                      crossAxisCount;

              return Wrap(
                spacing: spacing,
                runSpacing: spacing,
                alignment: WrapAlignment.center,
                children: [
                  _StatCard(
                    icon: Icons.calendar_month_rounded,
                    iconBg: LandingColors.primaryTint,
                    iconColor: LandingColors.primary,
                    value: '1.200+',
                    label: 'Turnos en Paraguay',
                    width: itemWidth,
                  ).animate().fadeIn(delay: 0.ms, duration: 500.ms).slideY(
                      begin: 0.15, end: 0, delay: 0.ms, duration: 500.ms),
                  _StatCard(
                    icon: Icons.access_time_rounded,
                    iconBg: const Color(0xFFEFF6FF),
                    iconColor: const Color(0xFF3B82F6),
                    value: '24/7',
                    label: 'Reservas online',
                    width: itemWidth,
                  ).animate().fadeIn(delay: 120.ms, duration: 500.ms).slideY(
                      begin: 0.15,
                      end: 0,
                      delay: 120.ms,
                      duration: 500.ms),
                  _StatCard(
                    icon: Icons.bolt_rounded,
                    iconBg: const Color(0xFFFFFBEB),
                    iconColor: LandingColors.warning,
                    value: '5 min',
                    label: 'Y ya estás operando',
                    width: itemWidth,
                  ).animate().fadeIn(delay: 240.ms, duration: 500.ms).slideY(
                      begin: 0.15,
                      end: 0,
                      delay: 240.ms,
                      duration: 500.ms),
                  _StatCard(
                    icon: Icons.public_rounded,
                    iconBg: const Color(0xFFECFDF5),
                    iconColor: LandingColors.success,
                    value: '100%',
                    label: 'Paraguayo 🇵🇾',
                    width: itemWidth,
                  ).animate().fadeIn(delay: 360.ms, duration: 500.ms).slideY(
                      begin: 0.15,
                      end: 0,
                      delay: 360.ms,
                      duration: 500.ms),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.value,
    required this.label,
    required this.width,
  });

  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String value;
  final String label;
  final double width;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
        decoration: BoxDecoration(
          color: LandingColors.bgWhite,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: LandingColors.border),
          boxShadow: const [
            BoxShadow(
              color: LandingColors.shadowLight,
              blurRadius: 8,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: iconBg,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 26),
            ),
            const SizedBox(height: 16),
            Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 32,
                fontWeight: FontWeight.w800,
                color: LandingColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: LandingColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
