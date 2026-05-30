import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import 'package:reservpy/src/core/constants/app_colors.dart';
import 'package:reservpy/src/core/constants/app_sizes.dart';
import 'package:reservpy/src/shared/providers/providers.dart';
import 'package:reservpy/src/data/repositories/promotion_repository.dart';

/// Promotions management section for business settings.
class PromotionsManager extends ConsumerStatefulWidget {
  final String businessId;

  const PromotionsManager({super.key, required this.businessId});

  @override
  ConsumerState<PromotionsManager> createState() => _PromotionsManagerState();
}

class _PromotionsManagerState extends ConsumerState<PromotionsManager> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final promosAsync = ref.watch(businessPromotionsProvider(widget.businessId));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          children: [
            Icon(Icons.local_offer_rounded,
                size: 20, color: AppColors.primary),
            const SizedBox(width: 8),
            Text(
              'Promociones',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const Spacer(),
            TextButton.icon(
              onPressed: () => _showCreateDialog(context),
              icon: const Icon(Icons.add_rounded, size: 18),
              label: Text(
                'Nueva',
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
          'Creá descuentos para atraer más clientes.',
          style: GoogleFonts.inter(
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 16),

        promosAsync.when(
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
          ),
          error: (e, _) => Text('Error: $e'),
          data: (promos) {
            if (promos.isEmpty) {
              return Container(
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
                    Icon(Icons.percent_rounded,
                        size: 36,
                        color: AppColors.textMuted.withValues(alpha: 0.4)),
                    const SizedBox(height: 8),
                    Text(
                      'Sin promociones activas',
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
              children: promos.map((p) => _PromotionTile(
                promotion: p,
                onToggle: () async {
                  await PromotionRepository().toggleActive(p.id, !p.isActive);
                  ref.invalidate(businessPromotionsProvider(widget.businessId));
                },
                onDelete: () async {
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (_) => AlertDialog(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      title: Text('¿Eliminar promoción?',
                          style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
                      content: Text('Se eliminará "${p.title}" permanentemente.',
                          style: GoogleFonts.inter()),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Cancelar'),
                        ),
                        FilledButton(
                          onPressed: () => Navigator.pop(context, true),
                          style: FilledButton.styleFrom(
                              backgroundColor: AppColors.error),
                          child: const Text('Eliminar',
                              style: TextStyle(color: Colors.white)),
                        ),
                      ],
                    ),
                  );
                  if (confirmed == true) {
                    await PromotionRepository().delete(p.id);
                    ref.invalidate(
                        businessPromotionsProvider(widget.businessId));
                  }
                },
              )).toList(),
            );
          },
        ),
      ],
    );
  }

  void _showCreateDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => _CreatePromotionDialog(
        businessId: widget.businessId,
        onCreated: () =>
            ref.invalidate(businessPromotionsProvider(widget.businessId)),
      ),
    );
  }
}

// ── Promotion Tile ──────────────────────────────────────
class _PromotionTile extends StatelessWidget {
  final Promotion promotion;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  const _PromotionTile({
    required this.promotion,
    required this.onToggle,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isValid = promotion.isCurrentlyValid;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isValid
            ? AppColors.primary.withValues(alpha: 0.04)
            : theme.cardTheme.color,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isValid
              ? AppColors.primary.withValues(alpha: 0.15)
              : theme.colorScheme.outline.withValues(alpha: 0.1),
        ),
      ),
      child: Row(
        children: [
          // Discount badge
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: isValid
                  ? LinearGradient(
                      colors: [AppColors.primary, AppColors.primary.withValues(alpha: 0.7)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : null,
              color: isValid ? null : AppColors.textMuted.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(
                '${promotion.discountPercent}%',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: isValid ? Colors.white : AppColors.textMuted,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  promotion.title,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                if (promotion.description.isNotEmpty)
                  Text(
                    promotion.description,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                const SizedBox(height: 2),
                Text(
                  _validityText(),
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: isValid ? AppColors.primary : AppColors.textMuted,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          // Actions
          Switch.adaptive(
            value: promotion.isActive,
            onChanged: (_) => onToggle(),
            activeColor: AppColors.primary,
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded,
                size: 18, color: AppColors.textMuted),
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }

  String _validityText() {
    final fmt = DateFormat('dd/MM');
    if (promotion.validFrom != null && promotion.validTo != null) {
      return '${fmt.format(promotion.validFrom!)} - ${fmt.format(promotion.validTo!)}';
    }
    if (promotion.validFrom != null) {
      return 'Desde ${fmt.format(promotion.validFrom!)}';
    }
    if (promotion.validTo != null) {
      return 'Hasta ${fmt.format(promotion.validTo!)}';
    }
    return 'Sin fecha límite';
  }
}

// ── Create Promotion Dialog ──────────────────────────────
class _CreatePromotionDialog extends StatefulWidget {
  final String businessId;
  final VoidCallback onCreated;

  const _CreatePromotionDialog({
    required this.businessId,
    required this.onCreated,
  });

  @override
  State<_CreatePromotionDialog> createState() =>
      _CreatePromotionDialogState();
}

class _CreatePromotionDialogState extends State<_CreatePromotionDialog> {
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  int _discount = 15;
  DateTime? _validFrom;
  DateTime? _validTo;
  bool _isCreating = false;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.local_offer_rounded,
                      size: 22, color: AppColors.primary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Nueva Promoción',
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Title
            TextField(
              controller: _titleCtrl,
              decoration: InputDecoration(
                labelText: 'Título *',
                hintText: 'Ej: Promo de verano',
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
              ),
            ),
            const SizedBox(height: 12),

            // Description
            TextField(
              controller: _descCtrl,
              decoration: InputDecoration(
                labelText: 'Descripción (opcional)',
                hintText: 'Detalles de la promo',
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
              ),
            ),
            const SizedBox(height: 16),

            // Discount slider
            Text('Descuento: $_discount%',
                style: GoogleFonts.inter(
                    fontWeight: FontWeight.w700, fontSize: 14)),
            Slider(
              value: _discount.toDouble(),
              min: 5,
              max: 80,
              divisions: 15,
              label: '$_discount%',
              activeColor: AppColors.primary,
              onChanged: (v) => setState(() => _discount = v.round()),
            ),
            const SizedBox(height: 12),

            // Date pickers
            Row(
              children: [
                Expanded(
                  child: _DatePickerField(
                    label: 'Desde',
                    value: _validFrom,
                    onPicked: (d) => setState(() => _validFrom = d),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _DatePickerField(
                    label: 'Hasta',
                    value: _validTo,
                    onPicked: (d) => setState(() => _validTo = d),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Actions
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed:
                        _isCreating ? null : () => Navigator.pop(context),
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
                    onPressed: _isCreating || _titleCtrl.text.trim().isEmpty
                        ? null
                        : _create,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isCreating
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : Text('Crear',
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

  Future<void> _create() async {
    setState(() => _isCreating = true);
    try {
      await PromotionRepository().create(
        businessId: widget.businessId,
        title: _titleCtrl.text.trim(),
        description: _descCtrl.text.trim(),
        discountPercent: _discount,
        validFrom: _validFrom,
        validTo: _validTo,
      );
      widget.onCreated();
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
        setState(() => _isCreating = false);
      }
    }
  }
}

class _DatePickerField extends StatelessWidget {
  final String label;
  final DateTime? value;
  final ValueChanged<DateTime> onPicked;

  const _DatePickerField({
    required this.label,
    required this.value,
    required this.onPicked,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: value ?? DateTime.now(),
          firstDate: DateTime.now().subtract(const Duration(days: 30)),
          lastDate: DateTime.now().add(const Duration(days: 365)),
        );
        if (picked != null) onPicked(picked);
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: theme.colorScheme.surface,
          suffixIcon: const Icon(Icons.calendar_today_rounded, size: 16),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: theme.colorScheme.outline.withValues(alpha: 0.12),
            ),
          ),
        ),
        child: Text(
          value != null ? DateFormat('dd/MM/yy').format(value!) : 'Opcional',
          style: TextStyle(
            color: value != null ? null : AppColors.textMuted,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}
