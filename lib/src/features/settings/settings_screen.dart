import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:reservpy/src/core/constants/app_sizes.dart';
import 'package:reservpy/src/core/constants/app_colors.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:reservpy/src/shared/models/models.dart';
import 'package:reservpy/src/shared/providers/providers.dart';
import 'package:reservpy/src/data/repositories/business_repository.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _addressController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _cancellationController;

  bool _initialized = false;
  bool _isSaving = false;
  double? _latitude;
  double? _longitude;

  final _mapController = MapController();
  bool _isSearchingAddress = false;

  void _initControllers(Business business) {
    if (_initialized) return;
    _nameController = TextEditingController(text: business.name);
    _phoneController = TextEditingController(text: business.phone ?? '');
    _addressController = TextEditingController(text: business.address ?? '');
    _descriptionController =
        TextEditingController(text: business.description ?? '');
    _cancellationController = TextEditingController(
      text: business.cancellationHoursPolicy.toString(),
    );
    _latitude = business.latitude;
    _longitude = business.longitude;
    _initialized = true;
  }

  @override
  void dispose() {
    if (_initialized) {
      _nameController.dispose();
      _phoneController.dispose();
      _addressController.dispose();
      _descriptionController.dispose();
      _cancellationController.dispose();
    }
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _searchAddressOnMap() async {
    final query = _addressController.text.trim();
    if (query.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Escribí una dirección para buscar en el mapa',
            style: GoogleFonts.inter(),
          ),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isSearchingAddress = true);

    try {
      final searchUrl = 'https://nominatim.openstreetmap.org/search?q=${Uri.encodeComponent(query)}&format=json&limit=1';
      final response = await http.get(Uri.parse(searchUrl), headers: {
        'User-Agent': 'com.reservly.app',
      });

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
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Ubicación encontrada y marcada en el mapa',
                    style: GoogleFonts.inter(),
                  ),
                  backgroundColor: AppColors.success,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
            return;
          }
        }
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'No pudimos encontrar esa dirección. Intentá ser más específico.',
              style: GoogleFonts.inter(),
            ),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error de red al buscar la dirección',
              style: GoogleFonts.inter(),
            ),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSearchingAddress = false);
      }
    }
  }

  String _slugFromName(String name) {
    return name
        .toLowerCase()
        .replaceAll(RegExp(r'[áàäâ]'), 'a')
        .replaceAll(RegExp(r'[éèëê]'), 'e')
        .replaceAll(RegExp(r'[íìïî]'), 'i')
        .replaceAll(RegExp(r'[óòöô]'), 'o')
        .replaceAll(RegExp(r'[úùüû]'), 'u')
        .replaceAll(RegExp(r'ñ'), 'n')
        .replaceAll(RegExp(r'[^a-z0-9\s-]'), '')
        .trim()
        .replaceAll(RegExp(r'\s+'), '-');
  }

  Future<void> _saveBusinessData(Business business) async {
    setState(() => _isSaving = true);

    final updatedBusiness = business.copyWith(
      name: _nameController.text.trim(),
      phone: _phoneController.text.trim(),
      address: _addressController.text.trim(),
      description: _descriptionController.text.trim(),
      latitude: _latitude,
      longitude: _longitude,
      cancellationHoursPolicy:
          int.tryParse(_cancellationController.text) ??
          business.cancellationHoursPolicy,
    );

    try {
      await BusinessRepository().update(updatedBusiness);
      // Invalidate to re-fetch from Supabase
      ref.invalidate(businessesProvider);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded,
                  color: Colors.white, size: 20),
              const SizedBox(width: AppSizes.s8),
              Expanded(
                child: Text(
                  '${updatedBusiness.name} guardado correctamente',
                  style: GoogleFonts.inter(),
                ),
              ),
            ],
          ),
          backgroundColor: AppColors.primary,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizes.radiusSm),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Error al guardar: $e',
            style: GoogleFonts.inter(),
          ),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizes.radiusSm),
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final businessesAsync = ref.watch(businessesProvider);
    final business = ref.watch(currentBusinessProvider);

    return businessesAsync.when(
      loading: () => const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      ),
      error: (e, _) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline_rounded,
                size: 48, color: AppColors.error),
            const SizedBox(height: AppSizes.s12),
            Text(
              'Error al cargar datos',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.accent,
              ),
            ),
            const SizedBox(height: AppSizes.s4),
            Text(
              '$e',
              style: GoogleFonts.inter(
                fontSize: 13,
                color: AppColors.textMuted,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
      data: (_) {
        if (business == null) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.store_rounded,
                    size: 48, color: AppColors.textMuted),
                const SizedBox(height: AppSizes.s12),
                Text(
                  'No se encontró tu negocio',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.accent,
                  ),
                ),
                const SizedBox(height: AppSizes.s4),
                Text(
                  'Creá uno desde el panel principal',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          );
        }

        _initControllers(business);

        return LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(AppSizes.s24),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight - 48,
                  maxWidth: constraints.maxWidth - 48,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ── Header ──────────────────────────────────
                    _buildHeader(theme),
                    const SizedBox(height: AppSizes.s24),

                    // ── Business Data Card ──────────────────────
                    _buildBusinessDataCard(theme, colorScheme, business),
                    const SizedBox(height: AppSizes.s24),

                    // ── Map Location Card ───────────────────────
                    _buildMapLocationCard(theme, colorScheme),
                    const SizedBox(height: AppSizes.s24),

                    // ── Reminders Navigation ─────────────────────
                    _buildRemindersCard(theme, colorScheme),
                    const SizedBox(height: AppSizes.s24),

                    // ── Save + Edit buttons ─────────────────────
                    _buildActionButtons(business),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ═══════════════════════════════════════════════════════════
  // Header
  // ═══════════════════════════════════════════════════════════
  Widget _buildHeader(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Configuración',
          style: GoogleFonts.inter(
            fontSize: 26,
            fontWeight: FontWeight.w700,
            color: AppColors.accent,
          ),
        ),
        const SizedBox(height: AppSizes.s4),
        Text(
          'Datos de tu negocio y perfil personal',
          style: GoogleFonts.inter(
            fontSize: 14,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════
  // Business Data Card
  // ═══════════════════════════════════════════════════════════
  Widget _buildBusinessDataCard(
    ThemeData theme,
    ColorScheme colorScheme,
    Business business,
  ) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.s24),
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
          // Section title
          Text(
            '📦 Datos del negocio',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.accent,
            ),
          ),
          const SizedBox(height: AppSizes.s20),

          // a. Public page URL
          _buildPublicUrlRow(business),
          const SizedBox(height: AppSizes.s24),

          // b. Logo
          _buildLogoSection(theme, colorScheme),
          const SizedBox(height: AppSizes.s24),

          // c. Name + Phone side by side
          _buildNamePhoneRow(theme, colorScheme),
          const SizedBox(height: AppSizes.s16),

          // d. Address
          _buildAddressField(theme, colorScheme),
          const SizedBox(height: AppSizes.s16),

          // e. Description
          _buildDescriptionField(theme, colorScheme),
          const SizedBox(height: AppSizes.s24),

          // f. Cancellation policy
          _buildCancellationPolicy(theme, colorScheme),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // Map Location Card
  // ═══════════════════════════════════════════════════════════
  Widget _buildMapLocationCard(ThemeData theme, ColorScheme colorScheme) {
    final defaultLat = -25.2637;
    final defaultLng = -57.5759;
    final hasLocation = _latitude != null && _longitude != null;

    return Container(
      padding: const EdgeInsets.all(AppSizes.s24),
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
          // Section title
          Text(
            '📍 Ubicación del negocio',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.accent,
            ),
          ),
          const SizedBox(height: AppSizes.s4),
          Text(
            'Tocá el mapa para marcar la ubicación de tu negocio',
            style: GoogleFonts.inter(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSizes.s16),

          // Map
          ClipRRect(
            borderRadius: BorderRadius.circular(AppSizes.radiusMd),
            child: SizedBox(
              height: 260,
              child: Stack(
                children: [
                  FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      initialCenter: LatLng(
                        _latitude ?? defaultLat,
                        _longitude ?? defaultLng,
                      ),
                      initialZoom: hasLocation ? 16.0 : 13.0,
                      onTap: (tapPosition, point) {
                        setState(() {
                          _latitude = point.latitude;
                          _longitude = point.longitude;
                        });
                      },
                    ),
                    children: [
                      TileLayer(
                        urlTemplate:
                            'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.reservly.app',
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
                                  border: Border.all(
                                      color: Colors.white, width: 3),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.primary
                                          .withValues(alpha: 0.4),
                                      blurRadius: 8,
                                      spreadRadius: 2,
                                    ),
                                  ],
                                ),
                                child: const Icon(Icons.store_rounded,
                                    color: Colors.white, size: 22),
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                  // Coordinates badge
                  if (hasLocation)
                    Positioned(
                      bottom: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.7),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.check_circle,
                                color: AppColors.success, size: 14),
                            const SizedBox(width: 4),
                            Text(
                              '${_latitude!.toStringAsFixed(4)}, ${_longitude!.toStringAsFixed(4)}',
                              style: GoogleFonts.inter(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  // No-location hint
                  if (!hasLocation)
                    Positioned(
                      bottom: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.touch_app_rounded,
                                color: Colors.white.withValues(alpha: 0.8),
                                size: 14),
                            const SizedBox(width: 4),
                            Text(
                              'Tocá para marcar ubicación',
                              style: GoogleFonts.inter(
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  // Zoom buttons (Acercar/Alejar)
                  Positioned(
                    right: 8,
                    bottom: 8,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          margin: const EdgeInsets.only(bottom: 6),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.9),
                            shape: BoxShape.circle,
                            boxShadow: const [
                              BoxShadow(
                                color: Colors.black12,
                                blurRadius: 4,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: IconButton(
                            padding: EdgeInsets.zero,
                            icon: const Icon(Icons.add_rounded, size: 20, color: AppColors.accent),
                            onPressed: () {
                              final currentCenter = _mapController.camera.center;
                              final currentZoom = _mapController.camera.zoom;
                              if (currentZoom < 18) {
                                _mapController.move(currentCenter, currentZoom + 1);
                              }
                            },
                            tooltip: 'Acercar',
                          ),
                        ),
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.9),
                            shape: BoxShape.circle,
                            boxShadow: const [
                              BoxShadow(
                                color: Colors.black12,
                                blurRadius: 4,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: IconButton(
                            padding: EdgeInsets.zero,
                            icon: const Icon(Icons.remove_rounded, size: 20, color: AppColors.accent),
                            onPressed: () {
                              final currentCenter = _mapController.camera.center;
                              final currentZoom = _mapController.camera.zoom;
                              if (currentZoom > 2) {
                                _mapController.move(currentCenter, currentZoom - 1);
                              }
                            },
                            tooltip: 'Alejar',
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Reset location button
          if (hasLocation) ...[
            const SizedBox(height: AppSizes.s12),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () {
                  setState(() {
                    _latitude = null;
                    _longitude = null;
                  });
                },
                icon: const Icon(Icons.close_rounded, size: 16),
                label: Text(
                  'Quitar ubicación',
                  style: GoogleFonts.inter(fontSize: 12),
                ),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.textMuted,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // Action Buttons (Save + Edit)
  // ═══════════════════════════════════════════════════════════
  Widget _buildActionButtons(Business business) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Save button
        SizedBox(
          height: AppSizes.buttonMd,
          child: ElevatedButton.icon(
            onPressed: _isSaving ? null : () => _saveBusinessData(business),
            icon: _isSaving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.save_rounded, size: 18),
            label: Text(
              _isSaving ? 'Guardando...' : 'Guardar datos del negocio',
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSizes.radiusLg),
              ),
              elevation: 0,
              textStyle: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSizes.s12),

        // Edit business link
        SizedBox(
          height: AppSizes.buttonMd,
          child: OutlinedButton.icon(
            onPressed: () => context.push('/business-edit'),
            icon: const Icon(Icons.edit_rounded, size: 18),
            label: const Text('Editar negocio completo'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: const BorderSide(color: AppColors.primary, width: 1.5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSizes.radiusLg),
              ),
              textStyle: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSizes.s24),

        // Danger zone divider
        Row(
          children: [
            Expanded(child: Divider(color: Colors.red.shade200)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                'Zona de peligro',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.red.shade400,
                ),
              ),
            ),
            Expanded(child: Divider(color: Colors.red.shade200)),
          ],
        ),
        const SizedBox(height: AppSizes.s12),

        // Delete & reconfigure button
        SizedBox(
          height: AppSizes.buttonMd,
          child: OutlinedButton.icon(
            onPressed: () => _showDeleteBusinessDialog(business),
            icon: const Icon(Icons.delete_forever_rounded, size: 18),
            label: const Text('Eliminar negocio y reconfigurar'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red.shade600,
              side: BorderSide(color: Colors.red.shade300, width: 1.5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSizes.radiusLg),
              ),
              textStyle: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _showDeleteBusinessDialog(Business business) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.warning_amber_rounded, color: Colors.red.shade600, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text('Eliminar negocio', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700)),
            ),
          ],
        ),
        content: Text(
          '¿Estás seguro de que querés eliminar "${business.name}"?\n\nEsto borrará el negocio y sus servicios. Vas a poder crear uno nuevo desde el onboarding.',
          style: GoogleFonts.inter(fontSize: 14, height: 1.5, color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: Text('Cancelar', style: GoogleFonts.inter(color: AppColors.textMuted)),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              Navigator.pop(dialogCtx);
              try {
                await BusinessRepository().delete(business.id);
                ref.invalidate(businessesProvider);
                ref.invalidate(ownerBusinessProvider);
                if (mounted) {
                  context.go('/onboarding');
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error al eliminar: $e'), backgroundColor: AppColors.error),
                  );
                }
              }
            },
            icon: const Icon(Icons.delete_forever_rounded, size: 18),
            label: Text('Sí, eliminar', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ],
      ),
    );
  }
  // ═══════════════════════════════════════════════════════════
  // Reminders Card (navigate to RemindersSettingsScreen)
  // ═══════════════════════════════════════════════════════════
  Widget _buildRemindersCard(ThemeData theme, ColorScheme colorScheme) {
    return Container(
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
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.amber.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.notifications_active_rounded, color: Colors.amber, size: 22),
        ),
        title: const Text('Recordatorios'),
        subtitle: const Text('Configurar notificaciones automáticas'),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: () => context.push('/business-reminders'),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // a. Public URL Row
  // ═══════════════════════════════════════════════════════════
  Widget _buildPublicUrlRow(Business business) {
    final slug = _slugFromName(business.name);
    final url = 'https://www.reservly.com.ar/b/$slug';

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.s16,
        vertical: AppSizes.s12,
      ),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.15),
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 450;

          final iconAndText = Row(
            children: [
              Icon(
                Icons.link_rounded,
                color: AppColors.primary,
                size: AppSizes.iconMd,
              ),
              const SizedBox(width: AppSizes.s12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tu página pública de reservas',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: AppSizes.s2),
                    Text(
                      url,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primaryDark,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          );

          final copyButton = SizedBox(
            height: 32,
            width: isNarrow ? double.infinity : 100,
            child: ElevatedButton.icon(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: url));
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'URL copiada al portapapeles',
                      style: GoogleFonts.inter(),
                    ),
                    backgroundColor: AppColors.primary,
                    behavior: SnackBarBehavior.floating,
                    duration: const Duration(seconds: 2),
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(AppSizes.radiusSm),
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.copy_rounded, size: 14),
              label: Text(
                'Copiar',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(AppSizes.radiusSm),
                ),
                elevation: 0,
              ),
            ),
          );

          if (isNarrow) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                iconAndText,
                const SizedBox(height: AppSizes.s12),
                copyButton,
              ],
            );
          }

          return Row(
            children: [
              Expanded(child: iconAndText),
              const SizedBox(width: AppSizes.s12),
              copyButton,
            ],
          );
        },
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // b. Logo Section
  // ═══════════════════════════════════════════════════════════
  Widget _buildLogoSection(ThemeData theme, ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Logo del negocio',
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.accent,
          ),
        ),
        const SizedBox(height: AppSizes.s8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Square placeholder 64x64
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: colorScheme.outline.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                border: Border.all(
                  color: colorScheme.outline.withValues(alpha: 0.15),
                  style: BorderStyle.solid,
                ),
              ),
              child: Icon(
                Icons.cloud_upload_outlined,
                color: AppColors.textMuted,
                size: AppSizes.iconLg,
              ),
            ),
            const SizedBox(width: AppSizes.s16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Elegir imagen desde tu computadora',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: AppSizes.s6),
                  Text(
                    'JPG, PNG o WebP · Cualquier tamaño (se comprime automáticamente) · Aparece en tu página pública',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: AppColors.textMuted,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════
  // c. Name + Phone side by side
  // ═══════════════════════════════════════════════════════════
  Widget _buildNamePhoneRow(ThemeData theme, ColorScheme colorScheme) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final useVerticalLayout = constraints.maxWidth < 500;

        if (useVerticalLayout) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildTextField(
                controller: _nameController,
                label: 'Nombre del negocio *',
                theme: theme,
                colorScheme: colorScheme,
              ),
              const SizedBox(height: AppSizes.s16),
              _buildTextField(
                controller: _phoneController,
                label: 'Teléfono de contacto',
                theme: theme,
                colorScheme: colorScheme,
                keyboardType: TextInputType.phone,
              ),
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _buildTextField(
                controller: _nameController,
                label: 'Nombre del negocio *',
                theme: theme,
                colorScheme: colorScheme,
              ),
            ),
            const SizedBox(width: AppSizes.s16),
            Expanded(
              child: _buildTextField(
                controller: _phoneController,
                label: 'Teléfono de contacto',
                theme: theme,
                colorScheme: colorScheme,
                keyboardType: TextInputType.phone,
              ),
            ),
          ],
        );
      },
    );
  }

  // ═══════════════════════════════════════════════════════════
  // d. Address field
  // ═══════════════════════════════════════════════════════════
  Widget _buildAddressField(ThemeData theme, ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '📍 Dirección',
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.accent,
          ),
        ),
        const SizedBox(height: AppSizes.s6),
        TextFormField(
          controller: _addressController,
          style: GoogleFonts.inter(
            fontSize: 14,
            color: AppColors.accent,
          ),
          decoration: InputDecoration(
            hintText: 'Ej: Av. Mariscal López 1234, Asunción',
            hintStyle: GoogleFonts.inter(
              fontSize: 13,
              color: AppColors.textMuted,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSizes.s12,
              vertical: AppSizes.s12,
            ),
            filled: true,
            fillColor: colorScheme.outline.withValues(alpha: 0.04),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSizes.radiusMd),
              borderSide: BorderSide(
                color: colorScheme.outline.withValues(alpha: 0.15),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSizes.radiusMd),
              borderSide: BorderSide(
                color: colorScheme.outline.withValues(alpha: 0.15),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSizes.radiusMd),
              borderSide: const BorderSide(
                color: AppColors.primary,
                width: 1.5,
              ),
            ),
            suffixIcon: _isSearchingAddress
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.primary,
                      ),
                    ),
                  )
                : IconButton(
                    icon: const Icon(
                      Icons.search_rounded,
                      color: AppColors.primary,
                      size: 20,
                    ),
                    onPressed: _searchAddressOnMap,
                    tooltip: 'Ubicar en el mapa',
                  ),
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════
  // e. Description field
  // ═══════════════════════════════════════════════════════════
  Widget _buildDescriptionField(ThemeData theme, ColorScheme colorScheme) {
    return _buildTextField(
      controller: _descriptionController,
      label: 'Descripción',
      theme: theme,
      colorScheme: colorScheme,
      maxLines: 3,
      hintText:
          'Contá brevemente qué hacés y por qué los clientes deberían elegirte...',
    );
  }

  // ═══════════════════════════════════════════════════════════
  // f. Cancellation Policy
  // ═══════════════════════════════════════════════════════════
  Widget _buildCancellationPolicy(
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Horas mínimas para cancelar / reprogramar',
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.accent,
          ),
        ),
        const SizedBox(height: AppSizes.s8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              width: 80,
              child: TextFormField(
                controller: _cancellationController,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.accent,
                ),
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.s12,
                    vertical: AppSizes.s8,
                  ),
                  filled: true,
                  fillColor: colorScheme.outline.withValues(alpha: 0.04),
                  border: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(AppSizes.radiusMd),
                    borderSide: BorderSide(
                      color: colorScheme.outline.withValues(alpha: 0.15),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(AppSizes.radiusMd),
                    borderSide: BorderSide(
                      color: colorScheme.outline.withValues(alpha: 0.15),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(AppSizes.radiusMd),
                    borderSide: const BorderSide(
                      color: AppColors.primary,
                      width: 1.5,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppSizes.s12),
            Text(
              'horas de anticipación',
              style: GoogleFonts.inter(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSizes.s8),
        Text(
          'Los clientes no podrán cancelar ni reprogramar si falta menos tiempo que este mínimo.',
          style: GoogleFonts.inter(
            fontSize: 12,
            color: AppColors.textMuted,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════
  // Shared TextField builder
  // ═══════════════════════════════════════════════════════════
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required ThemeData theme,
    required ColorScheme colorScheme,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    String? hintText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.accent,
          ),
        ),
        const SizedBox(height: AppSizes.s6),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          style: GoogleFonts.inter(
            fontSize: 14,
            color: AppColors.accent,
          ),
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: GoogleFonts.inter(
              fontSize: 13,
              color: AppColors.textMuted,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSizes.s12,
              vertical: AppSizes.s12,
            ),
            filled: true,
            fillColor: colorScheme.outline.withValues(alpha: 0.04),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSizes.radiusMd),
              borderSide: BorderSide(
                color: colorScheme.outline.withValues(alpha: 0.15),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSizes.radiusMd),
              borderSide: BorderSide(
                color: colorScheme.outline.withValues(alpha: 0.15),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSizes.radiusMd),
              borderSide: const BorderSide(
                color: AppColors.primary,
                width: 1.5,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
