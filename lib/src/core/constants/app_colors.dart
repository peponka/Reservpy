import 'package:flutter/material.dart';

/// ReservPy brand color palette.
/// Use via Theme.of(context).colorScheme — never reference these directly in widgets.
class AppColors {
  AppColors._();

  // ─── Primary ───────────────────────────────────────────
  static const Color primary = Color(0xFF00C896);
  static const Color primaryDark = Color(0xFF00A67E);
  static const Color primaryLight = Color(0xFF33D4AB);

  // ─── Accent ────────────────────────────────────────────
  static const Color accent = Color(0xFF0A2540);
  static const Color accentLight = Color(0xFF1A3A5C);

  // ─── Backgrounds (Light) ───────────────────────────────
  static const Color backgroundLight = Color(0xFFFAFBFC);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color cardLight = Color(0xFFFFFFFF);

  // ─── Backgrounds (Dark) ────────────────────────────────
  static const Color backgroundDark = Color(0xFF0F1923);
  static const Color surfaceDark = Color(0xFF1A2B3C);
  static const Color cardDark = Color(0xFF223344);

  // ─── Text ──────────────────────────────────────────────
  static const Color textPrimary = Color(0xFF1A1A2E);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textLight = Color(0xFFF1F5F9);
  static const Color textMuted = Color(0xFF9CA3AF);

  // ─── Semantic ──────────────────────────────────────────
  static const Color success = Color(0xFF2ED573);
  static const Color warning = Color(0xFF5B8DEF);
  static const Color error = Color(0xFFFF4757);
  static const Color info = Color(0xFF3B82F6);

  // ─── Dividers & Borders ────────────────────────────────
  static const Color divider = Color(0xFFE5E7EB);
  static const Color dividerDark = Color(0xFF2A3A4C);
  static const Color border = Color(0xFFD1D5DB);
  static const Color borderDark = Color(0xFF374151);

  // ─── Status Colors for Reservations ────────────────────
  static const Color statusPending = Color(0xFF5B8DEF);
  static const Color statusConfirmed = Color(0xFF2ED573);
  static const Color statusCancelled = Color(0xFFFF4757);
  static const Color statusCompleted = Color(0xFF3B82F6);
  static const Color statusBlocked = Color(0xFF9CA3AF);
}
