import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:reservpy/src/features/landing/landing_theme.dart';

/// Fixed top navbar with blur backdrop, responsive mobile menu, and scroll-to
/// callbacks for each section.
class LandingNavbar extends StatefulWidget {
  const LandingNavbar({
    super.key,
    this.onFeaturesPressed,
    this.onHowItWorksPressed,
    this.onTestimonialsPressed,
    this.onPricingPressed,
  });

  final VoidCallback? onFeaturesPressed;
  final VoidCallback? onHowItWorksPressed;
  final VoidCallback? onTestimonialsPressed;
  final VoidCallback? onPricingPressed;

  @override
  State<LandingNavbar> createState() => _LandingNavbarState();
}

class _LandingNavbarState extends State<LandingNavbar> {
  bool _mobileMenuOpen = false;

  void _toggleMenu() => setState(() => _mobileMenuOpen = !_mobileMenuOpen);

  void _closeMenu() {
    if (_mobileMenuOpen) setState(() => _mobileMenuOpen = false);
  }

  @override
  Widget build(BuildContext context) {
    final mobile = isMobile(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: LandingColors.bgWhite.withValues(alpha: 0.8),
                border: const Border(
                  bottom: BorderSide(color: LandingColors.border),
                ),
                boxShadow: [
                  BoxShadow(
                    color: LandingColors.primary.withValues(alpha: 0.04),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1200),
                  child: SizedBox(
                    height: 64,
                    child: Row(
                      children: [
                        // ── Logo ──────────────────────────
                        _Logo(),

                        const Spacer(),

                        // ── Desktop links ─────────────────
                        if (!mobile) ...[
                          _NavLink(
                            label: 'Funciones',
                            onTap: () {
                              _closeMenu();
                              widget.onFeaturesPressed?.call();
                            },
                          ),
                          _NavLink(
                            label: 'Cómo funciona',
                            onTap: () {
                              _closeMenu();
                              widget.onHowItWorksPressed?.call();
                            },
                          ),
                          _NavLink(
                            label: 'Testimonios',
                            onTap: () {
                              _closeMenu();
                              widget.onTestimonialsPressed?.call();
                            },
                          ),
                          _NavLink(
                            label: 'Precios',
                            onTap: () {
                              _closeMenu();
                              widget.onPricingPressed?.call();
                            },
                          ),
                          const SizedBox(width: 16),
                          _GhostButton(
                            label: 'Ingresar',
                            onTap: () => context.go('/login'),
                          ),
                          const SizedBox(width: 8),
                          _PrimaryPillButton(
                            label: 'Registrarse →',
                            onTap: () => context.go('/register'),
                          ),
                        ],

                        // ── Mobile hamburger ──────────────
                        if (mobile)
                          IconButton(
                            icon: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 250),
                              transitionBuilder: (child, anim) =>
                                  RotationTransition(
                                turns: Tween(begin: 0.5, end: 1.0)
                                    .animate(anim),
                                child: FadeTransition(
                                  opacity: anim,
                                  child: child,
                                ),
                              ),
                              child: Icon(
                                _mobileMenuOpen
                                    ? Icons.close_rounded
                                    : Icons.menu_rounded,
                                key: ValueKey(_mobileMenuOpen),
                                color: LandingColors.textPrimary,
                              ),
                            ),
                            onPressed: _toggleMenu,
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),

        // ── Mobile dropdown ───────────────────────────────
        AnimatedCrossFade(
          duration: const Duration(milliseconds: 250),
          crossFadeState: (_mobileMenuOpen && mobile)
              ? CrossFadeState.showFirst
              : CrossFadeState.showSecond,
          firstChild: ClipRRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: LandingColors.bgWhite.withValues(alpha: 0.95),
                  border: const Border(
                    bottom: BorderSide(color: LandingColors.border),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: LandingColors.primary.withValues(alpha: 0.03),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _MobileNavLink(
                      label: 'Funciones',
                      onTap: () {
                        _closeMenu();
                        widget.onFeaturesPressed?.call();
                      },
                    ),
                    _MobileNavLink(
                      label: 'Cómo funciona',
                      onTap: () {
                        _closeMenu();
                        widget.onHowItWorksPressed?.call();
                      },
                    ),
                    _MobileNavLink(
                      label: 'Testimonios',
                      onTap: () {
                        _closeMenu();
                        widget.onTestimonialsPressed?.call();
                      },
                    ),
                    _MobileNavLink(
                      label: 'Precios',
                      onTap: () {
                        _closeMenu();
                        widget.onPricingPressed?.call();
                      },
                    ),
                    const SizedBox(height: 12),
                    _GhostButton(label: 'Ingresar', onTap: () { _closeMenu(); context.go('/login'); }),
                    const SizedBox(height: 8),
                    _PrimaryPillButton(label: 'Registrarse →', onTap: () { _closeMenu(); context.go('/register'); }),
                  ],
                ),
              ),
            ),
          ),
          secondChild: const SizedBox(width: double.infinity),
        ),
      ],
    );
  }
}

// ── Internal widgets ──────────────────────────────────────────────────────────

class _Logo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset(
          'assets/images/icon.png',
          width: 40,
          height: 40,
          fit: BoxFit.contain,
        ),
        const SizedBox(width: 10),
        Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: 'Reserv',
                style: GoogleFonts.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: LandingColors.textPrimary,
                ),
              ),
              TextSpan(
                text: 'Py',
                style: GoogleFonts.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: LandingColors.primary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _NavLink extends StatefulWidget {
  const _NavLink({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  State<_NavLink> createState() => _NavLinkState();
}

class _NavLinkState extends State<_NavLink> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutBack,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          transform: Matrix4.diagonal3Values(_hovered ? 1.05 : 1.0, _hovered ? 1.05 : 1.0, 1.0),
          transformAlignment: Alignment.center,
          decoration: BoxDecoration(
            color: _hovered
                ? LandingColors.primary.withValues(alpha: 0.08)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: _hovered
                  ? LandingColors.primary.withValues(alpha: 0.15)
                  : Colors.transparent,
              width: 1.0,
            ),
          ),
          child: Text(
            widget.label,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: _hovered
                  ? LandingColors.primary
                  : LandingColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

class _MobileNavLink extends StatelessWidget {
  const _MobileNavLink({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: LandingColors.textPrimary,
          ),
        ),
      ),
    );
  }
}

class _GhostButton extends StatefulWidget {
  const _GhostButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  State<_GhostButton> createState() => _GhostButtonState();
}

class _GhostButtonState extends State<_GhostButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutBack,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          transform: Matrix4.diagonal3Values(_hovered ? 1.04 : 1.0, _hovered ? 1.04 : 1.0, 1.0),
          transformAlignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: _hovered ? LandingColors.primary.withValues(alpha: 0.6) : LandingColors.border,
              width: 1.5,
            ),
            color: _hovered
                ? LandingColors.primary.withValues(alpha: 0.04)
                : Colors.transparent,
            boxShadow: _hovered
                ? [
                    BoxShadow(
                      color: LandingColors.primary.withValues(alpha: 0.06),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : [],
          ),
          child: Text(
            widget.label,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: _hovered
                  ? LandingColors.primary
                  : LandingColors.textPrimary,
            ),
          ),
        ),
      ),
    );
  }
}

class _PrimaryPillButton extends StatefulWidget {
  const _PrimaryPillButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  State<_PrimaryPillButton> createState() => _PrimaryPillButtonState();
}

class _PrimaryPillButtonState extends State<_PrimaryPillButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutBack,
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
          transform: Matrix4.diagonal3Values(_hovered ? 1.05 : 1.0, _hovered ? 1.05 : 1.0, 1.0),
          transformAlignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            gradient: LinearGradient(
              colors: _hovered
                  ? [LandingColors.primaryDark, LandingColors.primary]
                  : [LandingColors.primary, LandingColors.primaryLight],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: LandingColors.primary.withValues(alpha: _hovered ? 0.4 : 0.18),
                blurRadius: _hovered ? 20 : 10,
                offset: Offset(0, _hovered ? 6 : 3),
              ),
            ],
          ),
          child: Text(
            widget.label,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: LandingColors.textWhite,
            ),
          ),
        ),
      ),
    );
  }
}
