import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:reservpy/src/core/constants/app_colors.dart';
import 'package:reservpy/src/core/constants/app_sizes.dart';
import 'package:reservpy/src/shared/providers/providers.dart';

/// Disponibilidad screen matching ReservPy's admin/availability page.
class AvailabilityScreen extends ConsumerWidget {
  const AvailabilityScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final business = ref.watch(currentBusinessProvider);

    final days = [
      _DaySchedule('Lun', 'Lunes', true),
      _DaySchedule('Mar', 'Martes', true),
      _DaySchedule('Mié', 'Miércoles', true),
      _DaySchedule('Jue', 'Jueves', true),
      _DaySchedule('Vie', 'Viernes', true),
      _DaySchedule('Sáb', 'Sábado', true),
      _DaySchedule('Dom', 'Domingo', false),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(AppSizes.s24),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: constraints.maxHeight - 48,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                Text(
                  'Disponibilidad',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Configurá tus días y horarios de atención',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.primary,
                  ),
                ),
                const SizedBox(height: AppSizes.s24),

                if (business == null)
                  _buildEmptyState(theme, colorScheme)
                else ...[
                  _buildCurrentHoursCard(theme, colorScheme, business),
                  const SizedBox(height: AppSizes.s24),
                  _buildDayChipsSection(theme, colorScheme, days, business),
                  const SizedBox(height: AppSizes.s24),
                  _buildScheduleTable(theme, colorScheme, days, business),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(ThemeData theme, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 60),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        border: Border.all(
          color: colorScheme.outline.withValues(alpha: 0.08),
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.schedule_outlined,
            size: 48,
            color: colorScheme.outline.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'Sin horario configurado',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Creá tu negocio para configurar la disponibilidad.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.outline,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentHoursCard(ThemeData theme, ColorScheme colorScheme, dynamic business) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.s20),
      decoration: BoxDecoration(
        color: colorScheme.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        border: Border.all(
          color: colorScheme.primary.withValues(alpha: 0.15),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSizes.s12),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.access_time_rounded,
                  color: colorScheme.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: AppSizes.s16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Horario actual',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${business.openingTimeStr} — ${business.closingTimeStr}  •  Turnos de ${business.slotDurationMinutes} min',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.outline,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: OutlinedButton(
              onPressed: () {},
              style: OutlinedButton.styleFrom(
                side: BorderSide(
                  color: colorScheme.primary,
                  width: 1.5,
                ),
                foregroundColor: colorScheme.primary,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.s16,
                  vertical: AppSizes.s8,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                ),
              ),
              child: const Text(
                'Editar',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDayChipsSection(ThemeData theme, ColorScheme colorScheme, List<_DaySchedule> days, dynamic business) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Días de atención',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: AppSizes.s4),
        Text(
          'Seleccioná los días en los que atendés',
          style: theme.textTheme.bodySmall?.copyWith(
            color: colorScheme.outline,
          ),
        ),
        const SizedBox(height: AppSizes.s16),
        Wrap(
          spacing: AppSizes.s8,
          runSpacing: AppSizes.s8,
          children: days.map((day) {
            return _DayChip(
              shortLabel: day.short,
              fullLabel: day.full,
              isActive: day.isActive,
              openTime: business.openingTimeStr,
              closeTime: business.closingTimeStr,
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildScheduleTable(ThemeData theme, ColorScheme colorScheme, List<_DaySchedule> days, dynamic business) {
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
      child: Column(
        children: [
          // Table header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: colorScheme.outline.withValues(alpha: 0.08),
                ),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Text('DÍA', style: theme.textTheme.labelSmall?.copyWith(
                    color: colorScheme.outline, fontWeight: FontWeight.w700, letterSpacing: 0.5,
                  )),
                ),
                Expanded(
                  flex: 2,
                  child: Text('APERTURA', style: theme.textTheme.labelSmall?.copyWith(
                    color: colorScheme.outline, fontWeight: FontWeight.w700, letterSpacing: 0.5,
                  )),
                ),
                Expanded(
                  flex: 2,
                  child: Text('CIERRE', style: theme.textTheme.labelSmall?.copyWith(
                    color: colorScheme.outline, fontWeight: FontWeight.w700, letterSpacing: 0.5,
                  )),
                ),
                Expanded(
                  flex: 2,
                  child: Text('ESTADO', style: theme.textTheme.labelSmall?.copyWith(
                    color: colorScheme.outline, fontWeight: FontWeight.w700, letterSpacing: 0.5,
                  ), textAlign: TextAlign.end),
                ),
              ],
            ),
          ),
          // Day rows
          ...days.map(
            (day) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: colorScheme.outline.withValues(alpha: 0.05),
                  ),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Text(day.full, style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    )),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(day.isActive ? business.openingTimeStr : '—', style: theme.textTheme.bodySmall),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(day.isActive ? business.closingTimeStr : '—', style: theme.textTheme.bodySmall),
                  ),
                  Expanded(
                    flex: 2,
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                        decoration: BoxDecoration(
                          color: (day.isActive ? AppColors.success : Colors.grey).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          day.isActive ? 'Abierto' : 'Cerrado',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: day.isActive ? AppColors.success : Colors.grey,
                          ),
                        ),
                      ),
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
}

class _DaySchedule {
  final String short;
  final String full;
  final bool isActive;
  const _DaySchedule(this.short, this.full, this.isActive);
}

class _DayChip extends StatelessWidget {
  final String shortLabel;
  final String fullLabel;
  final bool isActive;
  final String openTime;
  final String closeTime;

  const _DayChip({
    required this.shortLabel,
    required this.fullLabel,
    required this.isActive,
    required this.openTime,
    required this.closeTime,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Tooltip(
      message: isActive ? '$fullLabel: $openTime — $closeTime' : '$fullLabel: Cerrado',
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.s16,
          vertical: AppSizes.s12,
        ),
        decoration: BoxDecoration(
          color: isActive
              ? colorScheme.primary.withValues(alpha: 0.08)
              : colorScheme.outline.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          border: Border.all(
            color: isActive
                ? colorScheme.primary.withValues(alpha: 0.2)
                : colorScheme.outline.withValues(alpha: 0.1),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              shortLabel,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: isActive ? colorScheme.primary : Colors.grey,
              ),
            ),
            const SizedBox(height: 4),
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: isActive ? AppColors.success : Colors.grey,
                shape: BoxShape.circle,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
