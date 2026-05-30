import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:reservpy/src/shared/models/models.dart';
import 'package:reservpy/src/shared/providers/providers.dart';
import 'package:reservpy/src/core/constants/app_sizes.dart';
import 'package:reservpy/src/core/constants/app_colors.dart';
import 'package:reservpy/src/features/reviews/review_widgets.dart';
import 'package:reservpy/src/features/photos/photo_widgets.dart';
import 'package:reservpy/src/features/favorites/favorite_button.dart';

/// Client-facing business detail screen — premium layout.
///
/// Sections: Hero · Quick Info · About · Photo Gallery · Services · Map · CTA
class BusinessDetailScreen extends ConsumerWidget {
  final String businessId;

  const BusinessDetailScreen({super.key, required this.businessId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final businesses = ref.watch(businessesProvider).value ?? [];
    final business = businesses.cast<Business?>().firstWhere(
          (b) => b?.id == businessId,
          orElse: () => null,
        );

    if (business == null) {
      return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () => context.pop(),
          ),
        ),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.storefront_outlined,
                  size: 64, color: AppColors.textMuted),
              const SizedBox(height: AppSizes.s16),
              Text(
                'Negocio no encontrado',
                style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      );
    }

    final categories = ref.watch(categoriesProvider).value ?? [];
    final category = categories.isEmpty
        ? BusinessCategory(
            id: '', name: '...', icon: Icons.category, color: Colors.grey)
        : categories.firstWhere(
            (c) => c.id == business.categoryId,
            orElse: () => categories.first,
          );
    final services =
        ref.watch(businessServicesProvider(businessId)).value ?? [];
    final isOpen = business.isCurrentlyOpen;

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isDesktop = constraints.maxWidth >= 800;

          return Column(
            children: [
              Expanded(
                child: CustomScrollView(
                  slivers: [
                    // ── Collapsing App Bar with Hero ──
                    _buildSliverAppBar(context, business, category, isOpen),

                    // ── Body Content ──
                    SliverToBoxAdapter(
                      child: isDesktop
                          ? _buildDesktopLayout(
                              context, business, category, services, isOpen)
                          : _buildMobileLayout(
                              context, business, category, services, isOpen),
                    ),
                  ],
                ),
              ),
              // ── Sticky CTA ──
              _buildCtaBar(context, business, services),
            ],
          );
        },
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // SLIVER APP BAR — Hero with gradient
  // ═══════════════════════════════════════════════════════════════════════════
  SliverAppBar _buildSliverAppBar(
    BuildContext context,
    Business business,
    BusinessCategory category,
    bool isOpen,
  ) {
    final initial =
        business.name.isNotEmpty ? business.name[0].toUpperCase() : '?';

    return SliverAppBar(
      expandedHeight: 280,
      pinned: true,
      stretch: true,
      backgroundColor: category.color,
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 8),
          child: Material(
            color: Colors.white.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(AppSizes.radiusSm),
            child: FavoriteButton(businessId: businessId),
          ),
        ),
      ],
      leading: Padding(
        padding: const EdgeInsets.all(8),
        child: Material(
          color: Colors.white.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(AppSizes.radiusSm),
          child: InkWell(
            onTap: () => context.pop(),
            borderRadius: BorderRadius.circular(AppSizes.radiusSm),
            child: const Icon(Icons.arrow_back_rounded,
                color: Colors.white, size: 22),
          ),
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                category.color,
                category.color.withValues(alpha: 0.7),
                category.color.withValues(alpha: 0.5),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 32),
                // Avatar
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      initial,
                      style: GoogleFonts.inter(
                        fontSize: 34,
                        fontWeight: FontWeight.w800,
                        color: category.color,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppSizes.s12),
                // Name
                Text(
                  business.name,
                  style: GoogleFonts.inter(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    height: 1.2,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSizes.s8),
                // Quick badges row
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Category
                    _HeroBadge(
                      icon: category.icon,
                      label: category.name,
                      color: Colors.white.withValues(alpha: 0.2),
                    ),
                    const SizedBox(width: AppSizes.s8),
                    // Open/Closed
                    _HeroBadge(
                      icon: isOpen
                          ? Icons.check_circle_rounded
                          : Icons.cancel_rounded,
                      label: isOpen ? 'Abierto' : 'Cerrado',
                      color: isOpen
                          ? AppColors.success.withValues(alpha: 0.85)
                          : AppColors.error.withValues(alpha: 0.85),
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

  // ═══════════════════════════════════════════════════════════════════════════
  // DESKTOP LAYOUT — Two columns
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildDesktopLayout(
    BuildContext context,
    Business business,
    BusinessCategory category,
    List<ServiceModel> services,
    bool isOpen,
  ) {
    return Padding(
      padding: const EdgeInsets.all(AppSizes.s24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left column — Info + Map
          Expanded(
            flex: 5,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildInfoCard(business, category),
                const SizedBox(height: AppSizes.s20),
                if (business.description != null &&
                    business.description!.isNotEmpty) ...[
                  _buildAboutCard(business),
                  const SizedBox(height: AppSizes.s20),
                ],
                if (business.photos.isNotEmpty) ...[
                  _buildPhotoGallery(business),
                  const SizedBox(height: AppSizes.s20),
                ],
                // ── Photo Gallery ──
                PhotoCarousel(businessId: businessId),
                const SizedBox(height: 24),
                // ── Reviews Section ──
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.star_rounded, size: 22, color: Colors.amber.shade600),
                          const SizedBox(width: 8),
                          Text(
                            'Reseñas',
                            style: GoogleFonts.inter(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      ReviewsSection(businessId: businessId),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                _buildMapCard(business),
                const SizedBox(height: AppSizes.s24),
              ],
            ),
          ),
          const SizedBox(width: AppSizes.s24),
          // Right column — Services
          Expanded(
            flex: 4,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildServicesCard(context, services, category),
                const SizedBox(height: AppSizes.s20),
                _buildPoliciesCard(business),
                const SizedBox(height: AppSizes.s24),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // MOBILE LAYOUT — Single column
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildMobileLayout(
    BuildContext context,
    Business business,
    BusinessCategory category,
    List<ServiceModel> services,
    bool isOpen,
  ) {
    return Padding(
      padding: const EdgeInsets.all(AppSizes.s16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildInfoCard(business, category),
          const SizedBox(height: AppSizes.s16),
          if (business.description != null &&
              business.description!.isNotEmpty) ...[
            _buildAboutCard(business),
            const SizedBox(height: AppSizes.s16),
          ],
          if (business.photos.isNotEmpty) ...[
            _buildPhotoGallery(business),
            const SizedBox(height: AppSizes.s16),
          ],
          _buildServicesCard(context, services, category),
          const SizedBox(height: AppSizes.s16),
          // ── Photo Gallery ──
          PhotoCarousel(businessId: businessId),
          const SizedBox(height: 24),
          // ── Reviews Section ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.star_rounded, size: 22, color: Colors.amber.shade600),
                    const SizedBox(width: 8),
                    Text(
                      'Reseñas',
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ReviewsSection(businessId: businessId),
              ],
            ),
          ),
          const SizedBox(height: 32),
          _buildMapCard(business),
          const SizedBox(height: AppSizes.s16),
          _buildPoliciesCard(business),
          const SizedBox(height: AppSizes.s24),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // INFO CARD — Address, Phone, Website, Hours
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildInfoCard(Business business, BusinessCategory category) {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section title
          Row(
            children: [
              const Icon(Icons.info_outline_rounded,
                  size: 20, color: AppColors.primary),
              const SizedBox(width: AppSizes.s8),
              Text(
                'Información',
                style: GoogleFonts.inter(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: AppColors.accent,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.s16),

          // Hours
          _InfoRow(
            icon: Icons.schedule_rounded,
            iconColor: AppColors.primary,
            label: 'Horario',
            value: '${business.openingTimeStr} - ${business.closingTimeStr}',
            trailing: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: business.isCurrentlyOpen
                    ? AppColors.success.withValues(alpha: 0.1)
                    : AppColors.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppSizes.radiusFull),
              ),
              child: Text(
                business.isCurrentlyOpen ? 'Abierto' : 'Cerrado',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: business.isCurrentlyOpen
                      ? AppColors.success
                      : AppColors.error,
                ),
              ),
            ),
          ),

          // Address
          if (business.address != null && business.address!.isNotEmpty) ...[
            const _Divider(),
            _InfoRow(
              icon: Icons.location_on_rounded,
              iconColor: AppColors.error,
              label: 'Dirección',
              value: business.address!,
            ),
          ],

          // Phone
          if (business.phone != null && business.phone!.isNotEmpty) ...[
            const _Divider(),
            _InfoRow(
              icon: Icons.phone_rounded,
              iconColor: AppColors.info,
              label: 'Teléfono',
              value: business.phone!,
            ),
          ],

          // Website
          if (business.website != null && business.website!.isNotEmpty) ...[
            const _Divider(),
            _InfoRow(
              icon: Icons.language_rounded,
              iconColor: AppColors.primary,
              label: 'Web',
              value: business.website!,
            ),
          ],
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // ABOUT CARD — Description
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildAboutCard(Business business) {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.description_outlined,
                  size: 20, color: AppColors.primary),
              const SizedBox(width: AppSizes.s8),
              Text(
                'Acerca del negocio',
                style: GoogleFonts.inter(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: AppColors.accent,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.s12),
          Text(
            business.description!,
            style: GoogleFonts.inter(
              fontSize: 14,
              height: 1.6,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // PHOTO GALLERY — Horizontal scroll
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildPhotoGallery(Business business) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4),
          child: Row(
            children: [
              const Icon(Icons.photo_library_rounded,
                  size: 20, color: AppColors.primary),
              const SizedBox(width: AppSizes.s8),
              Text(
                'Fotos',
                style: GoogleFonts.inter(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: AppColors.accent,
                ),
              ),
              const SizedBox(width: AppSizes.s8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(AppSizes.radiusFull),
                ),
                child: Text(
                  '${business.photos.length}',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSizes.s12),
        SizedBox(
          height: 180,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: business.photos.length,
            separatorBuilder: (_, __) => const SizedBox(width: AppSizes.s12),
            itemBuilder: (context, index) {
              return ClipRRect(
                borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                child: Image.network(
                  business.photos[index],
                  width: 240,
                  height: 180,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    width: 240,
                    height: 180,
                    color: AppColors.divider,
                    child: const Icon(Icons.broken_image_rounded,
                        color: AppColors.textMuted, size: 40),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // SERVICES CARD — Full list with prices + book buttons
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildServicesCard(
    BuildContext context,
    List<ServiceModel> services,
    BusinessCategory category,
  ) {
    final activeServices = services.where((s) => s.isActive).toList();

    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              const Icon(Icons.miscellaneous_services_rounded,
                  size: 20, color: AppColors.primary),
              const SizedBox(width: AppSizes.s8),
              Expanded(
                child: Text(
                  'Servicios',
                  style: GoogleFonts.inter(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: AppColors.accent,
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: category.color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppSizes.radiusFull),
                ),
                child: Text(
                  '${activeServices.length} disponible${activeServices.length == 1 ? '' : 's'}',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: category.color,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.s16),

          if (activeServices.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSizes.s24),
                child: Column(
                  children: [
                    Icon(Icons.inbox_rounded,
                        size: 40, color: AppColors.textMuted),
                    const SizedBox(height: AppSizes.s8),
                    Text(
                      'Sin servicios disponibles',
                      style: GoogleFonts.inter(
                          fontSize: 14, color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
            )
          else
            ...activeServices.asMap().entries.map((entry) {
              final i = entry.key;
              final service = entry.value;
              return Column(
                children: [
                  if (i > 0) const _Divider(),
                  _ServiceTile(
                    service: service,
                    categoryColor: category.color,
                    onBook: () {
                      context.push('/reserve/$businessId/service');
                    },
                  ),
                ],
              );
            }),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // MAP CARD
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildMapCard(Business business) {
    return _Card(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSizes.s20, AppSizes.s20, AppSizes.s20, AppSizes.s12),
            child: Row(
              children: [
                const Icon(Icons.map_rounded,
                    size: 20, color: AppColors.primary),
                const SizedBox(width: AppSizes.s8),
                Text(
                  'Ubicación',
                  style: GoogleFonts.inter(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: AppColors.accent,
                  ),
                ),
              ],
            ),
          ),
          ClipRRect(
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(AppSizes.radiusLg),
              bottomRight: Radius.circular(AppSizes.radiusLg),
            ),
            child: SizedBox(
              height: 220,
              child: business.latitude != null && business.longitude != null
                  ? _buildMap(business.latitude!, business.longitude!)
                  : _buildMapPlaceholder(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMap(double lat, double lng) {
    final point = LatLng(lat, lng);
    return FlutterMap(
      options: MapOptions(
        initialCenter: point,
        initialZoom: 15,
        interactionOptions: const InteractionOptions(
          flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
        ),
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'reservly-app',
        ),
        MarkerLayer(
          markers: [
            Marker(
              point: point,
              width: 44,
              height: 44,
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(Icons.storefront_rounded,
                    color: Colors.white, size: 22),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMapPlaceholder() {
    return Container(
      color: AppColors.backgroundLight,
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.map_outlined, size: 48, color: AppColors.textMuted),
          const SizedBox(height: AppSizes.s8),
          Text(
            'Ubicación no disponible',
            style:
                GoogleFonts.inter(fontSize: 14, color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // POLICIES CARD — Cancellation, reminders
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildPoliciesCard(Business business) {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.policy_rounded,
                  size: 20, color: AppColors.primary),
              const SizedBox(width: AppSizes.s8),
              Text(
                'Políticas',
                style: GoogleFonts.inter(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: AppColors.accent,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.s16),
          _PolicyRow(
            icon: Icons.event_busy_rounded,
            label: 'Cancelación',
            value:
                'Hasta ${business.cancellationHoursPolicy}h antes del turno',
          ),
          const SizedBox(height: AppSizes.s12),
          _PolicyRow(
            icon: Icons.notifications_active_rounded,
            label: 'Recordatorios',
            value: business.remindersEnabled
                ? 'Activos (${business.reminderHoursBefore.map((h) => '${h}h').join(', ')} antes)'
                : 'No disponibles',
          ),
          const SizedBox(height: AppSizes.s12),
          _PolicyRow(
            icon: Icons.timer_rounded,
            label: 'Turno estándar',
            value: '${business.slotDurationMinutes} minutos',
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // STICKY CTA BAR
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildCtaBar(
      BuildContext context, Business business, List<ServiceModel> services) {
    // Price range
    final prices = services
        .where((s) => s.isActive && s.price != null && s.price! > 0)
        .map((s) => s.price!)
        .toList()
      ..sort();

    return Container(
      padding: const EdgeInsets.fromLTRB(
          AppSizes.s20, AppSizes.s12, AppSizes.s20, AppSizes.s16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Price info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (prices.isNotEmpty) ...[
                  Text(
                    'Desde',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  Text(
                    _formatGuaranies(prices.first),
                    style: GoogleFonts.inter(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: AppColors.accent,
                    ),
                  ),
                ] else ...[
                  Text(
                    '${services.where((s) => s.isActive).length} servicios',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
          // Book button
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 220),
            child: SizedBox(
              height: AppSizes.buttonLg,
              width: 200,
              child: ElevatedButton.icon(
                onPressed: () => context.push('/reserve/$businessId/service'),
                icon: const Icon(Icons.calendar_today_rounded,
                    color: Colors.white, size: 20),
                label: Text(
                  'Reservar turno',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                  ),
                  elevation: 0,
                  padding:
                      const EdgeInsets.symmetric(horizontal: AppSizes.s24),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Helpers ──────────────────────────────────────────────
  String _formatGuaranies(double? price) {
    if (price == null) return 'Gratis';
    final intPrice = price.toInt();
    final formatted = intPrice.toString().replaceAllMapped(
          RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]}.',
        );
    return 'Gs. $formatted';
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// REUSABLE COMPONENTS
// ═════════════════════════════════════════════════════════════════════════════

/// Standard card wrapper.
class _Card extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;

  const _Card({required this.child, this.padding});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding ?? const EdgeInsets.all(AppSizes.s20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        border: Border.all(color: AppColors.divider.withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }
}

/// Badge used in the hero header.
class _HeroBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _HeroBadge({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(AppSizes.radiusFull),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.white),
          const SizedBox(width: 5),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

/// Info row with icon, label, value, and optional trailing widget.
class _InfoRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  final Widget? trailing;

  const _InfoRow({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(AppSizes.radiusSm),
          ),
          child: Icon(icon, size: 18, color: iconColor),
        ),
        const SizedBox(width: AppSizes.s12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textMuted,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                value,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.accent,
                ),
              ),
            ],
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}

/// Thin divider with padding.
class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSizes.s12),
      child: Divider(
          height: 1, color: AppColors.divider.withValues(alpha: 0.5)),
    );
  }
}

/// Individual service tile with price, duration, and book icon.
class _ServiceTile extends StatefulWidget {
  final ServiceModel service;
  final Color categoryColor;
  final VoidCallback onBook;

  const _ServiceTile({
    required this.service,
    required this.categoryColor,
    required this.onBook,
  });

  @override
  State<_ServiceTile> createState() => _ServiceTileState();
}

class _ServiceTileState extends State<_ServiceTile> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final s = widget.service;
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(
            vertical: AppSizes.s8, horizontal: AppSizes.s4),
        decoration: BoxDecoration(
          color: _isHovered
              ? widget.categoryColor.withValues(alpha: 0.04)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(AppSizes.radiusSm),
        ),
        child: Row(
          children: [
            // Service icon
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: widget.categoryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppSizes.radiusSm),
              ),
              child: Icon(Icons.check_circle_rounded,
                  size: 20, color: widget.categoryColor),
            ),
            const SizedBox(width: AppSizes.s12),
            // Name + duration
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    s.name,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.accent,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(Icons.schedule_rounded,
                          size: 12, color: AppColors.textMuted),
                      const SizedBox(width: 4),
                      Text(
                        '${s.durationMinutes} min',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Price
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  s.price != null && s.price! > 0
                      ? _formatPrice(s.price!)
                      : 'Gratis',
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
                if (s.price != null && s.price! > 0)
                  Text(
                    'Gs.',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      color: AppColors.textMuted,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatPrice(double price) {
    final intPrice = price.toInt();
    final formatted = intPrice.toString().replaceAllMapped(
          RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]}.',
        );
    return formatted;
  }
}

/// Policy row with icon.
class _PolicyRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _PolicyRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.textMuted),
        const SizedBox(width: AppSizes.s12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
              Text(
                value,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
