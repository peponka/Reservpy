import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:reservpy/src/core/constants/app_sizes.dart';
import 'package:reservpy/src/core/constants/app_colors.dart';
import 'package:reservpy/src/shared/providers/providers.dart';
import 'package:reservpy/src/shared/models/models.dart';

/// Premium business detail / service selection page.
/// Standalone Scaffold — NOT rendered inside BusinessShell.
class SelectServiceScreen extends ConsumerStatefulWidget {
  final String businessId;

  const SelectServiceScreen({super.key, required this.businessId});

  @override
  ConsumerState<SelectServiceScreen> createState() =>
      _SelectServiceScreenState();
}

class _SelectServiceScreenState extends ConsumerState<SelectServiceScreen> {
  String get businessId => widget.businessId;

  /// Servicios elegidos por el cliente (selección múltiple).
  final Set<String> _selectedIds = {};

  final GlobalKey servicesKey = GlobalKey();

  void _toggleService(String id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
      } else {
        _selectedIds.add(id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final services = ref.watch(businessServicesProvider(businessId)).valueOrNull ?? [];
    final businesses = ref.watch(businessesProvider).valueOrNull ?? [];
    final business = businesses.where((b) => b.id == businessId).firstOrNull;
    final businessName = business?.name ?? 'Negocio';

    // Resumen de la selección (en orden de lista, no de clic)
    final selectedServices =
        services.where((s) => _selectedIds.contains(s.id)).toList();
    final totalMinutes = selectedServices.fold<int>(
        0, (sum, s) => sum + s.durationMinutes);
    final totalPrice =
        selectedServices.fold<double>(0, (sum, s) => sum + (s.price ?? 0));

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      bottomNavigationBar: selectedServices.isEmpty
          ? null
          : _SelectionSummaryBar(
              count: selectedServices.length,
              totalMinutes: totalMinutes,
              totalPrice: totalPrice,
              onContinue: () {
                final ids =
                    selectedServices.map((s) => s.id).join(',');
                context.push('/reserve/$businessId/time/$ids');
              },
            ),
      body: CustomScrollView(
        slivers: [
          // ── App Bar ──────────────────────────────────────────
          _PremiumAppBar(
            businessName: businessName,
            onReservarTap: () {
              final ctx = servicesKey.currentContext;
              if (ctx != null) {
                Scrollable.ensureVisible(ctx,
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.easeInOut);
              }
            },
          ),

          // ── Body ─────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1100),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.s24,
                    vertical: AppSizes.s32,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Gallery Placeholder ──────────────
                      _GalleryPlaceholder(),

                      const SizedBox(height: AppSizes.s32),

                      // ── Services Section ─────────────────
                      _ServicesSection(
                        key: servicesKey,
                        services: services,
                        businessId: businessId,
                        selectedIds: _selectedIds,
                        onToggle: _toggleService,
                      ),

                      const SizedBox(height: AppSizes.s48),

                      // ── Business Info ────────────────────
                      _BusinessInfoSections(
                        business: business,
                        serviceCount: services.length,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// APP BAR
// ═══════════════════════════════════════════════════════════════
class _PremiumAppBar extends StatelessWidget {
  final String businessName;
  final VoidCallback onReservarTap;

  const _PremiumAppBar({
    required this.businessName,
    required this.onReservarTap,
  });

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.accent, Color(0xFF132F4C)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSizes.s24, AppSizes.s16, AppSizes.s24, AppSizes.s32,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top row: back + breadcrumb + CTA
                Row(
                  children: [
                    // Back button
                    _CircleIconButton(
                      icon: Icons.arrow_back_rounded,
                      onTap: () => context.pop(),
                    ),
                    const SizedBox(width: AppSizes.s12),
                    // Breadcrumb
                    Expanded(
                      child: Text(
                        'Inicio  ›  Reservas  ›  $businessName',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: Colors.white.withValues(alpha: 0.6),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: AppSizes.s12),
                    // CTA button
                    Material(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(AppSizes.radiusFull),
                      child: InkWell(
                        onTap: onReservarTap,
                        borderRadius: BorderRadius.circular(AppSizes.radiusFull),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSizes.s20,
                            vertical: AppSizes.s12,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Reservar ahora',
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(width: AppSizes.s6),
                              const Icon(Icons.arrow_forward_rounded,
                                  size: 16, color: Colors.white),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: AppSizes.s24),

                // Green label
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.s12,
                    vertical: AppSizes.s4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(AppSizes.radiusFull),
                  ),
                  child: Text(
                    'RESERVAR EN',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),

                const SizedBox(height: AppSizes.s8),

                // Business name
                Text(
                  businessName,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    height: 1.1,
                  ),
                ),

                const SizedBox(height: AppSizes.s12),

                // Rating + badge row
                Row(
                  children: [
                    // Stars
                    ...List.generate(
                      5,
                      (i) => Icon(
                        i < 4 ? Icons.star_rounded : Icons.star_border_rounded,
                        size: 18,
                        color: const Color(0xFFFFC107),
                      ),
                    ),
                    const SizedBox(width: AppSizes.s8),
                    Text(
                      '4.0',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                    ),
                    const SizedBox(width: AppSizes.s16),
                    // Badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSizes.s12,
                        vertical: AppSizes.s4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.15),
                        borderRadius:
                            BorderRadius.circular(AppSizes.radiusFull),
                        border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: AppSizes.s6),
                          Text(
                            'Aceptando reservas',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _CircleIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.1),
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.s8),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// GALLERY PLACEHOLDER
// ═══════════════════════════════════════════════════════════════
class _GalleryPlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSizes.s32),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppSizes.radiusXl),
        gradient: const LinearGradient(
          colors: [Color(0xFF0A2540), Color(0xFF1A3A5C)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.accent.withValues(alpha: 0.25),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppSizes.radiusLg),
            ),
            child: const Icon(
              Icons.photo_library_rounded,
              size: 32,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: AppSizes.s16),
          Text(
            'Galería pendiente',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: AppSizes.s8),
          Text(
            'Subí fotos desde Configuración para destacar el negocio',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: Colors.white.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// SERVICES SECTION
// ═══════════════════════════════════════════════════════════════
class _ServicesSection extends StatelessWidget {
  final List<ServiceModel> services;
  final String businessId;
  final Set<String> selectedIds;
  final ValueChanged<String> onToggle;

  const _ServicesSection({
    super.key,
    required this.services,
    required this.businessId,
    required this.selectedIds,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section title
        Text(
          'Servicios',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 26,
            fontWeight: FontWeight.w800,
            color: AppColors.accent,
          ),
        ),
        const SizedBox(height: AppSizes.s4),
        Text(
          'Elegí uno o más servicios y después continuá al calendario',
          style: GoogleFonts.inter(
            fontSize: 15,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: AppSizes.s24),

        // Content: services list + sidebar
        LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth > 720;
            if (isWide) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Service cards
                  Expanded(
                    flex: 3,
                    child: services.isEmpty
                        ? _EmptyServicesState()
                        : _ServiceCardsList(
                            services: services,
                            selectedIds: selectedIds,
                            onToggle: onToggle),
                  ),
                  const SizedBox(width: AppSizes.s24),
                  // Sidebar
                  Expanded(
                    flex: 2,
                    child: _HowItWorksSidebar(),
                  ),
                ],
              );
            }
            // Narrow layout: stacked
            return Column(
              children: [
                services.isEmpty
                    ? _EmptyServicesState()
                    : _ServiceCardsList(
                        services: services,
                        selectedIds: selectedIds,
                        onToggle: onToggle),
                const SizedBox(height: AppSizes.s24),
                _HowItWorksSidebar(),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _ServiceCardsList extends StatelessWidget {
  final List<ServiceModel> services;
  final Set<String> selectedIds;
  final ValueChanged<String> onToggle;

  const _ServiceCardsList({
    required this.services,
    required this.selectedIds,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: services.map((service) {
        return Padding(
          padding: const EdgeInsets.only(bottom: AppSizes.s16),
          child: _PremiumServiceCard(
            service: service,
            isSelected: selectedIds.contains(service.id),
            onSelect: () => onToggle(service.id),
          ),
        );
      }).toList(),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// SELECTION SUMMARY BAR (selección múltiple de servicios)
// ═══════════════════════════════════════════════════════════════
class _SelectionSummaryBar extends StatelessWidget {
  final int count;
  final int totalMinutes;
  final double totalPrice;
  final VoidCallback onContinue;

  const _SelectionSummaryBar({
    required this.count,
    required this.totalMinutes,
    required this.totalPrice,
    required this.onContinue,
  });

  String get _formattedPrice {
    final parts = totalPrice.toStringAsFixed(0).split('');
    final buffer = StringBuffer();
    var c = 0;
    for (var i = parts.length - 1; i >= 0; i--) {
      buffer.write(parts[i]);
      c++;
      if (c % 3 == 0 && i > 0) buffer.write('.');
    }
    return '${buffer.toString().split('').reversed.join('')} Gs.';
  }

  String get _formattedDuration {
    if (totalMinutes < 60) return '$totalMinutes min';
    final h = totalMinutes ~/ 60;
    final m = totalMinutes % 60;
    return m == 0 ? '${h}h' : '${h}h $m min';
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSizes.s24, vertical: AppSizes.s12),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(
            top: BorderSide(color: AppColors.divider),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    count == 1
                        ? '1 servicio elegido'
                        : '$count servicios elegidos',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$_formattedPrice · $_formattedDuration',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppColors.accent,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSizes.s16),
            SizedBox(
              height: 48,
              child: FilledButton.icon(
                onPressed: onContinue,
                icon: const Icon(Icons.calendar_month_rounded, size: 18),
                label: Text(
                  'Continuar',
                  style: GoogleFonts.inter(
                      fontSize: 15, fontWeight: FontWeight.w700),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: AppSizes.s24),
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(AppSizes.radiusFull),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// PREMIUM SERVICE CARD
// ═══════════════════════════════════════════════════════════════
class _PremiumServiceCard extends StatefulWidget {
  final ServiceModel service;
  final bool isSelected;
  final VoidCallback onSelect;

  const _PremiumServiceCard({
    required this.service,
    required this.isSelected,
    required this.onSelect,
  });

  @override
  State<_PremiumServiceCard> createState() => _PremiumServiceCardState();
}

class _PremiumServiceCardState extends State<_PremiumServiceCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final service = widget.service;
    final selected = widget.isSelected;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: AppSizes.animNormal),
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary.withValues(alpha: 0.04)
              : Colors.white,
          borderRadius: BorderRadius.circular(AppSizes.radiusLg),
          border: Border.all(
            color: selected
                ? AppColors.primary
                : _hovered
                    ? AppColors.primary.withValues(alpha: 0.4)
                    : AppColors.divider,
            width: selected ? 1.8 : (_hovered ? 1.5 : 1),
          ),
          boxShadow: [
            BoxShadow(
              color: (selected || _hovered)
                  ? AppColors.primary.withValues(alpha: 0.1)
                  : Colors.black.withValues(alpha: 0.04),
              blurRadius: (selected || _hovered) ? 16 : 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onSelect,
            borderRadius: BorderRadius.circular(AppSizes.radiusLg),
            child: Padding(
              padding: const EdgeInsets.all(AppSizes.s20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top row: icon + name + price
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Icon
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppColors.primary.withValues(alpha: 0.15),
                              AppColors.primary.withValues(alpha: 0.05),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius:
                              BorderRadius.circular(AppSizes.radiusMd),
                        ),
                        child: const Icon(
                          Icons.spa_rounded,
                          color: AppColors.primary,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: AppSizes.s16),
                      // Name + duration
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              service.name,
                              style: GoogleFonts.inter(
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                                color: AppColors.accent,
                              ),
                            ),
                            const SizedBox(height: AppSizes.s4),
                            Row(
                              children: [
                                Icon(
                                  Icons.schedule_rounded,
                                  size: 14,
                                  color: AppColors.textSecondary,
                                ),
                                const SizedBox(width: AppSizes.s4),
                                Text(
                                  service.formattedDuration,
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      // Price
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSizes.s16,
                          vertical: AppSizes.s8,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.08),
                          borderRadius:
                              BorderRadius.circular(AppSizes.radiusFull),
                        ),
                        child: Text(
                          service.formattedPrice,
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primaryDark,
                          ),
                        ),
                      ),
                    ],
                  ),

                  // Description
                  if (service.description != null &&
                      service.description!.isNotEmpty) ...[
                    const SizedBox(height: AppSizes.s12),
                    Padding(
                      padding:
                          const EdgeInsets.only(left: 64), // align with text
                      child: Text(
                        service.description!,
                        style: GoogleFonts.inter(
                          fontSize: 13.5,
                          color: AppColors.textSecondary,
                          height: 1.5,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],

                  const SizedBox(height: AppSizes.s16),

                  // Select button
                  Align(
                    alignment: Alignment.centerRight,
                    child: Material(
                      color: (selected || _hovered)
                          ? AppColors.primary
                          : Colors.transparent,
                      borderRadius:
                          BorderRadius.circular(AppSizes.radiusFull),
                      child: InkWell(
                        onTap: widget.onSelect,
                        borderRadius:
                            BorderRadius.circular(AppSizes.radiusFull),
                        child: AnimatedContainer(
                          duration: const Duration(
                              milliseconds: AppSizes.animFast),
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSizes.s20,
                            vertical: AppSizes.s12,
                          ),
                          decoration: BoxDecoration(
                            borderRadius:
                                BorderRadius.circular(AppSizes.radiusFull),
                            border: Border.all(
                              color: (selected || _hovered)
                                  ? AppColors.primary
                                  : AppColors.primary.withValues(alpha: 0.4),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                selected ? 'Agregado' : 'Seleccionar',
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: (selected || _hovered)
                                      ? Colors.white
                                      : AppColors.primary,
                                ),
                              ),
                              const SizedBox(width: AppSizes.s6),
                              Icon(
                                selected
                                    ? Icons.check_rounded
                                    : Icons.add_rounded,
                                size: 16,
                                color: (selected || _hovered)
                                    ? Colors.white
                                    : AppColors.primary,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// EMPTY SERVICES STATE
// ═══════════════════════════════════════════════════════════════
class _EmptyServicesState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.s32,
        vertical: AppSizes.s48,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        border: Border.all(
          color: AppColors.divider,
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppColors.textSecondary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(AppSizes.radiusLg),
            ),
            child: const Icon(
              Icons.description_outlined,
              size: 32,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSizes.s16),
          Text(
            'Este negocio no tiene servicios\ndisponibles aún.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 15,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// HOW IT WORKS SIDEBAR
// ═══════════════════════════════════════════════════════════════
class _HowItWorksSidebar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.s24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        border: Border.all(
          color: AppColors.divider,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSizes.s12,
              vertical: AppSizes.s4,
            ),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(AppSizes.radiusFull),
            ),
            child: Text(
              '¿CÓMO FUNCIONA?',
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.primaryDark,
                letterSpacing: 0.8,
              ),
            ),
          ),
          const SizedBox(height: AppSizes.s24),

          _StepItem(
            number: '1',
            title: 'Elegí el servicio',
            subtitle: 'Seleccioná lo que necesitás',
          ),
          const SizedBox(height: AppSizes.s20),
          _StepItem(
            number: '2',
            title: 'Elegí fecha y hora',
            subtitle: 'Mirá la disponibilidad real',
          ),
          const SizedBox(height: AppSizes.s20),
          _StepItem(
            number: '3',
            title: '¡Confirmado!',
            subtitle: 'Recibís un email con todos los detalles',
          ),
        ],
      ),
    );
  }
}

class _StepItem extends StatelessWidget {
  final String number;
  final String title;
  final String subtitle;

  const _StepItem({
    required this.number,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Numbered circle
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.primary, AppColors.primaryDark],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(AppSizes.radiusFull),
          ),
          child: Center(
            child: Text(
              number,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
        ),
        const SizedBox(width: AppSizes.s12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.accent,
                ),
              ),
              const SizedBox(height: AppSizes.s2),
              Text(
                subtitle,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// BUSINESS INFO SECTIONS
// ═══════════════════════════════════════════════════════════════
class _BusinessInfoSections extends StatelessWidget {
  final Business? business;
  final int serviceCount;

  const _BusinessInfoSections({
    required this.business,
    required this.serviceCount,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 720;

        if (isWide) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left column
              Expanded(
                child: Column(
                  children: [
                    _TeamSection(),
                    const SizedBox(height: AppSizes.s24),
                    _AboutSection(description: business?.description),
                  ],
                ),
              ),
              const SizedBox(width: AppSizes.s24),
              // Right column
              Expanded(
                child: Column(
                  children: [
                    _AdditionalInfoCard(serviceCount: serviceCount),
                    const SizedBox(height: AppSizes.s24),
                    _RatingsSection(),
                  ],
                ),
              ),
            ],
          );
        }

        return Column(
          children: [
            _TeamSection(),
            const SizedBox(height: AppSizes.s24),
            _AboutSection(description: business?.description),
            const SizedBox(height: AppSizes.s24),
            _AdditionalInfoCard(serviceCount: serviceCount),
            const SizedBox(height: AppSizes.s24),
            _RatingsSection(),
          ],
        );
      },
    );
  }
}

// ── Team Section ───────────────────────────────────────────────
class _TeamSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return _InfoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(
            icon: Icons.groups_rounded,
            title: 'Equipo',
          ),
          const SizedBox(height: AppSizes.s16),
          Row(
            children: [
              // Stacked avatars placeholder
              SizedBox(
                width: 72,
                height: 36,
                child: Stack(
                  children: List.generate(3, (i) {
                    return Positioned(
                      left: i * 20.0,
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: [
                            AppColors.primary,
                            AppColors.primaryDark,
                            AppColors.accentLight,
                          ][i],
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: Center(
                          child: Icon(
                            Icons.person_rounded,
                            size: 16,
                            color: Colors.white.withValues(alpha: 0.8),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),
              const SizedBox(width: AppSizes.s12),
              Expanded(
                child: Text(
                  'Equipo disponible para atenderte',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: AppColors.textSecondary,
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

// ── About Section ──────────────────────────────────────────────
class _AboutSection extends StatelessWidget {
  final String? description;

  const _AboutSection({this.description});

  @override
  Widget build(BuildContext context) {
    return _InfoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(
            icon: Icons.info_outline_rounded,
            title: 'Acerca de',
          ),
          const SizedBox(height: AppSizes.s12),
          Text(
            description != null && description!.isNotEmpty
                ? description!
                : 'Este negocio aún no agregó una descripción.',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: description != null && description!.isNotEmpty
                  ? AppColors.textPrimary
                  : AppColors.textSecondary,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Additional Info Card ───────────────────────────────────────
class _AdditionalInfoCard extends StatelessWidget {
  final int serviceCount;

  const _AdditionalInfoCard({required this.serviceCount});

  @override
  Widget build(BuildContext context) {
    return _InfoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(
            icon: Icons.verified_rounded,
            title: 'Información adicional',
          ),
          const SizedBox(height: AppSizes.s16),
          _InfoRow(
            icon: Icons.email_outlined,
            text: 'Confirmación por email',
            color: AppColors.primary,
          ),
          const SizedBox(height: AppSizes.s12),
          _InfoRow(
            icon: Icons.calendar_today_rounded,
            text: '$serviceCount servicio${serviceCount == 1 ? '' : 's'} disponible${serviceCount == 1 ? '' : 's'}',
            color: AppColors.info,
          ),
          const SizedBox(height: AppSizes.s12),
          _InfoRow(
            icon: Icons.shield_outlined,
            text: 'Reserva segura y garantizada',
            color: AppColors.success,
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;

  const _InfoRow({
    required this.icon,
    required this.text,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppSizes.radiusSm),
          ),
          child: Icon(icon, size: 15, color: color),
        ),
        const SizedBox(width: AppSizes.s12),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.inter(
              fontSize: 13.5,
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}

// ── Ratings Section ────────────────────────────────────────────
class _RatingsSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return _InfoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(
            icon: Icons.star_rounded,
            title: 'Valoraciones',
          ),
          const SizedBox(height: AppSizes.s16),
          Center(
            child: Column(
              children: [
                // Big rating number
                Text(
                  '4.0',
                  style: GoogleFonts.inter(
                    fontSize: 42,
                    fontWeight: FontWeight.w800,
                    color: AppColors.accent,
                  ),
                ),
                const SizedBox(height: AppSizes.s8),
                // Stars row
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (i) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: Icon(
                        i < 4
                            ? Icons.star_rounded
                            : Icons.star_border_rounded,
                        size: 22,
                        color: const Color(0xFFFFC107),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: AppSizes.s16),
                // CTA
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.s16,
                    vertical: AppSizes.s8,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    borderRadius:
                        BorderRadius.circular(AppSizes.radiusFull),
                  ),
                  child: Text(
                    '⭐  Sé el primero en valorar',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryDark,
                    ),
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

// ═══════════════════════════════════════════════════════════════
// SHARED WIDGETS
// ═══════════════════════════════════════════════════════════════

class _InfoCard extends StatelessWidget {
  final Widget child;

  const _InfoCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSizes.s20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        border: Border.all(
          color: AppColors.divider,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;

  const _SectionHeader({
    required this.icon,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.primary),
        const SizedBox(width: AppSizes.s8),
        Text(
          title,
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.accent,
          ),
        ),
      ],
    );
  }
}
