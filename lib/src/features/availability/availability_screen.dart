import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:reservpy/src/core/constants/app_colors.dart';
import 'package:reservpy/src/core/constants/app_sizes.dart';
import 'package:reservpy/src/shared/providers/providers.dart';
import 'package:reservpy/src/data/repositories/business_repository.dart';

/// Disponibilidad screen matching ReservPy's admin/availability page.
class AvailabilityScreen extends ConsumerStatefulWidget {
  const AvailabilityScreen({super.key});

  @override
  ConsumerState<AvailabilityScreen> createState() => _AvailabilityScreenState();
}

class _AvailabilityScreenState extends ConsumerState<AvailabilityScreen> {
  bool _saving = false;

  static const _dayLabels = <({String short, String full, int dayNum})>[
    (short: 'Lun', full: 'Lunes', dayNum: 1),
    (short: 'Mar', full: 'Martes', dayNum: 2),
    (short: 'Mié', full: 'Miércoles', dayNum: 3),
    (short: 'Jue', full: 'Jueves', dayNum: 4),
    (short: 'Vie', full: 'Viernes', dayNum: 5),
    (short: 'Sáb', full: 'Sábado', dayNum: 6),
    (short: 'Dom', full: 'Domingo', dayNum: 7),
  ];

  Future<void> _toggleDay(int dayNum, bool currentlyActive) async {
    final business = ref.read(currentBusinessProvider);
    if (business == null) return;

    setState(() => _saving = true);

    final updatedDays = List<int>.from(business.workingDays);
    if (currentlyActive) {
      updatedDays.remove(dayNum);
    } else {
      updatedDays.add(dayNum);
      updatedDays.sort();
    }

    try {
      await BusinessRepository().updateField(
        business.id,
        'working_days',
        updatedDays,
      );
      ref.invalidate(ownerBusinessProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              currentlyActive
                  ? '${_dayLabels.firstWhere((d) => d.dayNum == dayNum).full} marcado como cerrado'
                  : '${_dayLabels.firstWhere((d) => d.dayNum == dayNum).full} marcado como abierto',
            ),
            backgroundColor: AppColors.primary,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al guardar: $e'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final business = ref.watch(currentBusinessProvider);

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
                  style: GoogleFonts.inter(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Configurá tus días y horarios de atención',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: colorScheme.primary,
                  ),
                ),
                const SizedBox(height: AppSizes.s24),

                if (business == null)
                  _buildEmptyState(theme, colorScheme)
                else ...[
                  _buildCurrentHoursCard(theme, colorScheme, business),
                  const SizedBox(height: AppSizes.s24),
                  _buildDayChipsSection(theme, colorScheme, business),
                  const SizedBox(height: AppSizes.s24),
                  _buildScheduleTable(theme, colorScheme, business),
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
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Creá tu negocio para configurar la disponibilidad.',
            style: GoogleFonts.inter(
              fontSize: 13,
              color: colorScheme.outline,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentHoursCard(ThemeData theme, ColorScheme colorScheme, dynamic business) {
    final openDays = business.workingDays.length;
    return Container(
      padding: const EdgeInsets.all(AppSizes.s20),
      decoration: BoxDecoration(
        color: colorScheme.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        border: Border.all(
          color: colorScheme.primary.withValues(alpha: 0.15),
        ),
      ),
      child: Row(
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
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${business.openingTimeStr} — ${business.closingTimeStr}  •  Turnos de ${business.slotDurationMinutes} min  •  $openDays días/semana',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: colorScheme.outline,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDayChipsSection(ThemeData theme, ColorScheme colorScheme, dynamic business) {
    final workingDays = business.workingDays as List<int>;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Días de atención',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: AppSizes.s4),
                  Text(
                    'Tocá un día para abrirlo o cerrarlo',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: colorScheme.outline,
                    ),
                  ),
                ],
              ),
            ),
            if (_saving)
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
              ),
          ],
        ),
        const SizedBox(height: AppSizes.s16),
        Wrap(
          spacing: AppSizes.s8,
          runSpacing: AppSizes.s8,
          children: _dayLabels.map((day) {
            final isActive = workingDays.contains(day.dayNum);
            return _DayChipButton(
              shortLabel: day.short,
              fullLabel: day.full,
              isActive: isActive,
              openTime: business.openingTimeStr,
              closeTime: business.closingTimeStr,
              onTap: _saving ? null : () => _toggleDay(day.dayNum, isActive),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildScheduleTable(ThemeData theme, ColorScheme colorScheme, dynamic business) {
    final workingDays = business.workingDays as List<int>;

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
                  child: Text('DÍA', style: GoogleFonts.inter(
                    fontSize: 11,
                    color: colorScheme.outline, fontWeight: FontWeight.w700, letterSpacing: 0.5,
                  )),
                ),
                Expanded(
                  flex: 2,
                  child: Text('APERTURA', style: GoogleFonts.inter(
                    fontSize: 11,
                    color: colorScheme.outline, fontWeight: FontWeight.w700, letterSpacing: 0.5,
                  )),
                ),
                Expanded(
                  flex: 2,
                  child: Text('CIERRE', style: GoogleFonts.inter(
                    fontSize: 11,
                    color: colorScheme.outline, fontWeight: FontWeight.w700, letterSpacing: 0.5,
                  )),
                ),
                Expanded(
                  flex: 2,
                  child: Text('ESTADO', style: GoogleFonts.inter(
                    fontSize: 11,
                    color: colorScheme.outline, fontWeight: FontWeight.w700, letterSpacing: 0.5,
                  ), textAlign: TextAlign.end),
                ),
              ],
            ),
          ),
          // Day rows
          ..._dayLabels.map((day) {
            final isActive = workingDays.contains(day.dayNum);
            return InkWell(
              onTap: _saving ? null : () => _toggleDay(day.dayNum, isActive),
              child: Container(
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
                      child: Text(day.full, style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isActive ? colorScheme.onSurface : colorScheme.outline,
                      )),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        isActive ? business.openingTimeStr : '—',
                        style: GoogleFonts.inter(fontSize: 13, color: colorScheme.outline),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        isActive ? business.closingTimeStr : '—',
                        style: GoogleFonts.inter(fontSize: 13, color: colorScheme.outline),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                          decoration: BoxDecoration(
                            color: (isActive ? AppColors.success : Colors.grey).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            isActive ? 'Abierto' : 'Cerrado',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: isActive ? AppColors.success : Colors.grey,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _DayChipButton extends StatelessWidget {
  final String shortLabel;
  final String fullLabel;
  final bool isActive;
  final String openTime;
  final String closeTime;
  final VoidCallback? onTap;

  const _DayChipButton({
    required this.shortLabel,
    required this.fullLabel,
    required this.isActive,
    required this.openTime,
    required this.closeTime,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Tooltip(
      message: isActive ? '$fullLabel: $openTime — $closeTime' : '$fullLabel: Cerrado',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
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
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: isActive ? colorScheme.primary : Colors.grey,
                  ),
                ),
                const SizedBox(height: 4),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
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
        ),
      ),
    );
  }
}
