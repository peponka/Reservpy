import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'package:reservpy/src/data/repositories/admin_repository.dart';
import 'admin_theme.dart';

// ── Provider ──────────────────────────────────────────────────────────────────

final activityLogProvider = FutureProvider<List<ActivityLog>>((ref) async {
  return AdminRepository().getActivityLog(limit: 200);
});

// ── Screen ────────────────────────────────────────────────────────────────────

class AdminAuditScreen extends ConsumerStatefulWidget {
  const AdminAuditScreen({super.key});

  @override
  ConsumerState<AdminAuditScreen> createState() => _AdminAuditScreenState();
}

class _AdminAuditScreenState extends ConsumerState<AdminAuditScreen> {
  String _search     = '';
  String _typeFilter = 'all';

  @override
  Widget build(BuildContext context) {
    final logAsync = ref.watch(activityLogProvider);

    return Scaffold(
      backgroundColor: AC.bg,
      body: Column(
        children: [
          // ── Header ──────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(28, 24, 28, 20),
            child: AdminSectionHeader(
              title:    'Auditoría',
              subtitle: 'Registro de todas las acciones del equipo',
              trailing: OutlinedButton.icon(
                onPressed: () => ref.invalidate(activityLogProvider),
                icon: const Icon(Icons.refresh_rounded, size: 15),
                label: const Text('Actualizar'),
              ),
            ),
          ),

          // ── Filters ──────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(28, 0, 28, 16),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: TextField(
                    onChanged: (v) => setState(() => _search = v.toLowerCase()),
                    style: GoogleFonts.inter(fontSize: 13, color: AC.text),
                    decoration: InputDecoration(
                      hintText:   'Buscar por usuario, acción o entidad…',
                      prefixIcon: const Icon(Icons.search_rounded, size: 15, color: AC.textSec),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color:  AC.surfaceHigh,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AC.border),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value:        _typeFilter,
                      dropdownColor: AC.surface,
                      style:        GoogleFonts.inter(fontSize: 13, color: AC.text),
                      icon:         const Icon(Icons.keyboard_arrow_down_rounded,
                          size: 15, color: AC.textSec),
                      items: const [
                        DropdownMenuItem(value: 'all',      child: Text('Todas')),
                        DropdownMenuItem(value: 'business', child: Text('Negocios')),
                        DropdownMenuItem(value: 'billing',  child: Text('Pagos')),
                        DropdownMenuItem(value: 'team',     child: Text('Equipo')),
                      ],
                      onChanged: (v) { if (v != null) setState(() => _typeFilter = v); },
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Log ─────────────────────────────────────────
          Expanded(
            child: logAsync.when(
              loading: () => const Center(child: CircularProgressIndicator(color: AC.violet)),
              error:   (e, _) => Center(child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.history_rounded, size: 52, color: AC.textMut),
                  const SizedBox(height: 12),
                  Text('Sin registros aún',
                      style: GoogleFonts.inter(fontSize: 15, color: AC.textSec)),
                  const SizedBox(height: 6),
                  Text('Cada acción en el panel quedará registrada aquí',
                      style: GoogleFonts.inter(fontSize: 12, color: AC.textMut)),
                ],
              )),
              data: (logs) {
                final filtered = logs.where((l) {
                  final ms = _search.isEmpty ||
                      (l.userEmail?.toLowerCase().contains(_search) ?? false) ||
                      l.action.toLowerCase().contains(_search) ||
                      (l.entityName?.toLowerCase().contains(_search) ?? false);
                  final mt = _typeFilter == 'all' ||
                      (l.entityType?.startsWith(_typeFilter) ?? false) ||
                      l.action.startsWith(_typeFilter);
                  return ms && mt;
                }).toList();

                if (filtered.isEmpty) {
                  return Center(child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.search_off_rounded, size: 44, color: AC.textMut),
                      const SizedBox(height: 10),
                      Text('Sin resultados', style: GoogleFonts.inter(
                          fontSize: 14, color: AC.textSec)),
                    ],
                  ));
                }

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(28, 0, 28, 28),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 4),
                  itemBuilder: (_, i) => _LogRow(log: filtered[i])
                      .animate(delay: Duration(milliseconds: 15 * i))
                      .fadeIn(duration: 200.ms),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ── Log Row ───────────────────────────────────────────────────────────────────

class _LogRow extends StatefulWidget {
  const _LogRow({required this.log});
  final ActivityLog log;

  @override
  State<_LogRow> createState() => _LogRowState();
}

class _LogRowState extends State<_LogRow> {
  bool _hovered = false;

  Color get _actionColor {
    final a = widget.log.action;
    if (a.contains('delete') || a.contains('suspend') || a.contains('revoke')) return AC.danger;
    if (a.contains('create') || a.contains('add') || a.contains('register') ||
        a.contains('invite')) return AC.success;
    if (a.contains('update') || a.contains('change') || a.contains('edit')) return AC.info;
    if (a.contains('reminder')) return AC.violet;
    return AC.textSec;
  }

  IconData get _actionIcon {
    final a = widget.log.action;
    if (a.contains('delete') || a.contains('revoke'))   return Icons.delete_outline_rounded;
    if (a.contains('suspend'))                           return Icons.pause_circle_outline_rounded;
    if (a.contains('create') || a.contains('invite'))   return Icons.add_circle_outline_rounded;
    if (a.contains('update') || a.contains('change'))   return Icons.edit_outlined;
    if (a.contains('payment') || a.contains('billing')) return Icons.payments_outlined;
    if (a.contains('reminder'))                          return Icons.email_outlined;
    if (a.contains('activate'))                          return Icons.play_circle_outline_rounded;
    return Icons.history_rounded;
  }

  String _formatAction(String action) {
    const m = <String, String>{
      'business.deactivate':    'Negocio desactivado',
      'business.activate':      'Negocio activado',
      'business.plan_change':   'Plan cambiado',
      'billing.payment_registered': 'Pago registrado',
      'billing.reminder_sent':  'Recordatorio enviado',
      'team.member_invited':    'Miembro invitado',
      'team.member_revoked':    'Acceso revocado',
      'INSERT.payments':        'Pago insertado',
      'UPDATE.payments':        'Pago actualizado',
    };
    return m[action] ?? action.replaceAll('.', ' › ').replaceAll('_', ' ');
  }

  @override
  Widget build(BuildContext context) {
    final log     = widget.log;
    final dateFmt = DateFormat('dd/MM/yy HH:mm');
    final color   = _actionColor;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit:  (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 130),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        decoration: BoxDecoration(
          color: _hovered ? AC.surfaceHigh : AC.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: _hovered ? AC.borderBright : AC.border),
        ),
        child: Row(
          children: [
            // Icon
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(_actionIcon, size: 14, color: color),
            ),
            const SizedBox(width: 14),

            // Action
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_formatAction(log.action), style: GoogleFonts.inter(
                      fontSize: 13, fontWeight: FontWeight.w500, color: AC.text)),
                  if (log.entityName != null && log.entityName!.isNotEmpty)
                    Text(log.entityName!, style: GoogleFonts.inter(
                        fontSize: 11, color: AC.textSec)),
                ],
              ),
            ),

            // User
            Expanded(
              flex: 2,
              child: Text(log.userEmail ?? '—', style: GoogleFonts.inter(
                  fontSize: 12, color: AC.textSec), overflow: TextOverflow.ellipsis),
            ),

            // Entity type
            if (log.entityType != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AC.surfaceHigh,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(log.entityType!, style: GoogleFonts.inter(
                    fontSize: 10, color: AC.textMut, fontWeight: FontWeight.w500)),
              ),
            const SizedBox(width: 12),

            // Time
            Text(dateFmt.format(log.createdAt.toLocal()),
                style: GoogleFonts.inter(fontSize: 11, color: AC.textMut)),
          ],
        ),
      ),
    );
  }
}
