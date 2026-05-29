import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import 'package:reservpy/src/core/widgets/widgets.dart';
import 'package:reservpy/src/core/constants/app_sizes.dart';
import 'package:reservpy/src/core/constants/app_strings.dart';
import 'package:reservpy/src/core/utils/date_utils.dart';
import 'package:reservpy/src/shared/providers/providers.dart';

/// Success screen displayed after a reservation is confirmed.
/// Shows an animated checkmark, reservation summary, and navigation buttons.
class ReservationSuccessScreen extends ConsumerWidget {
  final String businessName;
  final String serviceName;
  final DateTime date;
  final DateTime endDate;

  const ReservationSuccessScreen({
    super.key,
    required this.businessName,
    required this.serviceName,
    required this.date,
    required this.endDate,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final timeRange = AppDateUtils.formatTimeRange(date, endDate);
    final formattedDate = AppDateUtils.formatFullDate(date);

    return PopScope(
      canPop: false,
      child: Scaffold(
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSizes.s32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // ── Animated checkmark ──
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [
                          theme.colorScheme.primary,
                          theme.colorScheme.primary.withValues(alpha: 0.7),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color:
                              theme.colorScheme.primary.withValues(alpha: 0.3),
                          blurRadius: 30,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.check_rounded,
                      size: 64,
                      color: theme.colorScheme.onPrimary,
                    ),
                  )
                      .animate()
                      .scale(
                        begin: const Offset(0, 0),
                        end: const Offset(1, 1),
                        duration: 600.ms,
                        curve: Curves.elasticOut,
                      )
                      .fadeIn(duration: 300.ms),

                  const SizedBox(height: AppSizes.s32),

                  // ── Celebration particles ──
                  ..._buildCelebrationDots(theme),

                  // ── Title ──
                  Text(
                    AppStrings.reservationSuccess,
                    style: theme.textTheme.headlineLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                    textAlign: TextAlign.center,
                  )
                      .animate()
                      .fadeIn(delay: 400.ms, duration: 400.ms)
                      .slideY(begin: 0.2, end: 0, delay: 400.ms, duration: 400.ms),

                  const SizedBox(height: AppSizes.s8),

                  Text(
                    'Tu turno ha sido registrado correctamente',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.outline,
                    ),
                    textAlign: TextAlign.center,
                  )
                      .animate()
                      .fadeIn(delay: 500.ms, duration: 400.ms),

                  const SizedBox(height: AppSizes.s32),

                  // ── Summary card ──
                  AppCard(
                    padding: const EdgeInsets.all(AppSizes.s24),
                    child: Column(
                      children: [
                        _SuccessInfoRow(
                          icon: Icons.store_rounded,
                          label: 'Negocio',
                          value: businessName,
                        ),
                        Divider(
                          height: AppSizes.s24,
                          color: theme.colorScheme.outline
                              .withValues(alpha: 0.15),
                        ),
                        _SuccessInfoRow(
                          icon: Icons.spa_rounded,
                          label: 'Servicio',
                          value: serviceName,
                        ),
                        Divider(
                          height: AppSizes.s24,
                          color: theme.colorScheme.outline
                              .withValues(alpha: 0.15),
                        ),
                        _SuccessInfoRow(
                          icon: Icons.calendar_today_rounded,
                          label: 'Fecha',
                          value: formattedDate,
                        ),
                        Divider(
                          height: AppSizes.s24,
                          color: theme.colorScheme.outline
                              .withValues(alpha: 0.15),
                        ),
                        _SuccessInfoRow(
                          icon: Icons.schedule_rounded,
                          label: 'Horario',
                          value: timeRange,
                        ),
                      ],
                    ),
                  )
                      .animate()
                      .fadeIn(delay: 600.ms, duration: 400.ms)
                      .slideY(
                          begin: 0.15,
                          end: 0,
                          delay: 600.ms,
                          duration: 400.ms),

                  const SizedBox(height: AppSizes.s32),

                  // ── Buttons ──
                  AppButton(
                    label: 'Ver mis reservas',
                    icon: Icons.list_alt_rounded,
                    onPressed: () {
                      ref.read(clientNavIndexProvider.notifier).state = 3;
                      context.go('/client');
                    },
                  )
                      .animate()
                      .fadeIn(delay: 800.ms, duration: 300.ms)
                      .slideY(
                          begin: 0.15,
                          end: 0,
                          delay: 800.ms,
                          duration: 300.ms),

                  const SizedBox(height: AppSizes.s12),

                  AppButton(
                    label: 'Volver al inicio',
                    icon: Icons.home_rounded,
                    isOutlined: true,
                    onPressed: () {
                      ref.read(clientNavIndexProvider.notifier).state = 0;
                      context.go('/client');
                    },
                  )
                      .animate()
                      .fadeIn(delay: 900.ms, duration: 300.ms)
                      .slideY(
                          begin: 0.15,
                          end: 0,
                          delay: 900.ms,
                          duration: 300.ms),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Builds small animated celebration dots around the checkmark.
  List<Widget> _buildCelebrationDots(ThemeData theme) {
    final colors = [
      theme.colorScheme.primary,
      Colors.amber,
      Colors.deepPurple,
      Colors.pinkAccent,
      Colors.teal,
      Colors.orange,
    ];

    return [
      SizedBox(
        height: 8,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            colors.length,
            (i) => Container(
              width: 8,
              height: 8,
              margin: const EdgeInsets.symmetric(horizontal: 6),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: colors[i],
              ),
            )
                .animate()
                .fadeIn(
                  delay: Duration(milliseconds: 300 + i * 80),
                  duration: 300.ms,
                )
                .scale(
                  begin: const Offset(0, 0),
                  end: const Offset(1, 1),
                  delay: Duration(milliseconds: 300 + i * 80),
                  duration: 400.ms,
                  curve: Curves.elasticOut,
                )
                .then()
                .fadeOut(delay: 1200.ms, duration: 400.ms),
          ),
        ),
      ),
      const SizedBox(height: AppSizes.s16),
    ];
  }
}

/// Single info row in the success summary card.
class _SuccessInfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _SuccessInfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: theme.colorScheme.primary,
        ),
        const SizedBox(width: AppSizes.s12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
            const SizedBox(height: AppSizes.s2),
            Text(
              value,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
