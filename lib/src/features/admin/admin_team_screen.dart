import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'package:reservpy/src/data/repositories/admin_repository.dart';
import 'admin_theme.dart';

// ── Provider ──────────────────────────────────────────────────────────────────

final teamMembersProvider = FutureProvider<List<TeamMember>>((ref) async {
  return AdminRepository().getTeamMembers();
});

// ── Role config ───────────────────────────────────────────────────────────────

const _roleLabel = <String, String>{
  'super_admin': 'Super Admin',
  'admin':       'Admin',
  'manager':     'Manager',
  'soporte':     'Soporte',
};

const _roleColor = <String, Color>{
  'super_admin': Color(0xFFFF4757),
  'admin':       Color(0xFF6C63FF),
  'manager':     Color(0xFF00D4AA),
  'soporte':     Color(0xFF0EA5E9),
};

const _roleDesc = <String, String>{
  'super_admin': 'Acceso irrestricto. No puede ser removido.',
  'admin':       'Acceso completo excepto super admin.',
  'manager':     'Clientes, reservas, métricas y pagos.',
  'soporte':     'Solo lectura de clientes y reservas.',
};

// ── Screen ────────────────────────────────────────────────────────────────────

class AdminTeamScreen extends ConsumerWidget {
  const AdminTeamScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final teamAsync = ref.watch(teamMembersProvider);

    return Scaffold(
      backgroundColor: AC.bg,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(28, 24, 28, 20),
            child: AdminSectionHeader(
              title:    'Equipo',
              subtitle: 'Miembros con acceso al panel de administración',
              trailing: FilledButton.icon(
                onPressed: () => _showInviteDialog(context, ref),
                icon: const Icon(Icons.person_add_rounded, size: 15),
                label: const Text('Invitar'),
                style: FilledButton.styleFrom(backgroundColor: AC.violet),
              ),
            ),
          ),

          // ── Member grid / list ───────────────────────────
          Expanded(
            child: teamAsync.when(
              loading: () => const Center(child: CircularProgressIndicator(color: AC.violet)),
              error:   (e, _) => Center(child: Text('Error: $e',
                  style: GoogleFonts.inter(color: AC.textSec))),
              data: (members) {
                final active  = members.where((m) => m.status == 'active').toList();
                final pending = members.where((m) => m.status == 'pending').toList();

                if (members.isEmpty) {
                  return Center(child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.group_outlined, size: 56, color: AC.textMut),
                      const SizedBox(height: 14),
                      Text('Solo vos por ahora', style: GoogleFonts.spaceGrotesk(
                          fontSize: 16, fontWeight: FontWeight.w700, color: AC.text)),
                      const SizedBox(height: 6),
                      Text('Invitá personas de confianza para ayudarte a gestionar',
                          style: GoogleFonts.inter(fontSize: 13, color: AC.textSec)),
                    ],
                  ));
                }

                return SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(28, 0, 28, 28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (active.isNotEmpty) ...[
                        Text('Activos — ${active.length}', style: GoogleFonts.inter(
                            fontSize: 12, fontWeight: FontWeight.w600,
                            color: AC.textSec, letterSpacing: 0.5)),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 16, runSpacing: 16,
                          children: active.asMap().entries.map((e) =>
                            _MemberCard(
                              member:   e.value,
                              onRevoke: () => _confirmRevoke(context, ref, e.value),
                              onChange: () => _showChangeRoleDialog(context, ref, e.value),
                            ).animate(delay: Duration(milliseconds: 60 * e.key))
                                .fadeIn(duration: 300.ms).slideY(begin: 0.1, end: 0),
                          ).toList(),
                        ),
                      ],
                      if (pending.isNotEmpty) ...[
                        const SizedBox(height: 28),
                        Text('Invitaciones pendientes — ${pending.length}',
                            style: GoogleFonts.inter(
                                fontSize: 12, fontWeight: FontWeight.w600,
                                color: AC.textSec, letterSpacing: 0.5)),
                        const SizedBox(height: 12),
                        ...pending.map((m) => _PendingRow(
                          member: m,
                          onRevoke: () => _confirmRevoke(context, ref, m),
                        )),
                      ],
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showInviteDialog(BuildContext ctx, WidgetRef ref) {
    showDialog(
      context: ctx,
      builder: (_) => Theme(
        data: adminTheme(),
        child: _InviteDialog(
          onInvite: (email, role, name) async {
            await AdminRepository().inviteTeamMember(
              email: email, role: role, fullName: name.isEmpty ? null : name);
            ref.invalidate(teamMembersProvider);
          },
        ),
      ),
    );
  }

  void _showChangeRoleDialog(BuildContext ctx, WidgetRef ref, TeamMember m) {
    if (m.role == 'super_admin') return;
    String selected = m.role;
    showDialog(
      context: ctx,
      builder: (_) => Theme(
        data: adminTheme(),
        child: AlertDialog(
          backgroundColor: AC.surface,
          title: Text('Cambiar rol de ${m.displayName}',
              style: GoogleFonts.spaceGrotesk(
                  fontSize: 17, fontWeight: FontWeight.w700, color: AC.text)),
          content: StatefulBuilder(builder: (ctx, setSt) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: _roleLabel.entries
                  .where((e) => e.key != 'super_admin')
                  .map((e) {
                final color = _roleColor[e.key] ?? AC.textSec;
                return GestureDetector(
                  onTap: () => setSt(() => selected = e.key),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    margin:  const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color:  selected == e.key
                          ? color.withValues(alpha: 0.12) : AC.surfaceHigh,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: selected == e.key
                          ? color.withValues(alpha: 0.4) : AC.border),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(e.value, style: GoogleFonts.inter(
                              fontSize: 11, fontWeight: FontWeight.w600, color: color)),
                        ),
                        const SizedBox(width: 12),
                        Expanded(child: Text(_roleDesc[e.key] ?? '',
                            style: GoogleFonts.inter(fontSize: 12, color: AC.textSec))),
                        if (selected == e.key)
                          Icon(Icons.check_circle_rounded, size: 16, color: color),
                      ],
                    ),
                  ),
                );
              }).toList(),
            );
          }),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx),
                child: Text('Cancelar', style: GoogleFonts.inter(color: AC.textSec))),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: AC.violet),
              onPressed: () async {
                await AdminRepository().updateTeamMemberRole(m.id, selected);
                ref.invalidate(teamMembersProvider);
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: Text('Guardar', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmRevoke(BuildContext ctx, WidgetRef ref, TeamMember m) {
    if (m.role == 'super_admin') return;
    showDialog(
      context: ctx,
      builder: (_) => Theme(
        data: adminTheme(),
        child: AlertDialog(
          backgroundColor: AC.surface,
          title: Text('Revocar acceso', style: GoogleFonts.spaceGrotesk(
              fontSize: 17, fontWeight: FontWeight.w700, color: AC.text)),
          content: Text(
            '¿Eliminar a ${m.displayName} del equipo?\n'
            'Perderá acceso inmediatamente al panel de administración.',
            style: GoogleFonts.inter(fontSize: 13, color: AC.textSec),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx),
                child: Text('Cancelar', style: GoogleFonts.inter(color: AC.textSec))),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: AC.danger),
              onPressed: () async {
                await AdminRepository().revokeTeamMember(m.id, m.email);
                ref.invalidate(teamMembersProvider);
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: Text('Revocar acceso',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Member Card ───────────────────────────────────────────────────────────────

class _MemberCard extends StatefulWidget {
  const _MemberCard({
    required this.member,
    required this.onRevoke,
    required this.onChange,
  });
  final TeamMember member;
  final VoidCallback onRevoke;
  final VoidCallback onChange;

  @override
  State<_MemberCard> createState() => _MemberCardState();
}

class _MemberCardState extends State<_MemberCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final m     = widget.member;
    final color = _roleColor[m.role] ?? AC.textSec;
    final label = _roleLabel[m.role] ?? m.role;
    final isSA  = m.role == 'super_admin';
    final fmt   = DateFormat('dd/MM/yy');

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit:  (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 280,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: _hovered ? AC.surfaceHigh : AC.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _hovered ? color.withValues(alpha: 0.3) : AC.border,
          ),
          boxShadow: _hovered ? [
            BoxShadow(color: color.withValues(alpha: 0.08),
                blurRadius: 20, offset: const Offset(0, 8)),
          ] : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Avatar
                Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [color, color.withValues(alpha: 0.5)],
                      begin: Alignment.topLeft, end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(child: Text(m.initials, style: GoogleFonts.spaceGrotesk(
                      fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white))),
                ),
                const Spacer(),
                // Role badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: color.withValues(alpha: 0.25)),
                  ),
                  child: Text(label, style: GoogleFonts.inter(
                      fontSize: 10, fontWeight: FontWeight.w600, color: color)),
                ),
                if (!isSA) ...[
                  const SizedBox(width: 6),
                  PopupMenuButton<String>(
                    icon: Icon(Icons.more_vert_rounded, size: 16, color: AC.textSec),
                    color: AC.surface,
                    onSelected: (v) {
                      if (v == 'change') widget.onChange();
                      if (v == 'revoke') widget.onRevoke();
                    },
                    itemBuilder: (_) => [
                      PopupMenuItem(value: 'change',
                          child: Row(children: [
                            const Icon(Icons.swap_horiz_rounded, size: 15, color: AC.textSec),
                            const SizedBox(width: 10),
                            Text('Cambiar rol', style: GoogleFonts.inter(
                                fontSize: 13, color: AC.text)),
                          ])),
                      PopupMenuItem(value: 'revoke',
                          child: Row(children: [
                            const Icon(Icons.block_rounded, size: 15, color: AC.danger),
                            const SizedBox(width: 10),
                            Text('Revocar acceso', style: GoogleFonts.inter(
                                fontSize: 13, color: AC.danger)),
                          ])),
                    ],
                  ),
                ],
              ],
            ),
            const SizedBox(height: 14),
            Text(m.displayName, style: GoogleFonts.inter(
                fontSize: 14, fontWeight: FontWeight.w600, color: AC.text),
                overflow: TextOverflow.ellipsis),
            const SizedBox(height: 2),
            Text(m.email, style: GoogleFonts.inter(
                fontSize: 12, color: AC.textSec), overflow: TextOverflow.ellipsis),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.access_time_rounded, size: 12, color: AC.textMut),
                const SizedBox(width: 4),
                Text(
                  m.lastLoginAt != null
                      ? 'Último acceso ${fmt.format(m.lastLoginAt!)}'
                      : m.acceptedAt != null
                          ? 'Unido ${fmt.format(m.acceptedAt!)}'
                          : 'Sin accesos aún',
                  style: GoogleFonts.inter(fontSize: 11, color: AC.textMut),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Pending Row ───────────────────────────────────────────────────────────────

class _PendingRow extends StatelessWidget {
  const _PendingRow({required this.member, required this.onRevoke});
  final TeamMember member;
  final VoidCallback onRevoke;

  @override
  Widget build(BuildContext context) {
    final color = _roleColor[member.role] ?? AC.textSec;
    final label = _roleLabel[member.role] ?? member.role;
    final fmt   = DateFormat('dd/MM/yyyy');

    return Container(
      margin:  const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color:  AC.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AC.warning.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: AC.warning.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text('Pendiente', style: GoogleFonts.inter(
                fontSize: 10, fontWeight: FontWeight.w600, color: AC.warning)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(member.email, style: GoogleFonts.inter(
                    fontSize: 13, fontWeight: FontWeight.w500, color: AC.text)),
                if (member.invitedAt != null)
                  Text('Invitado el ${fmt.format(member.invitedAt!)}',
                      style: GoogleFonts.inter(fontSize: 11, color: AC.textSec)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(label, style: GoogleFonts.inter(
                fontSize: 10, fontWeight: FontWeight.w600, color: color)),
          ),
          const SizedBox(width: 12),
          IconButton(
            icon: const Icon(Icons.close_rounded, size: 15, color: AC.danger),
            tooltip: 'Cancelar invitación',
            onPressed: onRevoke,
          ),
        ],
      ),
    );
  }
}

// ── Invite Dialog ─────────────────────────────────────────────────────────────

class _InviteDialog extends StatefulWidget {
  const _InviteDialog({required this.onInvite});
  final Future<void> Function(String email, String role, String name) onInvite;

  @override
  State<_InviteDialog> createState() => _InviteDialogState();
}

class _InviteDialogState extends State<_InviteDialog> {
  final _emailCtrl = TextEditingController();
  final _nameCtrl  = TextEditingController();
  String _role     = 'manager';
  bool   _loading  = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AC.surface,
      title: Text('Invitar al equipo', style: GoogleFonts.spaceGrotesk(
          fontSize: 18, fontWeight: FontWeight.w700, color: AC.text)),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _emailCtrl,
              style: GoogleFonts.inter(fontSize: 13, color: AC.text),
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _nameCtrl,
              style: GoogleFonts.inter(fontSize: 13, color: AC.text),
              decoration: const InputDecoration(labelText: 'Nombre (opcional)'),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _role,
              decoration: const InputDecoration(labelText: 'Rol'),
              dropdownColor: AC.surface,
              style: GoogleFonts.inter(fontSize: 13, color: AC.text),
              items: _roleLabel.entries
                  .where((e) => e.key != 'super_admin')
                  .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
                  .toList(),
              onChanged: (v) { if (v != null) setState(() => _role = v); },
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AC.surfaceHigh,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(_roleDesc[_role] ?? '',
                  style: GoogleFonts.inter(fontSize: 12, color: AC.textSec)),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancelar', style: GoogleFonts.inter(color: AC.textSec)),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: AC.violet),
          onPressed: _loading ? null : () async {
            if (_emailCtrl.text.trim().isEmpty) return;
            setState(() => _loading = true);
            await widget.onInvite(
                _emailCtrl.text.trim(), _role, _nameCtrl.text.trim());
            if (mounted) Navigator.pop(context);
          },
          child: _loading
              ? const SizedBox.square(dimension: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : Text('Invitar', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _nameCtrl.dispose();
    super.dispose();
  }
}
