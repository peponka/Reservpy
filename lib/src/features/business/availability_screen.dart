import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:reservpy/src/core/constants/app_sizes.dart';
import 'package:reservpy/src/core/constants/app_colors.dart';
import 'package:reservpy/src/core/utils/date_utils.dart';
import 'package:reservpy/src/shared/providers/providers.dart';
import 'package:reservpy/src/shared/models/models.dart';
import 'package:reservpy/src/data/repositories/business_repository.dart';

class AvailabilityScreen extends ConsumerStatefulWidget {
  const AvailabilityScreen({super.key});

  @override
  ConsumerState<AvailabilityScreen> createState() => _AvailabilityScreenState();
}

class _AvailabilityScreenState extends ConsumerState<AvailabilityScreen> {
  bool _isSaving = false;

  // ── Day labels ──
  static const _dayNames = [
    'Lunes',
    'Martes',
    'Miércoles',
    'Jueves',
    'Viernes',
    'Sábado',
    'Domingo',
  ];

  /// Build DaySchedule list from the current business.
  /// Uses business.workingDays to determine which days are open.
  List<_DaySchedule> _buildSchedule(Business business) {
    return List.generate(7, (i) {
      final dayNum = i + 1; // 1=Mon, 2=Tue, ..., 7=Sun
      final isWorkDay = business.workingDays.contains(dayNum);
      return _DaySchedule(
        dayName: _dayNames[i],
        dayNum: dayNum,
        openingTime: isWorkDay ? business.openingTime : null,
        closingTime: isWorkDay ? business.closingTime : null,
      );
    });
  }

  Future<void> _toggleDay(Business business, int dayNum, bool currentlyOpen) async {
    setState(() => _isSaving = true);
    final updatedDays = List<int>.from(business.workingDays);
    if (currentlyOpen) {
      updatedDays.remove(dayNum);
    } else {
      updatedDays.add(dayNum);
      updatedDays.sort();
    }
    try {
      await BusinessRepository().updateField(business.id, 'working_days', updatedDays);
      ref.invalidate(ownerBusinessProvider);
      if (mounted) {
        final dayName = _dayNames[dayNum - 1];
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(currentlyOpen ? '$dayName marcado como cerrado' : '$dayName marcado como abierto'),
            backgroundColor: AppColors.primary,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al guardar: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _editSchedule(Business business) async {
    TimeOfDay opening = business.openingTime;
    TimeOfDay closing = business.closingTime;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            final theme = Theme.of(ctx);
            return AlertDialog(
              title: const Text('Editar horario'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(Icons.schedule_rounded,
                        color: theme.colorScheme.primary),
                    title: const Text('Apertura'),
                    trailing: TextButton(
                      onPressed: () async {
                        final picked = await showTimePicker(
                          context: ctx,
                          initialTime: opening,
                        );
                        if (picked != null) {
                          setDialogState(() => opening = picked);
                        }
                      },
                      child: Text(
                        AppDateUtils.timeOfDayToString(
                            opening.hour, opening.minute),
                      ),
                    ),
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(Icons.schedule_rounded,
                        color: theme.colorScheme.error),
                    title: const Text('Cierre'),
                    trailing: TextButton(
                      onPressed: () async {
                        final picked = await showTimePicker(
                          context: ctx,
                          initialTime: closing,
                        );
                        if (picked != null) {
                          setDialogState(() => closing = picked);
                        }
                      },
                      child: Text(
                        AppDateUtils.timeOfDayToString(
                            closing.hour, closing.minute),
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(false),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.of(ctx).pop(true),
                  child: const Text('Guardar'),
                ),
              ],
            );
          },
        );
      },
    );

    if (confirmed != true || !mounted) return;

    setState(() => _isSaving = true);
    try {
      final updated = business.copyWith(
        openingTime: opening,
        closingTime: closing,
      );
      await BusinessRepository().update(updated);
      ref.invalidate(businessesProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Horario actualizado correctamente')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al guardar: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final business = ref.watch(currentBusinessProvider);

    if (business == null) {
      return const Center(child: Text('No se encontró el negocio.'));
    }

    final weekDays = _buildSchedule(business);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 650;

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
                // ── Cabecera ──
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Disponibilidad',
                      style: theme.textTheme.headlineLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: AppSizes.s4),
                    Text(
                      'Configurá tus horarios de atención',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.outline,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSizes.s12),
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton.icon(
                    onPressed: _isSaving ? null : () => _editSchedule(business),
                    icon: _isSaving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.edit_rounded, size: 20),
                    label: Text(_isSaving ? 'Guardando...' : 'Editar horario'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorScheme.primary,
                      foregroundColor: colorScheme.onPrimary,
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSizes.s16,
                        vertical: AppSizes.s12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(AppSizes.radiusLg),
                      ),
                      elevation: 0,
                    ),
                  ),
                ),

                const SizedBox(height: AppSizes.s24),

                // ── Info Banner ──
                Container(
                  padding: const EdgeInsets.all(AppSizes.s16),
                  decoration: BoxDecoration(
                    color: AppColors.info.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                    border: Border.all(
                      color: AppColors.info.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline_rounded,
                          color: AppColors.info, size: 20),
                      const SizedBox(width: AppSizes.s12),
                      Expanded(
                        child: Text(
                          'El horario actual de tu negocio es de ${business.openingTimeStr} a ${business.closingTimeStr}. '
                          'Tocá un día para abrirlo o cerrarlo.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppColors.info,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: AppSizes.s24),

                // ── Horarios Semanales Card ──
                Container(
                  padding: const EdgeInsets.all(AppSizes.s20),
                  decoration: BoxDecoration(
                    color: theme.cardTheme.color,
                    borderRadius:
                        BorderRadius.circular(AppSizes.radiusLg),
                    border: Border.all(
                      color:
                          colorScheme.outline.withValues(alpha: 0.08),
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
                      Row(
                        children: [
                          Icon(
                            Icons.loop_rounded,
                            color: colorScheme.primary,
                            size: 20,
                          ),
                          const SizedBox(width: AppSizes.s8),
                          Text(
                            'Horarios semanales',
                            style:
                                theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSizes.s16),
                      const Divider(height: 1),
                      ...weekDays.map(
                        (day) => Column(
                          children: [
                            InkWell(
                              onTap: _isSaving ? null : () => _toggleDay(business, day.dayNum, day.openingTime != null),
                              child: _buildDayRow(context, theme, colorScheme,
                                  day, isMobile),
                            ),
                            const Divider(height: 1),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: AppSizes.s24),

                // ── Excepciones Card ──
                Container(
                  padding: const EdgeInsets.all(AppSizes.s20),
                  decoration: BoxDecoration(
                    color: theme.cardTheme.color,
                    borderRadius:
                        BorderRadius.circular(AppSizes.radiusLg),
                    border: Border.all(
                      color:
                          colorScheme.outline.withValues(alpha: 0.08),
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
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_month_rounded,
                            color: colorScheme.primary,
                            size: 20,
                          ),
                          const SizedBox(width: AppSizes.s8),
                          Text(
                            'Excepciones / fechas específicas',
                            style:
                                theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(width: AppSizes.s12),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSizes.s8,
                              vertical: AppSizes.s2,
                            ),
                            decoration: BoxDecoration(
                              color: colorScheme.outline
                                  .withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(
                                  AppSizes.radiusFull),
                            ),
                            child: Text(
                              '0 configuradas',
                              style:
                                  theme.textTheme.bodySmall?.copyWith(
                                color: colorScheme.outline,
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSizes.s20),
                      Container(
                        padding: const EdgeInsets.all(AppSizes.s32),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              colorScheme.outline
                                  .withValues(alpha: 0.02),
                              colorScheme.outline
                                  .withValues(alpha: 0.05),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(
                              AppSizes.radiusLg),
                          border: Border.all(
                            color: colorScheme.outline
                                .withValues(alpha: 0.06),
                            width: 1.5,
                          ),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              Icons.event_busy_rounded,
                              size: 36,
                              color: colorScheme.outline
                                  .withValues(alpha: 0.4),
                            ),
                            const SizedBox(height: AppSizes.s12),
                            Text(
                              'No hay fechas específicas configuradas.',
                              style: theme.textTheme.titleSmall
                                  ?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: AppSizes.s4),
                            Text(
                              'Usá excepciones para fechas fuera de lo habitual o días no laborables.',
                              style: theme.textTheme.bodySmall
                                  ?.copyWith(
                                color: colorScheme.outline,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDayRow(
    BuildContext context,
    ThemeData theme,
    ColorScheme colorScheme,
    _DaySchedule day,
    bool isMobile,
  ) {
    final isOpen = day.openingTime != null && day.closingTime != null;
    final scheduleStr = isOpen
        ? '${AppDateUtils.timeOfDayToString(day.openingTime!.hour, day.openingTime!.minute)} - ${AppDateUtils.timeOfDayToString(day.closingTime!.hour, day.closingTime!.minute)}'
        : null;

    if (isMobile) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSizes.s12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  day.dayName,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: !isOpen
                        ? colorScheme.outline.withValues(alpha: 0.6)
                        : null,
                  ),
                ),
                if (isOpen)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSizes.s8,
                      vertical: AppSizes.s4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.1),
                      borderRadius:
                          BorderRadius.circular(AppSizes.radiusFull),
                    ),
                    child: Text(
                      'Abierto',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: AppColors.success,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSizes.s8,
                      vertical: AppSizes.s4,
                    ),
                    decoration: BoxDecoration(
                      color: colorScheme.outline.withValues(alpha: 0.08),
                      borderRadius:
                          BorderRadius.circular(AppSizes.radiusFull),
                    ),
                    child: Text(
                      'Cerrado',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: colorScheme.outline,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: AppSizes.s8),
            if (scheduleStr != null)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.s12,
                  vertical: AppSizes.s8,
                ),
                decoration: BoxDecoration(
                  color:
                      colorScheme.primary.withValues(alpha: 0.06),
                  borderRadius:
                      BorderRadius.circular(AppSizes.radiusMd),
                  border: Border.all(
                    color: colorScheme.primary
                        .withValues(alpha: 0.25),
                    width: 1.2,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.access_time_rounded,
                      size: 16,
                      color: colorScheme.primary,
                    ),
                    const SizedBox(width: AppSizes.s8),
                    Text(
                      scheduleStr,
                      style:
                          theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              )
            else
              Text(
                'Sin horario de atención',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.outline
                      .withValues(alpha: 0.5),
                  fontStyle: FontStyle.italic,
                ),
              ),
          ],
        ),
      );
    }

    // Desktop view
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSizes.s12),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(
              day.dayName,
              style: theme.textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w600,
                color: !isOpen
                    ? colorScheme.outline.withValues(alpha: 0.6)
                    : null,
              ),
            ),
          ),
          const SizedBox(width: AppSizes.s16),
          Expanded(
            child: scheduleStr != null
                ? Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSizes.s12,
                          vertical: AppSizes.s8,
                        ),
                        decoration: BoxDecoration(
                          color: colorScheme.primary
                              .withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(
                              AppSizes.radiusMd),
                          border: Border.all(
                            color: colorScheme.primary
                                .withValues(alpha: 0.25),
                            width: 1.2,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.access_time_rounded,
                              size: 16,
                              color: colorScheme.primary,
                            ),
                            const SizedBox(width: AppSizes.s8),
                            Text(
                              scheduleStr,
                              style: theme.textTheme.bodyMedium
                                  ?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: AppSizes.s12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSizes.s8,
                          vertical: AppSizes.s4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.success
                              .withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(
                              AppSizes.radiusFull),
                        ),
                        child: Text(
                          'Abierto',
                          style: theme.textTheme.labelSmall
                              ?.copyWith(
                            color: AppColors.success,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  )
                : Text(
                    'Sin horario de atención',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.outline
                          .withValues(alpha: 0.5),
                      fontStyle: FontStyle.italic,
                    ),
                  ),
          ),
          if (!isOpen)
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.s8,
                vertical: AppSizes.s4,
              ),
              decoration: BoxDecoration(
                color: colorScheme.outline.withValues(alpha: 0.08),
                borderRadius:
                    BorderRadius.circular(AppSizes.radiusFull),
              ),
              child: Text(
                'Cerrado',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: colorScheme.outline,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _DaySchedule {
  final String dayName;
  final int dayNum;
  final TimeOfDay? openingTime;
  final TimeOfDay? closingTime;

  const _DaySchedule({
    required this.dayName,
    required this.dayNum,
    required this.openingTime,
    required this.closingTime,
  });
}
