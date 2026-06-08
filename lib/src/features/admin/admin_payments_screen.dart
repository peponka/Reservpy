import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'package:reservpy/src/data/repositories/admin_repository.dart';
import 'admin_theme.dart';

// ── Provider ──────────────────────────────────────────────────────────────────

final overduePaymentsProvider = FutureProvider<List<OverduePayment>>((ref) async {
  return AdminRepository().getOverduePayments();
});

// ── Screen ────────────────────────────────────────────────────────────────────

class AdminPaymentsScreen extends ConsumerStatefulWidget {
  const AdminPaymentsScreen({super.key});

  @override
  ConsumerState<AdminPaymentsScreen> createState() => _AdminPaymentsScreenState();
}

class _AdminPaymentsScreenState extends ConsumerState<AdminPaymentsScreen> {
  String _filter   = 'all'; // all | leve | moderado | critico
  Set<String> _selected = {};

  @override
  Widget build(BuildContext context) {
    final overdueAsync = ref.watch(overduePaymentsProvider);

    return Scaffold(
      backgroundColor: AC.bg,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(28, 24, 28, 0),
            child: AdminSectionHeader(
              title:    'Centro de Pagos',
              subtitle: 'Clientes con pagos vencidos o próximos a vencer',
              trailing: OutlinedButton.icon(
                onPressed: () => ref.invalidate(overduePaymentsProvider),
                icon: const Icon(Icons.refresh_rounded, size: 15),
                label: const Text('Actualizar'),
              ),
            ),
          ),

          // ── Summary stats ────────────────────────────────
          overdueAsync.when(
            loading: () => const SizedBox.shrink(),
            error:   (_, __) => const SizedBox.shrink(),
            data:    (items) => _SummaryStrip(items: items),
          ),

          // ── Severity filter ──────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(28, 12, 28, 8),
            child: Row(
              children: [
                _SevChip(label: 'Todos',    value: 'all',      current: _filter,
                    onTap: (v) => setState(() => _filter = v)),
                const SizedBox(width: 8),
                _SevChip(label: 'Leve (1-7d)',    value: 'leve',     current: _filter,
                    color: const Color(0xFFFFE066), onTap: (v) => setState(() => _filter = v)),
                const SizedBox(width: 8),
                _SevChip(label: 'Moderado (8-30d)', value: 'moderado', current: _filter,
                    color: AC.warning, onTap: (v) => setState(() => _filter = v)),
                const SizedBox(width: 8),
                _SevChip(label: 'Crítico (+30d)',  value: 'critico',  current: _filter,
                    color: AC.danger, onTap: (v) => setState(() => _filter = v)),
                const Spacer(),
                // Bulk action (if items selected)
                if (_selected.isNotEmpty)
                  FilledButton.icon(
                    onPressed: () => _bulkReminder(),
                    icon: const Icon(Icons.email_outlined, size: 14),
                    label: Text('Enviar recordatorio (${_selected.length})',
                        style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600)),
                    style: FilledButton.styleFrom(
                      backgroundColor: AC.violet,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    ),
                  ),
              ],
            ),
          ),

          // ── Table ────────────────────────────────────────
          Expanded(
            child: overdueAsync.when(
              loading: () => const Center(child: CircularProgressIndicator(color: AC.violet)),
              error:   (e, _) => Center(child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.receipt_long_outlined, size: 48, color: AC.textMut),
                  const SizedBox(height: 12),
                  Text('Sin pagos vencidos registrados aún\n'
                      '(Las tablas de pagos deben existir en Supabase)',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(color: AC.textSec, fontSize: 13)),
                ],
              )),
              data: (items) {
                final filtered = _filter == 'all'
                    ? items
                    : items.where((i) => i.severity == _filter).toList();

                if (filtered.isEmpty) {
                  return Center(child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle_outline_rounded, size: 52, color: AC.success),
                      const SizedBox(height: 12),
                      Text(_filter == 'all'
                          ? '¡Sin pagos vencidos! 🎉'
                          : 'Sin pagos en esta categoría',
                          style: GoogleFonts.spaceGrotesk(fontSize: 16,
                              fontWeight: FontWeight.w700, color: AC.text)),
                      const SizedBox(height: 6),
                      Text('Todos los clientes están al día con sus pagos',
                          style: GoogleFonts.inter(fontSize: 13, color: AC.textSec)),
                    ],
                  ));
                }

                return Column(
                  children: [
                    // Select all + header
                    _TableHdr(
                      selectedAll: _selected.length == filtered.length,
                      onSelectAll: (v) => setState(() => v
                          ? _selected = filtered.map((i) => i.paymentId).toSet()
                          : _selected.clear()),
                    ),
                    const Divider(height: 1, color: AC.border),
                    Expanded(
                      child: ListView.separated(
                        itemCount: filtered.length,
                        padding:   EdgeInsets.zero,
                        separatorBuilder: (_, __) => const Divider(height: 1, color: AC.border),
                        itemBuilder: (_, i) {
                          final item = filtered[i];
                          return _OverdueRow(
                            item:     item,
                            selected: _selected.contains(item.paymentId),
                            onSelect: (v) => setState(() => v
                                ? _selected.add(item.paymentId)
                                : _selected.remove(item.paymentId)),
                            onAction: (action) => _handleAction(action, item),
                          ).animate(delay: Duration(milliseconds: 20 * i))
                              .fadeIn(duration: 200.ms);
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _bulkReminder() async {
    final repo = AdminRepository();
    for (final paymentId in _selected) {
      // Find the businessId for this paymentId
      final items = (ref.read(overduePaymentsProvider).value ?? []);
      final item = items.where((i) => i.paymentId == paymentId).firstOrNull;
      if (item != null) {
        await repo.sendReminder(item.businessId, paymentId);
      }
    }
    setState(() => _selected.clear());
    ref.invalidate(overduePaymentsProvider);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        backgroundColor: AC.success,
        content: Text('Recordatorios enviados', style: GoogleFonts.inter(color: Colors.white)),
      ));
    }
  }

  Future<void> _handleAction(String action, OverduePayment item) async {
    final repo = AdminRepository();
    switch (action) {
      case 'reminder':
        await repo.sendReminder(item.businessId, item.paymentId);
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          backgroundColor: AC.violet,
          content: Text('Recordatorio enviado a ${item.businessName}',
              style: GoogleFonts.inter(color: Colors.white)),
        ));
        break;
      case 'mark_paid':
        await repo.updatePaymentStatus(item.paymentId, 'paid');
        ref.invalidate(overduePaymentsProvider);
        break;
      case 'suspend':
        await repo.setBusinessActive(item.businessId, false);
        ref.invalidate(overduePaymentsProvider);
        break;
    }
  }
}

// ── Summary Strip ─────────────────────────────────────────────────────────────

class _SummaryStrip extends StatelessWidget {
  const _SummaryStrip({required this.items});
  final List<OverduePayment> items;

  @override
  Widget build(BuildContext context) {
    final fmt    = NumberFormat('#,###', 'es_PY');
    final total  = items.fold(0.0, (s, i) => s + i.amount);
    final critico = items.where((i) => i.severity == 'critico').length;
    final avgDays = items.isEmpty ? 0
        : (items.fold(0, (s, i) => s + i.daysOverdue) / items.length).round();

    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 20, 28, 0),
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          _StatChip(label: 'Total adeudado',   value: '₲ ${fmt.format(total)}',   color: AC.danger),
          _StatChip(label: 'Clientes con deuda', value: '${items.length}',          color: AC.warning),
          _StatChip(label: 'Críticos (+30d)',   value: '$critico',                  color: AC.danger),
          _StatChip(label: 'Atraso promedio',   value: '$avgDays días',             color: AC.textSec),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({required this.label, required this.value, required this.color});
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color:  AC.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value, style: GoogleFonts.spaceGrotesk(
              fontSize: 18, fontWeight: FontWeight.w700, color: color)),
          Text(label, style: GoogleFonts.inter(fontSize: 11, color: AC.textSec)),
        ],
      ),
    );
  }
}

// ── Table Header ─────────────────────────────────────────────────────────────

class _TableHdr extends StatelessWidget {
  const _TableHdr({required this.selectedAll, required this.onSelectAll});
  final bool selectedAll;
  final ValueChanged<bool> onSelectAll;

  @override
  Widget build(BuildContext context) {
    const sty = TextStyle(fontSize: 10, fontWeight: FontWeight.w700,
        color: AC.textSec, letterSpacing: 0.8);
    return Container(
      color: AC.surface,
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 10),
      child: Row(
        children: [
          Checkbox(
            value:          selectedAll,
            onChanged:      (v) => onSelectAll(v ?? false),
            fillColor:      WidgetStateProperty.all(AC.violet),
            checkColor:     Colors.white,
            side:           const BorderSide(color: AC.borderBright),
          ),
          const Expanded(flex: 3, child: Text('CLIENTE', style: sty)),
          const Expanded(flex: 2, child: Text('MONTO', style: sty)),
          const Expanded(flex: 2, child: Text('VENCIMIENTO', style: sty)),
          const Expanded(flex: 2, child: Text('SEVERIDAD', style: sty)),
          const SizedBox(width: 120),
        ],
      ),
    );
  }
}

// ── Overdue Row ───────────────────────────────────────────────────────────────

class _OverdueRow extends StatefulWidget {
  const _OverdueRow({
    required this.item,
    required this.selected,
    required this.onSelect,
    required this.onAction,
  });
  final OverduePayment item;
  final bool selected;
  final ValueChanged<bool> onSelect;
  final ValueChanged<String> onAction;

  @override
  State<_OverdueRow> createState() => _OverdueRowState();
}

class _OverdueRowState extends State<_OverdueRow> {
  bool _hovered = false;

  Color get _sevBorderColor {
    switch (widget.item.severity) {
      case 'critico':  return AC.danger;
      case 'moderado': return AC.warning;
      default:         return const Color(0xFFFFE066);
    }
  }

  @override
  Widget build(BuildContext context) {
    final fmt    = NumberFormat('#,###', 'es_PY');
    final dateFmt = DateFormat('dd/MM/yyyy');
    final item   = widget.item;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit:  (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          color: _hovered || widget.selected
              ? AC.surfaceHigh : Colors.transparent,
          border: Border(
            left: BorderSide(color: _sevBorderColor, width: 3),
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
        child: Row(
          children: [
            Checkbox(
              value:   widget.selected,
              onChanged: (v) => widget.onSelect(v ?? false),
              fillColor: WidgetStateProperty.all(AC.violet),
              checkColor: Colors.white,
              side:    const BorderSide(color: AC.borderBright),
            ),
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.businessName, style: GoogleFonts.inter(
                      fontSize: 13, fontWeight: FontWeight.w600, color: AC.text)),
                  Text(item.businessEmail, style: GoogleFonts.inter(
                      fontSize: 11, color: AC.textSec)),
                ],
              ),
            ),
            Expanded(
              flex: 2,
              child: Text('₲ ${fmt.format(item.amount)}',
                  style: GoogleFonts.spaceGrotesk(fontSize: 14,
                      fontWeight: FontWeight.w600, color: AC.text)),
            ),
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(dateFmt.format(item.dueDate), style: GoogleFonts.inter(
                      fontSize: 12, color: AC.danger)),
                  Text('Hace ${item.daysOverdue} días', style: GoogleFonts.inter(
                      fontSize: 11, color: AC.textSec)),
                ],
              ),
            ),
            Expanded(
              flex: 2,
              child: SeverityBadge(severity: item.severity),
            ),
            SizedBox(
              width: 120,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (_hovered || widget.selected) ...[
                    _QAction(icon: Icons.email_outlined,       tooltip: 'Recordatorio',
                        color: AC.violet, onTap: () => widget.onAction('reminder')),
                    const SizedBox(width: 4),
                    _QAction(icon: Icons.check_circle_outline, tooltip: 'Marcar pagado',
                        color: AC.success, onTap: () => widget.onAction('mark_paid')),
                    const SizedBox(width: 4),
                    _QAction(icon: Icons.block_rounded,        tooltip: 'Suspender',
                        color: AC.danger, onTap: () => widget.onAction('suspend')),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QAction extends StatelessWidget {
  const _QAction({required this.icon, required this.tooltip,
      required this.color, required this.onTap});
  final IconData icon;
  final String tooltip;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 26, height: 26,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(icon, size: 13, color: color),
        ),
      ),
    );
  }
}

// ── Severity chip ─────────────────────────────────────────────────────────────

class _SevChip extends StatelessWidget {
  const _SevChip({
    required this.label,
    required this.value,
    required this.current,
    required this.onTap,
    this.color,
  });
  final String label;
  final String value;
  final String current;
  final ValueChanged<String> onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final active = value == current;
    final c = color ?? AC.textSec;
    return GestureDetector(
      onTap: () => onTap(value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: active ? c.withValues(alpha: 0.15) : AC.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: active ? c.withValues(alpha: 0.4) : AC.border),
        ),
        child: Text(label, style: GoogleFonts.inter(
          fontSize: 12, fontWeight: active ? FontWeight.w600 : FontWeight.w400,
          color: active ? c : AC.textSec,
        )),
      ),
    );
  }
}
