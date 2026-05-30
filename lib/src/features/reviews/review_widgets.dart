import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import 'package:reservpy/src/core/constants/app_colors.dart';
import 'package:reservpy/src/core/constants/app_sizes.dart';
import 'package:reservpy/src/core/supabase/supabase_config.dart';
import 'package:reservpy/src/shared/models/models.dart';
import 'package:reservpy/src/shared/providers/providers.dart';
import 'package:reservpy/src/data/repositories/review_repository.dart';

// ─── Star Rating Display ──────────────────────────────────
class StarRating extends StatelessWidget {
  final double rating;
  final double size;
  final Color? color;

  const StarRating({
    super.key,
    required this.rating,
    this.size = 18,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final starColor = color ?? Colors.amber.shade600;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        final fill = rating - i;
        return Icon(
          fill >= 1
              ? Icons.star_rounded
              : fill >= 0.5
                  ? Icons.star_half_rounded
                  : Icons.star_outline_rounded,
          color: fill > 0 ? starColor : AppColors.textMuted.withValues(alpha: 0.3),
          size: size,
        );
      }),
    );
  }
}

// ─── Interactive Star Selector ────────────────────────────
class StarSelector extends StatelessWidget {
  final int selected;
  final ValueChanged<int> onChanged;
  final double size;

  const StarSelector({
    super.key,
    required this.selected,
    required this.onChanged,
    this.size = 36,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (i) {
        final starNum = i + 1;
        return GestureDetector(
          onTap: () => onChanged(starNum),
          child: AnimatedScale(
            scale: selected >= starNum ? 1.15 : 1.0,
            duration: const Duration(milliseconds: 150),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Icon(
                selected >= starNum
                    ? Icons.star_rounded
                    : Icons.star_outline_rounded,
                color: selected >= starNum
                    ? Colors.amber.shade600
                    : AppColors.textMuted.withValues(alpha: 0.3),
                size: size,
              ),
            ),
          ),
        );
      }),
    );
  }
}

// ─── Reviews Section for Business Detail ──────────────────
class ReviewsSection extends ConsumerWidget {
  final String businessId;

  const ReviewsSection({super.key, required this.businessId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final reviewsAsync = ref.watch(businessReviewsProvider(businessId));
    final avgRating = ref.watch(businessAverageRatingProvider(businessId));

    return reviewsAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (reviews) {
        if (reviews.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: theme.cardTheme.color,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Icon(Icons.rate_review_outlined,
                    size: 40, color: AppColors.textMuted.withValues(alpha: 0.4)),
                const SizedBox(height: 12),
                Text(
                  'Sin reseñas todavía',
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Sé el primero en dejar una reseña',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with average
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.amber.shade50,
                    Colors.amber.shade50.withValues(alpha: 0.3),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  // Big number
                  Column(
                    children: [
                      Text(
                        avgRating.toStringAsFixed(1),
                        style: GoogleFonts.inter(
                          fontSize: 40,
                          fontWeight: FontWeight.w800,
                          color: Colors.amber.shade700,
                          height: 1,
                        ),
                      ),
                      const SizedBox(height: 4),
                      StarRating(rating: avgRating, size: 16),
                      const SizedBox(height: 2),
                      Text(
                        '${reviews.length} reseña${reviews.length == 1 ? '' : 's'}',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 24),
                  // Rating bars
                  Expanded(
                    child: Column(
                      children: List.generate(5, (i) {
                        final star = 5 - i;
                        final count =
                            reviews.where((r) => r.rating == star).length;
                        final pct =
                            reviews.isEmpty ? 0.0 : count / reviews.length;
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Row(
                            children: [
                              Text('$star',
                                  style: GoogleFonts.inter(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textSecondary)),
                              const SizedBox(width: 4),
                              Icon(Icons.star_rounded,
                                  size: 12, color: Colors.amber.shade600),
                              const SizedBox(width: 8),
                              Expanded(
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: LinearProgressIndicator(
                                    value: pct,
                                    backgroundColor:
                                        Colors.amber.shade100.withValues(alpha: 0.5),
                                    valueColor: AlwaysStoppedAnimation(
                                        Colors.amber.shade600),
                                    minHeight: 6,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              SizedBox(
                                width: 20,
                                child: Text('$count',
                                    style: GoogleFonts.inter(
                                        fontSize: 11,
                                        color: AppColors.textMuted),
                                    textAlign: TextAlign.right),
                              ),
                            ],
                          ),
                        );
                      }),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Review list
            ...reviews.take(5).map((review) => _ReviewTile(review: review)),
          ],
        );
      },
    );
  }
}

// ─── Single Review Tile ────────────────────────────────────
class _ReviewTile extends StatelessWidget {
  final Review review;

  const _ReviewTile({required this.review});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final initials = (review.clientName ?? '?')
        .split(' ')
        .take(2)
        .map((w) => w.isNotEmpty ? w[0].toUpperCase() : '')
        .join();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.06),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Avatar
              CircleAvatar(
                radius: 18,
                backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                child: Text(
                  initials,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review.clientName ?? 'Anónimo',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    Text(
                      DateFormat('dd MMM yyyy', 'es').format(review.createdAt),
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              StarRating(rating: review.rating.toDouble(), size: 14),
            ],
          ),
          if (review.comment.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              review.comment,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Review Dialog ──────────────────────────────────────────
class ReviewDialog extends StatefulWidget {
  final String businessId;
  final String businessName;
  final String? reservationId;

  const ReviewDialog({
    super.key,
    required this.businessId,
    required this.businessName,
    this.reservationId,
  });

  @override
  State<ReviewDialog> createState() => _ReviewDialogState();
}

class _ReviewDialogState extends State<ReviewDialog> {
  int _rating = 0;
  final _commentController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.star_rounded,
                  size: 28, color: Colors.amber.shade600),
            ),
            const SizedBox(height: 16),
            Text(
              'Calificá tu experiencia',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              widget.businessName,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 20),

            // Stars
            StarSelector(
              selected: _rating,
              onChanged: (r) => setState(() => _rating = r),
            ),
            if (_rating > 0)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  _ratingLabel(_rating),
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.amber.shade700,
                  ),
                ),
              ),
            const SizedBox(height: 20),

            // Comment
            TextField(
              controller: _commentController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Contanos tu experiencia (opcional)',
                hintStyle: GoogleFonts.inter(
                    fontSize: 13, color: AppColors.textMuted),
                filled: true,
                fillColor: theme.colorScheme.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: theme.colorScheme.outline.withValues(alpha: 0.12),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      BorderSide(color: Colors.amber.shade600, width: 2),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Actions
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed:
                        _isSubmitting ? null : () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text('Cancelar',
                        style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: _rating == 0 || _isSubmitting
                        ? null
                        : () => _submit(context),
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.amber.shade600,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child:
                                CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : Text('Enviar',
                            style: GoogleFonts.inter(
                                fontWeight: FontWeight.w700,
                                color: Colors.white)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _ratingLabel(int r) {
    switch (r) {
      case 1:
        return '😞 Malo';
      case 2:
        return '😐 Regular';
      case 3:
        return '🙂 Bueno';
      case 4:
        return '😊 Muy bueno';
      case 5:
        return '🤩 Excelente';
      default:
        return '';
    }
  }

  Future<void> _submit(BuildContext context) async {
    setState(() => _isSubmitting = true);
    try {
      final userId =
          SupabaseConfig.client.auth.currentUser?.id;
      if (userId == null) return;

      await ReviewRepository().create(
        businessId: widget.businessId,
        clientId: userId,
        reservationId: widget.reservationId,
        rating: _rating,
        comment: _commentController.text.trim(),
      );

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        if (e.toString().contains('23505') || e.toString().contains('duplicate')) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Ya calificaste esta reserva ⭐',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w500)),
              backgroundColor: Colors.amber.shade700,
            ),
          );
          Navigator.pop(context, true);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e')),
          );
          setState(() => _isSubmitting = false);
        }
      }
    }
  }
}
