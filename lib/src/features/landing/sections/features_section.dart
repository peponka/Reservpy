import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:reservpy/src/features/landing/landing_theme.dart';

class FeaturesSection extends StatelessWidget {
  const FeaturesSection({super.key});

  @override
  Widget build(BuildContext context) {
    final desktop = isDesktop(context);
    final mobile = isMobile(context);

    return Container(
      width: double.infinity,
      color: LandingColors.bgWhite,
      padding: EdgeInsets.symmetric(
        vertical: mobile ? 64 : 96,
        horizontal: mobile ? 16 : 24,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Column(
            children: [
              // ── Badge ──
              _buildBadge()
                  .animate()
                  .fadeIn(duration: 500.ms)
                  .slideY(begin: 0.2, end: 0),
              const SizedBox(height: 16),
              // ── Title ──
              _buildTitle(mobile)
                  .animate()
                  .fadeIn(duration: 500.ms, delay: 100.ms)
                  .slideY(begin: 0.2, end: 0),
              const SizedBox(height: 48),
              // ── Big Cards ──
              _buildBigCards(desktop, mobile),
              const SizedBox(height: 32),
              // ── Small Cards ──
              _buildSmallCards(desktop, mobile),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: LandingColors.primaryTint,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: LandingColors.primary.withValues(alpha: 0.25),
          width: 1.2,
        ),
      ),
      child: Text(
        'FUNCIONALIDADES',
        style: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: LandingColors.primary,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildTitle(bool mobile) {
    return RichText(
      textAlign: TextAlign.center,
      text: TextSpan(
        style: GoogleFonts.inter(
          fontSize: mobile ? 28 : 40,
          fontWeight: FontWeight.w800,
          color: LandingColors.textPrimary,
          height: 1.2,
        ),
        children: [
          const TextSpan(text: 'Todo lo que tu negocio\nnecesita para '),
          TextSpan(
            text: 'crecer en Paraguay',
            style: TextStyle(
              foreground: Paint()
                ..shader = const LinearGradient(
                  colors: [LandingColors.primary, LandingColors.primaryLight],
                ).createShader(const Rect.fromLTWH(0, 0, 300, 50)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBigCards(bool desktop, bool mobile) {
    final cards = [
      _BigCardData(
        title: 'Panel de control centralizado',
        description:
            'Visualizá todos los turnos, ingresos y métricas en un solo lugar. '
            'Como tener un gerente digital para tu negocio paraguayo.',
        gradient: [
          LandingColors.primary.withValues(alpha: 0.08),
          LandingColors.bgWhite,
        ],
        child: _buildStatsRow(),
      ),
      _BigCardData(
        title: 'Trabajo en equipo',
        description:
            'Asigná turnos a cada integrante de tu equipo. '
            'Ideal para peluquerías, barberías y consultorios con varios profesionales.',
        gradient: [
          const Color(0xFF6366F1).withValues(alpha: 0.08),
          LandingColors.bgWhite,
        ],
        child: _buildEmployeeRows(),
      ),
    ];

    if (desktop) {
      return IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: _HoverBigCard(data: cards[0])
                  .animate()
                  .fadeIn(duration: 500.ms, delay: 200.ms)
                  .slideY(begin: 0.15, end: 0),
            ),
            const SizedBox(width: 24),
            Expanded(
              child: _HoverBigCard(data: cards[1])
                  .animate()
                  .fadeIn(duration: 500.ms, delay: 350.ms)
                  .slideY(begin: 0.15, end: 0),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        _HoverBigCard(data: cards[0])
            .animate()
            .fadeIn(duration: 500.ms, delay: 200.ms)
            .slideY(begin: 0.15, end: 0),
        const SizedBox(height: 20),
        _HoverBigCard(data: cards[1])
            .animate()
            .fadeIn(duration: 500.ms, delay: 350.ms)
            .slideY(begin: 0.15, end: 0),
      ],
    );
  }

  Widget _buildStatsRow() {
    final stats = [
      _MiniStat('8', 'Hoy', const Color(0xFF3B82F6)),
      _MiniStat('34', 'Semana', const Color(0xFF10B981)),
      _MiniStat('Gs. 980k', 'Ingresos', LandingColors.primary),
    ];
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: stats.map((s) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: s.color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: s.color.withValues(alpha: 0.2)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                s.value,
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: s.color,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                s.label,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: LandingColors.textSecondary,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildEmployeeRows() {
    final employees = [
      _Employee('S', 'Sofía R.', 'Estilista', '5 turnos hoy',
          const Color(0xFFEC4899)),
      _Employee('M', 'Martín G.', 'Barbero', '3 turnos hoy',
          const Color(0xFF6366F1)),
    ];
    return Column(
      children: employees.map((e) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: LandingColors.bgWhite,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: LandingColors.border),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: e.color.withValues(alpha: 0.15),
                  child: Text(
                    e.initial,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: e.color,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        e.name,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: LandingColors.textPrimary,
                        ),
                      ),
                      Text(
                        e.role,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: LandingColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: e.color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    e.turnoCount,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: e.color,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSmallCards(bool desktop, bool mobile) {
    final items = [
      _SmallFeature(
        icon: Icons.notifications_active_outlined,
        title: 'Emails automáticos',
        description:
            'Recordatorios y confirmaciones enviados sin que hagas nada.',
        gradientColors: [const Color(0xFFF59E0B), const Color(0xFFD97706)],
      ),
      _SmallFeature(
        icon: Icons.shield_outlined,
        title: 'Política de cancelación',
        description:
            'Definí reglas claras para reducir cancelaciones de último momento.',
        gradientColors: [const Color(0xFFEF4444), const Color(0xFFDC2626)],
      ),
      _SmallFeature(
        icon: Icons.bar_chart_rounded,
        title: 'Reportes y métricas',
        description:
            'Analizá tus ingresos, turnos y rendimiento del equipo en tiempo real.',
        gradientColors: [const Color(0xFF10B981), const Color(0xFF059669)],
      ),
      _SmallFeature(
        icon: Icons.phone_iphone_rounded,
        title: '100% mobile',
        description:
            'Tu agenda y la de tus clientes funcionan perfecto desde el celular.',
        gradientColors: [const Color(0xFF8B5CF6), const Color(0xFF7C3AED)],
      ),
    ];

    final crossCount = desktop ? 4 : 2;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossCount,
        mainAxisSpacing: 20,
        crossAxisSpacing: 20,
        childAspectRatio: desktop ? 1.05 : (mobile ? 0.95 : 1.1),
      ),
      itemCount: items.length,
      itemBuilder: (context, i) {
        return _HoverSmallCard(feature: items[i])
            .animate()
            .fadeIn(duration: 500.ms, delay: (400 + i * 100).ms)
            .slideY(begin: 0.15, end: 0);
      },
    );
  }
}

// ── Data Classes ──────────────────────────────────────

class _BigCardData {
  final String title;
  final String description;
  final List<Color> gradient;
  final Widget child;

  const _BigCardData({
    required this.title,
    required this.description,
    required this.gradient,
    required this.child,
  });
}

class _MiniStat {
  final String value;
  final String label;
  final Color color;
  const _MiniStat(this.value, this.label, this.color);
}

class _Employee {
  final String initial;
  final String name;
  final String role;
  final String turnoCount;
  final Color color;
  const _Employee(
      this.initial, this.name, this.role, this.turnoCount, this.color);
}

class _SmallFeature {
  final IconData icon;
  final String title;
  final String description;
  final List<Color> gradientColors;
  const _SmallFeature({
    required this.icon,
    required this.title,
    required this.description,
    required this.gradientColors,
  });
}

// ── Hover Big Card ──────────────────────────────────────

class _HoverBigCard extends StatefulWidget {
  final _BigCardData data;
  const _HoverBigCard({required this.data});

  @override
  State<_HoverBigCard> createState() => _HoverBigCardState();
}

class _HoverBigCardState extends State<_HoverBigCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
        transform: Matrix4.translationValues(0, _hovered ? -6 : 0, 0),
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: widget.data.gradient,
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: _hovered
                ? LandingColors.primary.withValues(alpha: 0.5)
                : LandingColors.border,
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: _hovered
                  ? LandingColors.primary.withValues(alpha: 0.12)
                  : LandingColors.shadowLight,
              blurRadius: _hovered ? 32 : 12,
              offset: Offset(0, _hovered ? 12 : 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.data.title,
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: LandingColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.data.description,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: LandingColors.textSecondary,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 20),
            widget.data.child,
          ],
        ),
      ),
    );
  }
}

// ── Hover Small Card ──────────────────────────────────────

class _HoverSmallCard extends StatefulWidget {
  final _SmallFeature feature;
  const _HoverSmallCard({required this.feature});

  @override
  State<_HoverSmallCard> createState() => _HoverSmallCardState();
}

class _HoverSmallCardState extends State<_HoverSmallCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
        transform: Matrix4.translationValues(0, _hovered ? -4 : 0, 0),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: LandingColors.bgWhite,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _hovered
                ? LandingColors.primary.withValues(alpha: 0.4)
                : LandingColors.border,
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: _hovered
                  ? LandingColors.primary.withValues(alpha: 0.08)
                  : LandingColors.shadowLight,
              blurRadius: _hovered ? 24 : 8,
              offset: Offset(0, _hovered ? 8 : 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: widget.feature.gradientColors,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                widget.feature.icon,
                color: Colors.white,
                size: 22,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              widget.feature.title,
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: LandingColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              widget.feature.description,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: LandingColors.textSecondary,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
