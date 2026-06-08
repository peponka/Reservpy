import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import 'package:reservpy/src/core/constants/app_colors.dart';
import 'package:reservpy/src/data/repositories/admin_repository.dart';

// ── Provider ──────────────────────────────────────────────────────────────────

final auditLogsProvider = FutureProvider<List<AuditLog>>((ref) async {
  return AdminRepository().getAuditLogs(limit: 200);
});

// ── Screen ────────────────────────────────────────────────────────────────────

class AdminAuditScreen extends ConsumerStatefulWidget {
  const AdminAuditScreen({super.key});

  @override
  ConsumerState<AdminAuditScreen> createState() => _AdminAuditScreenState();
}

class _AdminAuditScreenState extends ConsumerState<AdminAuditScreen> {
  String _search = '';
  String _filterType = 'all'; // all | business | user | billing | team

  @override
  Widget build(BuildContext context) {
    final logsAsync = ref.watch(auditLogsProvider);
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
                    Text('Auditoría', style: GoogleFonts.inter(
                      fontSize: 24, fontWeight: FontWeight.w800,
                      color: theme.colorScheme.onSurface,
                    )),
                    Text('Historial de acciones en el sistema',
                        style: GoogleFonts.inter(fontSize: 13, color: Colors.grey.shade500)),
                  ],
                ),
                const Spacer(),
                OutlinedButton.icon(
                  onPressed: () => ref.invalidate(auditLogsProvider),
                  icon: const Icon(Icons.refresh_rounded, size: 16),
                  label: const Text('Actualizar'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: BorderSide(color: AppColors.primary.withValues(alpha: 0.4)),
                    textStyle: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),

          // ── Search + filter ───────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(28, 0, 28, 12),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: TextField(
                    onChanged: (v) => setState(() => _search = v.toLowerCase()),
                    decoration: InputDecoration(
                      hintText:     'Buscar por usuario, acción o entidad…',
                      prefixIcon:   const Icon(Icons.search_rounded, size: 18),
                      border:       OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    ),
                    style: GoogleFonts.inter(fontSize: 13),
                  ),
                ),
                const SizedBox(width: 12),
                // Entity type filter
                DropdownButton<String>(
                  value: _filterType,
                  underline: const SizedBox.shrink(),
                  borderRadius: BorderRadius.circular(10),
                  style: GoogleFonts.inter(fontSize: 13, color: Theme.of(context).colorScheme.onSurface),
                  items: const [
                    DropdownMenuItem(value: 'all',      child: Text('Todas las acciones')),
                    DropdownMenuItem(value: 'business', child: Text('Negocios')),
                    DropdownMenuItem(value: 'user',     child: Text('Usuarios')),
                    DropdownMenuItem(value: 'billing',  child: Text('Facturación')),
                    DropdownMenuItem(value: 'team',     child: Text('Equipo')),
                  ],
                  onChanged: (v) => setState(() => _filterType = v ?? 'all'),
                ),
              ],
            ),
          ),

          // ── Log list ──────────────────────────────────────
          Expanded(
            child: logsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error:   (e, _) => _EmptyState(
                icon:    Icons.history_outlined,
                title:   'Sin registros aún',
                subtitle: 'Los cambios que hagas en el panel aparecerán aquí',
              ),
              data: (logs) {
                final filtered = logs.where((log) {
                  final matchSearch = _search.isEmpty ||
                      (log.userEmail?.toLowerCase().contains(_search) ?? false) ||
                      log.action.toLowerCase().contains(_search) ||
                      (log.entityName?.toLowerCase().contains(_search) ?? false) ||
                      (log.entityType?.toLowerCase().contains(_search) ?? false);
                  final matchType = _filterType == 'all' ||
                      (log.entityType?.startsWith(_filterType) ?? false) ||
                      log.action.startsWith(_filterType);
                  return matchSearch && matchType;
                }).toList();

                if (filtered.isEmpty) {
                  return _EmptyState(
                    icon:     Icons.search_off_rounded,
                    title:    'Sin resultados',
                    subtitle: 'Probá con otros términos de búsqueda',
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(28, 0, 28, 28),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 4),
                  itemBuilder: (_, i) => _AuditLogRow(log: filtered[i]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ── Audit Log Row ─────────────────────────────────────────────────────────────

class _AuditLogRow extends StatelessWidget {
  const _AuditLogRow({required this.log});
  final AuditLog log;

  Color get _actionColor {
    if (log.action.contains('delete') || log.action.contains('suspend') || log.action.contains('removed')) {
      return const Color(0xFFEF4444);
    }
    if (log.action.contains('create') || log.action.contains('add') || log.action.contains('registered')) {
      return const Color(0xFF10B981);
    }
    if (log.action.contains('update') || log.action.contains('edit') || log.action.contains('change')) {
      return const Color(0xFF0EA5E9);
    }
    return const Color(0xFF8B5CF6);
  }

  IconData get _actionIcon {
    if (log.action.contains('delete') || log.action.contains('removed'))   return Icons.delete_outline_rounded;
    if (log.action.contains('suspend'))                                      return Icons.pause_circle_outline_rounded;
    if (log.action.contains('create') || log.action.contains('add'))        return Icons.add_circle_outline_rounded;
    if (log.action.contains('update') || log.action.contains('edit'))       return Icons.edit_outlined;
    if (log.action.contains('payment'))                                      return Icons.payments_outlined;
    if (log.action.contains('login'))                                        return Icons.login_rounded;
    return Icons.history_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final theme   = Theme.of(context);
    final dateFmt = DateFormat('dd/MM/yyyy HH:mm');
    final color   = _actionColor;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          // Icon
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(_actionIcon, size: 14, color: color),
          ),
          const SizedBox(width: 12),

          // Action + entity
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _formatAction(log.action),
                  style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurface),
                ),
                if (log.entityName != null) ...[
                  const SizedBox(height: 2),
                  Text(log.entityName!,
                      style: GoogleFonts.inter(fontSize: 11, color: Colors.grey.shade500)),
                ],
              ],
            ),
          ),

          // User
          Expanded(
            flex: 2,
            child: Text(
              log.userEmail ?? '—',
              style: GoogleFonts.inter(fontSize: 12, color: Colors.grey.shade500),
              overflow: TextOverflow.ellipsis,
            ),
          ),

          // Entity type badge
          if (log.entityType != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(log.entityType!,
                  style: GoogleFonts.inter(fontSize: 10, color: Colors.grey.shade500,
                      fontWeight: FontWeight.w500)),
            ),
          const SizedBox(width: 12),

          // Date
          Text(
            dateFmt.format(log.createdAt.toLocal()),
            style: GoogleFonts.inter(fontSize: 11, color: Colors.grey.shade400),
          ),
        ],
      ),
    );
  }

  String _formatAction(String action) {
    // "business.deactivate" → "Negocio desactivado"
    final parts    = action.split('.');
    final entity   = parts.isNotEmpty ? parts[0] : '';
    final operation = parts.length > 1 ? parts[1] : action;

    final entityLabels = <String, String>{
      'business': 'Negocio',
      'user':     'Usuario',
      'billing':  'Facturación',
      'team':     'Equipo',
    };

    final opLabels = <String, String>{
      'deactivate':         'desactivado',
      'activate':           'activado',
      'create':             'creado',
      'delete':             'eliminado',
      'update':             'actualizado',
      'suspend':            'suspendido',
      'reactivate':         'reactivado',
      'payment_registered': 'pago registrado',
      'plan_change':        'plan cambiado',
      'member_added':       'miembro agregado',
      'member_removed':     'miembro eliminado',
    };

    final eLabel = entityLabels[entity];
    final oLabel = opLabels[operation] ?? operation;

    if (eLabel != null) return '$eLabel $oLabel';
    return action;
  }
}

// ── Empty State ───────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.icon, required this.title, required this.subtitle});
  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 52, color: Colors.grey.shade300),
          const SizedBox(height: 14),
          Text(title,
              style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600,
                  color: Colors.grey.shade400)),
          const SizedBox(height: 6),
          Text(subtitle,
              style: GoogleFonts.inter(fontSize: 12, color: Colors.grey.shade400),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }
}
