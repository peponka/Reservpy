import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:reservpy/src/core/constants/app_colors.dart';
import 'package:reservpy/src/core/supabase/supabase_config.dart';
import 'package:reservpy/src/shared/providers/providers.dart';
import 'package:reservpy/src/data/repositories/favorite_repository.dart';

/// Heart toggle button for favorite businesses.
class FavoriteButton extends ConsumerStatefulWidget {
  final String businessId;
  final double size;

  const FavoriteButton({
    super.key,
    required this.businessId,
    this.size = 22,
  });

  @override
  ConsumerState<FavoriteButton> createState() => _FavoriteButtonState();
}

class _FavoriteButtonState extends ConsumerState<FavoriteButton>
    with SingleTickerProviderStateMixin {
  bool _isToggling = false;
  late AnimationController _animCtrl;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _scaleAnim = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.3), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 1.3, end: 1.0), weight: 50),
    ]).animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final favIds = ref.watch(clientFavoritesProvider).value ?? [];
    final isFav = favIds.contains(widget.businessId);

    return ScaleTransition(
      scale: _scaleAnim,
      child: IconButton(
        icon: Icon(
          isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
          color: isFav ? AppColors.error : AppColors.textMuted,
          size: widget.size,
        ),
        onPressed: _isToggling ? null : () => _toggle(isFav),
        tooltip: isFav ? 'Quitar de favoritos' : 'Agregar a favoritos',
        style: IconButton.styleFrom(
          backgroundColor: isFav
              ? AppColors.error.withValues(alpha: 0.08)
              : Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
    );
  }

  Future<void> _toggle(bool wasFav) async {
    final userId = SupabaseConfig.client.auth.currentUser?.id;
    if (userId == null) return;

    setState(() => _isToggling = true);
    _animCtrl.forward(from: 0);

    try {
      await FavoriteRepository().toggle(userId, widget.businessId);
      ref.invalidate(clientFavoritesProvider);
    } catch (_) {}

    if (mounted) setState(() => _isToggling = false);
  }
}
