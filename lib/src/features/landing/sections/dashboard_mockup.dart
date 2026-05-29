import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:reservpy/src/features/landing/landing_theme.dart';

/// Fake browser window showing a dashboard preview with floating cards.
class DashboardMockup extends StatelessWidget {
  const DashboardMockup({super.key});

  @override
  Widget build(BuildContext context) {
    final mobile = isMobile(context);
    final desktop = isDesktop(context);

    return Container(
      width: double.infinity,
      color: LandingColors.bgAlt,
      padding: EdgeInsets.symmetric(
        horizontal: mobile ? 16 : 24,
        vertical: mobile ? 40 : 64,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // ── Main browser window ──────────────────────
              Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: desktop ? 860 : double.infinity,
                  ),
                  child: _BrowserWindow(isMobile: mobile),
                ),
              )
                  .animate()
                  .fadeIn(duration: 700.ms)
                  .slideY(begin: 0.08, end: 0, duration: 700.ms),

              // ── Floating cards (desktop only) ────────────
              if (desktop) ...[
                // Left — notification card
                Positioned(
                  left: 0,
                  top: 120,
                  child: _FloatingNotification()
                      .animate(
                        onPlay: (c) => c.repeat(reverse: true),
                      )
                      .moveY(
                        begin: 0,
                        end: -8,
                        duration: 2500.ms,
                        curve: Curves.easeInOut,
                      )
                      .animate()
                      .fadeIn(delay: 400.ms, duration: 600.ms)
                      .slideX(begin: -0.3, end: 0, delay: 400.ms, duration: 600.ms),
                ),
                // Right top — revenue card
                Positioned(
                  right: 0,
                  top: 80,
                  child: _FloatingRevenue()
                      .animate(
                        onPlay: (c) => c.repeat(reverse: true),
                      )
                      .moveY(
                        begin: 0,
                        end: 8,
                        duration: 3000.ms,
                        curve: Curves.easeInOut,
                      )
                      .animate()
                      .fadeIn(delay: 500.ms, duration: 600.ms)
                      .slideX(begin: 0.3, end: 0, delay: 500.ms, duration: 600.ms),
                ),
                // Right bottom — confirmation card
                Positioned(
                  right: 20,
                  bottom: 60,
                  child: _FloatingConfirmation()
                      .animate(
                        onPlay: (c) => c.repeat(reverse: true),
                      )
                      .moveY(
                        begin: 0,
                        end: -6,
                        duration: 2800.ms,
                        curve: Curves.easeInOut,
                      )
                      .animate()
                      .fadeIn(delay: 650.ms, duration: 600.ms)
                      .slideX(begin: 0.3, end: 0, delay: 650.ms, duration: 600.ms),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// BROWSER WINDOW
// ═══════════════════════════════════════════════════════════════════════════════

class _BrowserWindow extends StatelessWidget {
  const _BrowserWindow({required this.isMobile});

  final bool isMobile;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFFFAF7),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.9),
          width: 2.0,
        ),
        boxShadow: [
          // Crisp ambient outline shadow
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
          // Soft medium depth shadow
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
          // Deep wide spread shadow
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 36,
            offset: const Offset(0, 18),
          ),
          // High-end subtle glow shadow utilizing brand primary
          BoxShadow(
            color: LandingColors.primary.withValues(alpha: 0.04),
            blurRadius: 60,
            offset: const Offset(0, 28),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _BrowserChrome(isMobile: isMobile),
            Padding(
              padding: EdgeInsets.all(isMobile ? 16 : 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Greeting ──────────────────────────
                  Text(
                    'Hola, María — Así va tu día en tu negocio',
                    style: GoogleFonts.inter(
                      fontSize: isMobile ? 14 : 17,
                      fontWeight: FontWeight.w700,
                      color: LandingColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ── Stat cards ────────────────────────
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      _MiniStatCard(
                        value: 'Gs. 350.000',
                        label: 'Hoy',
                        badge: '+12%',
                        badgeColor: LandingColors.success,
                        tint: LandingColors.primaryTint,
                        width: isMobile ? double.infinity : null,
                      ),
                      _MiniStatCard(
                        value: '8',
                        label: 'Turnos hoy',
                        badge: '3 confirmados',
                        badgeColor: LandingColors.success,
                        tint: const Color(0xFFECFDF5),
                        width: isMobile ? double.infinity : null,
                      ),
                      _MiniStatCard(
                        value: 'Gs. 2.450.000',
                        label: 'Semana',
                        badge: '+8%',
                        badgeColor: LandingColors.success,
                        tint: const Color(0xFFEFF6FF),
                        width: isMobile ? double.infinity : null,
                      ),
                      _MiniStatCard(
                        value: '12',
                        label: 'Clientes nuevos',
                        badge: 'Este mes',
                        badgeColor: const Color(0xFF3B82F6),
                        tint: const Color(0xFFF5F3FF),
                        width: isMobile ? double.infinity : null,
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // ── Upcoming appointments ─────────────
                  Text(
                    'Próximos turnos',
                    style: GoogleFonts.inter(
                      fontSize: isMobile ? 13 : 15,
                      fontWeight: FontWeight.w700,
                      color: LandingColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const _AppointmentRow(
                    initials: 'MG',
                    name: 'María González',
                    time: '09:00',
                    service: 'Corte y color',
                    price: 'Gs. 85.000',
                    status: 'Confirmado',
                    statusColor: Color(0xFF10B981),
                    avatarColor: LandingColors.primaryTint,
                  ),
                  const SizedBox(height: 8),
                  const _AppointmentRow(
                    initials: 'JL',
                    name: 'Juan López',
                    time: '10:30',
                    service: 'Consulta',
                    price: 'Gs. 60.000',
                    status: 'Pendiente',
                    statusColor: Color(0xFFF59E0B),
                    avatarColor: Color(0xFFEFF6FF),
                  ),
                  const SizedBox(height: 8),
                  const _AppointmentRow(
                    initials: 'AM',
                    name: 'Ana Martínez',
                    time: '11:00',
                    service: 'Tratamiento facial',
                    price: 'Gs. 120.000',
                    status: 'Confirmado',
                    statusColor: Color(0xFF10B981),
                    avatarColor: Color(0xFFECFDF5),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Browser chrome ────────────────────────────────────────────────────────────

class _BrowserChrome extends StatelessWidget {
  const _BrowserChrome({required this.isMobile});

  final bool isMobile;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: Color(0xFFF9FAFB),
        border: Border(
          bottom: BorderSide(color: LandingColors.border),
        ),
      ),
      child: Row(
        children: [
          // Traffic lights
          _dot(const Color(0xFFFF5F56)),
          const SizedBox(width: 6),
          _dot(const Color(0xFFFFBD2E)),
          const SizedBox(width: 6),
          _dot(const Color(0xFF27C93F)),
          const SizedBox(width: 16),
          // URL bar
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: LandingColors.border),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.lock_outline_rounded,
                    size: 12,
                    color: LandingColors.textMuted,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'reservly.com.py/admin/dashboard',
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: isMobile ? 11 : 12,
                        color: LandingColors.textMuted,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _dot(Color c) => Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(color: c, shape: BoxShape.circle),
      );
}

// ── Mini stat card ────────────────────────────────────────────────────────────

class _MiniStatCard extends StatelessWidget {
  const _MiniStatCard({
    required this.value,
    required this.label,
    required this.badge,
    required this.badgeColor,
    required this.tint,
    this.width,
  });

  final String value;
  final String label;
  final String badge;
  final Color badgeColor;
  final Color tint;
  final double? width;

  @override
  Widget build(BuildContext context) {
    final card = Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: tint,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: LandingColors.border.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: LandingColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: LandingColors.textSecondary,
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: badgeColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  badge,
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: badgeColor,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );

    if (width != null) {
      return SizedBox(width: width, child: card);
    }
    return card;
  }
}

// ── Appointment row ───────────────────────────────────────────────────────────

class _AppointmentRow extends StatelessWidget {
  const _AppointmentRow({
    required this.initials,
    required this.name,
    required this.time,
    required this.service,
    required this.price,
    required this.status,
    required this.statusColor,
    required this.avatarColor,
  });

  final String initials;
  final String name;
  final String time;
  final String service;
  final String price;
  final String status;
  final Color statusColor;
  final Color avatarColor;

  @override
  Widget build(BuildContext context) {
    final mobile = isMobile(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: LandingColors.border),
      ),
      child: mobile ? _buildMobileRow() : _buildDesktopRow(),
    );
  }

  Widget _buildDesktopRow() {
    return Row(
      children: [
        // Avatar
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: avatarColor,
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Text(
            initials,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: LandingColors.textPrimary,
            ),
          ),
        ),
        const SizedBox(width: 10),
        // Name
        SizedBox(
          width: 130,
          child: Text(
            name,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: LandingColors.textPrimary,
            ),
          ),
        ),
        const SizedBox(width: 8),
        // Time
        Text(
          time,
          style: GoogleFonts.inter(
            fontSize: 13,
            color: LandingColors.textSecondary,
          ),
        ),
        const SizedBox(width: 12),
        // Service
        Expanded(
          child: Text(
            service,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: LandingColors.textSecondary,
            ),
          ),
        ),
        // Price
        Text(
          price,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: LandingColors.textPrimary,
          ),
        ),
        const SizedBox(width: 12),
        // Status badge
        _statusBadge(),
      ],
    );
  }

  Widget _buildMobileRow() {
    return Row(
      children: [
        // Avatar
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: avatarColor,
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Text(
            initials,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: LandingColors.textPrimary,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$name · $time',
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: LandingColors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '$service — $price',
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: LandingColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        _statusBadge(),
      ],
    );
  }

  Widget _statusBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        status,
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: statusColor,
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// FLOATING CARDS
// ═══════════════════════════════════════════════════════════════════════════════

class _FloatingNotification extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 200,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: LandingColors.border),
        boxShadow: const [
          BoxShadow(
            color: LandingColors.shadowLight,
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: const BoxDecoration(
              color: LandingColors.primaryTint,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.notifications_active_rounded,
              size: 18,
              color: LandingColors.primary,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Nueva reserva',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: LandingColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Hace 2 min',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    color: LandingColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FloatingRevenue extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 190,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: LandingColors.border),
        boxShadow: const [
          BoxShadow(
            color: LandingColors.shadowLight,
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Gs. 2.450.000',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: LandingColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Text(
                'Esta semana',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: LandingColors.textSecondary,
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: LandingColors.successBg,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '+8%',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: LandingColors.success,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FloatingConfirmation extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 210,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: LandingColors.border),
        boxShadow: const [
          BoxShadow(
            color: LandingColors.shadowLight,
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: const BoxDecoration(
              color: Color(0xFFECFDF5),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_rounded,
              size: 18,
              color: LandingColors.success,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '¡Confirmado!',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: LandingColors.success,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Juan López 10:30 hs',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: LandingColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
