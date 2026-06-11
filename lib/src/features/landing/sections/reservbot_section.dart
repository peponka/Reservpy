import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:reservpy/src/features/landing/landing_theme.dart';

class ReservbotSection extends StatefulWidget {
  const ReservbotSection({super.key});

  @override
  State<ReservbotSection> createState() => _ReservbotSectionState();
}

class _ReservbotSectionState extends State<ReservbotSection> {
  @override
  Widget build(BuildContext context) {
    final desktop = isDesktop(context);
    final mobile = isMobile(context);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            LandingColors.primaryTint,
            LandingColors.bgWhite,
            LandingColors.bgAlt,
          ],
        ),
      ),
      padding: EdgeInsets.symmetric(
        vertical: mobile ? 64 : 96,
        horizontal: mobile ? 16 : 24,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Container(
            padding: EdgeInsets.all(mobile ? 20 : 40),
            decoration: BoxDecoration(
              color: LandingColors.bgWhite.withValues(alpha: 0.85),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: LandingColors.border),
              boxShadow: const [
                BoxShadow(
                  color: LandingColors.shadowLight,
                  blurRadius: 40,
                  offset: Offset(0, 12),
                ),
              ],
            ),
            child: desktop
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 5, child: _buildLeftColumn(mobile)),
                      const SizedBox(width: 40),
                      Expanded(flex: 6, child: _buildChatMockup(mobile)),
                    ],
                  )
                : Column(
                    children: [
                      _buildLeftColumn(mobile),
                      const SizedBox(height: 32),
                      _buildChatMockup(mobile),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildLeftColumn(bool mobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
          decoration: BoxDecoration(
            color: LandingColors.primaryTint,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            'NUEVO EN PRO',
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: LandingColors.primary,
              letterSpacing: 1.2,
            ),
          ),
        ).animate().fadeIn(duration: 400.ms).slideX(begin: -0.15, end: 0),
        const SizedBox(height: 16),
        // Title
        Text(
          'Reservbot entiende tu agenda y te ayuda a operar más rápido',
          style: GoogleFonts.plusJakartaSans(
            fontSize: mobile ? 26 : 34,
            fontWeight: FontWeight.w800,
            color: LandingColors.textPrimary,
            height: 1.2,
          ),
        ).animate().fadeIn(duration: 500.ms, delay: 100.ms).slideY(begin: 0.1),
        const SizedBox(height: 14),
        Text(
          'Tu asistente virtual con IA integrado en el panel de ReservPy. '
          'Consultá turnos, detectá huecos y ejecutá acciones con lenguaje natural.',
          style: GoogleFonts.inter(
            fontSize: 15,
            color: LandingColors.textSecondary,
            height: 1.7,
          ),
        ).animate().fadeIn(duration: 500.ms, delay: 200.ms),
        const SizedBox(height: 24),
        // Feature mini-cards 2x2
        _buildFeatureGrid(mobile),
        const SizedBox(height: 28),
        // CTAs
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _OrangeCta(label: 'Probar ReservPy'),
            _OutlineCta(label: 'Ver plan Pro'),
          ],
        ).animate().fadeIn(duration: 400.ms, delay: 600.ms),
      ],
    );
  }

  Widget _buildFeatureGrid(bool mobile) {
    final features = [
      _BotFeature(Icons.event_available_rounded, 'Agenda del día'),
      _BotFeature(Icons.groups_outlined, 'Turnos por empleado'),
      _BotFeature(Icons.schedule_outlined, 'Pendientes y huecos'),
      _BotFeature(Icons.verified_user_outlined, 'Acciones con confirmación'),
    ];

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: mobile ? 2.8 : 3.0,
      children: List.generate(features.length, (i) {
        final f = features[i];
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: LandingColors.bgAlt,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: LandingColors.border),
          ),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: LandingColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(f.icon, size: 16, color: LandingColors.primary),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  f.label,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: LandingColors.textPrimary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        )
            .animate()
            .fadeIn(duration: 400.ms, delay: (350 + i * 80).ms)
            .slideY(begin: 0.12, end: 0);
      }),
    );
  }

  Widget _buildChatMockup(bool mobile) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0A0A0B),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF2A2A2E)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x40000000),
            blurRadius: 30,
            offset: Offset(0, 10),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // Browser bar
          _buildBrowserBar(),
          // Content area
          Container(
            color: const Color(0xFF111113),
            child: mobile
                ? Column(
                    children: [
                      _buildAgendaPanel(),
                      const Divider(
                          height: 1, color: Color(0xFF2A2A2E)),
                      _buildChatPanel(),
                    ],
                  )
                : IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SizedBox(width: 200, child: _buildAgendaPanel()),
                        const VerticalDivider(
                            width: 1, color: Color(0xFF2A2A2E)),
                        Expanded(child: _buildChatPanel()),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 600.ms, delay: 300.ms).slideY(begin: 0.1);
  }

  Widget _buildBrowserBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: const BoxDecoration(
        color: Color(0xFF18181B),
        border: Border(bottom: BorderSide(color: Color(0xFF2A2A2E))),
      ),
      child: Row(
        children: [
          // Dots
          Row(
            children: [
              _dot(const Color(0xFFFF5F57)),
              const SizedBox(width: 6),
              _dot(const Color(0xFFFFBD2E)),
              const SizedBox(width: 6),
              _dot(const Color(0xFF28C840)),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xFF0A0A0B),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'reservpy.com/admin',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: const Color(0xFF71717A),
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: LandingColors.primary.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              'Demo',
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: LandingColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _dot(Color color) {
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }

  Widget _buildAgendaPanel() {
    final appointments = [
      _Appointment('10:00', 'Corte clásico', 'Carlos M.'),
      _Appointment('12:00', 'Barba completa', 'Juan P.'),
      _Appointment('15:00', 'Tratamiento capilar', 'Martina L.'),
      _Appointment('17:30', 'Color + Corte', 'Lucía R.'),
    ];

    return Container(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Agenda del negocio',
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 10),
          ...List.generate(appointments.length, (i) {
            final a = appointments[i];
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E22),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF2A2A2E)),
                ),
                child: Row(
                  children: [
                    Text(
                      a.time,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: LandingColors.primary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            a.service,
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            a.client,
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              color: const Color(0xFF71717A),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            )
                .animate()
                .fadeIn(duration: 300.ms, delay: (400 + i * 100).ms)
                .slideX(begin: -0.1, end: 0);
          }),
        ],
      ),
    );
  }

  Widget _buildChatPanel() {
    final messages = <_ChatMsg>[
      _ChatMsg(
        text: 'Reservbot, que turnos tengo hoy?',
        isUser: true,
        delay: 500,
      ),
      _ChatMsg(
        text:
            'Tenés 4 turnos: 10:00 Corte, 12:00 Barba, 15:00 Tratamiento y 17:30 Color.',
        isUser: false,
        delay: 1000,
      ),
      _ChatMsg(
        text: 'Cancelame el de las 15.',
        isUser: true,
        delay: 1600,
      ),
      _ChatMsg(
        text: 'Necesito tu confirmación antes de cancelar el turno.',
        isUser: false,
        delay: 2200,
      ),
    ];

    return Container(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [LandingColors.primary, LandingColors.primaryLight],
                  ),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(Icons.smart_toy_outlined,
                    size: 14, color: Colors.white),
              ),
              const SizedBox(width: 8),
              Text(
                'Reservbot',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 6),
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: Color(0xFF22C55E),
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Flexible(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  ...messages.map((m) => _buildBubble(m)),
                  // Action card
                  _buildActionCard(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBubble(_ChatMsg msg) {
    return Align(
      alignment: msg.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        constraints: const BoxConstraints(maxWidth: 280),
        decoration: BoxDecoration(
          color: msg.isUser
              ? LandingColors.primary
              : const Color(0xFF27272A),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(14),
            topRight: const Radius.circular(14),
            bottomLeft: Radius.circular(msg.isUser ? 14 : 4),
            bottomRight: Radius.circular(msg.isUser ? 4 : 14),
          ),
        ),
        child: Text(
          msg.text,
          style: GoogleFonts.inter(
            fontSize: 12,
            color: Colors.white,
            height: 1.5,
          ),
        ),
      ),
    )
        .animate()
        .fadeIn(duration: 400.ms, delay: msg.delay.ms)
        .slideY(begin: 0.2, end: 0);
  }

  Widget _buildActionCard() {
    return Container(
      margin: const EdgeInsets.only(top: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF7F1D1D).withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFEF4444).withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Confirmar acción',
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: const Color(0xFFFCA5A5),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Cancelar turno de Martina a las 15:00',
            style: GoogleFonts.inter(
              fontSize: 12,
              color: Colors.white70,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            decoration: BoxDecoration(
              color: const Color(0xFFDC2626),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'Confirmar cancelación',
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(duration: 500.ms, delay: 2800.ms)
        .slideY(begin: 0.15, end: 0)
        .then()
        .shimmer(duration: 800.ms, color: Colors.white24);
  }
}

// ── Data Classes ──

class _BotFeature {
  final IconData icon;
  final String label;
  const _BotFeature(this.icon, this.label);
}

class _Appointment {
  final String time;
  final String service;
  final String client;
  const _Appointment(this.time, this.service, this.client);
}

class _ChatMsg {
  final String text;
  final bool isUser;
  final int delay;
  const _ChatMsg({
    required this.text,
    required this.isUser,
    required this.delay,
  });
}

// ── CTA Buttons ──

class _OrangeCta extends StatefulWidget {
  final String label;
  const _OrangeCta({required this.label});

  @override
  State<_OrangeCta> createState() => _OrangeCtaState();
}

class _OrangeCtaState extends State<_OrangeCta> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 13),
        decoration: BoxDecoration(
          color: _hovered ? LandingColors.primaryDark : LandingColors.primary,
          borderRadius: BorderRadius.circular(999),
          boxShadow: _hovered
              ? const [
                  BoxShadow(
                    color: LandingColors.shadowPrimary,
                    blurRadius: 20,
                    offset: Offset(0, 6),
                  )
                ]
              : [],
        ),
        child: Text(
          widget.label,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

class _OutlineCta extends StatefulWidget {
  final String label;
  const _OutlineCta({required this.label});

  @override
  State<_OutlineCta> createState() => _OutlineCtaState();
}

class _OutlineCtaState extends State<_OutlineCta> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 13),
        decoration: BoxDecoration(
          color: _hovered
              ? LandingColors.primary.withValues(alpha: 0.06)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: LandingColors.border, width: 1.5),
        ),
        child: Text(
          widget.label,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: LandingColors.textPrimary,
          ),
        ),
      ),
    );
  }
}
