import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:uuid/uuid.dart';

import 'package:reservpy/src/shared/models/models.dart';
import 'package:reservpy/src/shared/providers/providers.dart';
import 'package:reservpy/src/core/widgets/widgets.dart';
import 'package:reservpy/src/core/constants/app_sizes.dart';
import 'package:reservpy/src/core/constants/app_strings.dart';
import 'package:reservpy/src/core/utils/validators.dart';
import 'package:reservpy/src/data/repositories/business_repository.dart';
import 'package:reservpy/src/data/repositories/service_repository.dart';

/// Multi-step business creation flow using a [PageController].
///
/// **Step 1 ? Category Selection**: 2-column grid of business categories.
/// **Step 2 ? Business Info**: Name, address, phone, website fields + interactive map.
/// **Step 3 — Configuration**: Description, opening/closing times, slot duration,
/// services list with add-service dialog. On completion, creates the business
/// and navigates to /business.
class CreateBusinessScreen extends ConsumerStatefulWidget {
  const CreateBusinessScreen({super.key});

  @override
  ConsumerState<CreateBusinessScreen> createState() => _CreateBusinessScreenState();
}

class _CreateBusinessScreenState extends ConsumerState<CreateBusinessScreen> {
  final _pageController = PageController();
  int _currentStep = 0;
  static const int _totalSteps = 3;

  // Step 1 — Category
  String? _selectedCategoryId;

  // Step 2 — Business Info
  final _infoFormKey = GlobalKey<FormState>();
  final _searchController = TextEditingController();
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  final _websiteController = TextEditingController();

  double? _latitude;
  double? _longitude;
  final _mapController = MapController();
  bool _isSearchingAddress = false;

  // Step 3 — Configuration
  final _descriptionController = TextEditingController();
  TimeOfDay _openingTime = const TimeOfDay(hour: 8, minute: 0);
  TimeOfDay _closingTime = const TimeOfDay(hour: 18, minute: 0);
  int _slotDurationMinutes = 30;
  final List<ServiceModel> _services = [];

  bool _isCreating = false;

  @override
  void dispose() {
    _pageController.dispose();
    _searchController.dispose();
    _nameController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _websiteController.dispose();
    _descriptionController.dispose();
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _searchAddressOnMap() async {
    final query = _addressController.text.trim().isNotEmpty
        ? _addressController.text.trim()
        : _searchController.text.trim();
    if (query.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Escribi una direccion para buscar en el mapa')),
      );
      return;
    }

    if (_addressController.text.trim().isEmpty) {
      _addressController.text = query;
    }

    setState(() => _isSearchingAddress = true);

    try {
      final searchUrl =
          'https://nominatim.openstreetmap.org/search?q=${Uri.encodeComponent(query)}&format=json&limit=1';
      final response = await http.get(
        Uri.parse(searchUrl),
        headers: {'User-Agent': 'com.reservpy.app'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is List && data.isNotEmpty) {
          final lat = double.tryParse(data[0]['lat'].toString());
          final lon = double.tryParse(data[0]['lon'].toString());
          if (lat != null && lon != null) {
            setState(() {
              _latitude = lat;
              _longitude = lon;
            });
            _mapController.move(LatLng(lat, lon), 16.0);
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Ubicacion encontrada y marcada en el mapa')),
            );
            return;
          }
        }
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No pudimos encontrar esa direccion. Proba una mas especifica.')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Hubo un error de red al buscar la direccion')),
      );
    } finally {
      if (mounted) {
        setState(() => _isSearchingAddress = false);
      }
    }
  }

  /// Validates current step and advances the PageView.
  void _goToNextStep() {
    if (_currentStep == 0) {
      if (_selectedCategoryId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Seleccioná un rubro para continuar')),
        );
        return;
      }
    } else if (_currentStep == 1) {
      if (!_infoFormKey.currentState!.validate()) return;
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

  /// Picks a time with the platform picker.
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

  /// Shows a dialog to add a new service.
  Future<void> _showAddServiceDialog() async {
    final nameController = TextEditingController();
    final durationController = TextEditingController(text: '30');
    final priceController = TextEditingController(text: '0');
    final dialogFormKey = GlobalKey<FormState>();

    final result = await showDialog<ServiceModel>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text(AppStrings.addService),
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
                    validator: (v) => Validators.required(v, 'Nombre'),
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
                      if (double.tryParse(v) == null) return 'Ingresá un número válido';
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
              child: const Text(AppStrings.cancel),
            ),
            ElevatedButton(
              onPressed: () {
                if (!dialogFormKey.currentState!.validate()) return;
                final service = ServiceModel(
                  id: const Uuid().v4(),
                  businessId: '',
                  name: nameController.text.trim(),
                  durationMinutes: int.parse(durationController.text.trim()),
                  price: double.parse(priceController.text.trim()),
                );
                Navigator.of(ctx).pop(service);
              },
              child: const Text('Agregar'),
            ),
          ],
        );
      },
    );

    if (result != null && mounted) {
      setState(() => _services.add(result));
    }
  }

  /// Creates the business in Supabase and persists the initial services.
  Future<void> _handleCreate() async {
    if (_descriptionController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Agregá una descripción para tu negocio')),
      );
      return;
    }

    final user = ref.read(currentUserProvider);
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Necesitás iniciar sesión para crear un negocio')),
      );
      return;
    }

    setState(() => _isCreating = true);

    try {
      final businessId = const Uuid().v4();
      final businessRepo = BusinessRepository();
      final serviceRepo = ServiceRepository();

      final newBusiness = Business(
        id: businessId,
        ownerId: user.id,
        categoryId: _selectedCategoryId!,
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        address: _addressController.text.trim(),
        phone: _phoneController.text.trim(),
        website: _websiteController.text.trim().isNotEmpty
            ? _websiteController.text.trim()
            : null,
        openingTime: _openingTime,
        closingTime: _closingTime,
        slotDurationMinutes: _slotDurationMinutes,
        latitude: _latitude,
        longitude: _longitude,
        createdAt: DateTime.now(),
      );

      await businessRepo.create(newBusiness);

      for (var i = 0; i < _services.length; i++) {
        final service = _services[i];
        await serviceRepo.create(
          ServiceModel(
            id: const Uuid().v4(),
            businessId: businessId,
            name: service.name,
            description: service.description,
            durationMinutes: service.durationMinutes,
            price: service.price,
            currency: service.currency,
            isActive: service.isActive,
            sortOrder: i,
          ),
        );
      }

      ref.invalidate(businessesProvider);
      ref.invalidate(ownerBusinessProvider);
      ref.invalidate(currentBusinessProvider);
      ref.invalidate(servicesProvider);
      ref.invalidate(businessServicesProvider(businessId));

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
              const SizedBox(width: AppSizes.s8),
              Expanded(child: Text('¡${newBusiness.name} creado exitosamente!')),
            ],
          ),
        ),
      );

      context.go('/business');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al crear el negocio: $e')),
      );
    } finally {
      if (mounted) setState(() => _isCreating = false);
    }
  }

  String _formatTimeOfDay(TimeOfDay tod) {
    return '${tod.hour.toString().padLeft(2, '0')}:${tod.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final categories = ref.watch(categoriesProvider).valueOrNull ?? [];

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => context.go('/business'),
        ),
        title: const Text(AppStrings.createBusiness),
      ),
      body: Column(
        children: [
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
                    padding: EdgeInsets.only(right: i < _totalSteps - 1 ? AppSizes.s8 : 0),
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
                                        : colorScheme.outline.withValues(alpha: 0.3),
                              ),
                              child: Center(
                                child: isCompleted
                                    ? const Icon(Icons.check_rounded, size: 16, color: Colors.white)
                                    : Text(
                                        '${i + 1}',
                                        style: theme.textTheme.labelMedium?.copyWith(
                                          color: isActive ? Colors.white : colorScheme.onSurface.withValues(alpha: 0.5),
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                              ),
                            ),
                            const SizedBox(width: AppSizes.s6),
                            Expanded(
                              child: Text(
                                [AppStrings.selectCategory, 'Datos', 'Config'][i],
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: isActive || isCompleted
                                      ? colorScheme.onSurface
                                      : colorScheme.onSurface.withValues(alpha: 0.4),
                                  fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSizes.s6),
                        LinearProgressIndicator(
                          value: isCompleted ? 1.0 : (isActive ? 0.5 : 0.0),
                          backgroundColor: colorScheme.outline.withValues(alpha: 0.15),
                          color: colorScheme.primary,
                          minHeight: 3,
                          borderRadius: BorderRadius.circular(AppSizes.radiusFull),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),

          // ─── Page Content ──────────────────────────────────
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildCategoryStep(categories, theme, colorScheme),
                _buildInfoStep(theme, colorScheme),
                _buildConfigStep(theme, colorScheme),
              ],
            ),
          ),

          // ─── Bottom Navigation ─────────────────────────────
          Container(
            padding: const EdgeInsets.all(AppSizes.s16),
            decoration: BoxDecoration(
              color: theme.scaffoldBackgroundColor,
              border: Border(
                top: BorderSide(color: colorScheme.outline.withValues(alpha: 0.2)),
              ),
            ),
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  if (_currentStep > 0)
                    Expanded(
                      child: AppButton(
                        label: AppStrings.back,
                        icon: Icons.arrow_back_rounded,
                        isOutlined: true,
                        onPressed: _goToPreviousStep,
                      ),
                    ),
                  if (_currentStep > 0) const SizedBox(width: AppSizes.s12),
                  Expanded(
                    child: _currentStep < _totalSteps - 1
                        ? AppButton(
                            label: AppStrings.next,
                            icon: Icons.arrow_forward_rounded,
                            onPressed: _goToNextStep,
                          )
                        : AppButton(
                            label: AppStrings.createBusiness,
                            icon: Icons.check_rounded,
                            isLoading: _isCreating,
                            onPressed: _isCreating ? null : _handleCreate,
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

  // ─── Step 1: Category Selection ────────────────────────────
  Widget _buildCategoryStep(
    List<BusinessCategory> categories,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSizes.s24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppStrings.selectCategory,
                style: theme.textTheme.headlineLarge,
              )
                  .animate()
                  .fadeIn(duration: 400.ms)
                  .slideX(begin: -0.1, end: 0, duration: 400.ms),

              const SizedBox(height: AppSizes.s4),

              Text(
                'Elegí la categoría que mejor describe tu negocio',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              )
                  .animate()
                  .fadeIn(delay: 50.ms, duration: 400.ms),

              const SizedBox(height: AppSizes.s24),

              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: AppSizes.s12,
                  crossAxisSpacing: AppSizes.s12,
                  childAspectRatio: 1.35,
                ),
                itemCount: categories.length,
                itemBuilder: (context, index) {
                  final cat = categories[index];
                  final isSelected = _selectedCategoryId == cat.id;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedCategoryId = cat.id),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeInOut,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? colorScheme.primary.withValues(alpha: 0.08)
                            : theme.cardTheme.color,
                        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                        border: Border.all(
                          color: isSelected ? colorScheme.primary : colorScheme.outline.withValues(alpha: 0.25),
                          width: isSelected ? 2 : 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: colorScheme.shadow,
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Stack(
                        children: [
                          Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(cat.icon, size: 36, color: cat.color),
                                const SizedBox(height: AppSizes.s8),
                                Text(
                                  cat.name,
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (isSelected)
                            Positioned(
                              top: AppSizes.s8,
                              right: AppSizes.s8,
                              child: Container(
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  color: colorScheme.primary,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.check_rounded,
                                  size: 16,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  )
                      .animate()
                      .fadeIn(
                        delay: Duration(milliseconds: 100 + index * 80),
                        duration: 400.ms,
                      )
                      .scale(
                        begin: const Offset(0.9, 0.9),
                        end: const Offset(1, 1),
                        delay: Duration(milliseconds: 100 + index * 80),
                        duration: 400.ms,
                      );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Step 2: Business Info ─────────────────────────────────
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
                Text(
                  'Datos del negocio',
                  style: theme.textTheme.headlineLarge,
                )
                    .animate()
                    .fadeIn(duration: 400.ms)
                    .slideX(begin: -0.1, end: 0, duration: 400.ms),

                const SizedBox(height: AppSizes.s4),

                Text(
                  'Completá la información básica de tu negocio',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                )
                    .animate()
                    .fadeIn(delay: 50.ms, duration: 400.ms),

                const SizedBox(height: AppSizes.s24),

                AppTextField(
                  controller: _searchController,
                  label: 'Buscar direccion',
                  hint: 'Escribi para buscar...',
                  prefixIcon: Icons.search_rounded,
                  suffix: IconButton(
                    onPressed: _isSearchingAddress ? null : _searchAddressOnMap,
                    icon: _isSearchingAddress
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.travel_explore_rounded),
                    tooltip: 'Buscar en el mapa',
                  ),
                  onChanged: (value) {
                    if (value.length > 5 && _addressController.text.isEmpty) {
                      _addressController.text = value;
                    }
                  },
                )
                    .animate()
                    .fadeIn(delay: 100.ms, duration: 400.ms)
                    .slideY(begin: 0.1, end: 0, delay: 100.ms, duration: 400.ms),

                const SizedBox(height: AppSizes.s16),

                AppTextField(
                  controller: _nameController,
                  label: AppStrings.businessName,
                  prefixIcon: Icons.store_rounded,
                  validator: (v) => Validators.required(v, AppStrings.businessName),
                )
                    .animate()
                    .fadeIn(delay: 200.ms, duration: 400.ms)
                    .slideY(begin: 0.1, end: 0, delay: 200.ms, duration: 400.ms),

                const SizedBox(height: AppSizes.s16),

                AppTextField(
                  controller: _addressController,
                  label: AppStrings.businessAddress,
                  prefixIcon: Icons.location_on_outlined,
                  validator: (v) => Validators.required(v, AppStrings.businessAddress),
                )
                    .animate()
                    .fadeIn(delay: 300.ms, duration: 400.ms)
                    .slideY(begin: 0.1, end: 0, delay: 300.ms, duration: 400.ms),

                const SizedBox(height: AppSizes.s16),

                AppTextField(
                  controller: _phoneController,
                  label: AppStrings.businessPhone,
                  prefixIcon: Icons.phone_outlined,
                  keyboardType: TextInputType.phone,
                  validator: Validators.phone,
                )
                    .animate()
                    .fadeIn(delay: 400.ms, duration: 400.ms)
                    .slideY(begin: 0.1, end: 0, delay: 400.ms, duration: 400.ms),

                const SizedBox(height: AppSizes.s16),

                AppTextField(
                  controller: _websiteController,
                  label: AppStrings.businessWebsite,
                  hint: 'https://...',
                  prefixIcon: Icons.language_rounded,
                  keyboardType: TextInputType.url,
                )
                    .animate()
                    .fadeIn(delay: 500.ms, duration: 400.ms)
                    .slideY(begin: 0.1, end: 0, delay: 500.ms, duration: 400.ms),

                const SizedBox(height: AppSizes.s12),

                Align(
                  alignment: Alignment.centerLeft,
                  child: FilledButton.tonalIcon(
                    onPressed: _isSearchingAddress ? null : _searchAddressOnMap,
                    icon: const Icon(Icons.search_rounded, size: 18),
                    label: Text(_isSearchingAddress ? 'Buscando...' : 'Buscar direccion en el mapa'),
                  ),
                )
                    .animate()
                    .fadeIn(delay: 540.ms, duration: 400.ms),

                const SizedBox(height: AppSizes.s16),

                Text(
                  'Toca el mapa para ajustar la ubicacion exacta de tu negocio',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.55),
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
                          mapController: _mapController,
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
                                        color: colorScheme.primary,
                                        shape: BoxShape.circle,
                                        border: Border.all(color: Colors.white, width: 3),
                                        boxShadow: [
                                          BoxShadow(
                                            color: colorScheme.primary.withValues(alpha: 0.35),
                                            blurRadius: 8,
                                            spreadRadius: 2,
                                          ),
                                        ],
                                      ),
                                      child: const Icon(
                                        Icons.store_rounded,
                                        color: Colors.white,
                                        size: 22,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                          ],
                        ),
                        if (_latitude != null && _longitude != null)
                          Positioned(
                            left: 8,
                            bottom: 8,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.72),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.check_circle, color: Colors.white, size: 14),
                                  const SizedBox(width: 6),
                                  Text(
                                    '${_latitude!.toStringAsFixed(4)}, ${_longitude!.toStringAsFixed(4)}',
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
                )
                    .animate()
                    .fadeIn(delay: 600.ms, duration: 400.ms),

                const SizedBox(height: AppSizes.s24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─── Step 3: Configuration ─────────────────────────────────
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
                'Configuración',
                style: theme.textTheme.headlineLarge,
              )
                  .animate()
                  .fadeIn(duration: 400.ms)
                  .slideX(begin: -0.1, end: 0, duration: 400.ms),

              const SizedBox(height: AppSizes.s4),

              Text(
                'Configurá horarios, turnos y servicios',
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
                label: AppStrings.businessDescription,
                hint: 'Contá de qué se trata tu negocio...',
                prefixIcon: Icons.description_outlined,
                maxLines: 3,
                validator: (v) => Validators.required(v, 'Descripción'),
              )
                  .animate()
                  .fadeIn(delay: 100.ms, duration: 400.ms)
                  .slideY(begin: 0.1, end: 0, delay: 100.ms, duration: 400.ms),

              const SizedBox(height: AppSizes.s20),

              // Time pickers
              Row(
                children: [
                  Expanded(
                    child: _TimePickerTile(
                      label: AppStrings.openingTime,
                      time: _formatTimeOfDay(_openingTime),
                      icon: Icons.wb_sunny_outlined,
                      onTap: () => _pickTime(isOpening: true),
                    ),
                  ),
                  const SizedBox(width: AppSizes.s12),
                  Expanded(
                    child: _TimePickerTile(
                      label: AppStrings.closingTime,
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

              const SizedBox(height: AppSizes.s20),

              // Slot duration
              Text(
                AppStrings.slotDuration,
                style: theme.textTheme.titleMedium,
              ),
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
                ],
                onChanged: (v) {
                  if (v != null) setState(() => _slotDurationMinutes = v);
                },
              )
                  .animate()
                  .fadeIn(delay: 300.ms, duration: 400.ms)
                  .slideY(begin: 0.1, end: 0, delay: 300.ms, duration: 400.ms),

              const SizedBox(height: AppSizes.s24),

              // Services section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    AppStrings.services,
                    style: theme.textTheme.titleMedium,
                  ),
                  TextButton.icon(
                    onPressed: _showAddServiceDialog,
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: const Text(AppStrings.addService),
                  ),
                ],
              )
                  .animate()
                  .fadeIn(delay: 400.ms, duration: 400.ms),

              const SizedBox(height: AppSizes.s8),

              if (_services.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppSizes.s24),
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
                        size: 36,
                        color: colorScheme.onSurface.withValues(alpha: 0.3),
                      ),
                      const SizedBox(height: AppSizes.s8),
                      Text(
                        'Todavía no agregaste servicios',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurface.withValues(alpha: 0.4),
                        ),
                      ),
                    ],
                  ),
                )
              else
                ...List.generate(_services.length, (index) {
                  final svc = _services[index];
                  return AppCard(
                    margin: const EdgeInsets.only(bottom: AppSizes.s8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSizes.s16,
                      vertical: AppSizes.s12,
                    ),
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
                            Icons.design_services_rounded,
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
                                svc.name,
                                style: theme.textTheme.titleMedium,
                              ),
                              Text(
                                '${svc.formattedDuration} • ${svc.formattedPrice}',
                                style: theme.textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.delete_outline_rounded,
                            size: 20,
                            color: colorScheme.error,
                          ),
                          onPressed: () {
                            setState(() => _services.removeAt(index));
                          },
                        ),
                      ],
                    ),
                  )
                      .animate()
                      .fadeIn(duration: 300.ms)
                      .slideX(begin: 0.1, end: 0, duration: 300.ms);
                }),

              const SizedBox(height: AppSizes.s32),
            ],
          ),
        ),
      ),
    );
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
          border: Border.all(color: colorScheme.outline.withValues(alpha: 0.25)),
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
                Text(
                  label,
                  style: theme.textTheme.bodySmall,
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
