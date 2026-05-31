import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../../core/widgets/widgets.dart';
import '../../shared/models/models.dart';
import '../../shared/providers/providers.dart';

/// Multi-step business editing flow using a [PageController].
///
/// **Step 1 — Business Info**: Name, address, phone, website (pre-filled).
/// **Step 2 — Schedule & Config**: Description, opening/closing times, slot duration.
/// **Step 3 — Services**: List existing services with edit/delete, add new service dialog.
///
/// All fields are pre-populated from the current business data via
/// [currentBusinessProvider] and [businessServicesProvider].
class EditBusinessScreen extends ConsumerStatefulWidget {
  const EditBusinessScreen({super.key});

  @override
  ConsumerState<EditBusinessScreen> createState() => _EditBusinessScreenState();
}

class _EditBusinessScreenState extends ConsumerState<EditBusinessScreen> {
  final _pageController = PageController();
  int _currentStep = 0;
  static const int _totalSteps = 3;

  // Step 1 — Business Info
  final _infoFormKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  final _websiteController = TextEditingController();

  // Step 2 — Schedule & Config

  final _descriptionController = TextEditingController();
  TimeOfDay _openingTime = const TimeOfDay(hour: 8, minute: 0);
  TimeOfDay _closingTime = const TimeOfDay(hour: 18, minute: 0);
  int _slotDurationMinutes = 30;

  // Step 3 — Services
  List<ServiceModel> _services = [];

  bool _isSaving = false;
  bool _initialized = false;
  double? _latitude;
  double? _longitude;

  /// Pre-fill all fields from the existing business.
  void _initializeFromBusiness(Business business) {
    if (_initialized) return;
    _initialized = true;

    _nameController.text = business.name;
    _addressController.text = business.address ?? '';
    _phoneController.text = business.phone ?? '';
    _websiteController.text = business.website ?? '';
    _descriptionController.text = business.description ?? '';
    _openingTime = business.openingTime;
    _closingTime = business.closingTime;
    _slotDurationMinutes = business.slotDurationMinutes;
    _latitude = business.latitude;
    _longitude = business.longitude;

    // Load existing services
    final existingServices = ref.read(businessServicesProvider(business.id)).value ?? [];
    _services = List<ServiceModel>.from(existingServices);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _websiteController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  // ─── Navigation ──────────────────────────────────────────

  /// Validates current step and advances the PageView.
  void _goToNextStep() {
    if (_currentStep == 0) {
      if (!_infoFormKey.currentState!.validate()) return;
    } else if (_currentStep == 1) {
      if (_descriptionController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Agregá una descripción para tu negocio'),
          ),
        );
        return;
      }
    }

    if (_currentStep < _totalSteps - 1) {
      setState(() => _currentStep++);
      _pageController.animateToPage(
        _currentStep,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    }
  }

  void _goToPreviousStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
      _pageController.animateToPage(
        _currentStep,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    }
  }

  // ─── Time Picker ─────────────────────────────────────────

  Future<void> _pickTime({required bool isOpening}) async {
    final initial = isOpening ? _openingTime : _closingTime;
    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
    );
    if (picked != null && mounted) {
      setState(() {
        if (isOpening) {
          _openingTime = picked;
        } else {
          _closingTime = picked;
        }
      });
    }
  }

  // ─── Service Dialogs ─────────────────────────────────────

  /// Shows a dialog to add a new service.
  Future<void> _showAddServiceDialog() async {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();
    final durationController = TextEditingController(text: '30');
    final priceController = TextEditingController(text: '0');
    final dialogFormKey = GlobalKey<FormState>();

    final result = await showDialog<ServiceModel>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizes.radiusLg),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSizes.s8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                ),
                child: const Icon(
                  Icons.add_circle_outline_rounded,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: AppSizes.s12),
              const Text('Agregar servicio'),
            ],
          ),
          content: Form(
            key: dialogFormKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AppTextField(
                    controller: nameController,
                    label: 'Nombre del servicio',
                    prefixIcon: Icons.design_services_rounded,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'Nombre es requerido';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: AppSizes.s12),
                  AppTextField(
                    controller: descriptionController,
                    label: 'Descripción (opcional)',
                    prefixIcon: Icons.notes_rounded,
                    maxLines: 2,
                  ),
                  const SizedBox(height: AppSizes.s12),
                  AppTextField(
                    controller: durationController,
                    label: 'Duración (minutos)',
                    prefixIcon: Icons.timer_outlined,
                    keyboardType: TextInputType.number,
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Requerido';
                      final n = int.tryParse(v);
                      if (n == null || n <= 0) return 'Ingresá un número válido';
                      return null;
                    },
                  ),
                  const SizedBox(height: AppSizes.s12),
                  AppTextField(
                    controller: priceController,
                    label: 'Precio (Gs.)',
                    prefixIcon: Icons.attach_money_rounded,
                    keyboardType: TextInputType.number,
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Requerido';
                      if (double.tryParse(v) == null) {
                        return 'Ingresá un número válido';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton.icon(
              onPressed: () {
                if (!dialogFormKey.currentState!.validate()) return;
                final service = ServiceModel(
                  id: const Uuid().v4(),
                  businessId: '',
                  name: nameController.text.trim(),
                  description: descriptionController.text.trim().isNotEmpty
                      ? descriptionController.text.trim()
                      : null,
                  durationMinutes: int.parse(durationController.text.trim()),
                  price: double.parse(priceController.text.trim()),
                );
                Navigator.of(ctx).pop(service);
              },
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Agregar'),
            ),
          ],
        );
      },
    );

    if (result != null && mounted) {
      setState(() => _services.add(result));
    }
  }

  /// Shows a dialog to edit an existing service.
  Future<void> _showEditServiceDialog(int index) async {
    final service = _services[index];
    final nameController = TextEditingController(text: service.name);
    final descriptionController =
        TextEditingController(text: service.description ?? '');
    final durationController =
        TextEditingController(text: service.durationMinutes.toString());
    final priceController =
        TextEditingController(text: (service.price ?? 0).toStringAsFixed(0));
    final dialogFormKey = GlobalKey<FormState>();

    final result = await showDialog<ServiceModel>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizes.radiusLg),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSizes.s8),
                decoration: BoxDecoration(
                  color: AppColors.info.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                ),
                child: const Icon(
                  Icons.edit_rounded,
                  color: AppColors.info,
                  size: 20,
                ),
              ),
              const SizedBox(width: AppSizes.s12),
              const Expanded(
                child: Text('Editar servicio', overflow: TextOverflow.ellipsis),
              ),
            ],
          ),
          content: Form(
            key: dialogFormKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AppTextField(
                    controller: nameController,
                    label: 'Nombre del servicio',
                    prefixIcon: Icons.design_services_rounded,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'Nombre es requerido';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: AppSizes.s12),
                  AppTextField(
                    controller: descriptionController,
                    label: 'Descripción (opcional)',
                    prefixIcon: Icons.notes_rounded,
                    maxLines: 2,
                  ),
                  const SizedBox(height: AppSizes.s12),
                  AppTextField(
                    controller: durationController,
                    label: 'Duración (minutos)',
                    prefixIcon: Icons.timer_outlined,
                    keyboardType: TextInputType.number,
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Requerido';
                      final n = int.tryParse(v);
                      if (n == null || n <= 0) return 'Ingresá un número válido';
                      return null;
                    },
                  ),
                  const SizedBox(height: AppSizes.s12),
                  AppTextField(
                    controller: priceController,
                    label: 'Precio (Gs.)',
                    prefixIcon: Icons.attach_money_rounded,
                    keyboardType: TextInputType.number,
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Requerido';
                      if (double.tryParse(v) == null) {
                        return 'Ingresá un número válido';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton.icon(
              onPressed: () {
                if (!dialogFormKey.currentState!.validate()) return;
                final updated = ServiceModel(
                  id: service.id,
                  businessId: service.businessId,
                  name: nameController.text.trim(),
                  description: descriptionController.text.trim().isNotEmpty
                      ? descriptionController.text.trim()
                      : null,
                  durationMinutes: int.parse(durationController.text.trim()),
                  price: double.parse(priceController.text.trim()),
                  currency: service.currency,
                  isActive: service.isActive,
                  sortOrder: service.sortOrder,
                );
                Navigator.of(ctx).pop(updated);
              },
              icon: const Icon(Icons.check_rounded, size: 18),
              label: const Text('Guardar'),
            ),
          ],
        );
      },
    );

    if (result != null && mounted) {
      setState(() => _services[index] = result);
    }
  }

  /// Confirms and deletes a service at [index].
  Future<void> _confirmDeleteService(int index) async {
    final service = _services[index];
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSizes.radiusLg),
        ),
      ),
      builder: (ctx) {
        final theme = Theme.of(ctx);
        final colorScheme = theme.colorScheme;
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppSizes.s24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: colorScheme.outline.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(AppSizes.radiusFull),
                  ),
                ),
                const SizedBox(height: AppSizes.s24),
                Container(
                  padding: const EdgeInsets.all(AppSizes.s16),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.delete_outline_rounded,
                    color: AppColors.error,
                    size: 32,
                  ),
                ),
                const SizedBox(height: AppSizes.s16),
                Text(
                  '¿Eliminar servicio?',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppSizes.s8),
                Text(
                  '¿Estás seguro de que querés eliminar "${service.name}"? Esta acción no se puede deshacer.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSizes.s24),
                Row(
                  children: [
                    Expanded(
                      child: AppButton(
                        label: 'Cancelar',
                        isOutlined: true,
                        onPressed: () => Navigator.of(ctx).pop(false),
                      ),
                    ),
                    const SizedBox(width: AppSizes.s12),
                    Expanded(
                      child: AppButton(
                        label: 'Eliminar',
                        icon: Icons.delete_rounded,
                        backgroundColor: AppColors.error,
                        foregroundColor: Colors.white,
                        onPressed: () => Navigator.of(ctx).pop(true),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );

    if (confirmed == true && mounted) {
      setState(() => _services.removeAt(index));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
              const SizedBox(width: AppSizes.s8),
              Expanded(child: Text('"${service.name}" eliminado')),
            ],
          ),
        ),
      );
    }
  }

  // ─── Save ────────────────────────────────────────────────

  /// Updates the business in the provider, shows snackbar, and pops.
  Future<void> _handleSave() async {
    final business = ref.read(currentBusinessProvider);
    if (business == null) return;

    setState(() => _isSaving = true);

    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 600));

    if (!mounted) return;

    final updatedBusiness = Business(
      id: business.id,
      ownerId: business.ownerId,
      categoryId: business.categoryId,
      name: _nameController.text.trim(),
      description: _descriptionController.text.trim().isNotEmpty
          ? _descriptionController.text.trim()
          : null,
      address: _addressController.text.trim().isNotEmpty
          ? _addressController.text.trim()
          : null,
      latitude: _latitude,
      longitude: _longitude,
      phone: _phoneController.text.trim().isNotEmpty
          ? _phoneController.text.trim()
          : null,
      website: _websiteController.text.trim().isNotEmpty
          ? _websiteController.text.trim()
          : null,
      logoUrl: business.logoUrl,
      photos: business.photos,
      openingTime: _openingTime,
      closingTime: _closingTime,
      slotDurationMinutes: _slotDurationMinutes,
      isActive: business.isActive,
      createdAt: business.createdAt,
    );

    // Invalidate to re-fetch from Supabase
    ref.invalidate(businessesProvider);

    setState(() => _isSaving = false);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
            const SizedBox(width: AppSizes.s8),
            Expanded(
              child: Text('¡${updatedBusiness.name} actualizado exitosamente!'),
            ),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusSm),
        ),
      ),
    );

    context.pop();
  }

  // ─── Helpers ─────────────────────────────────────────────

  String _formatTimeOfDay(TimeOfDay tod) {
    return '${tod.hour.toString().padLeft(2, '0')}:${tod.minute.toString().padLeft(2, '0')}';
  }

  String _formatPrice(double? price) {
    if (price == null || price == 0) return 'Gratis';
    final formatted = price.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]}.',
        );
    return '$formatted Gs.';
  }

  // ─── Build ───────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final business = ref.watch(currentBusinessProvider);

    // No business found — show error state
    if (business == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Editar negocio')),
        body: const EmptyState(
          icon: Icons.store_rounded,
          title: 'No se encontró el negocio',
          subtitle: 'No tenés un negocio asociado a tu cuenta.',
        ),
      );
    }

    // Initialize fields from business data (once)
    _initializeFromBusiness(business);

    final stepLabels = ['Datos', 'Horarios', 'Servicios'];

    return Scaffold(
      body: Column(
        children: [
          // ─── Gradient Header ────────────────────────────────
          _EditBusinessHeader(
            businessName: business.name,
            categoryId: business.categoryId,
            onClose: () => context.pop(),
          ),

          // ─── Step Indicators ────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSizes.s24,
              vertical: AppSizes.s12,
            ),
            child: Row(
              children: List.generate(_totalSteps, (i) {
                final isActive = i == _currentStep;
                final isCompleted = i < _currentStep;
                return Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(
                      right: i < _totalSteps - 1 ? AppSizes.s8 : 0,
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isCompleted
                                    ? colorScheme.primary
                                    : isActive
                                        ? colorScheme.primary
                                        : colorScheme.outline
                                            .withValues(alpha: 0.3),
                              ),
                              child: Center(
                                child: isCompleted
                                    ? const Icon(Icons.check_rounded,
                                        size: 16, color: Colors.white)
                                    : Text(
                                        '${i + 1}',
                                        style: theme.textTheme.labelMedium
                                            ?.copyWith(
                                          color: isActive
                                              ? Colors.white
                                              : colorScheme.onSurface
                                                  .withValues(alpha: 0.5),
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                              ),
                            ),
                            const SizedBox(width: AppSizes.s6),
                            Expanded(
                              child: Text(
                                stepLabels[i],
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: isActive || isCompleted
                                      ? colorScheme.onSurface
                                      : colorScheme.onSurface
                                          .withValues(alpha: 0.4),
                                  fontWeight: isActive
                                      ? FontWeight.w600
                                      : FontWeight.w400,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSizes.s6),
                        LinearProgressIndicator(
                          value: isCompleted
                              ? 1.0
                              : (isActive ? 0.5 : 0.0),
                          backgroundColor:
                              colorScheme.outline.withValues(alpha: 0.15),
                          color: colorScheme.primary,
                          minHeight: 3,
                          borderRadius:
                              BorderRadius.circular(AppSizes.radiusFull),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),

          // ─── Page Content ───────────────────────────────────
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildInfoStep(theme, colorScheme),
                _buildConfigStep(theme, colorScheme),
                _buildServicesStep(theme, colorScheme),
              ],
            ),
          ),

          // ─── Bottom Navigation ──────────────────────────────
          Container(
            padding: const EdgeInsets.all(AppSizes.s16),
            decoration: BoxDecoration(
              color: theme.scaffoldBackgroundColor,
              border: Border(
                top: BorderSide(
                  color: colorScheme.outline.withValues(alpha: 0.2),
                ),
              ),
            ),
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  if (_currentStep > 0)
                    Expanded(
                      child: AppButton(
                        label: 'Volver',
                        icon: Icons.arrow_back_rounded,
                        isOutlined: true,
                        onPressed: _goToPreviousStep,
                      ),
                    ),
                  if (_currentStep > 0) const SizedBox(width: AppSizes.s12),
                  Expanded(
                    child: _currentStep < _totalSteps - 1
                        ? AppButton(
                            label: 'Siguiente',
                            icon: Icons.arrow_forward_rounded,
                            onPressed: _goToNextStep,
                          )
                        : AppButton(
                            label: 'Guardar cambios',
                            icon: Icons.save_rounded,
                            isLoading: _isSaving,
                            onPressed: _isSaving ? null : _handleSave,
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

  // ═══════════════════════════════════════════════════════════
  // STEP 1: Business Info
  // ═══════════════════════════════════════════════════════════

  Widget _buildInfoStep(ThemeData theme, ColorScheme colorScheme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSizes.s24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: Form(
            key: _infoFormKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Section title
                Text(
                  'Datos del negocio',
                  style: theme.textTheme.headlineLarge,
                )
                    .animate()
                    .fadeIn(duration: 400.ms)
                    .slideX(begin: -0.1, end: 0, duration: 400.ms),

                const SizedBox(height: AppSizes.s4),

                Text(
                  'Modificá la información básica de tu negocio',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                )
                    .animate()
                    .fadeIn(delay: 50.ms, duration: 400.ms),

                const SizedBox(height: AppSizes.s8),

                // Change indicator chip
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.s12,
                    vertical: AppSizes.s6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.info.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(AppSizes.radiusFull),
                    border: Border.all(
                      color: AppColors.info.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.edit_note_rounded,
                        size: 16,
                        color: AppColors.info.withValues(alpha: 0.8),
                      ),
                      const SizedBox(width: AppSizes.s6),
                      Text(
                        'Editando negocio existente',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: AppColors.info,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                )
                    .animate()
                    .fadeIn(delay: 100.ms, duration: 400.ms)
                    .slideY(begin: 0.1, end: 0, delay: 100.ms, duration: 400.ms),

                const SizedBox(height: AppSizes.s20),

                // Name field
                AppTextField(
                  controller: _nameController,
                  label: 'Nombre del negocio',
                  prefixIcon: Icons.store_rounded,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Nombre del negocio es requerido';
                    }
                    return null;
                  },
                )
                    .animate()
                    .fadeIn(delay: 150.ms, duration: 400.ms)
                    .slideY(begin: 0.1, end: 0, delay: 150.ms, duration: 400.ms),

                const SizedBox(height: AppSizes.s16),

                // Address field
                AppTextField(
                  controller: _addressController,
                  label: 'Dirección',
                  prefixIcon: Icons.location_on_outlined,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Dirección es requerido';
                    }
                    return null;
                  },
                )
                    .animate()
                    .fadeIn(delay: 250.ms, duration: 400.ms)
                    .slideY(begin: 0.1, end: 0, delay: 250.ms, duration: 400.ms),

                const SizedBox(height: AppSizes.s16),

                // Phone field
                AppTextField(
                  controller: _phoneController,
                  label: 'Teléfono',
                  prefixIcon: Icons.phone_outlined,
                  keyboardType: TextInputType.phone,
                  hint: '+595 ...',
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Teléfono es requerido';
                    }
                    final digits = v.replaceAll(RegExp(r'[\s\-\(\)\+]'), '');
                    if (digits.length < 7 || digits.length > 15) {
                      return 'Ingresá un teléfono válido';
                    }
                    return null;
                  },
                )
                    .animate()
                    .fadeIn(delay: 350.ms, duration: 400.ms)
                    .slideY(begin: 0.1, end: 0, delay: 350.ms, duration: 400.ms),

                const SizedBox(height: AppSizes.s16),

                // Website field
                AppTextField(
                  controller: _websiteController,
                  label: 'Sitio web',
                  hint: 'https://...',
                  prefixIcon: Icons.language_rounded,
                  keyboardType: TextInputType.url,
                )
                    .animate()
                    .fadeIn(delay: 450.ms, duration: 400.ms)
                    .slideY(begin: 0.1, end: 0, delay: 450.ms, duration: 400.ms),

                const SizedBox(height: AppSizes.s20),

                // ── Interactive Map ──
                Text(
                  '📍 Ubicación en el mapa',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppSizes.s4),
                Text(
                  'Tocá el mapa para marcar la ubicación de tu negocio',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                ),
                const SizedBox(height: AppSizes.s8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                  child: SizedBox(
                    height: 220,
                    width: double.infinity,
                    child: Stack(
                      children: [
                        FlutterMap(
                          options: MapOptions(
                            initialCenter: LatLng(
                              _latitude ?? -25.2637,
                              _longitude ?? -57.5759,
                            ),
                            initialZoom: _latitude != null ? 16.0 : 13.0,
                            onTap: (tapPosition, point) {
                              setState(() {
                                _latitude = point.latitude;
                                _longitude = point.longitude;
                              });
                            },
                          ),
                          children: [
                            TileLayer(
                              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                              userAgentPackageName: 'com.reservpy.app',
                            ),
                            if (_latitude != null && _longitude != null)
                              MarkerLayer(
                                markers: [
                                  Marker(
                                    point: LatLng(_latitude!, _longitude!),
                                    width: 48,
                                    height: 48,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: AppColors.primary,
                                        shape: BoxShape.circle,
                                        border: Border.all(color: Colors.white, width: 3),
                                        boxShadow: [
                                          BoxShadow(
                                            color: AppColors.primary.withValues(alpha: 0.4),
                                            blurRadius: 8,
                                            spreadRadius: 2,
                                          ),
                                        ],
                                      ),
                                      child: const Icon(Icons.store_rounded, color: Colors.white, size: 22),
                                    ),
                                  ),
                                ],
                              ),
                          ],
                        ),
                        // Coordinates badge
                        if (_latitude != null && _longitude != null)
                          Positioned(
                            bottom: 8,
                            left: 8,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.7),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.check_circle, color: AppColors.success, size: 14),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Ubicación marcada',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 11,
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

                const SizedBox(height: AppSizes.s24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // STEP 2: Schedule & Configuration
  // ═══════════════════════════════════════════════════════════

  Widget _buildConfigStep(ThemeData theme, ColorScheme colorScheme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSizes.s24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Horarios y configuración',
                style: theme.textTheme.headlineLarge,
              )
                  .animate()
                  .fadeIn(duration: 400.ms)
                  .slideX(begin: -0.1, end: 0, duration: 400.ms),

              const SizedBox(height: AppSizes.s4),

              Text(
                'Ajustá los horarios, turnos y la descripción',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              )
                  .animate()
                  .fadeIn(delay: 50.ms, duration: 400.ms),

              const SizedBox(height: AppSizes.s24),

              // Description
              AppTextField(
                controller: _descriptionController,
                label: 'Descripción',
                hint: 'Contá de qué se trata tu negocio...',
                prefixIcon: Icons.description_outlined,
                maxLines: 3,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Descripción es requerido';
                  }
                  return null;
                },
              )
                  .animate()
                  .fadeIn(delay: 100.ms, duration: 400.ms)
                  .slideY(begin: 0.1, end: 0, delay: 100.ms, duration: 400.ms),

              const SizedBox(height: AppSizes.s24),

              // Schedule section header
              Row(
                children: [
                  Icon(
                    Icons.schedule_rounded,
                    size: 20,
                    color: colorScheme.primary,
                  ),
                  const SizedBox(width: AppSizes.s8),
                  Text(
                    'Horario de atención',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              )
                  .animate()
                  .fadeIn(delay: 150.ms, duration: 400.ms),

              const SizedBox(height: AppSizes.s12),

              // Time pickers
              Row(
                children: [
                  Expanded(
                    child: _TimePickerTile(
                      label: 'Hora de apertura',
                      time: _formatTimeOfDay(_openingTime),
                      icon: Icons.wb_sunny_outlined,
                      onTap: () => _pickTime(isOpening: true),
                    ),
                  ),
                  const SizedBox(width: AppSizes.s12),
                  Expanded(
                    child: _TimePickerTile(
                      label: 'Hora de cierre',
                      time: _formatTimeOfDay(_closingTime),
                      icon: Icons.nights_stay_outlined,
                      onTap: () => _pickTime(isOpening: false),
                    ),
                  ),
                ],
              )
                  .animate()
                  .fadeIn(delay: 200.ms, duration: 400.ms)
                  .slideY(begin: 0.1, end: 0, delay: 200.ms, duration: 400.ms),

              const SizedBox(height: AppSizes.s8),

              // Operating hours summary
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.s12,
                  vertical: AppSizes.s8,
                ),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      size: 16,
                      color: colorScheme.primary.withValues(alpha: 0.7),
                    ),
                    const SizedBox(width: AppSizes.s8),
                    Expanded(
                      child: Text(
                        _buildOperatingHoursSummary(),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              )
                  .animate()
                  .fadeIn(delay: 250.ms, duration: 400.ms),

              const SizedBox(height: AppSizes.s24),

              // Slot duration
              Row(
                children: [
                  Icon(
                    Icons.timer_outlined,
                    size: 20,
                    color: colorScheme.primary,
                  ),
                  const SizedBox(width: AppSizes.s8),
                  Text(
                    'Duración del turno',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              )
                  .animate()
                  .fadeIn(delay: 300.ms, duration: 400.ms),

              const SizedBox(height: AppSizes.s8),

              DropdownButtonFormField<int>(
                initialValue: _slotDurationMinutes,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.timer_outlined, size: 20),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                  ),
                ),
                items: const [
                  DropdownMenuItem(value: 15, child: Text('15 minutos')),
                  DropdownMenuItem(value: 20, child: Text('20 minutos')),
                  DropdownMenuItem(value: 30, child: Text('30 minutos')),
                  DropdownMenuItem(value: 45, child: Text('45 minutos')),
                  DropdownMenuItem(value: 60, child: Text('60 minutos')),
                  DropdownMenuItem(value: 90, child: Text('90 minutos')),
                  DropdownMenuItem(value: 120, child: Text('120 minutos')),
                ],
                onChanged: (v) {
                  if (v != null) setState(() => _slotDurationMinutes = v);
                },
              )
                  .animate()
                  .fadeIn(delay: 350.ms, duration: 400.ms)
                  .slideY(begin: 0.1, end: 0, delay: 350.ms, duration: 400.ms),

              const SizedBox(height: AppSizes.s12),

              // Slot count summary
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSizes.s16),
                decoration: BoxDecoration(
                  color: colorScheme.outline.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                  border: Border.all(
                    color: colorScheme.outline.withValues(alpha: 0.15),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(AppSizes.s8),
                      decoration: BoxDecoration(
                        color: colorScheme.primary.withValues(alpha: 0.1),
                        borderRadius:
                            BorderRadius.circular(AppSizes.radiusSm),
                      ),
                      child: Icon(
                        Icons.event_available_rounded,
                        size: 20,
                        color: colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: AppSizes.s12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Turnos disponibles por día',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurface
                                  .withValues(alpha: 0.5),
                            ),
                          ),
                          const SizedBox(height: AppSizes.s2),
                          Text(
                            '${_calculateSlotCount()} turnos',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              )
                  .animate()
                  .fadeIn(delay: 400.ms, duration: 400.ms),

              const SizedBox(height: AppSizes.s32),
            ],
          ),
        ),
      ),
    );
  }

  String _buildOperatingHoursSummary() {
    final totalMinutes = (_closingTime.hour * 60 + _closingTime.minute) -
        (_openingTime.hour * 60 + _openingTime.minute);
    final hours = totalMinutes ~/ 60;
    final minutes = totalMinutes % 60;
    if (minutes > 0) {
      return 'Horario: ${_formatTimeOfDay(_openingTime)} – ${_formatTimeOfDay(_closingTime)} ($hours h $minutes min)';
    }
    return 'Horario: ${_formatTimeOfDay(_openingTime)} – ${_formatTimeOfDay(_closingTime)} ($hours horas)';
  }

  int _calculateSlotCount() {
    final totalMinutes = (_closingTime.hour * 60 + _closingTime.minute) -
        (_openingTime.hour * 60 + _openingTime.minute);
    if (_slotDurationMinutes <= 0 || totalMinutes <= 0) return 0;
    return totalMinutes ~/ _slotDurationMinutes;
  }

  // ═══════════════════════════════════════════════════════════
  // STEP 3: Services
  // ═══════════════════════════════════════════════════════════

  Widget _buildServicesStep(ThemeData theme, ColorScheme colorScheme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSizes.s24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Servicios',
                style: theme.textTheme.headlineLarge,
              )
                  .animate()
                  .fadeIn(duration: 400.ms)
                  .slideX(begin: -0.1, end: 0, duration: 400.ms),

              const SizedBox(height: AppSizes.s4),

              Text(
                'Administrá los servicios que ofrecés',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              )
                  .animate()
                  .fadeIn(delay: 50.ms, duration: 400.ms),

              const SizedBox(height: AppSizes.s16),

              // Add service button
              AppCard(
                onTap: _showAddServiceDialog,
                padding: const EdgeInsets.all(AppSizes.s16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(AppSizes.s6),
                      decoration: BoxDecoration(
                        color: colorScheme.primary.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.add_rounded,
                        size: 20,
                        color: colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: AppSizes.s12),
                    Text(
                      'Agregar servicio',
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              )
                  .animate()
                  .fadeIn(delay: 100.ms, duration: 400.ms)
                  .slideY(begin: 0.1, end: 0, delay: 100.ms, duration: 400.ms),

              const SizedBox(height: AppSizes.s8),

              // Service count badge
              if (_services.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSizes.s12),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSizes.s8,
                          vertical: AppSizes.s4,
                        ),
                        decoration: BoxDecoration(
                          color: colorScheme.primary.withValues(alpha: 0.1),
                          borderRadius:
                              BorderRadius.circular(AppSizes.radiusFull),
                        ),
                        child: Text(
                          '${_services.length} ${_services.length == 1 ? 'servicio' : 'servicios'}',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
                    .animate()
                    .fadeIn(delay: 150.ms, duration: 300.ms),

              // Empty state
              if (_services.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppSizes.s32),
                  decoration: BoxDecoration(
                    color: colorScheme.outline.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                    border: Border.all(
                      color: colorScheme.outline.withValues(alpha: 0.15),
                      style: BorderStyle.solid,
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.design_services_outlined,
                        size: 48,
                        color: colorScheme.onSurface.withValues(alpha: 0.2),
                      ),
                      const SizedBox(height: AppSizes.s12),
                      Text(
                        'No hay servicios todavía',
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: colorScheme.onSurface.withValues(alpha: 0.4),
                        ),
                      ),
                      const SizedBox(height: AppSizes.s4),
                      Text(
                        'Agregá al menos un servicio para que tus clientes puedan reservar',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurface.withValues(alpha: 0.3),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
                    .animate()
                    .fadeIn(delay: 200.ms, duration: 400.ms)
                    .scale(
                      begin: const Offset(0.95, 0.95),
                      end: const Offset(1, 1),
                      delay: 200.ms,
                      duration: 400.ms,
                    ),

              // Service list
              if (_services.isNotEmpty)
                ...List.generate(_services.length, (index) {
                  final svc = _services[index];
                  return _ServiceEditCard(
                    service: svc,
                    index: index,
                    onEdit: () => _showEditServiceDialog(index),
                    onDelete: () => _confirmDeleteService(index),
                    formatPrice: _formatPrice,
                  )
                      .animate()
                      .fadeIn(
                        delay: Duration(milliseconds: 150 + index * 60),
                        duration: 350.ms,
                      )
                      .slideX(
                        begin: 0.08,
                        end: 0,
                        delay: Duration(milliseconds: 150 + index * 60),
                        duration: 350.ms,
                      );
                }),

              const SizedBox(height: AppSizes.s32),
            ],
          ),
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════
// PRIVATE WIDGETS
// ═════════════════════════════════════════════════════════════

/// Gradient header with business name and category info.
class _EditBusinessHeader extends ConsumerWidget {
  final String businessName;
  final String categoryId;
  final VoidCallback onClose;

  const _EditBusinessHeader({
    required this.businessName,
    required this.categoryId,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final categories = ref.watch(categoriesProvider).value ?? [];
    final category = categories.cast<BusinessCategory?>().firstWhere(
      (c) => c?.id == categoryId,
      orElse: () => null,
    ) ?? const BusinessCategory(id: '', name: 'Cargando...', icon: Icons.category, color: Colors.grey);

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.accent,
            AppColors.accentLight,
          ],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSizes.s8,
            AppSizes.s4,
            AppSizes.s8,
            AppSizes.s16,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top row: back button + title
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: Colors.white),
                    onPressed: onClose,
                  ),
                  const SizedBox(width: AppSizes.s4),
                  Expanded(
                    child: Text(
                      'Editar negocio',
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),

              // Business name & category
              Padding(
                padding: const EdgeInsets.only(
                  left: AppSizes.s16,
                  right: AppSizes.s16,
                  bottom: AppSizes.s4,
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(AppSizes.s8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius:
                            BorderRadius.circular(AppSizes.radiusSm),
                      ),
                      child: Icon(
                        category.icon,
                        size: 20,
                        color: category.color,
                      ),
                    ),
                    const SizedBox(width: AppSizes.s12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            businessName,
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            category.name,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color:
                                  Colors.white.withValues(alpha: 0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    )
        .animate()
        .fadeIn(duration: 500.ms)
        .slideY(begin: -0.05, end: 0, duration: 500.ms);
  }
}

/// Tappable tile displaying a time value with an icon.
class _TimePickerTile extends StatelessWidget {
  final String label;
  final String time;
  final IconData icon;
  final VoidCallback onTap;

  const _TimePickerTile({
    required this.label,
    required this.time,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSizes.s16),
        decoration: BoxDecoration(
          color: theme.cardTheme.color,
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          border: Border.all(
            color: colorScheme.outline.withValues(alpha: 0.25),
          ),
          boxShadow: [
            BoxShadow(
              color: colorScheme.shadow,
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 18, color: colorScheme.primary),
                const SizedBox(width: AppSizes.s6),
                Expanded(
                  child: Text(
                    label,
                    style: theme.textTheme.bodySmall,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSizes.s8),
            Text(
              time,
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Card for each service in the edit list with edit/delete actions.
class _ServiceEditCard extends StatelessWidget {
  final ServiceModel service;
  final int index;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final String Function(double?) formatPrice;

  const _ServiceEditCard({
    required this.service,
    required this.index,
    required this.onEdit,
    required this.onDelete,
    required this.formatPrice,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AppCard(
      margin: const EdgeInsets.only(bottom: AppSizes.s8),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.s16,
        vertical: AppSizes.s12,
      ),
      child: Row(
        children: [
          // Service icon badge
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppSizes.radiusSm),
            ),
            child: Center(
              child: Icon(
                Icons.design_services_rounded,
                size: 22,
                color: colorScheme.primary,
              ),
            ),
          ),
          const SizedBox(width: AppSizes.s12),

          // Service info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  service.name,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppSizes.s2),
                Row(
                  children: [
                    Icon(
                      Icons.timer_outlined,
                      size: 13,
                      color: colorScheme.onSurface.withValues(alpha: 0.4),
                    ),
                    const SizedBox(width: AppSizes.s4),
                    Text(
                      service.formattedDuration,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurface.withValues(alpha: 0.5),
                      ),
                    ),
                    const SizedBox(width: AppSizes.s8),
                    Container(
                      width: 3,
                      height: 3,
                      decoration: BoxDecoration(
                        color: colorScheme.onSurface.withValues(alpha: 0.3),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: AppSizes.s8),
                    Text(
                      formatPrice(service.price),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                if (service.description != null &&
                    service.description!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: AppSizes.s4),
                    child: Text(
                      service.description!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurface.withValues(alpha: 0.4),
                        fontStyle: FontStyle.italic,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
            ),
          ),

          // Actions
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 34,
                height: 34,
                child: IconButton(
                  icon: Icon(
                    Icons.edit_outlined,
                    size: 18,
                    color: AppColors.info,
                  ),
                  padding: EdgeInsets.zero,
                  onPressed: onEdit,
                  tooltip: 'Editar',
                ),
              ),
              SizedBox(
                width: 34,
                height: 34,
                child: IconButton(
                  icon: Icon(
                    Icons.delete_outline_rounded,
                    size: 18,
                    color: colorScheme.error,
                  ),
                  padding: EdgeInsets.zero,
                  onPressed: onDelete,
                  tooltip: 'Eliminar',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
