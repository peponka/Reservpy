import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../../core/widgets/widgets.dart';
import '../../shared/providers/providers.dart';
import '../../data/repositories/business_repository.dart';

// ─── Local Providers ───────────────────────────────────────────
final _remindersEnabledProvider = StateProvider<bool>((ref) => true);
final _selectedTimingsProvider = StateProvider<Set<int>>((ref) => {24});
final _remindersInitializedBusinessIdProvider = StateProvider<String?>((ref) => null);

/// Reminders Settings Screen.
///
/// Allows business owners to configure reminder preferences.
/// The live automation sends WhatsApp reminders using the saved business timings.
class RemindersSettingsScreen extends ConsumerWidget {
  const RemindersSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final remindersEnabled = ref.watch(_remindersEnabledProvider);
    final business = ref.watch(currentBusinessProvider);
    final businessName = business?.name ?? 'Tu negocio';
    final initializedBusinessId = ref.watch(_remindersInitializedBusinessIdProvider);

    if (business != null && initializedBusinessId != business.id) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(_remindersEnabledProvider.notifier).state = business.remindersEnabled;
        ref.read(_selectedTimingsProvider.notifier).state = business.reminderHoursBefore.toSet();
        ref.read(_remindersInitializedBusinessIdProvider.notifier).state = business.id;
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Recordatorios'),
        centerTitle: false,
        actions: [
          // Save button
          Padding(
            padding: const EdgeInsets.only(right: AppSizes.s8),
            child: FilledButton.tonalIcon(
              onPressed: business == null
                  ? null
                  : () async {
                      final reminderHours = ref.read(_selectedTimingsProvider).toList()..sort();
                      if (remindersEnabled && reminderHours.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text('Elegi al menos un horario para enviar recordatorios'),
                            backgroundColor: AppColors.error,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                            ),
                          ),
                        );
                        return;
                      }

                      try {
                        await BusinessRepository().update(
                          business.copyWith(
                            remindersEnabled: remindersEnabled,
                            reminderHoursBefore: reminderHours,
                          ),
                        );
                        ref.invalidate(businessesProvider);
                        ref.invalidate(ownerBusinessProvider);
                        ref.invalidate(currentBusinessProvider);

                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text('Configuracion guardada correctamente'),
                            backgroundColor: AppColors.success,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                            ),
                          ),
                        );
                      } catch (e) {
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('No se pudo guardar la configuracion: $e'),
                            backgroundColor: AppColors.error,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                            ),
                          ),
                        );
                      }
                    },
              icon: const Icon(Icons.save_rounded, size: 18),
              label: const Text('Guardar'),
            ),
          ),
        ],
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
                  'Configura como queres manejar los recordatorios de tus turnos',
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
                      ref.read(_remindersEnabledProvider.notifier).state = val,
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
                            const SectionHeader(title: 'Configuracion guardada'),
                            const SizedBox(height: AppSizes.s4),
                            Text(
                              'Tus horarios preferidos se guardan y el envio automatico por WhatsApp respeta los horarios seleccionados para cada negocio.',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurface.withValues(alpha: 0.5),
                              ),
                            ),
                            const SizedBox(height: AppSizes.s12),
                            const _TimingChips(),
                            const SizedBox(height: AppSizes.s24),
                          ],
                        )
                          .animate()
                          .fadeIn(delay: 200.ms, duration: 400.ms)
                          .slideY(begin: 0.1, end: 0, delay: 200.ms, duration: 400.ms)
                      : const SizedBox.shrink(),
                ),

                // ─── Email Preview ───────────────────────────
                AnimatedSize(
                  duration: 300.ms,
                  curve: Curves.easeInOut,
                  alignment: Alignment.topCenter,
                  child: remindersEnabled
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SectionHeader(title: 'Vista previa del recordatorio'),
                            const SizedBox(height: AppSizes.s8),
                            _EmailPreviewCard(businessName: businessName),
                            const SizedBox(height: AppSizes.s24),
                          ],
                        )
                          .animate()
                          .fadeIn(delay: 300.ms, duration: 400.ms)
                          .slideY(begin: 0.1, end: 0, delay: 300.ms, duration: 400.ms)
                      : const SizedBox.shrink(),
                ),

                // ─── Additional Email Toggles ────────────────
                const SectionHeader(title: 'Envios automaticos actuales'),
                const SizedBox(height: AppSizes.s8),
                _EmailToggleCard(
                  icon: Icons.check_circle_outline_rounded,
                  iconColor: AppColors.success,
                  title: 'Confirmacion por email',
                  subtitle: 'Se envia automaticamente cuando el cliente reserva un turno',
                  value: true,
                  onChanged: null,
                )
                    .animate()
                    .fadeIn(delay: 400.ms, duration: 400.ms)
                    .slideY(begin: 0.1, end: 0, delay: 400.ms, duration: 400.ms),

                _EmailToggleCard(
                  icon: Icons.cancel_outlined,
                  iconColor: AppColors.error,
                  title: 'Cancelacion por email',
                  subtitle: 'Se envia automaticamente cuando un turno se cancela',
                  value: true,
                  onChanged: null,
                )
                    .animate()
                    .fadeIn(delay: 500.ms, duration: 400.ms)
                    .slideY(begin: 0.1, end: 0, delay: 500.ms, duration: 400.ms),

                const SizedBox(height: AppSizes.s24),

                // Estado real de la funcionalidad
                const SectionHeader(title: 'Estado actual'),
                const SizedBox(height: AppSizes.s8),
                const _ReminderStatusCard(),

                const SizedBox(height: AppSizes.s24),

                // ─── Info Banner ─────────────────────────────
                _InfoBanner()
                    .animate()
                    .fadeIn(delay: 800.ms, duration: 400.ms)
                    .slideY(begin: 0.1, end: 0, delay: 800.ms, duration: 400.ms),

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
  final ValueChanged<bool>? onChanged;

  const _MainToggleCard({required this.enabled, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AppCard(
      padding: const EdgeInsets.all(AppSizes.s20),
      child: Row(
        children: [
          // Icon container
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
          // Text
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
                  'Guardar la preferencia de recordatorios del negocio',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.55),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSizes.s12),
          // Switch
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

String _formatReminderTimingSummary(Set<int> timings) {
  if (timings.isEmpty) return 'sin horario definido';
  final sorted = timings.toList()..sort();
  if (sorted.length == 1) return '${sorted.first} horas antes';
  return sorted.map((hours) => '${hours}h').join(', ');
}

class _TimingChips extends ConsumerWidget {
  const _TimingChips();

  static const _timings = <int>[2, 6, 12, 24, 48];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(_selectedTimingsProvider);
    final theme = Theme.of(context);

    return Wrap(
      spacing: AppSizes.s8,
      runSpacing: AppSizes.s8,
      children: List.generate(_timings.length, (index) {
        final hours = _timings[index];
        final isSelected = selected.contains(hours);
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
              Text('$hours horas antes'),
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
          onSelected: (val) {
            final current = Set<int>.from(selected);
            if (val) {
              current.add(hours);
            } else {
              current.remove(hours);
            }
            ref.read(_selectedTimingsProvider.notifier).state = current;
          },
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
// ─── Email Preview Card ────────────────────────────────────────
// ═══════════════════════════════════════════════════════════════

class _EmailPreviewCard extends ConsumerWidget {
  final String businessName;

  const _EmailPreviewCard({required this.businessName});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final selectedTimings = ref.watch(_selectedTimingsProvider);
    final reminderSummary = _formatReminderTimingSummary(selectedTimings);

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
                  Icons.email_outlined,
                  size: 18,
                  color: colorScheme.onSurface.withValues(alpha: 0.5),
                ),
                const SizedBox(width: AppSizes.s8),
                Text(
                  'Vista previa actual',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.5),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                StatusBadge(label: 'WHATSAPP', color: AppColors.info),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSizes.s16,
              AppSizes.s16,
              AppSizes.s16,
              0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _EmailMetaRow(
                  label: 'Canal:',
                  value: 'WhatsApp automatico',
                ),
                const SizedBox(height: AppSizes.s6),
                _EmailMetaRow(
                  label: 'Para:',
                  value: 'Cliente con turno reservado',
                ),
                const SizedBox(height: AppSizes.s6),
                _EmailMetaRow(
                  label: 'Momento:',
                  value: reminderSummary,
                  isBold: true,
                ),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: AppSizes.s16),
            child: Divider(height: AppSizes.s24),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSizes.s16),
            child: _EmailBody(
              businessName: businessName,
              reminderSummary: reminderSummary,
            ),
          ),
          const SizedBox(height: AppSizes.s16),
        ],
      ),
    );
  }
}

class _EmailMetaRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isBold;

  const _EmailMetaRow({
    required this.label,
    required this.value,
    this.isBold = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 52,
          child: Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurface.withValues(alpha: 0.45),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: isBold ? FontWeight.w600 : FontWeight.w400,
              color: isBold
                  ? colorScheme.onSurface
                  : colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
        ),
      ],
    );
  }
}

class _EmailBody extends StatelessWidget {
  final String businessName;
  final String reminderSummary;

  const _EmailBody({
    required this.businessName,
    required this.reminderSummary,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSizes.s20),
      decoration: BoxDecoration(
        color: colorScheme.outline.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(AppSizes.radiusSm),
        border: Border.all(
          color: colorScheme.outline.withValues(alpha: 0.12),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                ),
                child: const Icon(
                  Icons.calendar_month_rounded,
                  size: 18,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: AppSizes.s8),
              Text(
                'ReservPy',
                style: theme.textTheme.titleSmall?.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.s20),
          Text(
            'Hola,',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSizes.s12),
          Text(
            'Este ejemplo muestra el recordatorio automatico activo hoy. La automatizacion conectada usa WhatsApp y aplica los horarios guardados en esta pantalla.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurface.withValues(alpha: 0.7),
              height: 1.5,
            ),
          ),
          const SizedBox(height: AppSizes.s16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSizes.s16),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(AppSizes.radiusSm),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.15),
              ),
            ),
            child: Column(
              children: [
                _AppointmentDetailRow(
                  icon: Icons.store_rounded,
                  label: 'Negocio',
                  value: businessName,
                ),
                const SizedBox(height: AppSizes.s12),
                _AppointmentDetailRow(
                  icon: Icons.design_services_rounded,
                  label: 'Servicio',
                  value: 'Servicio reservado',
                ),
                const SizedBox(height: AppSizes.s12),
                _AppointmentDetailRow(
                  icon: Icons.calendar_today_rounded,
                  label: 'Envio',
                  value: reminderSummary,
                ),
                const SizedBox(height: AppSizes.s12),
                _AppointmentDetailRow(
                  icon: Icons.access_time_rounded,
                  label: 'Turno',
                  value: 'Horario real del turno reservado',
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSizes.s20),
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.s24,
                vertical: AppSizes.s12,
              ),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.check_circle_rounded,
                    size: 18,
                    color: Colors.white,
                  ),
                  const SizedBox(width: AppSizes.s8),
                  Text(
                    'Ver mi reserva',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSizes.s16),
          Center(
            child: Text(
              'La configuracion de horarios ya impacta en el envio real. Las metricas detalladas todavia no muestran datos historicos.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurface.withValues(alpha: 0.4),
                fontSize: 11,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}

class _AppointmentDetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _AppointmentDetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.primary),
        const SizedBox(width: AppSizes.s8),
        SizedBox(
          width: 70,
          child: Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurface.withValues(alpha: 0.5),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// ─── Email Toggle Card ─────────────────────────────────────────
// ═══════════════════════════════════════════════════════════════

class _EmailToggleCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool>? onChanged;

  const _EmailToggleCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
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
          onChanged != null
              ? Switch.adaptive(
                  value: value,
                  onChanged: onChanged,
                  activeTrackColor: AppColors.primary,
                )
              : StatusBadge(
                  label: value ? 'ACTIVO' : 'INACTIVO',
                  color: value ? AppColors.success : AppColors.error,
                ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// ─── Email Stats Section ───────────────────────────────────────
// ═══════════════════════════════════════════════════════════════

class _ReminderStatusCard extends ConsumerWidget {
  const _ReminderStatusCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AppCard(
      padding: const EdgeInsets.all(AppSizes.s16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.warning.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppSizes.radiusSm),
            ),
            child: const Icon(
              Icons.insights_outlined,
              color: AppColors.warning,
              size: 20,
            ),
          ),
          const SizedBox(width: AppSizes.s12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Recordatorios activos hoy: WhatsApp configurable',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppSizes.s6),
                Text(
                  'La configuracion se guarda correctamente y el flujo automatico ya envia WhatsApp segun los horarios elegidos. Lo que todavia falta conectar son las metricas y reportes de rendimiento.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.65),
                    height: 1.45,
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
                  'Como funcionan hoy los recordatorios',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.info,
                  ),
                ),
                const SizedBox(height: AppSizes.s6),
                Text(
                  'Hoy ReservPy envia recordatorios automaticos por WhatsApp segun los horarios que configures en esta pantalla. '
                  'La parte pendiente en esta seccion es mostrar metricas reales e historial de entregas.',
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
