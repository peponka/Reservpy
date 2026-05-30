import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:reservpy/src/core/constants/app_colors.dart';
import 'package:reservpy/src/core/constants/app_sizes.dart';
import 'package:reservpy/src/shared/models/models.dart';
import 'package:reservpy/src/shared/providers/providers.dart';
import 'package:reservpy/src/features/favorites/favorite_button.dart';

/// Provider for the currently selected business on the map.
final _selectedMapBusinessProvider = StateProvider<Business?>((ref) => null);

/// Provider for toggling between map+list and full list view.
final _showMapProvider = StateProvider<bool>((ref) => true);

/// Client-facing explore screen with real OpenStreetMap and business list.
class ExploreMapScreen extends ConsumerStatefulWidget {
  const ExploreMapScreen({super.key});

  @override
  ConsumerState<ExploreMapScreen> createState() => _ExploreMapScreenState();
}

class _ExploreMapScreenState extends ConsumerState<ExploreMapScreen> {
  final _searchController = TextEditingController();
  final _mapController = MapController();

  @override
  void dispose() {
    _searchController.dispose();
    _mapController.dispose();
    super.dispose();
  }

  void _selectBusiness(Business business) {
    ref.read(_selectedMapBusinessProvider.notifier).state = business;
    if (business.latitude != null && business.longitude != null) {
      _mapController.move(
        LatLng(business.latitude!, business.longitude!),
        15.0,
      );
    }
  }

  void _clearSelection() {
    ref.read(_selectedMapBusinessProvider.notifier).state = null;
  }

  BusinessCategory _findCategory(List<BusinessCategory> categories, String categoryId) {
    return categories.cast<BusinessCategory?>().firstWhere(
      (c) => c?.id == categoryId,
      orElse: () => null,
    ) ?? const BusinessCategory(id: '', name: 'Cargando...', icon: Icons.category, color: Colors.grey);
  }

  List<Marker> _buildMarkers(
    List<Business> businesses,
    List<BusinessCategory> categories,
    ThemeData theme,
  ) {
    final selected = ref.read(_selectedMapBusinessProvider);
    return businesses
        .where((b) => b.latitude != null && b.longitude != null)
        .map((business) {
      final category = _findCategory(categories, business.categoryId);
      final isSelected = selected?.id == business.id;
      final markerSize = isSelected ? 52.0 : 44.0;
      return Marker(
        point: LatLng(business.latitude!, business.longitude!),
        width: markerSize,
        height: markerSize,
        child: GestureDetector(
          onTap: () => _selectBusiness(business),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.primary : category.color,
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected ? Colors.white : Colors.white,
                width: isSelected ? 4 : 3,
              ),
              boxShadow: [
                BoxShadow(
                  color: isSelected
                      ? AppColors.primary.withValues(alpha: 0.5)
                      : Colors.black26,
                  blurRadius: isSelected ? 12 : 4,
                  spreadRadius: isSelected ? 2 : 0,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(category.icon, color: Colors.white, size: isSelected ? 24 : 20),
          ),
        ),
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final categories = ref.watch(categoriesProvider).value ?? [];
    final selectedCategory = ref.watch(selectedCategoryFilterProvider);
    final businessesAsync = ref.watch(businessesProvider);
    final businesses = ref.watch(filteredBusinessesProvider);
    final selectedBusiness = ref.watch(_selectedMapBusinessProvider);
    final showMap = ref.watch(_showMapProvider);

    // Show loading state while fetching businesses from Supabase
    if (businessesAsync is AsyncLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (businessesAsync is AsyncError) {
      return Center(
        child: Text('Error al cargar negocios: ${(businessesAsync as AsyncError).error}'),
      );
    }

    return Column(
      children: [
        // ── Map Section ──
        if (showMap)
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.65,
            child: Stack(
              children: [
                // OpenStreetMap
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: const LatLng(-25.2637, -57.5759),
                    initialZoom: 13.0,
                    interactionOptions: const InteractionOptions(
                      flags: InteractiveFlag.all,
                    ),
                    onTap: (_, _) => _clearSelection(),
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.reservly.app',
                    ),
                    MarkerLayer(
                      markers: _buildMarkers(businesses, categories, theme),
                    ),
                  ],
                ),

                // Toggle button (top-right)
                Positioned(
                  top: AppSizes.s12,
                  right: AppSizes.s12,
                  child: _MapToggleButton(
                    showMap: showMap,
                    onTap: () {
                      ref.read(_showMapProvider.notifier).state = !showMap;
                    },
                  ),
                ),

                // Selected business popup (bottom of map)
                if (selectedBusiness != null)
                  Positioned(
                    left: AppSizes.s12,
                    right: AppSizes.s12,
                    bottom: AppSizes.s12,
                    child: _SelectedBusinessPopup(
                      business: selectedBusiness,
                      category: _findCategory(categories, selectedBusiness.categoryId),
                      onClose: _clearSelection,
                      onReserve: () {
                        context.push(
                            '/reserve/${selectedBusiness.id}/service');
                      },
                    ),
                  ),
              ],
            ),
          ),

        // ── Toggle button when map is hidden ──
        if (!showMap)
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSizes.s16,
              vertical: AppSizes.s8,
            ),
            child: Row(
              children: [
                Text(
                  'Explorar',
                  style: GoogleFonts.inter(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: colorScheme.onSurface,
                  ),
                ),
                const Spacer(),
                _MapToggleButton(
                  showMap: showMap,
                  onTap: () {
                    ref.read(_showMapProvider.notifier).state = !showMap;
                  },
                ),
              ],
            ),
          ),

        // ── Bottom Section: Business List ──
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Location banner
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.s16,
                  vertical: AppSizes.s8,
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.location_on_rounded,
                      size: AppSizes.iconMd,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: AppSizes.s6),
                    Text(
                      'Asunción, Paraguay 🇵🇾',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),

              // Search bar
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.s16,
                ),
                child: Container(
                  height: 44,
                  decoration: BoxDecoration(
                    color: theme.cardTheme.color ?? Colors.white,
                    borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                    border: Border.all(
                      color: colorScheme.outline.withValues(alpha: 0.12),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _searchController,
                    style: GoogleFonts.inter(fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'Buscar negocios...',
                      hintStyle: GoogleFonts.inter(
                        fontSize: 14,
                        color: colorScheme.outline.withValues(alpha: 0.6),
                      ),
                      prefixIcon: Icon(
                        Icons.search_rounded,
                        size: 20,
                        color: colorScheme.outline,
                      ),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear_rounded, size: 18),
                              onPressed: () {
                                _searchController.clear();
                                ref.read(searchQueryProvider.notifier).state =
                                    '';
                                setState(() {});
                              },
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 12,
                      ),
                    ),
                    onChanged: (value) {
                      ref.read(searchQueryProvider.notifier).state = value;
                      setState(() {});
                    },
                  ),
                ),
              ),

              const SizedBox(height: AppSizes.s8),

              // Category filter chips
              SizedBox(
                height: 44,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.s16,
                    vertical: AppSizes.s4,
                  ),
                  itemCount: categories.length + 1,
                  separatorBuilder: (_, _) =>
                      const SizedBox(width: AppSizes.s8),
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      final isSelected = selectedCategory == null;
                      return _CategoryChip(
                        label: 'Todos',
                        icon: Icons.apps_rounded,
                        color: AppColors.primary,
                        isSelected: isSelected,
                        onTap: () {
                          ref
                              .read(selectedCategoryFilterProvider.notifier)
                              .state = null;
                        },
                      );
                    }
                    final cat = categories[index - 1];
                    final isSelected = selectedCategory == cat.id;
                    return _CategoryChip(
                      label: cat.name,
                      icon: cat.icon,
                      color: cat.color,
                      isSelected: isSelected,
                      onTap: () {
                        ref
                            .read(selectedCategoryFilterProvider.notifier)
                            .state = isSelected ? null : cat.id;
                      },
                    );
                  },
                ),
              ),

              const SizedBox(height: AppSizes.s4),

              // Business cards list
              Expanded(
                child: businesses.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.search_off_rounded,
                              size: 48,
                              color: colorScheme.outline.withValues(alpha: 0.4),
                            ),
                            const SizedBox(height: AppSizes.s12),
                            Text(
                              'Sin resultados',
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: colorScheme.onSurface,
                              ),
                            ),
                            const SizedBox(height: AppSizes.s4),
                            Text(
                              'No encontramos negocios con esos filtros.',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                color: colorScheme.outline,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSizes.s16,
                        ),
                        itemCount: businesses.length,
                        itemBuilder: (context, index) {
                          final business = businesses[index];
                          final category =
                              _findCategory(categories, business.categoryId);
                          return Padding(
                            padding: const EdgeInsets.only(
                              bottom: AppSizes.s12,
                            ),
                            child: _BusinessCard(
                              business: business,
                              category: category,
                              isSelected:
                                  selectedBusiness?.id == business.id,
                              onTap: () {
                                _selectBusiness(business);
                              },
                              onReserve: () {
                                context.push(
                                    '/reserve/${business.id}/service');
                              },
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── Map Toggle Button ──────────────────────────────────────────────────────

class _MapToggleButton extends StatelessWidget {
  final bool showMap;
  final VoidCallback onTap;

  const _MapToggleButton({
    required this.showMap,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 4,
      borderRadius: BorderRadius.circular(AppSizes.radiusMd),
      color: Colors.white,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        child: Container(
          padding: const EdgeInsets.all(AppSizes.s8),
          child: Icon(
            showMap ? Icons.list_rounded : Icons.map_rounded,
            color: AppColors.accent,
            size: 22,
          ),
        ),
      ),
    );
  }
}

// ─── Selected Business Popup ────────────────────────────────────────────────

class _SelectedBusinessPopup extends StatelessWidget {
  final Business business;
  final BusinessCategory category;
  final VoidCallback onClose;
  final VoidCallback onReserve;

  const _SelectedBusinessPopup({
    required this.business,
    required this.category,
    required this.onClose,
    required this.onReserve,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isOpen = business.isCurrentlyOpen;

    return Container(
      padding: const EdgeInsets.all(AppSizes.s16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Category icon
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: category.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                ),
                child: Icon(
                  category.icon,
                  color: category.color,
                  size: 20,
                ),
              ),
              const SizedBox(width: AppSizes.s12),

              // Business info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      business.name,
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      category.name,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: category.color,
                      ),
                    ),
                    if (business.address != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        business.address!,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: colorScheme.outline,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),

              // Status badge + close
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  GestureDetector(
                    onTap: onClose,
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: colorScheme.outline.withValues(alpha: 0.08),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.close_rounded,
                        size: 16,
                        color: colorScheme.outline,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSizes.s6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: (isOpen ? AppColors.success : AppColors.error)
                          .withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      isOpen ? 'Abierto' : 'Cerrado',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: isOpen ? AppColors.success : AppColors.error,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppSizes.s12),

          // Reserve button
          SizedBox(
            width: double.infinity,
            height: 40,
            child: ElevatedButton(
              onPressed: onReserve,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                ),
                elevation: 0,
              ),
              child: Text(
                'Reservar turno',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Category Chip ──────────────────────────────────────────────────────────

class _CategoryChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const _CategoryChip({
    required this.label,
    required this.icon,
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: AppSizes.animNormal),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.s12,
          vertical: AppSizes.s6,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? color.withValues(alpha: 0.15)
              : theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(AppSizes.radiusFull),
          border: Border.all(
            color: isSelected
                ? color
                : theme.colorScheme.outline.withValues(alpha: 0.2),
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? color : theme.colorScheme.outline,
            ),
            const SizedBox(width: AppSizes.s6),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? color : theme.colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Business Card ──────────────────────────────────────────────────────────

class _BusinessCard extends StatelessWidget {
  final Business business;
  final BusinessCategory category;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onReserve;

  const _BusinessCard({
    required this.business,
    required this.category,
    required this.isSelected,
    required this.onTap,
    required this.onReserve,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isOpen = business.isCurrentlyOpen;

    // Simulated distance based on business coordinates.
    final distanceKm =
        ((business.latitude ?? 0).abs() % 5 * 0.3 + 0.2).toStringAsFixed(1);

    // Lighter shade for gradient
    final lighterCategoryColor = Color.lerp(category.color, Colors.white, 0.35)!;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: AppSizes.animNormal),
        decoration: BoxDecoration(
          color: theme.cardTheme.color ?? Colors.white,
          borderRadius: BorderRadius.circular(AppSizes.radiusLg),
          border: Border.all(
            color: isSelected
                ? category.color.withValues(alpha: 0.5)
                : colorScheme.outline.withValues(alpha: 0.08),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? category.color.withValues(alpha: 0.10)
                  : Colors.black.withValues(alpha: 0.04),
              blurRadius: isSelected ? 10 : 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppSizes.radiusLg - 1),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Left accent bar when selected
                if (isSelected)
                  Container(
                    width: 4,
                    decoration: BoxDecoration(
                      color: category.color,
                    ),
                  ),

                // Card content
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSizes.s16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Category icon – gradient circle
                            Container(
                              width: 52,
                              height: 52,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    category.color,
                                    lighterCategoryColor,
                                  ],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: category.color.withValues(alpha: 0.25),
                                    blurRadius: 8,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: Icon(
                                category.icon,
                                color: Colors.white,
                                size: AppSizes.iconLg,
                              ),
                            ),
                            const SizedBox(width: AppSizes.s12),

                            // Business info
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Name with category color dot
                                  Row(
                                    children: [
                                      Container(
                                        width: 8,
                                        height: 8,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: category.color,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          business.name,
                                          style: GoogleFonts.inter(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w700,
                                            color: colorScheme.onSurface,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: AppSizes.s2),
                                  if (business.address != null)
                                    Padding(
                                      padding: const EdgeInsets.only(left: 14),
                                      child: Text(
                                        business.address!,
                                        style: GoogleFonts.inter(
                                          fontSize: 12,
                                          color: colorScheme.outline,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  const SizedBox(height: AppSizes.s4),
                                  Padding(
                                    padding: const EdgeInsets.only(left: 14),
                                    child: Text(
                                      category.name,
                                      style: GoogleFonts.inter(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                        color: category.color,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Favorite button
                            FavoriteButton(businessId: business.id),
                            const SizedBox(width: AppSizes.s8),

                            // Open/Closed pill badge with pulsing dot
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: (isOpen ? AppColors.success : AppColors.error)
                                    .withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(AppSizes.radiusFull),
                                border: Border.all(
                                  color: (isOpen ? AppColors.success : AppColors.error)
                                      .withValues(alpha: 0.2),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (isOpen)
                                    TweenAnimationBuilder<double>(
                                      tween: Tween<double>(begin: 0.3, end: 1.0),
                                      duration: const Duration(milliseconds: 1500),
                                      builder: (context, value, child) {
                                        return Opacity(
                                          opacity: value,
                                          child: child,
                                        );
                                      },
                                      onEnd: () {},
                                      child: Container(
                                        width: 6,
                                        height: 6,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: AppColors.success,
                                        ),
                                      ),
                                    )
                                  else
                                    Container(
                                      width: 6,
                                      height: 6,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: AppColors.error,
                                      ),
                                    ),
                                  const SizedBox(width: 5),
                                  Text(
                                    isOpen ? 'Abierto' : 'Cerrado',
                                    style: GoogleFonts.inter(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: isOpen ? AppColors.success : AppColors.error,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSizes.s12),

                        // Bottom row: distance, hours, reserve button
                        Row(
                          children: [
                            Icon(
                              Icons.near_me_rounded,
                              size: 14,
                              color: colorScheme.outline,
                            ),
                            const SizedBox(width: AppSizes.s4),
                            Text(
                              '$distanceKm km',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: colorScheme.outline,
                              ),
                            ),
                            const SizedBox(width: AppSizes.s16),
                            Icon(
                              Icons.schedule_rounded,
                              size: 14,
                              color: colorScheme.outline,
                            ),
                            const SizedBox(width: AppSizes.s4),
                            Expanded(
                              child: Text(
                                '${business.openingTimeStr} - ${business.closingTimeStr}',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: colorScheme.outline,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSizes.s8),

                        // Gradient reserve button
                        SizedBox(
                          width: double.infinity,
                          height: 38,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [
                                  AppColors.primary,
                                  Color(0xFF00A67E),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primary.withValues(alpha: 0.25),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: ElevatedButton(
                              onPressed: onReserve,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppSizes.s12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.circular(AppSizes.radiusSm),
                                ),
                                elevation: 0,
                              ),
                              child: Text(
                                'Reservar',
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
