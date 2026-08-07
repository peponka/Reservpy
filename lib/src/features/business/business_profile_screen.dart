import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:reservpy/src/features/photos/photo_widgets.dart';

import 'package:reservpy/src/shared/models/models.dart';
import 'package:reservpy/src/shared/providers/providers.dart';
import 'package:reservpy/src/core/widgets/widgets.dart';
import 'package:reservpy/src/core/constants/app_colors.dart';
import 'package:reservpy/src/core/constants/app_sizes.dart';
import 'package:reservpy/src/core/constants/app_strings.dart';
import 'package:reservpy/src/core/utils/string_utils.dart';

/// Public profile screen for a single business.
///
/// Displays a hero gradient section, business details, interactive map,
/// services list with booking buttons, share functionality, and an edit FAB
/// for the business owner.
class BusinessProfileScreen extends ConsumerWidget {
  final String businessId;

  const BusinessProfileScreen({
    super.key,
    required this.businessId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final currentUser = ref.watch(currentUserProvider);
    final businessAsync = ref.watch(businessByIdProvider(businessId));

    return businessAsync.when(
      loading: () => Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/client');
              }
            },
          ),
        ),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (_, __) => Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/client');
              }
            },
          ),
        ),
        body: const EmptyState(
          icon: Icons.store_outlined,
          title: 'Negocio no encontrado',
          subtitle: 'No pudimos cargar este negocio en este momento.',
        ),
      ),
      data: (business) {
        if (business == null) {
          return Scaffold(
            appBar: AppBar(
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_rounded),
                onPressed: () {
                  if (context.canPop()) {
                    context.pop();
                  } else {
                    context.go('/client');
                  }
                },
              ),
            ),
            body: const EmptyState(
              icon: Icons.store_outlined,
              title: 'Negocio no encontrado',
              subtitle: 'El negocio que buscas no existe o fue eliminado.',
            ),
          );
        }

        final servicesAsync = ref.watch(businessServicesProvider(businessId));
        final services = servicesAsync.valueOrNull ?? [];
        final activeServices = services.where((service) => service.isActive).toList();
        final servicesLoading = servicesAsync.isLoading && servicesAsync.valueOrNull == null;
        final categoriesAsync = ref.watch(categoriesProvider);
        final categories = categoriesAsync.valueOrNull ?? [];
        final categoriesLoading = categoriesAsync.isLoading && categoriesAsync.valueOrNull == null;
        final category = categories.cast<BusinessCategory?>().firstWhere(
          (c) => c?.id == business.categoryId,
          orElse: () => null,
        ) ?? BusinessCategory(
          id: '',
          name: categoriesLoading ? 'Cargando...' : 'Sin categoria',
          icon: Icons.category,
          color: Colors.grey,
        );
        final isOwner = currentUser?.id == business.ownerId;

        return Scaffold(
          body: CustomScrollView(
            slivers: [
              // Hero section
              SliverAppBar(
                expandedHeight: 220,
                pinned: true,
                leading: _CircleBackButton(
                  onPressed: () {
                    if (context.canPop()) {
                      context.pop();
                    } else {
                      context.go('/client');
                    }
                  },
                ),
                actions: [
                  Padding(
                    padding: const EdgeInsets.only(right: AppSizes.s8),
                    child: _CircleIconButton(
                      icon: Icons.share_rounded,
                      onPressed: () {
                        Share.share(
                          'Mira ${business.name} en ReservPy. Reserva tu turno aca: ${publicBusinessUrl(business.id)}',
                          subject: business.name,
                        );
                      },
                    ),
                  ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background: _HeroGradient(
                    business: business,
                    category: category,
                  ),
                ),
              ),

              // Content
              SliverToBoxAdapter(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 800),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: AppSizes.s20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: AppSizes.s20),

                          // Info section
                          _InfoSection(business: business, category: category),

                          const SizedBox(height: AppSizes.s24),

                          // Management actions (owner only)
                          if (isOwner) ...[
                            _ManagementActions(),
                            const SizedBox(height: AppSizes.s24),
                          ],

                          PhotoCarousel(businessId: businessId),
                          const SizedBox(height: AppSizes.s24),

                          // Map section
                          _MapPlaceholder(
                            address: business.address ?? '',
                            latitude: business.latitude,
                            longitude: business.longitude,
                          ),

                          const SizedBox(height: AppSizes.s24),

                          // Services list
                          SectionHeader(
                            title: AppStrings.services,
                            actionLabel: servicesLoading
                                ? 'Cargando...'
                                : '${activeServices.length} disponibles',
                          ),

                          const SizedBox(height: AppSizes.s8),

                          if (servicesLoading)
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(AppSizes.s24),
                              decoration: BoxDecoration(
                                color: colorScheme.outline.withValues(alpha: 0.04),
                                borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                              ),
                              child: const Center(
                                child: CircularProgressIndicator(),
                              ),
                            )
                          else if (activeServices.isEmpty)
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(AppSizes.s32),
                              decoration: BoxDecoration(
                                color: colorScheme.outline.withValues(alpha: 0.06),
                                borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                              ),
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.design_services_outlined,
                                    size: 40,
                                    color: colorScheme.onSurface.withValues(alpha: 0.3),
                                  ),
                                  const SizedBox(height: AppSizes.s8),
                                  Text(
                                    'Este negocio aun no tiene servicios disponibles',
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: colorScheme.onSurface.withValues(alpha: 0.4),
                                    ),
                                  ),
                                ],
                              ),
                            )
                          else
                            ...List.generate(activeServices.length, (index) {
                              return _ServiceCard(
                                service: activeServices[index],
                                businessId: businessId,
                                delay: 350 + index * 80,
                              );
                            }),

                          const SizedBox(height: AppSizes.s24),

                          // Primary CTA
                          AppButton(
                            label: AppStrings.reserve,
                            icon: Icons.calendar_today_rounded,
                            onPressed: activeServices.isEmpty
                                ? null
                                : () {
                                    if (activeServices.length == 1) {
                                      context.push('/reserve/$businessId/time/${activeServices.first.id}');
                                      return;
                                    }
                                    context.push('/reserve/$businessId/service');
                                  },
                          ),

                          const SizedBox(height: AppSizes.s40),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          floatingActionButton: isOwner
              ? FloatingActionButton.extended(
                  heroTag: 'business_profile_fab',
                  onPressed: () {
                    context.push('/business-edit');
                  },
                  icon: const Icon(Icons.edit_rounded),
                  label: const Text(AppStrings.edit),
                )
              : null,
        );
      },
    );
  }

class _ManagementActions extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Gestión del negocio',
          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: AppSizes.s12),
        Row(
          children: [
            Expanded(
              child: _ActionChip(
                icon: Icons.people_rounded,
                label: 'Equipo',
                color: AppColors.info,
                onTap: () => context.push('/business-employees'),
              ),
            ),
            const SizedBox(width: AppSizes.s8),
            Expanded(
              child: _ActionChip(
                icon: Icons.bar_chart_rounded,
                label: 'Reportes',
                color: AppColors.success,
                onTap: () => context.push('/business-reports'),
              ),
            ),
            const SizedBox(width: AppSizes.s8),
            Expanded(
              child: _ActionChip(
                icon: Icons.notifications_active_rounded,
                label: 'Recordatorios',
                color: AppColors.warning,
                onTap: () => context.push('/business-reminders'),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSizes.s8),
        Row(
          children: [
            Expanded(
              child: _ActionChip(
                icon: Icons.people_outline_rounded,
                label: 'Clientes',
                color: Colors.indigo,
                onTap: () => context.push('/business-clients'),
              ),
            ),
            const SizedBox(width: AppSizes.s8),
            Expanded(
              child: _ActionChip(
                icon: Icons.spa_rounded,
                label: 'Servicios',
                color: Colors.purple,
                onTap: () => context.push('/business-services-manage'),
              ),
            ),
            const SizedBox(width: AppSizes.s8),
            Expanded(
              child: _ActionChip(
                icon: Icons.more_time_rounded,
                label: 'Disponibilidad',
                color: Colors.pink,
                onTap: () => context.push('/business-availability'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ActionChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionChip({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: color.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(AppSizes.radiusMd),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSizes.s12,
            vertical: AppSizes.s16,
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(height: AppSizes.s8),
              Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Hero Gradient ─────────────────────────────────────────────
class _HeroGradient extends StatelessWidget {
  final Business business;
  final BusinessCategory category;

  const _HeroGradient({required this.business, required this.category});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary,
            AppColors.accent,
          ],
        ),
      ),
      child: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSizes.s24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: AppSizes.s32),
                Text(
                  business.name,
                  style: theme.textTheme.headlineLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppSizes.s12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Category badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSizes.s12,
                        vertical: AppSizes.s4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(AppSizes.radiusFull),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(category.icon, size: 14, color: Colors.white),
                          const SizedBox(width: AppSizes.s4),
                          Text(
                            category.name,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSizes.s8),
                    // Open/closed badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSizes.s12,
                        vertical: AppSizes.s4,
                      ),
                      decoration: BoxDecoration(
                        color: business.isCurrentlyOpen
                            ? AppColors.success.withValues(alpha: 0.25)
                            : AppColors.error.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(AppSizes.radiusFull),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: business.isCurrentlyOpen
                                  ? AppColors.success
                                  : AppColors.error,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: AppSizes.s6),
                          Text(
                            business.isCurrentlyOpen
                                ? AppStrings.openNow
                                : AppStrings.closed,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
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

// ─── Info Section ──────────────────────────────────────────────
class _InfoSection extends StatelessWidget {
  final Business business;
  final BusinessCategory category;

  const _InfoSection({required this.business, required this.category});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AppCard(
      padding: const EdgeInsets.all(AppSizes.s20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Description
          if (business.description != null && business.description!.isNotEmpty) ...[
            Text(
              business.description!,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurface.withValues(alpha: 0.75),
                height: 1.5,
              ),
            ),
            const SizedBox(height: AppSizes.s16),
            Divider(color: colorScheme.outline.withValues(alpha: 0.2)),
            const SizedBox(height: AppSizes.s12),
          ],

          // Address
          if (business.address != null)
            _InfoRow(
              icon: Icons.location_on_outlined,
              text: business.address!,
              color: colorScheme.primary,
              onTap: () => _openAddress(business.address!),
            ),

          // Phone
          if (business.phone != null) ...[
            const SizedBox(height: AppSizes.s12),
            _InfoRow(
              icon: Icons.phone_outlined,
              text: business.phone!,
              color: colorScheme.primary,
              onTap: () => _openPhone(business.phone!),
            ),
          ],

          // Website
          if (business.website != null) ...[
            const SizedBox(height: AppSizes.s12),
            _InfoRow(
              icon: Icons.language_rounded,
              text: business.website!,
              color: colorScheme.primary,
              onTap: () => _openWebsite(business.website!),
            ),
          ],

          // Hours
          const SizedBox(height: AppSizes.s12),
          _InfoRow(
            icon: Icons.access_time_rounded,
            text: '${business.openingTimeStr} – ${business.closingTimeStr}',
            color: colorScheme.primary,
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
  final VoidCallback? onTap;

  const _InfoRow({
    required this.icon,
    required this.text,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final row = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: AppSizes.s8),
        Expanded(
          child: Text(
            text,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: onTap != null ? color : null,
              decoration: onTap != null ? TextDecoration.underline : null,
            ),
          ),
        ),
      ],
    );

    if (onTap == null) return row;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSizes.radiusSm),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSizes.s2),
        child: row,
      ),
    );
  }
}

Future<void> _openAddress(String address) async {
  final query = Uri.encodeComponent(address.trim());
  await _launchExternal(Uri.parse('https://www.google.com/maps/search/?api=1&query=$query'));
}

Future<void> _openMapLocation({
  required String address,
  required double? latitude,
  required double? longitude,
}) async {
  if (latitude != null && longitude != null) {
    await _launchExternal(
      Uri.parse('https://www.google.com/maps/search/?api=1&query=$latitude,$longitude'),
    );
    return;
  }
  if (address.trim().isNotEmpty) {
    await _openAddress(address);
  }
}

Future<void> _openPhone(String phone) async {
  await _launchExternal(Uri(scheme: 'tel', path: phone.trim()));
}

Future<void> _openWebsite(String website) async {
  final trimmed = website.trim();
  final normalized = trimmed.startsWith('http://') || trimmed.startsWith('https://')
      ? trimmed
      : 'https://$trimmed';
  await _launchExternal(Uri.parse(normalized));
}

Future<void> _launchExternal(Uri uri) async {
  try {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  } catch (_) {
    // Ignore launch failures on unsupported platforms.
  }
}

// ─── Map Placeholder ───────────────────────────────────────────
class _MapPlaceholder extends StatelessWidget {
  final String address;
  final double? latitude;
  final double? longitude;

  const _MapPlaceholder({
    required this.address,
    required this.latitude,
    required this.longitude,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final hasLocation = latitude != null && longitude != null;
    final canOpenMap = hasLocation || address.trim().isNotEmpty;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: canOpenMap
            ? () => _openMapLocation(
                  address: address,
                  latitude: latitude,
                  longitude: longitude,
                )
            : null,
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        child: Container(
          height: 200,
          width: double.infinity,
          decoration: BoxDecoration(
            color: colorScheme.outline.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(AppSizes.radiusMd),
            border: Border.all(color: colorScheme.outline.withValues(alpha: 0.2)),
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            children: [
              Positioned.fill(
                child: hasLocation
                    ? FlutterMap(
                        options: MapOptions(
                          initialCenter: LatLng(latitude!, longitude!),
                          initialZoom: 15,
                          interactionOptions: const InteractionOptions(
                            flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
                          ),
                        ),
                        children: [
                          TileLayer(
                            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                            userAgentPackageName: 'reservpy-app',
                          ),
                          MarkerLayer(
                            markers: [
                              Marker(
                                point: LatLng(latitude!, longitude!),
                                width: 44,
                                height: 44,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: colorScheme.primary,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: colorScheme.primary.withValues(alpha: 0.3),
                                        blurRadius: 12,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.storefront_rounded,
                                    color: Colors.white,
                                    size: 22,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              color: colorScheme.primary.withValues(alpha: 0.12),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.place_rounded,
                              size: 28,
                              color: colorScheme.primary,
                            ),
                          ),
                          const SizedBox(height: AppSizes.s12),
                          if (address.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: AppSizes.s24),
                              child: Text(
                                address,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: colorScheme.onSurface.withValues(alpha: 0.5),
                                ),
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            )
                          else
                            Text(
                              'Mapa no disponible',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurface.withValues(alpha: 0.4),
                              ),
                            ),
                        ],
                      ),
              ),
              if (canOpenMap)
                Positioned(
                  right: AppSizes.s12,
                  bottom: AppSizes.s12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSizes.s10,
                      vertical: AppSizes.s8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(AppSizes.radiusFull),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.open_in_new_rounded,
                          size: 14,
                          color: Colors.white,
                        ),
                        const SizedBox(width: AppSizes.s6),
                        Text(
                          'Abrir mapa',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
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
    );
  }
}

// ─── Service Card ──────────────────────────────────────────────
class _ServiceCard extends StatelessWidget {
  final ServiceModel service;
  final String businessId;
  final int delay;

  const _ServiceCard({
    required this.service,
    required this.businessId,
    this.delay = 0,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AppCard(
      padding: const EdgeInsets.all(AppSizes.s16),
      child: Row(
        children: [
          // Icon
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppSizes.radiusSm),
            ),
            child: Icon(
              Icons.design_services_rounded,
              size: 24,
              color: colorScheme.primary,
            ),
          ),
          const SizedBox(width: AppSizes.s12),

          // Name + details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  service.name,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppSizes.s4),
                Row(
                  children: [
                    Icon(
                      Icons.timer_outlined,
                      size: 14,
                      color: colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                    const SizedBox(width: AppSizes.s4),
                    Text(
                      service.formattedDuration,
                      style: theme.textTheme.bodySmall,
                    ),
                    const SizedBox(width: AppSizes.s12),
                    Text(
                      service.formattedPrice,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Reserve button
          AppButton(
            label: AppStrings.reserve,
            width: 100,
            height: AppSizes.buttonSm,
            onPressed: () {
              context.push('/reserve/$businessId/time/${service.id}');
            },
          ),
        ],
      ),
    );
  }
}

// ─── Circle Back Button ────────────────────────────────────────
class _CircleBackButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _CircleBackButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSizes.s8),
      child: CircleAvatar(
        backgroundColor: Colors.black.withValues(alpha: 0.3),
        child: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 20),
          onPressed: onPressed,
        ),
      ),
    );
  }
}

// ─── Circle Icon Button ────────────────────────────────────────
class _CircleIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;

  const _CircleIconButton({
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      backgroundColor: Colors.black.withValues(alpha: 0.3),
      child: IconButton(
        icon: Icon(icon, color: Colors.white, size: 20),
        onPressed: onPressed,
      ),
    );
  }
}
