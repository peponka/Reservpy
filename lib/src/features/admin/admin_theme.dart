import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ── Colors ────────────────────────────────────────────────────────────────────

class AC {
  // Backgrounds
  static const bg          = Color(0xFF0A0A0F);
  static const surface     = Color(0xFF111118);
  static const surfaceHigh = Color(0xFF16161F);
  static const border      = Color(0xFF1E1E2E);
  static const borderBright = Color(0xFF2A2A3E);

  // Accents
  static const violet  = Color(0xFF6C63FF);
  static const teal    = Color(0xFF00D4AA);
  static const danger  = Color(0xFFFF4757);
  static const warning = Color(0xFFFFA502);
  static const success = Color(0xFF2ED573);
  static const info    = Color(0xFF2196F3);

  // Text
  static const text    = Color(0xFFF0F0FF);
  static const textSec = Color(0xFF8585A4);
  static const textMut = Color(0xFF4A4A6A);

  // Gradient pairs
  static const gradViolet = [Color(0xFF6C63FF), Color(0xFF9C6FFF)];
  static const gradTeal   = [Color(0xFF00D4AA), Color(0xFF00B4D8)];
  static const gradFire   = [Color(0xFFFF4757), Color(0xFFFF6B35)];
  static const gradGold   = [Color(0xFFFFA502), Color(0xFFFFD700)];
}

// ── Theme ─────────────────────────────────────────────────────────────────────

ThemeData adminTheme() {
  return ThemeData(
    brightness:       Brightness.dark,
    scaffoldBackgroundColor: AC.bg,
    colorScheme: const ColorScheme.dark(
      surface:          AC.surface,
      surfaceContainerLowest: AC.surface,
      surfaceContainerLow:    AC.surfaceHigh,
      primary:          AC.violet,
      secondary:        AC.teal,
      error:            AC.danger,
      onSurface:        AC.text,
      onPrimary:        Colors.white,
    ),
    dividerColor: AC.border,
    textTheme: TextTheme(
      displayLarge: GoogleFonts.spaceGrotesk(color: AC.text, fontWeight: FontWeight.w700),
      displayMedium: GoogleFonts.spaceGrotesk(color: AC.text, fontWeight: FontWeight.w700),
      headlineLarge: GoogleFonts.spaceGrotesk(color: AC.text, fontWeight: FontWeight.w700),
      headlineMedium: GoogleFonts.spaceGrotesk(color: AC.text, fontWeight: FontWeight.w700),
      headlineSmall: GoogleFonts.spaceGrotesk(color: AC.text, fontWeight: FontWeight.w600),
      titleLarge: GoogleFonts.inter(color: AC.text, fontWeight: FontWeight.w600),
      titleMedium: GoogleFonts.inter(color: AC.text, fontWeight: FontWeight.w500),
      bodyLarge: GoogleFonts.inter(color: AC.text),
      bodyMedium: GoogleFonts.inter(color: AC.textSec),
      bodySmall: GoogleFonts.inter(color: AC.textSec, fontSize: 12),
      labelLarge: GoogleFonts.inter(color: AC.text, fontWeight: FontWeight.w600),
    ),
    iconTheme: const IconThemeData(color: AC.textSec),
    inputDecorationTheme: InputDecorationTheme(
      filled:      true,
      fillColor:   AC.surfaceHigh,
      hintStyle:   GoogleFonts.inter(color: AC.textMut),
      labelStyle:  GoogleFonts.inter(color: AC.textSec),
      border:      OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide:   const BorderSide(color: AC.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide:   const BorderSide(color: AC.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide:   const BorderSide(color: AC.violet, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    ),
    cardTheme: CardThemeData(
      color:  AC.surface,
      elevation: 0,
      shape:  RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side:         const BorderSide(color: AC.border),
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: AC.surfaceHigh,
      selectedColor:   AC.violet.withValues(alpha: 0.2),
      labelStyle:      GoogleFonts.inter(color: AC.textSec, fontSize: 12),
      side:            const BorderSide(color: AC.border),
      shape:           RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AC.violet,
        foregroundColor: Colors.white,
        textStyle: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AC.text,
        side:            const BorderSide(color: AC.border),
        textStyle:       GoogleFonts.inter(fontWeight: FontWeight.w500, fontSize: 13),
        shape:           RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        padding:         const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      ),
    ),
    scrollbarTheme: ScrollbarThemeData(
      thumbColor: WidgetStateProperty.all(AC.border),
      radius:     const Radius.circular(4),
      thickness:  WidgetStateProperty.all(4),
    ),
  );
}

// ── Reusable widgets ──────────────────────────────────────────────────────────

/// Card with glassmorphism + gradient border
class AdminCard extends StatelessWidget {
  const AdminCard({
    super.key,
    required this.child,
    this.padding,
    this.gradient = false,
    this.onTap,
    this.width,
    this.height,
  });

  final Widget child;
  final EdgeInsets? padding;
  final bool gradient;
  final VoidCallback? onTap;
  final double? width;
  final double? height;

  @override
  Widget build(BuildContext context) {
    final inner = Container(
      width:  width,
      height: height,
      decoration: BoxDecoration(
        color:        AC.surface,
        borderRadius: BorderRadius.circular(16),
        border:       Border.all(color: gradient ? Colors.transparent : AC.border),
      ),
      padding: padding ?? const EdgeInsets.all(20),
      child: child,
    );

    Widget result = gradient
        ? Container(
            width:  width,
            height: height,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0x226C63FF), Color(0x2200D4AA)],
                begin:  Alignment.topLeft,
                end:    Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(17),
            ),
            padding: const EdgeInsets.all(1),
            child: inner,
          )
        : inner;

    if (onTap != null) {
      result = Material(
        color:        Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap:        onTap,
          borderRadius: BorderRadius.circular(16),
          splashColor:  AC.violet.withValues(alpha: 0.08),
          hoverColor:   AC.violet.withValues(alpha: 0.04),
          child: result,
        ),
      );
    }

    return result;
  }
}

/// Shimmering loading placeholder
class AdminShimmer extends StatelessWidget {
  const AdminShimmer({super.key, this.width, this.height, this.radius = 10});
  final double? width;
  final double? height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width:  width,
      height: height ?? 16,
      decoration: BoxDecoration(
        color:        AC.surfaceHigh,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

/// Animated KPI number (count-up)
class CountUpValue extends StatefulWidget {
  const CountUpValue({
    super.key,
    required this.value,
    required this.style,
    this.prefix = '',
    this.suffix = '',
    this.duration = const Duration(milliseconds: 1200),
  });

  final double value;
  final TextStyle style;
  final String prefix;
  final String suffix;
  final Duration duration;

  @override
  State<CountUpValue> createState() => _CountUpValueState();
}

class _CountUpValueState extends State<CountUpValue>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double>   _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: widget.duration);
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic);
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) {
        final current = widget.value * _anim.value;
        final formatted = widget.value >= 1000
            ? _fmt(current)
            : current.toStringAsFixed(widget.value % 1 == 0 ? 0 : 1);
        return Text('${widget.prefix}$formatted${widget.suffix}', style: widget.style);
      },
    );
  }

  String _fmt(double v) {
    // Format with thousands separator
    final n = v.toInt();
    final s = n.toString();
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write('.');
      buf.write(s[i]);
    }
    return buf.toString();
  }
}

/// Severity badge
class SeverityBadge extends StatelessWidget {
  const SeverityBadge({super.key, required this.severity});
  final String severity; // leve | moderado | critico

  Color get _color {
    switch (severity) {
      case 'critico':  return AC.danger;
      case 'moderado': return AC.warning;
      default:         return const Color(0xFFFFE066);
    }
  }

  String get _label {
    switch (severity) {
      case 'critico':  return 'Crítico';
      case 'moderado': return 'Moderado';
      default:         return 'Leve';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        color:        _color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border:       Border.all(color: _color.withValues(alpha: 0.3)),
      ),
      child: Text(_label, style: GoogleFonts.inter(
        fontSize: 11, fontWeight: FontWeight.w600, color: _color,
      )),
    );
  }
}

/// Status badge
class StatusBadge extends StatelessWidget {
  const StatusBadge({super.key, required this.status});
  final String status;

  Color get _color {
    switch (status) {
      case 'active':    return AC.success;
      case 'paid':      return AC.success;
      case 'inactive':  return AC.textMut;
      case 'pending':   return AC.warning;
      case 'overdue':   return AC.danger;
      case 'suspended': return AC.danger;
      case 'cancelled': return AC.textMut;
      case 'refunded':  return AC.info;
      default:          return AC.textSec;
    }
  }

  String get _label {
    const m = <String, String>{
      'active':    'Activo',
      'paid':      'Pagado',
      'inactive':  'Inactivo',
      'pending':   'Pendiente',
      'overdue':   'Vencido',
      'suspended': 'Suspendido',
      'cancelled': 'Cancelado',
      'refunded':  'Reembolsado',
    };
    return m[status] ?? status;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        color:        _color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border:       Border.all(color: _color.withValues(alpha: 0.25)),
      ),
      child: Text(_label, style: GoogleFonts.inter(
        fontSize: 11, fontWeight: FontWeight.w600, color: _color,
      )),
    );
  }
}

/// Section header row
class AdminSectionHeader extends StatelessWidget {
  const AdminSectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
  });
  final String title;
  final String? subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: GoogleFonts.spaceGrotesk(
                fontSize: 22, fontWeight: FontWeight.w700, color: AC.text,
              )),
              if (subtitle != null) ...[
                const SizedBox(height: 3),
                Text(subtitle!, style: GoogleFonts.inter(fontSize: 13, color: AC.textSec)),
              ],
            ],
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}
