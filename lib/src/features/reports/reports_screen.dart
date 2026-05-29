import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:reservpy/src/core/constants/app_sizes.dart';
import 'package:reservpy/src/shared/providers/providers.dart';

/// Reports screen – free-plan empty state prompting upgrade to Pro.
class ReportsScreen extends ConsumerWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

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
                // Vertically center the empty state
                SizedBox(
                  height: constraints.maxHeight - 48,
                  child: Center(
                    child: _buildEmptyState(theme, colorScheme, ref),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(
    ThemeData theme,
    ColorScheme colorScheme,
    WidgetRef ref,
  ) {
    const crownColor = Color(0xFFF59E0B);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Crown icon in amber circle
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: crownColor.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.workspace_premium_rounded,
            size: 36,
            color: crownColor,
          ),
        ),
        const SizedBox(height: AppSizes.s24),

        // Title
        Text(
          'Reportes disponibles en el plan Pro',
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: colorScheme.onSurface,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSizes.s12),

        // Subtitle
        Text(
          'Accedé a reportes de ingresos, turnos, clientes y horarios\npico actualizando tu plan.',
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: colorScheme.onSurface.withValues(alpha: 0.55),
            height: 1.5,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSizes.s32),

        // "Ver plan Pro" button
        SizedBox(
          width: 200,
          height: 48,
          child: ElevatedButton.icon(
            onPressed: () {
              ref.read(businessNavIndexProvider.notifier).state = 7;
            },
            icon: const Icon(
              Icons.workspace_premium_rounded,
              size: 20,
              color: Colors.white,
            ),
            label: Text(
              'Ver plan Pro',
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: colorScheme.primary,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSizes.radiusLg),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
