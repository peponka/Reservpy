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

/// Client-facing business detail screen.
///
/// Shows business info, location map, services preview, and a CTA to book.
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
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.pop(),
          ),
        ),
        body: Center(
          child: Text(
            'Negocio no encontrado',
            style: GoogleFonts.inter(fontSize: 16, color: AppColors.textSecondary),
          ),
        ),
      );
    }

    final categories = ref.watch(categoriesProvider).value ?? [];
    final category = categories.isEmpty
        ? BusinessCategory(id: '', name: '...', icon: Icons.category, color: Colors.grey)
        : categories.firstWhere(
            (c) => c.id == business.categoryId,
            orElse: () => categories.first,
          );
    final services = ref.watch(businessServicesProvider(businessId)).value ?? [];

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              business.name,
              style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            Text(
              category.name,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w400,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight - AppSizes.buttonLg - AppSizes.s32,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildHeroHeader(business, category),
                        const SizedBox(height: AppSizes.s16),
                        _buildInfoSection(business),
                        const SizedBox(height: AppSizes.s24),
                        _buildMapSection(business),
                        const SizedBox(height: AppSizes.s24),
                        _buildServicesPreview(services),
                        const SizedBox(height: AppSizes.s24),
                      ],
                    ),
                  ),
                ),
              ),
              _buildCtaButton(context),
            ],
          );
        },
      ),
    );
  }

  // ─── Hero Header ──────────────────────────────────────────

  Widget _buildHeroHeader(Business business, BusinessCategory category) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.s24,
        vertical: AppSizes.s32,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            category.color,
            category.color.withValues(alpha: 0.7),
          ],
        ),
      ),
      child: Column(
        children: [
          // Business initial
          Container(
            width: 56,
            height: 56,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              business.name.isNotEmpty ? business.name[0].toUpperCase() : '?',
              style: GoogleFonts.inter(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: category.color,
              ),
            ),
          ),
          const SizedBox(height: AppSizes.s12),

          // Business name
          Text(
            business.name,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: AppSizes.s8),

          // Category chip
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(AppSizes.radiusFull),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(category.icon, size: 16, color: Colors.white),
                const SizedBox(width: AppSizes.s6),
                Text(
                  category.name,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSizes.s12),

          // Open / Closed badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
              color: business.isCurrentlyOpen
                  ? Colors.white.withValues(alpha: 0.25)
                  : Colors.black.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              business.isCurrentlyOpen ? 'Abierto' : 'Cerrado',
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Info Section ─────────────────────────────────────────

  Widget _buildInfoSection(Business business) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.s16),
      child: Container(
        padding: const EdgeInsets.all(AppSizes.s20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppSizes.radiusLg),
          border: Border.all(color: AppColors.divider),
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
            // Address
            if (business.address != null && business.address!.isNotEmpty)
              _buildInfoRow(Icons.location_on_outlined, business.address!),

            // Phone
            if (business.phone != null && business.phone!.isNotEmpty) ...[
              const SizedBox(height: AppSizes.s12),
              _buildInfoRow(Icons.phone_outlined, business.phone!),
            ],

            // Hours
            const SizedBox(height: AppSizes.s12),
            _buildInfoRow(
              Icons.access_time_outlined,
              '${business.openingTimeStr} - ${business.closingTimeStr}',
            ),

            // Description
            if (business.description != null && business.description!.isNotEmpty) ...[
              const SizedBox(height: AppSizes.s16),
              const Divider(height: 1, color: AppColors.divider),
              const SizedBox(height: AppSizes.s16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.description_outlined, size: 20, color: AppColors.textSecondary),
                  const SizedBox(width: AppSizes.s12),
                  Expanded(
                    child: Text(
                      business.description!,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        height: 1.5,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.textSecondary),
        const SizedBox(width: AppSizes.s12),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.inter(fontSize: 14, color: AppColors.textPrimary),
          ),
        ),
      ],
    );
  }

  // ─── Map Section ──────────────────────────────────────────

  Widget _buildMapSection(Business business) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.s16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Ubicación',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSizes.s12),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppSizes.radiusLg),
            child: SizedBox(
              height: 250,
              child: business.latitude != null && business.longitude != null
                  ? _buildInteractiveMap(business.latitude!, business.longitude!)
                  : _buildMapPlaceholder(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInteractiveMap(double lat, double lng) {
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
              width: 40,
              height: 40,
              child: const Icon(
                Icons.location_on,
                color: AppColors.error,
                size: 40,
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
            style: GoogleFonts.inter(fontSize: 14, color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }

  // ─── Services Preview ─────────────────────────────────────

  Widget _buildServicesPreview(List<ServiceModel> services) {
    final preview = services.take(3).toList();
    if (preview.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.s16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Servicios disponibles',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSizes.s12),
          Container(
            padding: const EdgeInsets.all(AppSizes.s16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppSizes.radiusLg),
              border: Border.all(color: AppColors.divider),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                for (int i = 0; i < preview.length; i++) ...[
                  if (i > 0) ...[
                    const SizedBox(height: AppSizes.s8),
                    const Divider(height: 1, color: AppColors.divider),
                    const SizedBox(height: AppSizes.s8),
                  ],
                  _buildServiceRow(preview[i]),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServiceRow(ServiceModel service) {
    return Row(
      children: [
        const Icon(Icons.check_circle, size: 20, color: AppColors.primary),
        const SizedBox(width: AppSizes.s12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                service.name,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: AppSizes.s2),
              Text(
                '${service.durationMinutes} min',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        Text(
          _formatGuaranies(service.price),
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: AppColors.primary,
          ),
        ),
      ],
    );
  }

  // ─── CTA Button ───────────────────────────────────────────

  Widget _buildCtaButton(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSizes.s16,
        AppSizes.s12,
        AppSizes.s16,
        AppSizes.s16,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SizedBox(
        width: double.infinity,
        height: AppSizes.buttonLg,
        child: ElevatedButton.icon(
          onPressed: () => context.push('/reserve/$businessId/service'),
          icon: const Icon(Icons.calendar_today_rounded, color: Colors.white),
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
          ),
        ),
      ),
    );
  }

  // ─── Helpers ──────────────────────────────────────────────

  /// Formats a price in Paraguayan Guaraníes: 'Gs. 120.000'
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
