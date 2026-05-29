import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../../core/widgets/widgets.dart';
import '../../shared/providers/providers.dart';

// ─── Local Providers ───────────────────────────────────────────
final _remindersEnabledProvider = StateProvider<bool>((ref) => true);
final _selectedTimingsProvider = StateProvider<Set<int>>((ref) => {1, 3}); // indices
final _confirmationEmailProvider = StateProvider<bool>((ref) => true);
final _cancellationEmailProvider = StateProvider<bool>((ref) => false);

/// Reminders Settings Screen.
///
/// Allows business owners to configure automatic email reminders
/// for their clients before each reservation.
class RemindersSettingsScreen extends ConsumerWidget {
  const RemindersSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final remindersEnabled = ref.watch(_remindersEnabledProvider);
    final business = ref.watch(currentBusinessProvider);
    final businessName = business?.name ?? 'Mi Negocio';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Recordatorios'),
        centerTitle: false,
        actions: [
          // Save button
          Padding(
            padding: const EdgeInsets.only(right: AppSizes.s8),
            child: FilledButton.tonalIcon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Configuración guardada correctamente'),
                    backgroundColor: AppColors.success,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                    ),
                  ),
                );
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
                  'Configurá los emails automáticos para tus clientes',
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
                            const SectionHeader(title: 'Horarios de envío'),
                            const SizedBox(height: AppSizes.s4),
                            Text(
                              'Elegí cuándo enviar los recordatorios antes del turno',
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
                            const SectionHeader(title: 'Vista previa del email'),
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
                const SectionHeader(title: 'Emails adicionales'),
                const SizedBox(height: AppSizes.s8),
                _EmailToggleCard(
                  icon: Icons.check_circle_outline_rounded,
                  iconColor: AppColors.success,
                  title: 'Email de confirmación',
                  subtitle: 'Enviar un email al cliente cuando reserva un turno',
                  value: ref.watch(_confirmationEmailProvider),
                  onChanged: (val) =>
                      ref.read(_confirmationEmailProvider.notifier).state = val,
                )
                    .animate()
                    .fadeIn(delay: 400.ms, duration: 400.ms)
                    .slideY(begin: 0.1, end: 0, delay: 400.ms, duration: 400.ms),

                _EmailToggleCard(
                  icon: Icons.cancel_outlined,
                  iconColor: AppColors.error,
                  title: 'Notificación de cancelación',
                  subtitle: 'Enviar un email al cliente cuando se cancela su turno',
                  value: ref.watch(_cancellationEmailProvider),
                  onChanged: (val) =>
                      ref.read(_cancellationEmailProvider.notifier).state = val,
                )
                    .animate()
                    .fadeIn(delay: 500.ms, duration: 400.ms)
                    .slideY(begin: 0.1, end: 0, delay: 500.ms, duration: 400.ms),

                const SizedBox(height: AppSizes.s24),

                // ─── Stats ───────────────────────────────────
                const SectionHeader(title: 'Estadísticas de emails'),
                const SizedBox(height: AppSizes.s8),
                const _EmailStatsSection(),

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
                  'Enviar emails de recordatorio antes de cada turno',
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

class _TimingChips extends ConsumerWidget {
  const _TimingChips();

  static const _timings = [
    '2 horas antes',
    '6 horas antes',
    '12 horas antes',
    '24 horas antes',
    '48 horas antes',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(_selectedTimingsProvider);
    final theme = Theme.of(context);

    return Wrap(
      spacing: AppSizes.s8,
      runSpacing: AppSizes.s8,
      children: List.generate(_timings.length, (index) {
        final isSelected = selected.contains(index);
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
              Text(_timings[index]),
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
              current.add(index);
            } else {
              current.remove(index);
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

class _EmailPreviewCard extends StatelessWidget {
  final String businessName;

  const _EmailPreviewCard({required this.businessName});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ─── Email header bar ──────────────────────────
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
                  'Vista previa',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.5),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                StatusBadge(label: 'PREVIEW', color: AppColors.info),
              ],
            ),
          ),

          // ─── Email metadata ────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSizes.s16, AppSizes.s16, AppSizes.s16, 0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _EmailMetaRow(
                  label: 'De:',
                  value: 'ReservPy <noreply@reservpy.com.py>',
                ),
                const SizedBox(height: AppSizes.s6),
                _EmailMetaRow(
                  label: 'Para:',
                  value: 'cliente@email.com',
                ),
                const SizedBox(height: AppSizes.s6),
                _EmailMetaRow(
                  label: 'Asunto:',
                  value: 'Recordatorio: Tu turno en $businessName es mañana',
                  isBold: true,
                ),
              ],
            ),
          ),

          const Padding(
            padding: EdgeInsets.symmetric(horizontal: AppSizes.s16),
            child: Divider(height: AppSizes.s24),
          ),

          // ─── Email body ────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSizes.s16),
            child: _EmailBody(businessName: businessName),
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

  const _EmailBody({required this.businessName});

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
          // Logo area
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

          // Greeting
          Text(
            '¡Hola, María! 👋',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),

          const SizedBox(height: AppSizes.s12),

          Text(
            'Te recordamos que tenés un turno próximo:',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurface.withValues(alpha: 0.7),
              height: 1.5,
            ),
          ),

          const SizedBox(height: AppSizes.s16),

          // Appointment details box
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
                  value: 'Corte de pelo',
                ),
                const SizedBox(height: AppSizes.s12),
                _AppointmentDetailRow(
                  icon: Icons.calendar_today_rounded,
                  label: 'Fecha',
                  value: 'Miércoles, 28 de mayo 2026',
                ),
                const SizedBox(height: AppSizes.s12),
                _AppointmentDetailRow(
                  icon: Icons.access_time_rounded,
                  label: 'Hora',
                  value: '10:00 hs.',
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSizes.s20),

          // CTA Button (static, non-functional)
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
                    'Confirmar asistencia',
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

          // Footer text
          Center(
            child: Text(
              'Si necesitás cancelar, hacelo desde la app.',
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
  final ValueChanged<bool> onChanged;

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
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
            activeTrackColor: AppColors.primary,
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// ─── Email Stats Section ───────────────────────────────────────
// ═══════════════════════════════════════════════════════════════

class _EmailStatsSection extends StatelessWidget {
  const _EmailStatsSection();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Use a responsive grid: 3 columns on wider screens, stack on narrow
        if (constraints.maxWidth >= 500) {
          return Row(
            children: [
              Expanded(
                child: _StatMiniCard(
                  icon: Icons.send_rounded,
                  color: AppColors.info,
                  value: '47',
                  label: 'Emails enviados\neste mes',
                  delay: 600,
                ),
              ),
              const SizedBox(width: AppSizes.s12),
              Expanded(
                child: _StatMiniCard(
                  icon: Icons.visibility_rounded,
                  color: AppColors.warning,
                  value: '68%',
                  label: 'Tasa de\napertura',
                  delay: 680,
                ),
              ),
              const SizedBox(width: AppSizes.s12),
              Expanded(
                child: _StatMiniCard(
                  icon: Icons.thumb_up_alt_rounded,
                  color: AppColors.success,
                  value: '32',
                  label: 'Confirmaciones\nrecibidas',
                  delay: 760,
                ),
              ),
            ],
          );
        }
        // Narrow layout — vertical
        return Column(
          children: [
            _StatMiniCard(
              icon: Icons.send_rounded,
              color: AppColors.info,
              value: '47',
              label: 'Emails enviados este mes',
              delay: 600,
            ),
            const SizedBox(height: AppSizes.s8),
            _StatMiniCard(
              icon: Icons.visibility_rounded,
              color: AppColors.warning,
              value: '68%',
              label: 'Tasa de apertura',
              delay: 680,
            ),
            const SizedBox(height: AppSizes.s8),
            _StatMiniCard(
              icon: Icons.thumb_up_alt_rounded,
              color: AppColors.success,
              value: '32',
              label: 'Confirmaciones recibidas',
              delay: 760,
            ),
          ],
        );
      },
    );
  }
}

class _StatMiniCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String value;
  final String label;
  final int delay;

  const _StatMiniCard({
    required this.icon,
    required this.color,
    required this.value,
    required this.label,
    this.delay = 0,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppCard(
      padding: const EdgeInsets.all(AppSizes.s16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppSizes.radiusSm),
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(height: AppSizes.s12),
          Text(
            value,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSizes.s4),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
              height: 1.3,
            ),
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(
          delay: Duration(milliseconds: delay),
          duration: 400.ms,
        )
        .slideY(
          begin: 0.15,
          end: 0,
          delay: Duration(milliseconds: delay),
          duration: 400.ms,
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
                  'Los emails se envían automáticamente a los clientes que tienen turnos reservados. '
                  'Podés elegir múltiples horarios de envío para maximizar la tasa de asistencia.',
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
