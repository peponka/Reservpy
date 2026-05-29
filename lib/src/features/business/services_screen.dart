import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:reservpy/src/core/constants/app_colors.dart';
import 'package:reservpy/src/core/constants/app_sizes.dart';
import 'package:reservpy/src/core/widgets/widgets.dart';
import 'package:reservpy/src/shared/providers/providers.dart';
import 'package:reservpy/src/shared/models/models.dart';
import 'package:reservpy/src/data/repositories/service_repository.dart';

class ServicesScreen extends ConsumerWidget {
  const ServicesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final business = ref.watch(currentBusinessProvider);
    final businessId = business?.id;

    if (businessId == null) {
      return const Center(child: Text('No hay negocio seleccionado'));
    }

    return _ServicesBody(businessId: businessId);
  }
}

/// Inner widget that watches the async provider keyed by businessId.
class _ServicesBody extends ConsumerWidget {
  final String businessId;
  const _ServicesBody({required this.businessId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final servicesAsync = ref.watch(businessServicesProvider(businessId));

    return servicesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error al cargar servicios: $e')),
      data: (services) {
        // Compute KPI values
        final activeServices = services.where((s) => s.isActive).toList();
        final pausedServices = services.where((s) => !s.isActive).toList();
        final avgDuration = activeServices.isEmpty
            ? 0
            : (activeServices.map((s) => s.durationMinutes).reduce((a, b) => a + b) / activeServices.length).round();
        final maxPrice = activeServices.isEmpty
            ? 0.0
            : activeServices.map((s) => s.price ?? 0).reduce((a, b) => a > b ? a : b);

        return LayoutBuilder(
          builder: (context, constraints) {
            final isMobile = constraints.maxWidth < 768;
            return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSizes.s24,
            vertical: AppSizes.s16,
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: constraints.maxHeight - 32,
              maxWidth: constraints.maxWidth - 48,
            ),
            child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Cabecera ──
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Servicios',
                    style: theme.textTheme.headlineLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: AppSizes.s4),
                  Text(
                    'Gestioná los servicios que ofrecés',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.outline,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSizes.s12),
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton.icon(
                  onPressed: () => _showServiceForm(
                    context: context,
                    ref: ref,
                    businessId: businessId,
                  ),
                  icon: const Icon(Icons.add_rounded, size: 20),
                  label: const Text('Nuevo servicio'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    foregroundColor: colorScheme.onPrimary,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSizes.s16,
                      vertical: AppSizes.s12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                    ),
                    elevation: 0,
                  ),
                ),
              ),

              const SizedBox(height: AppSizes.s24),

              // ── KPI Cards ──
              LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth >= 600;
                  final metrics = [
                    _MetricCard(
                      value: '${activeServices.length}',
                      label: 'Servicios activos',
                      icon: Icons.store_rounded,
                      color: colorScheme.primary,
                    ),
                    _MetricCard(
                      value: '$avgDuration min',
                      label: 'Duración promedio',
                      icon: Icons.access_time_rounded,
                      color: AppColors.info,
                    ),
                    _MetricCard(
                      value: '₲ ${maxPrice.toStringAsFixed(0)}',
                      label: 'Servicio más caro',
                      icon: Icons.payments_rounded,
                      color: AppColors.success,
                    ),
                    _MetricCard(
                      value: '${pausedServices.length}',
                      label: 'Servicios pausados',
                      icon: Icons.pause_circle_rounded,
                      color: colorScheme.outline,
                    ),
                  ];

                  if (isWide) {
                    return Row(
                      children: metrics.map((m) => Expanded(child: Padding(padding: const EdgeInsets.symmetric(horizontal: AppSizes.s4), child: m))).toList(),
                    );
                  } else {
                    return GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: AppSizes.s12,
                      mainAxisSpacing: AppSizes.s12,
                      childAspectRatio: 1.5,
                      children: metrics,
                    );
                  }
                },
              ),

              const SizedBox(height: AppSizes.s32),

              // ── Tabla/Listado de Servicios ──
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: theme.cardTheme.color,
                  borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                  border: Border.all(
                    color: colorScheme.outline.withValues(alpha: 0.08),
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
                    if (!isMobile) ...[
                      // Tabla Header (desktop only)
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSizes.s20,
                          vertical: AppSizes.s16,
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: Text(
                                'SERVICIO',
                                style: theme.textTheme.labelMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: colorScheme.outline,
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(
                                'DURACIÓN',
                                style: theme.textTheme.labelMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: colorScheme.outline,
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(
                                'PRECIO',
                                style: theme.textTheme.labelMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: colorScheme.outline,
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Align(
                                alignment: Alignment.centerRight,
                                child: Text(
                                  'ACCIONES',
                                  style: theme.textTheme.labelMedium?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: colorScheme.outline,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Divider(height: 1),
                    ],

                    // Dynamic service rows
                    if (services.isEmpty)
                      Padding(
                        padding: const EdgeInsets.all(AppSizes.s24),
                        child: Center(
                          child: Text(
                            'No hay servicios creados aún',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: colorScheme.outline,
                            ),
                          ),
                        ),
                      )
                    else
                      ...services.map((service) => Column(
                        children: [
                          _ServiceRow(
                            service: service,
                            isMobile: isMobile,
                            onEdit: () => _showServiceForm(
                              context: context,
                              ref: ref,
                              businessId: businessId,
                              service: service,
                            ),
                            onToggle: () => _toggleActive(context, ref, businessId, service),
                          ),
                          const Divider(height: 1),
                        ],
                      )),

                    // + Agregar nuevo servicio Card Button at bottom
                    InkWell(
                      onTap: () => _showServiceForm(
                        context: context,
                        ref: ref,
                        businessId: businessId,
                      ),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: AppSizes.s20),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.04),
                          borderRadius: const BorderRadius.only(
                            bottomLeft: Radius.circular(AppSizes.radiusLg),
                            bottomRight: Radius.circular(AppSizes.radiusLg),
                          ),
                          border: Border(
                            top: BorderSide(
                              color: AppColors.primary.withValues(alpha: 0.1),
                            ),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.add_rounded,
                              color: colorScheme.primary,
                              size: 20,
                            ),
                            const SizedBox(width: AppSizes.s8),
                            Text(
                              'Agregar nuevo servicio',
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: colorScheme.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          ),  // ConstrainedBox
        );  // SingleChildScrollView
          },  // LayoutBuilder builder
        );  // LayoutBuilder
      },
    );
  }

  // ─── Actions ───────────────────────────────────────────────

  Future<void> _toggleActive(
    BuildContext context,
    WidgetRef ref,
    String businessId,
    ServiceModel service,
  ) async {
    try {
      await ServiceRepository().toggleActive(service.id, !service.isActive);
      ref.invalidate(businessServicesProvider(businessId));
      ref.invalidate(servicesProvider);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cambiar estado: $e')),
        );
      }
    }
  }

  void _showServiceForm({
    required BuildContext context,
    required WidgetRef ref,
    required String businessId,
    ServiceModel? service,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ServiceFormSheet(
        service: service,
        businessId: businessId,
        onSave: (saved) async {
          try {
            if (service != null) {
              await ServiceRepository().update(saved);
            } else {
              await ServiceRepository().create(saved);
            }
            ref.invalidate(businessServicesProvider(businessId));
            ref.invalidate(servicesProvider);
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      const Icon(Icons.check_circle_rounded,
                          color: Colors.white, size: 18),
                      const SizedBox(width: AppSizes.s8),
                      Expanded(
                        child: Text(service != null
                            ? '${saved.name} actualizado'
                            : '${saved.name} creado'),
                      ),
                    ],
                  ),
                ),
              );
            }
          } catch (e) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Error al guardar: $e')),
              );
            }
          }
        },
      ),
    );
  }
}

/// A single service row in the services table or mobile stacked view.
class _ServiceRow extends StatelessWidget {
  final ServiceModel service;
  final bool isMobile;
  final VoidCallback onEdit;
  final VoidCallback onToggle;
  const _ServiceRow({
    required this.service,
    required this.isMobile,
    required this.onEdit,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isActive = service.isActive;

    if (isMobile) {
      // Stacked responsive layout for mobile
      return Padding(
        padding: const EdgeInsets.all(AppSizes.s16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                  ),
                  child: Icon(
                    Icons.content_cut_rounded,
                    color: colorScheme.primary,
                    size: 18,
                  ),
                ),
                const SizedBox(width: AppSizes.s12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: Text(
                              service.name,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: AppSizes.s8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSizes.s6,
                              vertical: AppSizes.s2,
                            ),
                            decoration: BoxDecoration(
                              color: (isActive ? AppColors.success : AppColors.warning).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                              border: Border.all(
                                color: (isActive ? AppColors.success : AppColors.warning).withValues(alpha: 0.25),
                                width: 1.2,
                              ),
                            ),
                            child: Text(
                              isActive ? 'Activo' : 'Pausado',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: isActive ? AppColors.success : AppColors.warning,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSizes.s2),
                      Text(
                        service.description ?? 'Sin descripción',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.outline,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSizes.s12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.access_time_rounded,
                      size: 14,
                      color: colorScheme.outline,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      service.formattedDuration,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      service.formattedPrice,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    IconButton(
                      onPressed: onEdit,
                      icon: const Icon(Icons.edit_rounded, size: 16),
                      constraints: const BoxConstraints(),
                      style: IconButton.styleFrom(
                        padding: EdgeInsets.zero,
                        visualDensity: VisualDensity.compact,
                      ),
                      tooltip: 'Editar',
                    ),
                    const SizedBox(width: 12),
                    IconButton(
                      onPressed: onToggle,
                      icon: Icon(
                        isActive ? Icons.pause_rounded : Icons.play_arrow_rounded,
                        size: 16,
                        color: isActive ? AppColors.warning : AppColors.success,
                      ),
                      constraints: const BoxConstraints(),
                      style: IconButton.styleFrom(
                        padding: EdgeInsets.zero,
                        visualDensity: VisualDensity.compact,
                      ),
                      tooltip: isActive ? 'Pausar' : 'Activar',
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      );
    }

    // Desktop/Tablet Row View (Original)
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.s20,
        vertical: AppSizes.s16,
      ),
      child: Row(
        children: [
          // Service column
          Expanded(
            flex: 3,
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                  ),
                  child: Icon(
                    Icons.content_cut_rounded,
                    color: colorScheme.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: AppSizes.s12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: Text(
                              service.name,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: AppSizes.s8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSizes.s6,
                              vertical: AppSizes.s2,
                            ),
                            decoration: BoxDecoration(
                              color: (isActive ? AppColors.success : AppColors.warning).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                              border: Border.all(
                                color: (isActive ? AppColors.success : AppColors.warning).withValues(alpha: 0.25),
                                width: 1.2,
                              ),
                            ),
                            child: Text(
                              isActive ? 'Activo' : 'Pausado',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: isActive ? AppColors.success : AppColors.warning,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSizes.s2),
                      Text(
                        service.description ?? 'Sin descripción',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.outline,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Duration column
          Expanded(
            flex: 2,
            child: Row(
              children: [
                Icon(
                  Icons.access_time_rounded,
                  size: 16,
                  color: colorScheme.outline,
                ),
                const SizedBox(width: AppSizes.s6),
                Text(
                  service.formattedDuration,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          // Price column
          Expanded(
            flex: 2,
            child: Text(
              service.formattedPrice,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          // Actions column
          Expanded(
            flex: 2,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_rounded, size: 14),
                  label: const Text('Editar'),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: AppSizes.s8),
                    visualDensity: VisualDensity.compact,
                  ),
                ),
                TextButton.icon(
                  onPressed: onToggle,
                  icon: Icon(
                    isActive ? Icons.pause_rounded : Icons.play_arrow_rounded,
                    size: 14,
                    color: isActive ? AppColors.warning : AppColors.success,
                  ),
                  label: Text(
                    isActive ? 'Pausar' : 'Activar',
                    style: TextStyle(color: isActive ? AppColors.warning : AppColors.success),
                  ),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: AppSizes.s8),
                    visualDensity: VisualDensity.compact,
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

class _MetricCard extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  final Color color;

  const _MetricCard({
    required this.value,
    required this.label,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(AppSizes.s16),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        gradient: LinearGradient(
          colors: [
            theme.cardTheme.color ?? Colors.white,
            color.withValues(alpha: 0.02),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
          color: color.withValues(alpha: 0.15),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSizes.s8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: color,
              size: 24,
            ),
          ),
          const SizedBox(width: AppSizes.s12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  value,
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 22,
                  ),
                ),
                const SizedBox(height: AppSizes.s2),
                Text(
                  label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.outline,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// SERVICE FORM BOTTOM SHEET
// ═══════════════════════════════════════════════════════════════════

/// Duration presets in minutes.
const List<int> _durationPresets = [15, 30, 45, 60, 90, 120];

class _ServiceFormSheet extends StatefulWidget {
  final ServiceModel? service;
  final String businessId;
  final ValueChanged<ServiceModel> onSave;

  const _ServiceFormSheet({
    this.service,
    required this.businessId,
    required this.onSave,
  });

  @override
  State<_ServiceFormSheet> createState() => _ServiceFormSheetState();
}

class _ServiceFormSheetState extends State<_ServiceFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _descCtrl;
  late final TextEditingController _priceCtrl;
  late int _durationMinutes;
  late bool _isActive;

  bool get _isEditing => widget.service != null;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.service?.name ?? '');
    _descCtrl = TextEditingController(text: widget.service?.description ?? '');
    _priceCtrl = TextEditingController(
      text: widget.service?.price != null
          ? widget.service!.price!.toStringAsFixed(0)
          : '',
    );
    _durationMinutes = widget.service?.durationMinutes ?? 30;
    _isActive = widget.service?.isActive ?? true;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _priceCtrl.dispose();
    super.dispose();
  }

  void _handleSave() {
    if (!_formKey.currentState!.validate()) return;

    final priceText = _priceCtrl.text.trim();
    final service = ServiceModel(
      id: widget.service?.id ?? '',
      businessId: widget.service?.businessId ?? widget.businessId,
      name: _nameCtrl.text.trim(),
      description: _descCtrl.text.trim().isNotEmpty ? _descCtrl.text.trim() : null,
      durationMinutes: _durationMinutes,
      price: priceText.isNotEmpty ? double.tryParse(priceText) : null,
      currency: widget.service?.currency ?? 'PYG',
      isActive: _isActive,
      sortOrder: widget.service?.sortOrder ?? 0,
    );

    widget.onSave(service);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppSizes.radiusXl),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Drag handle ──
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: AppSizes.s12),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: colorScheme.outline.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // ── Header ──
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSizes.s20, AppSizes.s16, AppSizes.s12, 0,
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSizes.s8),
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                  ),
                  child: Icon(
                    _isEditing
                        ? Icons.edit_rounded
                        : Icons.add_business_rounded,
                    color: colorScheme.primary,
                    size: 22,
                  ),
                ),
                const SizedBox(width: AppSizes.s12),
                Text(
                  _isEditing ? 'Editar servicio' : 'Nuevo servicio',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSizes.s8),
          Divider(color: colorScheme.outline.withValues(alpha: 0.15)),

          // ── Scrollable form ──
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                AppSizes.s20, AppSizes.s16, AppSizes.s20, AppSizes.s24,
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Name ──
                    AppTextField(
                      controller: _nameCtrl,
                      label: 'Nombre del servicio',
                      prefixIcon: Icons.content_cut_rounded,
                      hint: 'Ej: Corte de cabello, Manicura…',
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'El nombre es obligatorio';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: AppSizes.s16),

                    // ── Description ──
                    AppTextField(
                      controller: _descCtrl,
                      label: 'Descripción (opcional)',
                      prefixIcon: Icons.description_rounded,
                      hint: 'Breve descripción del servicio…',
                      maxLines: 2,
                    ),

                    const SizedBox(height: AppSizes.s16),

                    // ── Price ──
                    AppTextField(
                      controller: _priceCtrl,
                      label: 'Precio (Gs.)',
                      prefixIcon: Icons.payments_rounded,
                      hint: 'Ej: 50000',
                      keyboardType: TextInputType.number,
                    ),

                    const SizedBox(height: AppSizes.s24),

                    // ── Duration ──
                    Text(
                      'Duración',
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: AppSizes.s12),
                    Wrap(
                      spacing: AppSizes.s8,
                      runSpacing: AppSizes.s8,
                      children: _durationPresets.map((mins) {
                        final isSelected = _durationMinutes == mins;
                        return GestureDetector(
                          onTap: () => setState(() => _durationMinutes = mins),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSizes.s16,
                              vertical: AppSizes.s8,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? colorScheme.primary.withValues(alpha: 0.12)
                                  : colorScheme.outline.withValues(alpha: 0.06),
                              borderRadius:
                                  BorderRadius.circular(AppSizes.radiusFull),
                              border: Border.all(
                                color: isSelected
                                    ? colorScheme.primary
                                    : colorScheme.outline.withValues(alpha: 0.2),
                                width: isSelected ? 1.5 : 1,
                              ),
                            ),
                            child: Text(
                              mins >= 60
                                  ? '${mins ~/ 60}h${mins % 60 > 0 ? ' ${mins % 60}m' : ''}'
                                  : '$mins min',
                              style: TextStyle(
                                fontWeight: isSelected
                                    ? FontWeight.w700
                                    : FontWeight.w400,
                                color: isSelected
                                    ? colorScheme.primary
                                    : colorScheme.onSurface.withValues(alpha: 0.7),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: AppSizes.s24),

                    // ── Active toggle ──
                    AppCard(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSizes.s16,
                        vertical: AppSizes.s4,
                      ),
                      child: SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          'Servicio activo',
                          style: theme.textTheme.titleSmall,
                        ),
                        subtitle: Text(
                          _isActive
                              ? 'Visible y disponible para reservas'
                              : 'No aparecerá en las opciones de reserva',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color:
                                colorScheme.onSurface.withValues(alpha: 0.5),
                          ),
                        ),
                        value: _isActive,
                        activeThumbColor: colorScheme.primary,
                        onChanged: (v) => setState(() => _isActive = v),
                      ),
                    ),

                    const SizedBox(height: AppSizes.s24),

                    // ── Save button ──
                    AppButton(
                      label: _isEditing ? 'Guardar cambios' : 'Crear servicio',
                      icon: _isEditing
                          ? Icons.save_rounded
                          : Icons.add_business_rounded,
                      onPressed: _handleSave,
                    ),

                    const SizedBox(height: AppSizes.s16),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
