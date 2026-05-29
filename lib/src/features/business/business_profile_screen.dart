import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import 'package:reservpy/src/shared/models/models.dart';
import 'package:reservpy/src/shared/providers/providers.dart';
import 'package:reservpy/src/core/widgets/widgets.dart';
import 'package:reservpy/src/core/constants/app_colors.dart';
import 'package:reservpy/src/core/constants/app_sizes.dart';
import 'package:reservpy/src/core/constants/app_strings.dart';

/// Public profile screen for a single business.
///
/// Displays a hero gradient section, business details, map placeholder,
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
    final businesses = ref.watch(businessesProvider).value ?? [];
    final currentUser = ref.watch(currentUserProvider);

    // Find the business by ID.
    final business = businesses.cast<Business?>().firstWhere(
          (b) => b?.id == businessId,
          orElse: () => null,
        );

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
          subtitle: 'El negocio que buscás no existe o fue eliminado.',
        ),
      );
    }

    final services = ref.watch(businessServicesProvider(businessId)).value ?? [];
    final categories = ref.watch(categoriesProvider).value ?? [];
    final category = categories.cast<BusinessCategory?>().firstWhere(
      (c) => c?.id == business.categoryId,
      orElse: () => null,
    ) ?? const BusinessCategory(id: '', name: 'Cargando...', icon: Icons.category, color: Colors.grey);
    final isOwner = currentUser?.id == business.ownerId;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // ─── Hero Section ──────────────────────────────────
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
                      '¡Mirá ${business.name} en ReservPy! Reservá tu turno ahora.',
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

          // ─── Content ────────────────────────────────────────
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

                      // ─── Info Section ────────────────────────
                      _InfoSection(business: business, category: category),

                      const SizedBox(height: AppSizes.s24),

                      // ─── Management Actions (Owner only) ──────
                      if (isOwner) ...[
                        _ManagementActions(),
                        const SizedBox(height: AppSizes.s24),
                      ],

                      // ─── Map Placeholder ─────────────────────
                      _MapPlaceholder(address: business.address ?? ''),

                      const SizedBox(height: AppSizes.s24),

                      // ─── Services List ───────────────────────
                      SectionHeader(
                        title: AppStrings.services,
                        actionLabel: '${services.length} disponibles',
                      ),

                      const SizedBox(height: AppSizes.s8),

                      if (services.isEmpty)
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
                                'Este negocio aún no tiene servicios',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: colorScheme.onSurface.withValues(alpha: 0.4),
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        ...List.generate(services.length, (index) {
                          return _ServiceCard(
                            service: services[index],
                            businessId: businessId,
                            delay: 350 + index * 80,
                          );
                        }),

                      const SizedBox(height: AppSizes.s24),

                      // ─── Primary CTA ─────────────────────────
                      AppButton(
                        label: AppStrings.reserve,
                        icon: Icons.calendar_today_rounded,
                        onPressed: () {
                          // Navigate to reservation flow with business pre-selected.
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
  }
}

// ─── Management Actions (Owner Only) ────────────────────
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
            ),

          // Phone
          if (business.phone != null) ...[
            const SizedBox(height: AppSizes.s12),
            _InfoRow(
              icon: Icons.phone_outlined,
              text: business.phone!,
              color: colorScheme.primary,
            ),
          ],

          // Website
          if (business.website != null) ...[
            const SizedBox(height: AppSizes.s12),
            _InfoRow(
              icon: Icons.language_rounded,
              text: business.website!,
              color: colorScheme.primary,
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

  const _InfoRow({
    required this.icon,
    required this.text,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: AppSizes.s8),
        Expanded(
          child: Text(
            text,
            style: theme.textTheme.bodyMedium,
          ),
        ),
      ],
    );
  }
}

// ─── Map Placeholder ───────────────────────────────────────────
class _MapPlaceholder extends StatelessWidget {
  final String address;

  const _MapPlaceholder({required this.address});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      height: 200,
      width: double.infinity,
      decoration: BoxDecoration(
        color: colorScheme.outline.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.2)),
      ),
      child: Column(
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
