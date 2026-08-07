import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../../core/widgets/widgets.dart';
import '../../shared/providers/providers.dart';
import '../../data/repositories/business_repository.dart';

// ─── Real reminder offsets, in hours before the appointment ────
const List<int> _hourOptions = [2, 6, 12, 24, 48];

/// Reminders Settings Screen.
///
/// Allows business owners to configure the automatic WhatsApp reminders
/// sent to their clients before each reservation. Every change is saved
/// immediately to the business record — there is no separate save step.
class RemindersSettingsScreen extends ConsumerWidget {
  const RemindersSettingsScreen({super.key});

  Future<void> _toggleEnabled(
    BuildContext context,
    WidgetRef ref,
    String businessId,
    bool value,
  ) async {
    try {
      await BusinessRepository().updateField(businessId, 'reminders_enabled', value);
      ref.invalidate(ownerBusinessProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(value
                ? 'Recordatorios activados'
                : 'Recordatorios desactivados'),
            backgroundColor: AppColors.primary,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al guardar: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  Future<void> _toggleHour(
    BuildContext context,
    WidgetRef ref,
    String businessId,
    List<int> currentHours,
    int hour,
  ) async {
    final updated = List<int>.from(currentHours);
    if (updated.contains(hour)) {
      if (updated.length == 1) return; // keep at least one timing selected
      updated.remove(hour);
    } else {
      updated.add(hour);
    }
    updated.sort();
    try {
      await BusinessRepository().updateField(businessId, 'reminder_hours_before', updated);
      ref.invalidate(ownerBusinessProvider);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al guardar: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final business = ref.watch(currentBusinessProvider);

    if (business == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Recordatorios')),
        body: const EmptyState(
          icon: Icons.notifications_off_outlined,
          title: 'Sin negocio',
          subtitle: 'Creá tu negocio para configurar los recordatorios.',
        ),
      );
    }

    final remindersEnabled = business.remindersEnabled;
    final selectedHours = business.reminderHoursBefore.isEmpty
        ? const [24]
        : business.reminderHoursBefore;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Recordatorios'),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.s20,
          vertical: AppSizes.s16,
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 700),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ─── Subtitle ────────────────────────────────
                Text(
                  'Recordatorios automáticos por WhatsApp para tus clientes',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                )
                    .animate()
                    .fadeIn(duration: 400.ms)
                    .slideY(begin: 0.1, end: 0, duration: 400.ms),

                const SizedBox(height: AppSizes.s24),

                // ─── Main Toggle ─────────────────────────────
                _MainToggleCard(
                  enabled: remindersEnabled,
                  onChanged: (val) =>
                      _toggleEnabled(context, ref, business.id, val),
                )
                    .animate()
                    .fadeIn(delay: 100.ms, duration: 400.ms)
                    .slideY(begin: 0.12, end: 0, delay: 100.ms, duration: 400.ms),

                const SizedBox(height: AppSizes.s24),

                // ─── Reminder Timing ─────────────────────────
                AnimatedSize(
                  duration: 300.ms,
                  curve: Curves.easeInOut,
                  alignment: Alignment.topCenter,
                  child: remindersEnabled
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SectionHeader(title: 'Horarios de envío'),
                            const SizedBox(height: AppSizes.s4),
                            Text(
                              'Elegí cuándo enviar el recordatorio antes del turno',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurface.withValues(alpha: 0.5),
                              ),
                            ),
                            const SizedBox(height: AppSizes.s12),
                            _TimingChips(
                              selectedHours: selectedHours,
                              onToggle: (hour) => _toggleHour(
                                context, ref, business.id, selectedHours, hour,
                              ),
                            ),
                            const SizedBox(height: AppSizes.s24),
                          ],
                        )
                          .animate()
                          .fadeIn(delay: 200.ms, duration: 400.ms)
                          .slideY(begin: 0.1, end: 0, delay: 200.ms, duration: 400.ms)
                      : const SizedBox.shrink(),
                ),

                // ─── WhatsApp Preview ────────────────────────
                AnimatedSize(
                  duration: 300.ms,
                  curve: Curves.easeInOut,
                  alignment: Alignment.topCenter,
                  child: remindersEnabled
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SectionHeader(title: 'Así lo recibe tu cliente'),
                            const SizedBox(height: AppSizes.s8),
                            _WhatsAppPreviewCard(businessName: business.name),
                            const SizedBox(height: AppSizes.s24),
                          ],
                        )
                          .animate()
                          .fadeIn(delay: 300.ms, duration: 400.ms)
                          .slideY(begin: 0.1, end: 0, delay: 300.ms, duration: 400.ms)
                      : const SizedBox.shrink(),
                ),

                // ─── Other automatic emails (always on) ──────
                const SectionHeader(title: 'Emails automáticos'),
                const SizedBox(height: AppSizes.s4),
                Text(
                  'Estos se envían siempre, no se pueden desactivar',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                ),
                const SizedBox(height: AppSizes.s12),
                _AlwaysOnRow(
                  icon: Icons.check_circle_outline_rounded,
                  iconColor: AppColors.success,
                  title: 'Email de confirmación',
                  subtitle: 'Se envía al cliente y al negocio cuando se reserva un turno',
                )
                    .animate()
                    .fadeIn(delay: 400.ms, duration: 400.ms)
                    .slideY(begin: 0.1, end: 0, delay: 400.ms, duration: 400.ms),
                const SizedBox(height: AppSizes.s8),
                _AlwaysOnRow(
                  icon: Icons.cancel_outlined,
                  iconColor: AppColors.error,
                  title: 'Notificación de cancelación',
                  subtitle: 'Se envía al cliente y al negocio cuando se cancela un turno',
                )
                    .animate()
                    .fadeIn(delay: 480.ms, duration: 400.ms)
                    .slideY(begin: 0.1, end: 0, delay: 480.ms, duration: 400.ms),

                const SizedBox(height: AppSizes.s24),

                // ─── Info Banner ─────────────────────────────
                _InfoBanner()
                    .animate()
                    .fadeIn(delay: 600.ms, duration: 400.ms)
                    .slideY(begin: 0.1, end: 0, delay: 600.ms, duration: 400.ms),

                const SizedBox(height: AppSizes.s40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// ─── Main Toggle Card ──────────────────────────────────────────
// ═══════════════════════════════════════════════════════════════

class _MainToggleCard extends StatelessWidget {
  final bool enabled;
  final ValueChanged<bool> onChanged;

  const _MainToggleCard({required this.enabled, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AppCard(
      padding: const EdgeInsets.all(AppSizes.s20),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: (enabled ? AppColors.primary : colorScheme.outline)
                  .withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppSizes.radiusMd),
            ),
            child: Icon(
              Icons.notifications_active_rounded,
              size: AppSizes.iconLg,
              color: enabled ? AppColors.primary : colorScheme.outline,
            ),
          ),
          const SizedBox(width: AppSizes.s16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Recordatorios automáticos',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppSizes.s4),
                Text(
                  'Enviar un WhatsApp de recordatorio antes de cada turno',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.55),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSizes.s12),
          Switch.adaptive(
            value: enabled,
            onChanged: onChanged,
            activeTrackColor: AppColors.primary,
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// ─── Timing Chips ──────────────────────────────────────────────
// ═══════════════════════════════════════════════════════════════

class _TimingChips extends StatelessWidget {
  final List<int> selectedHours;
  final ValueChanged<int> onToggle;

  const _TimingChips({required this.selectedHours, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Wrap(
      spacing: AppSizes.s8,
      runSpacing: AppSizes.s8,
      children: List.generate(_hourOptions.length, (index) {
        final hour = _hourOptions[index];
        final isSelected = selectedHours.contains(hour);
        return FilterChip(
          selected: isSelected,
          label: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.schedule_rounded,
                size: 16,
                color: isSelected
                    ? Colors.white
                    : theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
              const SizedBox(width: AppSizes.s6),
              Text('$hour horas antes'),
            ],
          ),
          selectedColor: AppColors.primary,
          checkmarkColor: Colors.white,
          labelStyle: TextStyle(
            color: isSelected ? Colors.white : theme.colorScheme.onSurface,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            fontSize: 13,
          ),
          backgroundColor:
              theme.colorScheme.outline.withValues(alpha: 0.08),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizes.radiusFull),
            side: BorderSide(
              color: isSelected
                  ? AppColors.primary
                  : theme.colorScheme.outline.withValues(alpha: 0.2),
            ),
          ),
          onSelected: (_) => onToggle(hour),
        )
            .animate()
            .fadeIn(
              delay: Duration(milliseconds: 250 + index * 60),
              duration: 350.ms,
            )
            .scale(
              begin: const Offset(0.9, 0.9),
              end: const Offset(1.0, 1.0),
              delay: Duration(milliseconds: 250 + index * 60),
              duration: 350.ms,
            );
      }),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// ─── WhatsApp Preview Card ─────────────────────────────────────
// ═══════════════════════════════════════════════════════════════

class _WhatsAppPreviewCard extends StatelessWidget {
  final String businessName;

  const _WhatsAppPreviewCard({required this.businessName});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSizes.s16,
              vertical: AppSizes.s12,
            ),
            decoration: BoxDecoration(
              color: colorScheme.outline.withValues(alpha: 0.06),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(AppSizes.radiusMd),
                topRight: Radius.circular(AppSizes.radiusMd),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.chat_bubble_outline_rounded,
                  size: 18,
                  color: colorScheme.onSurface.withValues(alpha: 0.5),
                ),
                const SizedBox(width: AppSizes.s8),
                Text(
                  'Mensaje de WhatsApp',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.5),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                StatusBadge(label: 'EJEMPLO', color: AppColors.info),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSizes.s16),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSizes.s16),
              decoration: BoxDecoration(
                color: const Color(0xFFDCF8C6),
                borderRadius: BorderRadius.circular(AppSizes.radiusSm),
              ),
              child: Text(
                'Hola María 👋 te recordamos tu turno en $businessName '
                'para el servicio Corte de pelo el miércoles 28/05 a las 10:00 hs.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.black87,
                  height: 1.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// ─── Always-on Info Row (non-toggleable) ────────────────────────
// ═══════════════════════════════════════════════════════════════

class _AlwaysOnRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;

  const _AlwaysOnRow({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AppCard(
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
              color: iconColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppSizes.radiusSm),
            ),
            child: Icon(icon, size: 20, color: iconColor),
          ),
          const SizedBox(width: AppSizes.s12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppSizes.s2),
                Text(
                  subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSizes.s8),
          StatusBadge(label: 'ACTIVO', color: AppColors.success),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// ─── Info Banner ───────────────────────────────────────────────
// ═══════════════════════════════════════════════════════════════

class _InfoBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSizes.s16),
      decoration: BoxDecoration(
        color: AppColors.info.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        border: Border.all(
          color: AppColors.info.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.info.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(AppSizes.radiusSm),
            ),
            child: const Icon(
              Icons.info_outline_rounded,
              size: 18,
              color: AppColors.info,
            ),
          ),
          const SizedBox(width: AppSizes.s12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '¿Cómo funcionan los recordatorios?',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.info,
                  ),
                ),
                const SizedBox(height: AppSizes.s6),
                Text(
                  'Se envían automáticamente por WhatsApp a los clientes con turnos '
                  'reservados, en los horarios que elijas arriba. Los cambios se '
                  'guardan al instante, no hace falta tocar ningún botón.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.6),
                    height: 1.5,
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
