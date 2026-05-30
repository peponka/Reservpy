import 'dart:typed_data';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:reservpy/src/core/constants/app_colors.dart';
import 'package:reservpy/src/core/constants/app_sizes.dart';
import 'package:reservpy/src/shared/providers/providers.dart';
import 'package:reservpy/src/data/repositories/business_photo_repository.dart';

/// Pick an image file on Flutter Web using dart:html.
Future<({Uint8List bytes, String name})?> _pickImageWeb() async {
  final completer = Completer<({Uint8List bytes, String name})?>();
  final input = html.FileUploadInputElement()..accept = 'image/*';
  input.click();
  input.onChange.listen((event) {
    final file = input.files?.first;
    if (file == null) {
      completer.complete(null);
      return;
    }
    final reader = html.FileReader();
    reader.readAsArrayBuffer(file);
    reader.onLoadEnd.listen((_) {
      final bytes = reader.result as Uint8List;
      completer.complete((bytes: bytes, name: file.name));
    });
  });
  Future.delayed(const Duration(minutes: 2), () {
    if (!completer.isCompleted) completer.complete(null);
  });
  return completer.future;
}

/// Photo gallery management for business owners.
class BusinessPhotosManager extends ConsumerStatefulWidget {
  final String businessId;

  const BusinessPhotosManager({super.key, required this.businessId});

  @override
  ConsumerState<BusinessPhotosManager> createState() =>
      _BusinessPhotosManagerState();
}

class _BusinessPhotosManagerState extends ConsumerState<BusinessPhotosManager> {
  bool _isUploading = false;

  Future<void> _pickAndUpload() async {
    final picked = await _pickImageWeb();
    if (picked == null) return;

    setState(() => _isUploading = true);
    try {
      await BusinessPhotoRepository().uploadPhoto(
        businessId: widget.businessId,
        bytes: picked.bytes,
        fileName: picked.name,
      );
      ref.invalidate(businessPhotosProvider(widget.businessId));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded,
                    color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Text('Foto subida',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w500)),
              ],
            ),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al subir: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  Future<void> _deletePhoto(BusinessPhoto photo) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('¿Eliminar foto?',
            style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
        content: Text('Esta acción no se puede deshacer.',
            style: GoogleFonts.inter()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Eliminar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await BusinessPhotoRepository().deletePhoto(photo);
      ref.invalidate(businessPhotosProvider(widget.businessId));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final photosAsync = ref.watch(businessPhotosProvider(widget.businessId));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          children: [
            Icon(Icons.photo_library_rounded,
                size: 20, color: AppColors.primary),
            const SizedBox(width: 8),
            Text(
              'Fotos del negocio',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const Spacer(),
            TextButton.icon(
              onPressed: _isUploading ? null : _pickAndUpload,
              icon: _isUploading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.add_photo_alternate_rounded, size: 18),
              label: Text(
                _isUploading ? 'Subiendo...' : 'Agregar',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Máximo 6 fotos. Mostrá tu local y trabajos.',
          style: GoogleFonts.inter(
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 16),

        // Photo grid
        photosAsync.when(
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
          ),
          error: (e, _) => Text('Error: $e'),
          data: (photos) {
            if (photos.isEmpty) {
              return GestureDetector(
                onTap: _isUploading ? null : _pickAndUpload,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 32),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: theme.colorScheme.outline.withValues(alpha: 0.15),
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    children: [
                      Icon(Icons.add_a_photo_rounded,
                          size: 36,
                          color: AppColors.textMuted.withValues(alpha: 0.4)),
                      const SizedBox(height: 8),
                      Text(
                        'Subí fotos de tu negocio',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 1,
              ),
              itemCount: photos.length < 6 ? photos.length + 1 : photos.length,
              itemBuilder: (_, i) {
                if (i == photos.length && photos.length < 6) {
                  return GestureDetector(
                    onTap: _isUploading ? null : _pickAndUpload,
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: theme.colorScheme.outline.withValues(alpha: 0.15),
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.add_rounded,
                          size: 32,
                          color: AppColors.textMuted.withValues(alpha: 0.4)),
                    ),
                  );
                }

                final photo = photos[i];
                return Stack(
                  fit: StackFit.expand,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        photo.url,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: theme.colorScheme.surface,
                          child: const Icon(Icons.broken_image_rounded,
                              color: AppColors.textMuted),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 4,
                      right: 4,
                      child: GestureDetector(
                        onTap: () => _deletePhoto(photo),
                        child: Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.close_rounded,
                              size: 16, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                );
              },
            );
          },
        ),
      ],
    );
  }
}

/// Photo carousel for the client-facing business detail screen.
class PhotoCarousel extends ConsumerWidget {
  final String businessId;

  const PhotoCarousel({super.key, required this.businessId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final photosAsync = ref.watch(businessPhotosProvider(businessId));

    return photosAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (photos) {
        if (photos.isEmpty) return const SizedBox.shrink();

        return SizedBox(
          height: 180,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            itemCount: photos.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (_, i) {
              return GestureDetector(
                onTap: () => _showFullScreen(context, photos, i),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Image.network(
                    photos[i].url,
                    width: 240,
                    height: 180,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      width: 240,
                      height: 180,
                      color: Colors.grey.shade200,
                      child: const Icon(Icons.broken_image_rounded),
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  void _showFullScreen(
      BuildContext context, List<BusinessPhoto> photos, int initialIndex) {
    showDialog(
      context: context,
      builder: (_) => Dialog.fullscreen(
        backgroundColor: Colors.black,
        child: Stack(
          children: [
            PageView.builder(
              controller: PageController(initialPage: initialIndex),
              itemCount: photos.length,
              itemBuilder: (_, i) => Center(
                child: InteractiveViewer(
                  child: Image.network(photos[i].url, fit: BoxFit.contain),
                ),
              ),
            ),
            Positioned(
              top: 16,
              right: 16,
              child: IconButton(
                icon: const Icon(Icons.close_rounded,
                    color: Colors.white, size: 28),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
