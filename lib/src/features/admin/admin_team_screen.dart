import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import 'package:reservpy/src/core/constants/app_colors.dart';
import 'package:reservpy/src/data/repositories/admin_repository.dart';

// ── Providers ─────────────────────────────────────────────────────────────────

final teamMembersProvider = FutureProvider<List<AdminTeamMember>>((ref) async {
  return AdminRepository().getTeamMembers();
});

// ── Role config ───────────────────────────────────────────────────────────────

const _roleLabels = <String, String>{
  'super_admin': 'Super Admin',
  'admin':       'Admin',
  'manager':     'Manager',
  'operator':    'Operador',
  'support':     'Soporte',
};

const _roleColors = <String, Color>{
  'super_admin': Color(0xFFEF4444),
  'admin':       Color(0xFFF59E0B),
  'manager':     Color(0xFF8B5CF6),
  'operator':    Color(0xFF0EA5E9),
  'support':     Color(0xFF10B981),
};

const _permKeys = <String, String>{
  'can_view_clients':         'Ver clientes',
  'can_edit_clients':         'Editar clientes',
  'can_delete_clients':       'Eliminar clientes',
  'can_view_metrics':         'Ver métricas',
  'can_view_billing':         'Ver facturación',
  'can_manage_subscriptions': 'Gestionar suscripciones',
  'can_manage_team':          'Gestionar equipo',
  'can_view_audit_logs':      'Ver auditoría',
};

// ── Screen ────────────────────────────────────────────────────────────────────

class AdminTeamScreen extends ConsumerWidget {
  const AdminTeamScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final teamAsync = ref.watch(teamMembersProvider);
    final theme     = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(28, 28, 28, 20),
            child: Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Equipo', style: GoogleFonts.inter(
                      fontSize: 24, fontWeight: FontWeight.w800,
                      color: theme.colorScheme.onSurface,
                    )),
                    Text('Miembros del equipo interno de la plataforma',
                        style: GoogleFonts.inter(fontSize: 13, color: Colors.grey.shade500)),
                  ],
                ),
                const Spacer(),
                FilledButton.icon(
                  onPressed: () => _showAddMemberDialog(context, ref),
                  icon: const Icon(Icons.person_add_rounded, size: 16),
                  label: const Text('Agregar miembro'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    textStyle: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),

          // ── List ──────────────────────────────────────────
          Expanded(
            child: teamAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error:   (e, _) => Center(child: Text('Error: $e')),
              data: (members) {
                if (members.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.group_rounded, size: 56, color: Colors.grey.shade300),
                        const SizedBox(height: 14),
                        Text('Sin miembros del equipo',
                            style: GoogleFonts.inter(fontSize: 15, color: Colors.grey.shade400)),
                        const SizedBox(height: 8),
                        Text('Agregá personas de confianza para administrar la plataforma',
                            style: GoogleFonts.inter(fontSize: 12, color: Colors.grey.shade400)),
                      ],
                    ),
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(28, 0, 28, 28),
                  itemCount: members.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (_, i) => _TeamMemberCard(
                    member: members[i],
                    onEdit:   () => _showEditDialog(context, ref, members[i]),
                    onToggle: () => _toggleActive(ref, members[i]),
                    onDelete: () => _confirmDelete(context, ref, members[i]),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleActive(WidgetRef ref, AdminTeamMember member) async {
    await AdminRepository().updateTeamMember(member.id, isActive: !member.isActive);
    ref.invalidate(teamMembersProvider);
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref, AdminTeamMember member) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar miembro'),
        content: Text('¿Eliminar a ${member.fullName} del equipo?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFFEF4444)),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await AdminRepository().deleteTeamMember(member.id, member.userId);
      await AdminRepository().logAction(
        action: 'team.member_removed', entityType: 'team_member',
        entityId: member.id, entityName: member.fullName,
      );
      ref.invalidate(teamMembersProvider);
    }
  }

  void _showAddMemberDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (_) => _MemberFormDialog(
        onSave: (data) async {
          await AdminRepository().addTeamMember(
            userId:      data['user_id']!,
            email:       data['email']!,
            firstName:   data['first_name']!,
            lastName:    data['last_name']!,
            adminRole:   data['admin_role']!,
            permissions: _defaultPermissionsForRole(data['admin_role']!),
          );
          await AdminRepository().logAction(
            action: 'team.member_added', entityType: 'team_member',
            entityName: '${data['first_name']} ${data['last_name']}',
          );
          ref.invalidate(teamMembersProvider);
        },
      ),
    );
  }

  void _showEditDialog(BuildContext context, WidgetRef ref, AdminTeamMember member) {
    showDialog(
      context: context,
      builder: (_) => _MemberFormDialog(
        member: member,
        onSave: (data) async {
          await AdminRepository().updateTeamMember(
            member.id,
            adminRole:   data['admin_role'],
            permissions: _defaultPermissionsForRole(data['admin_role'] ?? member.adminRole),
          );
          ref.invalidate(teamMembersProvider);
        },
      ),
    );
  }

  Map<String, dynamic> _defaultPermissionsForRole(String role) {
    switch (role) {
      case 'super_admin':
      case 'admin':
        return {for (final k in _permKeys.keys) k: true};
      case 'manager':
        return {
          'can_view_clients': true, 'can_edit_clients': true, 'can_delete_clients': false,
          'can_view_metrics': true, 'can_view_billing': true, 'can_manage_subscriptions': true,
          'can_manage_team': false, 'can_view_audit_logs': false,
        };
      case 'operator':
        return {
          'can_view_clients': true, 'can_edit_clients': true, 'can_delete_clients': false,
          'can_view_metrics': true, 'can_view_billing': false, 'can_manage_subscriptions': false,
          'can_manage_team': false, 'can_view_audit_logs': false,
        };
      default: // support
        return {
          'can_view_clients': true, 'can_edit_clients': false, 'can_delete_clients': false,
          'can_view_metrics': true, 'can_view_billing': false, 'can_manage_subscriptions': false,
          'can_manage_team': false, 'can_view_audit_logs': false,
        };
    }
  }
}

// ── Team Member Card ──────────────────────────────────────────────────────────

class _TeamMemberCard extends StatelessWidget {
  const _TeamMemberCard({
    required this.member,
    required this.onEdit,
    required this.onToggle,
    required this.onDelete,
  });

  final AdminTeamMember member;
  final VoidCallback onEdit;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme    = Theme.of(context);
    final color    = _roleColors[member.adminRole] ?? AppColors.primary;
    final dateFmt  = DateFormat('dd/MM/yyyy');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          // Avatar
          CircleAvatar(
            radius: 22,
            backgroundColor: color.withValues(alpha: 0.15),
            child: Text(member.initials,
                style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: color)),
          ),
          const SizedBox(width: 14),

          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(member.fullName, style: GoogleFonts.inter(
                      fontSize: 14, fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurface,
                    )),
                    const SizedBox(width: 8),
                    if (!member.isActive)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.grey.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text('Inactivo',
                            style: GoogleFonts.inter(fontSize: 10, color: Colors.grey.shade500)),
                      ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(member.email,
                    style: GoogleFonts.inter(fontSize: 12, color: Colors.grey.shade500)),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    _Badge(label: _roleLabels[member.adminRole] ?? member.adminRole, color: color),
                    if (member.lastLogin != null)
                      _Badge(
                        label: 'Último acceso: ${dateFmt.format(member.lastLogin!)}',
                        color: Colors.grey,
                      ),
                  ],
                ),
              ],
            ),
          ),

          // Permissions count
          Column(
            children: [
              Text(
                '${member.permissions.values.where((v) => v == true).length}/${_permKeys.length}',
                style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700,
                    color: AppColors.primary),
              ),
              Text('permisos',
                  style: GoogleFonts.inter(fontSize: 10, color: Colors.grey.shade400)),
            ],
          ),
          const SizedBox(width: 12),

          // Actions
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert_rounded, size: 18,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5)),
            onSelected: (v) {
              if (v == 'edit')   onEdit();
              if (v == 'toggle') onToggle();
              if (v == 'delete') onDelete();
            },
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'edit',
                  child: ListTile(dense: true, leading: Icon(Icons.edit_outlined), title: Text('Editar'))),
              PopupMenuItem(value: 'toggle',
                  child: ListTile(dense: true,
                      leading: Icon(member.isActive ? Icons.pause_outlined : Icons.play_arrow_outlined),
                      title: Text(member.isActive ? 'Desactivar' : 'Activar'))),
              const PopupMenuItem(value: 'delete',
                  child: ListTile(dense: true,
                      leading: Icon(Icons.delete_outline_rounded, color: Color(0xFFEF4444)),
                      title: Text('Eliminar', style: TextStyle(color: Color(0xFFEF4444))))),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Badge ─────────────────────────────────────────────────────────────────────

class _Badge extends StatelessWidget {
  const _Badge({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(label, style: GoogleFonts.inter(
        fontSize: 11, fontWeight: FontWeight.w500, color: color,
      )),
    );
  }
}

// ── Form Dialog ───────────────────────────────────────────────────────────────

class _MemberFormDialog extends StatefulWidget {
  const _MemberFormDialog({this.member, required this.onSave});
  final AdminTeamMember? member;
  final Future<void> Function(Map<String, String>) onSave;

  @override
  State<_MemberFormDialog> createState() => _MemberFormDialogState();
}

class _MemberFormDialogState extends State<_MemberFormDialog> {
  late final _firstNameCtrl = TextEditingController(text: widget.member?.firstName ?? '');
  late final _lastNameCtrl  = TextEditingController(text: widget.member?.lastName  ?? '');
  late final _emailCtrl     = TextEditingController(text: widget.member?.email     ?? '');
  late final _userIdCtrl    = TextEditingController(text: widget.member?.userId    ?? '');
  String _role = 'operator';
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _role = widget.member?.adminRole ?? 'operator';
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.member != null;
    return AlertDialog(
      title: Text(isEdit ? 'Editar miembro' : 'Agregar miembro al equipo'),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!isEdit) ...[
                _Field(ctrl: _userIdCtrl, label: 'User ID (Supabase)', hint: 'uuid del usuario'),
                const SizedBox(height: 12),
                _Field(ctrl: _emailCtrl, label: 'Email'),
                const SizedBox(height: 12),
                _Field(ctrl: _firstNameCtrl, label: 'Nombre'),
                const SizedBox(height: 12),
                _Field(ctrl: _lastNameCtrl, label: 'Apellido'),
                const SizedBox(height: 16),
              ],
              Text('Rol', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _role,
                decoration: InputDecoration(
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
                items: _roleLabels.entries.map((e) =>
                    DropdownMenuItem(value: e.key, child: Text(e.value))).toList(),
                onChanged: (v) => setState(() => _role = v ?? _role),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
          onPressed: _loading ? null : () async {
            setState(() => _loading = true);
            await widget.onSave({
              'user_id':    _userIdCtrl.text.trim(),
              'email':      _emailCtrl.text.trim(),
              'first_name': _firstNameCtrl.text.trim(),
              'last_name':  _lastNameCtrl.text.trim(),
              'admin_role': _role,
            });
            if (mounted) Navigator.pop(context);
          },
          child: _loading
              ? const SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : Text(isEdit ? 'Guardar' : 'Agregar'),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _emailCtrl.dispose();
    _userIdCtrl.dispose();
    super.dispose();
  }
}

class _Field extends StatelessWidget {
  const _Field({required this.ctrl, required this.label, this.hint});
  final TextEditingController ctrl;
  final String label;
  final String? hint;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: ctrl,
      decoration: InputDecoration(
        labelText: label,
        hintText:  hint,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
    );
  }
}
