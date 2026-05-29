import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:reservpy/src/core/constants/app_colors.dart';
import 'package:reservpy/src/core/constants/app_sizes.dart';
import 'package:reservpy/src/core/widgets/widgets.dart';
import 'package:reservpy/src/shared/models/models.dart';
import 'package:reservpy/src/shared/providers/providers.dart';
import 'package:reservpy/src/shared/models/employee.dart';
import 'package:reservpy/src/data/repositories/employee_repository.dart';



/// Suggested roles for quick selection.
const List<String> _suggestedRoles = [
  'Estilista',
  'Barbero/a',
  'Manicurista',
  'Recepcionista',
  'Masajista',
  'Maquillador/a',
  'Cosmetóloga',
  'Otro',
];

// ═══════════════════════════════════════════════════════════════════
// EMPLOYEES SCREEN
// ═══════════════════════════════════════════════════════════════════

/// Full employee management screen for a business.
///
/// Shows KPI stats, employee list with avatars / schedules / services,
/// and allows CRUD operations through bottom sheets and dialogs.
class EmployeesScreen extends ConsumerWidget {
  const EmployeesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final business = ref.watch(currentBusinessProvider);
    final employeesAsync = ref.watch(employeesProvider);
    final services = ref.watch(businessServicesProvider(business?.id ?? '')).value ?? [];

    return employeesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded, size: 48, color: AppColors.error),
            const SizedBox(height: AppSizes.s12),
            Text('Error al cargar empleados', style: theme.textTheme.titleMedium),
            const SizedBox(height: AppSizes.s4),
            Text('$error', style: theme.textTheme.bodySmall),
            const SizedBox(height: AppSizes.s16),
            ElevatedButton.icon(
              onPressed: () => ref.invalidate(employeesProvider),
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      ),
      data: (employees) => _buildContent(context, ref, theme, business, employees, services),
    );
  }

  Widget _buildContent(
    BuildContext context,
    WidgetRef ref,
    ThemeData theme,
    Business? business,
    List<Employee> employees,
    List<ServiceModel> services,
  ) {

    // ── Derived stats ──
    final activeCount = employees.where((e) => e.isActive).length;

    return LayoutBuilder(
      builder: (context, constraints) {
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
                // ─── Header ─────────────────────────────────
                Container(
                  padding: const EdgeInsets.all(AppSizes.s20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [AppColors.primary, AppColors.accent],
                    ),
                    borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Empleados',
                                  style: theme.textTheme.headlineMedium?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: AppSizes.s4),
                                Text(
                                  business?.name ?? 'Studio Bella',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: Colors.white.withValues(alpha: 0.8),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSizes.s12),
                      Align(
                        alignment: Alignment.centerRight,
                        child: ElevatedButton.icon(
                          onPressed: () => _showEmployeeForm(
                            context: context,
                            ref: ref,
                            services: services,
                            businessId: business?.id ?? '',
                          ),
                          icon: const Icon(Icons.person_add_rounded, size: 18),
                          label: const Text('Agregar'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: AppColors.primary,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: AppSizes.s20),

                // ─── KPI Cards ──────────────────────────
                _KpiRow(
                  total: employees.length,
                  active: activeCount,
                ),

                const SizedBox(height: AppSizes.s24),

                // ─── Section Header ─────────────────────
                SectionHeader(
                  title: 'Equipo',
                  actionLabel: '$activeCount activos',
                ),

                const SizedBox(height: AppSizes.s8),

                // ─── Employee List or Empty State ───────
                if (employees.isEmpty)
                  EmptyState(
                    icon: Icons.people_outline_rounded,
                    title: 'Sin empleados aún',
                    subtitle:
                        'Agregá tu primer empleado para comenzar a gestionar tu equipo.',
                    action: AppButton(
                      label: 'Agregar empleado',
                      icon: Icons.person_add_rounded,
                      width: 220,
                      onPressed: () => _showEmployeeForm(
                        context: context,
                        ref: ref,
                        services: services,
                        businessId: business?.id ?? '',
                      ),
                    ),
                  )
                else
                  ...List.generate(employees.length, (index) {
                    final emp = employees[index];
                    return _EmployeeCard(
                      employee: emp,
                      onToggleActive: () => _toggleActive(context, ref, emp),
                      onEdit: () => _showEmployeeForm(
                        context: context,
                        ref: ref,
                        services: services,
                        businessId: business?.id ?? '',
                        employee: emp,
                      ),
                      onDelete: () => _confirmDelete(
                        context: context,
                        ref: ref,
                        employee: emp,
                      ),
                    );
                  }),

                const SizedBox(height: AppSizes.s80),
              ],
            ),
          ),
        );
      },
    );
  }

  // ─── Actions ───────────────────────────────────────────────

  Future<void> _toggleActive(BuildContext context, WidgetRef ref, Employee employee) async {
    try {
      await EmployeeRepository().toggleActive(employee.id, !employee.isActive);
      ref.invalidate(employeesProvider);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cambiar estado: $e')),
        );
      }
    }
  }

  void _confirmDelete({
    required BuildContext context,
    required WidgetRef ref,
    required Employee employee,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppSizes.s8),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppSizes.radiusSm),
              ),
              child: const Icon(
                Icons.warning_amber_rounded,
                color: AppColors.error,
                size: 24,
              ),
            ),
            const SizedBox(width: AppSizes.s12),
            const Text('Eliminar empleado'),
          ],
        ),
        content: RichText(
          text: TextSpan(
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurface.withValues(alpha: 0.75),
              height: 1.5,
            ),
            children: [
              const TextSpan(text: '¿Estás seguro de que querés eliminar a '),
              TextSpan(
                text: employee.name,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              const TextSpan(
                text: '? Esta acción no se puede deshacer.',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              try {
                await EmployeeRepository().delete(employee.id);
                ref.invalidate(employeesProvider);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Row(
                        children: [
                          const Icon(Icons.delete_rounded,
                              color: Colors.white, size: 18),
                          const SizedBox(width: AppSizes.s8),
                          Expanded(
                            child:
                                Text('${employee.name} fue eliminado del equipo'),
                          ),
                        ],
                      ),
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error al eliminar: $e')),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  void _showEmployeeForm({
    required BuildContext context,
    required WidgetRef ref,
    required List<ServiceModel> services,
    required String businessId,
    Employee? employee,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _EmployeeFormSheet(
        employee: employee,
        services: services,
        businessId: businessId,
        onSave: (saved) async {
          try {
            if (employee != null) {
              await EmployeeRepository().update(saved);
            } else {
              await EmployeeRepository().create(saved);
            }
            ref.invalidate(employeesProvider);
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      const Icon(Icons.check_circle_rounded,
                          color: Colors.white, size: 18),
                      const SizedBox(width: AppSizes.s8),
                      Expanded(
                        child: Text(employee != null
                            ? '${saved.name} actualizado correctamente'
                            : '${saved.name} agregado al equipo'),
                      ),
                    ],
                  ),
                ),
              );
            }
          } catch (e) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Error al guardar: $e')),
              );
            }
          }
        },
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// KPI ROW
// ═══════════════════════════════════════════════════════════════════

class _KpiRow extends StatelessWidget {
  final int total;
  final int active;

  const _KpiRow({
    required this.total,
    required this.active,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: KpiCard(
            title: 'Total empleados',
            value: '$total',
            icon: Icons.people_rounded,
            color: AppColors.info,
            delay: 0,
          ),
        ),
        const SizedBox(width: AppSizes.s12),
        Expanded(
          child: KpiCard(
            title: 'Activos',
            value: '$active',
            icon: Icons.event_available_rounded,
            color: AppColors.success,
            delay: 80,
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// EMPLOYEE CARD
// ═══════════════════════════════════════════════════════════════════

class _EmployeeCard extends StatelessWidget {
  final Employee employee;
  final VoidCallback onToggleActive;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _EmployeeCard({
    required this.employee,
    required this.onToggleActive,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AppCard(
      padding: const EdgeInsets.all(AppSizes.s16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Top row: avatar + name + status badge ──
          Row(
            children: [
              // Avatar
              UserAvatar(
                imageUrl: employee.avatarUrl,
                initials: employee.initials,
                size: 48,
              ),
              const SizedBox(width: AppSizes.s12),

              // Name + role
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      employee.name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (employee.role != null) ...[
                      const SizedBox(height: AppSizes.s2),
                      Text(
                        employee.role!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // Active badge
              StatusBadge(
                label: employee.isActive ? 'Activo' : 'Inactivo',
                color: employee.isActive ? AppColors.success : AppColors.error,
              ),
            ],
          ),

          const SizedBox(height: AppSizes.s12),

          // ── Contact info ──
          if (employee.phone != null || employee.email != null)
            Wrap(
              spacing: AppSizes.s12,
              runSpacing: AppSizes.s4,
              children: [
                if (employee.phone != null)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.phone_rounded, size: 14, color: colorScheme.onSurface.withValues(alpha: 0.5)),
                      const SizedBox(width: AppSizes.s4),
                      Text(employee.phone!, style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurface.withValues(alpha: 0.6))),
                    ],
                  ),
                if (employee.email != null)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.email_rounded, size: 14, color: colorScheme.onSurface.withValues(alpha: 0.5)),
                      const SizedBox(width: AppSizes.s4),
                      Text(employee.email!, style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurface.withValues(alpha: 0.6))),
                    ],
                  ),
              ],
            ),

          const SizedBox(height: AppSizes.s12),
          Divider(color: colorScheme.outline.withValues(alpha: 0.15)),
          const SizedBox(height: AppSizes.s8),

          // ── Action row ──
          Row(
            children: [
              // Active toggle
              _ActionChip(
                icon: employee.isActive
                    ? Icons.toggle_on_rounded
                    : Icons.toggle_off_rounded,
                label: employee.isActive ? 'Desactivar' : 'Activar',
                color: employee.isActive ? AppColors.warning : AppColors.success,
                onTap: onToggleActive,
              ),
              const Spacer(),
              // Edit
              IconButton(
                onPressed: onEdit,
                icon: const Icon(Icons.edit_rounded),
                iconSize: 20,
                tooltip: 'Editar',
                style: IconButton.styleFrom(
                  foregroundColor: colorScheme.primary,
                  backgroundColor: colorScheme.primary.withValues(alpha: 0.08),
                ),
              ),
              const SizedBox(width: AppSizes.s8),
              // Delete
              IconButton(
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline_rounded),
                iconSize: 20,
                tooltip: 'Eliminar',
                style: IconButton.styleFrom(
                  foregroundColor: AppColors.error,
                  backgroundColor: AppColors.error.withValues(alpha: 0.08),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// ACTION CHIP (inline mini-button)
// ═══════════════════════════════════════════════════════════════════

class _ActionChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionChip({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSizes.radiusFull),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.s12,
          vertical: AppSizes.s6,
        ),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AppSizes.radiusFull),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: AppSizes.s4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// EMPLOYEE FORM BOTTOM SHEET
// ═══════════════════════════════════════════════════════════════════

class _EmployeeFormSheet extends StatefulWidget {
  final Employee? employee;
  final List<ServiceModel> services;
  final String businessId;
  final ValueChanged<Employee> onSave;

  const _EmployeeFormSheet({
    this.employee,
    required this.services,
    required this.businessId,
    required this.onSave,
  });

  @override
  State<_EmployeeFormSheet> createState() => _EmployeeFormSheetState();
}

class _EmployeeFormSheetState extends State<_EmployeeFormSheet> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameCtrl;
  late final TextEditingController _roleCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _emailCtrl;

  late bool _isActive;

  bool get _isEditing => widget.employee != null;

  @override
  void initState() {
    super.initState();
    final emp = widget.employee;
    _nameCtrl = TextEditingController(text: emp?.name ?? '');
    _roleCtrl = TextEditingController(text: emp?.role ?? '');
    _phoneCtrl = TextEditingController(text: emp?.phone ?? '');
    _emailCtrl = TextEditingController(text: emp?.email ?? '');
    _isActive = emp?.isActive ?? true;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _roleCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  void _handleSave() {
    if (!_formKey.currentState!.validate()) return;

    final employee = Employee(
      id: widget.employee?.id ?? '',
      businessId: widget.employee?.businessId ?? widget.businessId,
      name: _nameCtrl.text.trim(),
      role: _roleCtrl.text.trim().isNotEmpty ? _roleCtrl.text.trim() : null,
      phone: _phoneCtrl.text.trim().isNotEmpty ? _phoneCtrl.text.trim() : null,
      email: _emailCtrl.text.trim().isNotEmpty ? _emailCtrl.text.trim() : null,
      isActive: _isActive,
      createdAt: widget.employee?.createdAt ?? DateTime.now(),
    );

    widget.onSave(employee);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppSizes.radiusXl),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Drag handle ──
          const SizedBox(height: AppSizes.s12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: colorScheme.outline.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(AppSizes.radiusFull),
            ),
          ),
          const SizedBox(height: AppSizes.s16),

          // ── Header ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSizes.s20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSizes.s8),
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                  ),
                  child: Icon(
                    _isEditing
                        ? Icons.edit_rounded
                        : Icons.person_add_rounded,
                    color: colorScheme.primary,
                    size: 22,
                  ),
                ),
                const SizedBox(width: AppSizes.s12),
                Text(
                  _isEditing ? 'Editar empleado' : 'Nuevo empleado',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSizes.s8),
          Divider(color: colorScheme.outline.withValues(alpha: 0.15)),

          // ── Scrollable form ──
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                AppSizes.s20, AppSizes.s16, AppSizes.s20, AppSizes.s24,
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Basic fields ──
                    AppTextField(
                      controller: _nameCtrl,
                      label: 'Nombre completo',
                      prefixIcon: Icons.person_rounded,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'El nombre es obligatorio';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: AppSizes.s16),

                    // Role with quick-select chips
                    AppTextField(
                      controller: _roleCtrl,
                      label: 'Rol / Especialidad',
                      prefixIcon: Icons.badge_rounded,
                      hint: 'Ej: Estilista, Barbero…',
                    ),

                    const SizedBox(height: AppSizes.s8),

                    // Quick role chips
                    Wrap(
                      spacing: AppSizes.s6,
                      runSpacing: AppSizes.s6,
                      children: _suggestedRoles.map((r) {
                        final isSelected = _roleCtrl.text == r;
                        return GestureDetector(
                          onTap: () {
                            setState(() => _roleCtrl.text = r);
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSizes.s12,
                              vertical: AppSizes.s6,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? colorScheme.primary.withValues(alpha: 0.12)
                                  : colorScheme.outline.withValues(alpha: 0.08),
                              borderRadius:
                                  BorderRadius.circular(AppSizes.radiusFull),
                              border: Border.all(
                                color: isSelected
                                    ? colorScheme.primary
                                    : colorScheme.outline.withValues(alpha: 0.2),
                                width: isSelected ? 1.5 : 1,
                              ),
                            ),
                            child: Text(
                              r,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: isSelected
                                    ? FontWeight.w600
                                    : FontWeight.w400,
                                color: isSelected
                                    ? colorScheme.primary
                                    : colorScheme.onSurface.withValues(alpha: 0.7),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: AppSizes.s16),

                    AppTextField(
                      controller: _phoneCtrl,
                      label: 'Teléfono',
                      prefixIcon: Icons.phone_outlined,
                      hint: '+595 9xx xxxxxx',
                      keyboardType: TextInputType.phone,
                    ),

                    const SizedBox(height: AppSizes.s16),

                    AppTextField(
                      controller: _emailCtrl,
                      label: 'Correo electrónico',
                      prefixIcon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                    ),

                    const SizedBox(height: AppSizes.s24),

                    // ── Active toggle ──
                    AppCard(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSizes.s16,
                        vertical: AppSizes.s4,
                      ),
                      child: SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          'Empleado activo',
                          style: theme.textTheme.titleSmall,
                        ),
                        subtitle: Text(
                          _isActive
                              ? 'Visible y disponible para reservas'
                              : 'No aparecerá en las opciones de reserva',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color:
                                colorScheme.onSurface.withValues(alpha: 0.5),
                          ),
                        ),
                        value: _isActive,
                        activeThumbColor: colorScheme.primary,
                        onChanged: (v) => setState(() => _isActive = v),
                      ),
                    ),

                    const SizedBox(height: AppSizes.s24),

                    // ── Save button ──
                    AppButton(
                      label: _isEditing ? 'Guardar cambios' : 'Agregar empleado',
                      icon: _isEditing
                          ? Icons.save_rounded
                          : Icons.person_add_rounded,
                      onPressed: _handleSave,
                    ),

                    const SizedBox(height: AppSizes.s16),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
