import 'package:flutter/material.dart';

/// Landing page color palette (green ReservPy brand).
class LandingColors {
  LandingColors._();

  // ─── Primary (Green ReservPy) ──────────────────────────────────
  static const Color primary = Color(0xFF00C896);
  static const Color primaryDark = Color(0xFF00A87A);
  static const Color primaryLight = Color(0xFF33D4AB);
  static const Color primaryBg = Color(0xFFF0FDF9);
  static const Color primaryTint = Color(0xFFE6FAF5);

  // ─── Backgrounds ───────────────────────────────────────
  static const Color bgWhite = Color(0xFFFFFFFF);
  static const Color bgAlt = Color(0xFFF0FDF9);
  static const Color bgDark = Color(0xFF0F0F10);

  // ─── Text ──────────────────────────────────────────────
  static const Color textPrimary = Color(0xFF0F0F10);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textMuted = Color(0xFF9CA3AF);
  static const Color textWhite = Color(0xFFFFFFFF);

  // ─── Borders ───────────────────────────────────────────
  static const Color border = Color(0xFFE0F2ED);
  static const Color borderLight = Color(0xFFF3F4F6);

  // ─── Semantic ──────────────────────────────────────────
  static const Color success = Color(0xFF10B981);
  static const Color successBg = Color(0xFFECFDF5);
  static const Color warning = Color(0xFFF59E0B);
  static const Color warningBg = Color(0xFFFFFBEB);

  // ─── Shadows ───────────────────────────────────────────
  static const Color shadowPrimary = Color(0x3000C896);
  static const Color shadowLight = Color(0x12000000);
}

/// Responsive breakpoints for the landing page.
class LandingBreakpoints {
  LandingBreakpoints._();
  static const double mobile = 640;
  static const double tablet = 900;
  static const double desktop = 1200;
}

/// Check if the screen is wider than a breakpoint.
bool isDesktop(BuildContext context) =>
    MediaQuery.sizeOf(context).width >= LandingBreakpoints.desktop;
bool isTablet(BuildContext context) =>
    MediaQuery.sizeOf(context).width >= LandingBreakpoints.tablet;
bool isMobile(BuildContext context) =>
    MediaQuery.sizeOf(context).width < LandingBreakpoints.tablet;
