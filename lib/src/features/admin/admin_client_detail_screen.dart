import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'package:reservpy/src/data/repositories/admin_repository.dart';
import 'admin_theme.dart';

// ── Providers ─────────────────────────────────────────────────────────────────

final _businessDetailProvider = FutureProvider.family<AdminBusiness?, String>((ref, id) async {
  return AdminRepository().getBusinessById(id);
});

final _businessPaymentsProvider = FutureProvider.family<List<Payment>, String>((ref, id) async {
  return AdminRepository().getBusinessPayments(id);
});

final _businessReservationsProvider = FutureProvider.family<List<Map<String, dynamic>>, String>((ref, id) async {
  return AdminRepository().getBusinessReservations(id);
});

// ── Screen ────────────────────────────────────────────────────────────────────

class AdminClientDetailScreen extends ConsumerStatefulWidget {
  const AdminClientDetailScreen({super.key, required this.businessId});
  final String businessId;

  @override
  ConsumerState<AdminClientDetailScreen> createState() => _AdminClientDetailScreenState();
}

class _AdminClientDetailScreenState extends ConsumerState<AdminClientDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;
  String? _internalNotes;
  bool _notesLoading = false;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final detailAsync = ref.watch(_businessDetailProvider(widget.businessId));

    return Scaffold(
      backgroundColor: AC.bg,
      body: detailAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AC.violet)),
        error:   (e, _) => Center(child: Text('Error: $e',
            style: GoogleFonts.inter(color: AC.textSec))),
        data: (business) {
          if (business == null) return Center(
            child: Text('Cliente no encontrado', style: GoogleFonts.inter(color: AC.textSec)));
          if (_internalNotes == null) _internalNotes = '';
          return _DetailBody(
            business:     business,
            tabs:         _tabs,
            businessId:   widget.businessId,
            internalNotes: _internalNotes!,
            onNotesChange: (v) => setState(() => _internalNotes = v),
            onToggle: () async {
              await AdminRepository().setBusinessActive(business.id, !business.isActive);
              ref.invalidate(_businessDetailProvider(widget.businessId));
            },
          );
        },
      ),
    );
  }
}

// ── Detail Body ───────────────────────────────────────────────────────────────

class _DetailBody extends StatelessWidget {
  const _DetailBody({
    required this.business,
    required this.tabs,
    required this.businessId,
    required this.internalNotes,
    required this.onNotesChange,
    required this.onToggle,
  });

  final AdminBusiness business;
  final TabController tabs;
  final String businessId;
  final String internalNotes;
  final ValueChanged<String> onNotesChange;
  final VoidCallback onToggle;

  static const _planColors = <String, Color>{
    'free': Color(0xFF4A4A6A), 'basic': Color(0xFF0EA5E9),
    'pro': AC.violet, 'enterprise': AC.warning,
  };
  static const _planLabels = <String, String>{
    'free': 'Gratuito', 'basic': 'Básico',
    'pro': 'Pro', 'enterprise': 'Enterprise',
  };

  @override
  Widget build(BuildContext context) {
    final pc  = _planColors[business.plan] ?? AC.textSec;
    final pl  = _planLabels[business.plan] ?? business.plan;
    final fmt = DateFormat('dd/MM/yyyy');
    final daysSince = DateTime.now().difference(business.createdAt).inDays;

    return Column(
      children: [
        // ── Header ──────────────────────────────────────────
        Container(
          decoration: const BoxDecoration(
            color: AC.surface,
            border: Border(bottom: BorderSide(color: AC.border)),
          ),
          padding: const EdgeInsets.fromLTRB(28, 24, 28, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Back + actions
              Row(
                children: [
                  TextButton.icon(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.arrow_back_rounded, size: 16, color: AC.textSec),
                    label: Text('Volver', style: GoogleFonts.inter(
                        fontSize: 13, color: AC.textSec)),
                    style: TextButton.styleFrom(padding: EdgeInsets.zero),
                  ),
                  const Spacer(),
                  // Action buttons
                  _ActionBtn(
                    icon: business.isActive
                        ? Icons.pause_circle_outline_rounded
                        : Icons.play_circle_outline_rounded,
                    label: business.isActive ? 'Suspender' : 'Reactivar',
                    color: business.isActive ? AC.danger : AC.success,
                    onTap: onToggle,
                  ),
                  const SizedBox(width: 8),
                  _ActionBtn(
                    icon:  Icons.edit_outlined,
                    label: 'Editar',
                    color: AC.violet,
                    onTap: () {},
                  ),
                  const SizedBox(width: 8),
                  _ActionBtn(
                    icon:  Icons.email_outlined,
                    label: 'Email',
                    color: AC.teal,
                    onTap: () {},
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Business info
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Avatar
                  Container(
                    width: 60, height: 60,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [pc, pc.withValues(alpha: 0.5)],
                        begin: Alignment.topLeft, end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Center(child: Text(business.initials,
                        style: GoogleFonts.spaceGrotesk(
                            fontSize: 22, fontWeight: FontWeight.w700, color: Colors.white))),
                  ),
                  const SizedBox(width: 18),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(business.name, style: GoogleFonts.spaceGrotesk(
                                fontSize: 22, fontWeight: FontWeight.w700, color: AC.text)),
                            const SizedBox(width: 10),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                              decoration: BoxDecoration(
                                color:  pc.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: pc.withValues(alpha: 0.3)),
                              ),
                              child: Text(pl, style: GoogleFonts.inter(
                                  fontSize: 11, fontWeight: FontWeight.w600, color: pc)),
                            ),
                            const SizedBox(width: 8),
                            StatusBadge(status: business.isActive ? 'active' : 'inactive'),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(business.email, style: GoogleFonts.inter(
                            fontSize: 13, color: AC.textSec)),
                        const SizedBox(height: 4),
                        Text('Cliente hace $daysSince días • '
                            'Registrado el ${fmt.format(business.createdAt)}',
                            style: GoogleFonts.inter(fontSize: 12, color: AC.textMut)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Tabs
              TabBar(
                controller: tabs,
                tabs: const [
                  Tab(text: 'Resumen'),
                  Tab(text: 'Pagos'),
                  Tab(text: 'Reservas'),
                ],
                labelColor:        AC.violet,
                unselectedLabelColor: AC.textSec,
                indicatorColor:    AC.violet,
                indicatorWeight:   2,
                labelStyle:        GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600),
                unselectedLabelStyle: GoogleFonts.inter(fontSize: 13),
                dividerColor:      Colors.transparent,
              ),
            ],
          ),
        ),

        // ── Tab content ─────────────────────────────────────
        Expanded(
          child: TabBarView(
            controller: tabs,
            children: [
              _SummaryTab(business: business, internalNotes: internalNotes,
                  onNotesChange: onNotesChange),
              _PaymentsTab(businessId: businessId),
              _ReservationsTab(businessId: businessId),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Summary Tab ───────────────────────────────────────────────────────────────

class _SummaryTab extends StatelessWidget {
  const _SummaryTab({
    required this.business,
    required this.internalNotes,
    required this.onNotesChange,
  });
  final AdminBusiness business;
  final String internalNotes;
  final ValueChanged<String> onNotesChange;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Quick metrics
          Wrap(
            spacing: 16, runSpacing: 16,
            children: [
              _MiniStat(label: 'Reservas totales', value: '—',
                  icon: Icons.event_note_rounded, color: AC.violet),
              _MiniStat(label: 'Este mes', value: '—',
                  icon: Icons.today_rounded, color: AC.teal),
              _MiniStat(label: 'Estado de cuenta',
                  value: business.isActive ? 'Al día' : 'Inactivo',
                  icon: Icons.account_balance_wallet_rounded,
                  color: business.isActive ? AC.success : AC.danger),
            ],
          ),
          const SizedBox(height: 28),

          // Internal notes
          AdminCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  const Icon(Icons.sticky_note_2_outlined, size: 15, color: AC.textSec),
                  const SizedBox(width: 8),
                  Text('Notas internas', style: GoogleFonts.inter(
                      fontSize: 14, fontWeight: FontWeight.w600, color: AC.text)),
                ]),
                const SizedBox(height: 12),
                TextField(
                  controller: TextEditingController(text: internalNotes)
                    ..selection = TextSelection.fromPosition(
                        TextPosition(offset: internalNotes.length)),
                  onChanged: onNotesChange,
                  maxLines: 4,
                  style: GoogleFonts.inter(fontSize: 13, color: AC.text),
                  decoration: InputDecoration(
                    hintText: 'Agregar notas internas sobre este cliente…',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: AC.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: AC.border),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Payments Tab ─────────────────────────────────────────────────────────────

class _PaymentsTab extends ConsumerWidget {
  const _PaymentsTab({required this.businessId});
  final String businessId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final paymentsAsync = ref.watch(_businessPaymentsProvider(businessId));

    return paymentsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator(color: AC.violet)),
      error:   (e, _) => Center(child: Text('Error: $e',
          style: GoogleFonts.inter(color: AC.textSec))),
      data: (payments) {
        return Column(
          children: [
            // Header + add button
            Padding(
              padding: const EdgeInsets.fromLTRB(28, 20, 28, 12),
              child: Row(
                children: [
                  Text('Historial de Pagos', style: GoogleFonts.inter(
                      fontSize: 14, fontWeight: FontWeight.w600, color: AC.text)),
                  const Spacer(),
                  FilledButton.icon(
                    onPressed: () => _showRegisterPayment(context, ref, businessId),
                    icon: const Icon(Icons.add_rounded, size: 15),
                    label: const Text('Registrar pago'),
                    style: FilledButton.styleFrom(
                      backgroundColor: AC.violet,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      textStyle: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: payments.isEmpty
                  ? Center(child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.receipt_long_outlined, size: 44, color: AC.textMut),
                        const SizedBox(height: 10),
                        Text('Sin pagos registrados', style: GoogleFonts.inter(
                            fontSize: 14, color: AC.textSec)),
                      ],
                    ))
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(28, 0, 28, 28),
                      itemCount: payments.length,
                      separatorBuilder: (_, __) => const Divider(height: 1, color: AC.border),
                      itemBuilder: (_, i) => _PaymentRow(payment: payments[i]),
                    ),
            ),
          ],
        );
      },
    );
  }

  void _showRegisterPayment(BuildContext ctx, WidgetRef ref, String businessId) {
    showDialog(
      context: ctx,
      builder: (dCtx) => Theme(
        data: adminTheme(),
        child: _RegisterPaymentDialog(
          businessId: businessId,
          onSave: () {
            ref.invalidate(_businessPaymentsProvider(businessId));
          },
        ),
      ),
    );
  }
}

// ── Payment Row ───────────────────────────────────────────────────────────────

class _PaymentRow extends StatelessWidget {
  const _PaymentRow({required this.payment});
  final Payment payment;

  @override
  Widget build(BuildContext context) {
    final fmt    = NumberFormat('#,###', 'es_PY');
    final dateFmt = DateFormat('dd/MM/yyyy');

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(dateFmt.format(payment.dueDate), style: GoogleFonts.inter(
                  fontSize: 13, color: AC.text)),
              if (payment.paymentMethod != null)
                Text(payment.paymentMethod!, style: GoogleFonts.inter(
                    fontSize: 11, color: AC.textSec)),
            ],
          )),
          Expanded(child: Text('₲ ${fmt.format(payment.amount)}',
              style: GoogleFonts.spaceGrotesk(fontSize: 14,
                  fontWeight: FontWeight.w600, color: AC.text))),
          StatusBadge(status: payment.status),
          if (payment.paidAt != null) ...[
            const SizedBox(width: 12),
            Text('Pagado ${dateFmt.format(payment.paidAt!)}',
                style: GoogleFonts.inter(fontSize: 11, color: AC.success)),
          ],
        ],
      ),
    );
  }
}

// ── Reservations Tab ──────────────────────────────────────────────────────────

class _ReservationsTab extends ConsumerWidget {
  const _ReservationsTab({required this.businessId});
  final String businessId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reservAsync = ref.watch(_businessReservationsProvider(businessId));
    final dateFmt     = DateFormat('dd/MM/yyyy HH:mm');

    return reservAsync.when(
      loading: () => const Center(child: CircularProgressIndicator(color: AC.violet)),
      error:   (e, _) => Center(child: Text('Error: $e',
          style: GoogleFonts.inter(color: AC.textSec))),
      data: (reservations) {
        if (reservations.isEmpty) {
          return Center(child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.calendar_today_outlined, size: 44, color: AC.textMut),
              const SizedBox(height: 10),
              Text('Sin reservas', style: GoogleFonts.inter(
                  fontSize: 14, color: AC.textSec)),
            ],
          ));
        }
        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(28, 20, 28, 28),
          itemCount: reservations.length,
          separatorBuilder: (_, __) => const Divider(height: 1, color: AC.border),
          itemBuilder: (_, i) {
            final r   = reservations[i];
            final dt  = r['start_time'] != null
                ? DateTime.tryParse(r['start_time'] as String)
                : null;
            final status = r['status'] as String? ?? 'pending';
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(
                children: [
                  Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(dt != null ? dateFmt.format(dt) : '—',
                          style: GoogleFonts.inter(fontSize: 13, color: AC.text)),
                      if (r['notes'] != null)
                        Text(r['notes'] as String, style: GoogleFonts.inter(
                            fontSize: 11, color: AC.textSec)),
                    ],
                  )),
                  StatusBadge(status: status),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

// ── Mini stat card ────────────────────────────────────────────────────────────

class _MiniStat extends StatelessWidget {
  const _MiniStat({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 180,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AC.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AC.border),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(icon, size: 16, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value, style: GoogleFonts.spaceGrotesk(
                    fontSize: 18, fontWeight: FontWeight.w700, color: AC.text)),
                Text(label, style: GoogleFonts.inter(
                    fontSize: 11, color: AC.textSec)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Action button ─────────────────────────────────────────────────────────────

class _ActionBtn extends StatelessWidget {
  const _ActionBtn({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 6),
            Text(label, style: GoogleFonts.inter(
                fontSize: 12, fontWeight: FontWeight.w500, color: color)),
          ],
        ),
      ),
    );
  }
}

// ── Register Payment Dialog ───────────────────────────────────────────────────

class _RegisterPaymentDialog extends StatefulWidget {
  const _RegisterPaymentDialog({required this.businessId, required this.onSave});
  final String businessId;
  final VoidCallback onSave;

  @override
  State<_RegisterPaymentDialog> createState() => _RegisterPaymentDialogState();
}

class _RegisterPaymentDialogState extends State<_RegisterPaymentDialog> {
  final _amountCtrl  = TextEditingController();
  final _notesCtrl   = TextEditingController();
  final _refCtrl     = TextEditingController();
  String _method     = 'transferencia';
  String _status     = 'paid';
  bool   _loading    = false;
  DateTime _dueDate  = DateTime.now();

  final _methods = const {
    'transferencia': 'Transferencia',
    'tigo_money':    'Tigo Money',
    'bancard':       'Bancard',
    'efectivo':      'Efectivo',
    'credito':       'Crédito',
  };
  final _statuses = const {
    'paid':    'Pagado',
    'pending': 'Pendiente',
    'overdue': 'Vencido',
  };

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AC.surface,
      title: Text('Registrar Pago', style: GoogleFonts.spaceGrotesk(
          fontSize: 18, fontWeight: FontWeight.w700, color: AC.text)),
      content: SizedBox(
        width: 440,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _DField(ctrl: _amountCtrl, label: 'Monto (PYG)',
                  hint: '75000', keyboardType: TextInputType.number),
              const SizedBox(height: 12),
              _DDropdown(label: 'Método de pago', value: _method,
                  items: _methods, onChanged: (v) => setState(() => _method = v)),
              const SizedBox(height: 12),
              _DDropdown(label: 'Estado', value: _status,
                  items: _statuses, onChanged: (v) => setState(() => _status = v)),
              const SizedBox(height: 12),
              _DField(ctrl: _refCtrl, label: 'Referencia (opcional)'),
              const SizedBox(height: 12),
              _DField(ctrl: _notesCtrl, label: 'Notas', maxLines: 2),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancelar', style: GoogleFonts.inter(color: AC.textSec)),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: AC.violet),
          onPressed: _loading ? null : _save,
          child: _loading
              ? const SizedBox.square(dimension: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : Text('Registrar', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
        ),
      ],
    );
  }

  Future<void> _save() async {
    final amount = double.tryParse(_amountCtrl.text.trim()) ?? 0;
    if (amount <= 0) return;
    setState(() => _loading = true);
    await AdminRepository().registerPayment(
      businessId:   widget.businessId,
      amount:       amount,
      currency:     'PYG',
      status:       _status,
      dueDate:      _dueDate,
      paymentMethod: _method,
      reference:    _refCtrl.text.trim().isEmpty ? null : _refCtrl.text.trim(),
      notes:        _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
    );
    widget.onSave();
    if (mounted) Navigator.pop(context);
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _notesCtrl.dispose();
    _refCtrl.dispose();
    super.dispose();
  }
}

class _DField extends StatelessWidget {
  const _DField({
    required this.ctrl,
    required this.label,
    this.hint,
    this.maxLines = 1,
    this.keyboardType,
  });
  final TextEditingController ctrl;
  final String label;
  final String? hint;
  final int maxLines;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: ctrl,
      maxLines: maxLines,
      keyboardType: keyboardType,
      style: GoogleFonts.inter(fontSize: 13, color: AC.text),
      decoration: InputDecoration(
        labelText: label,
        hintText:  hint,
      ),
    );
  }
}

class _DDropdown extends StatelessWidget {
  const _DDropdown({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });
  final String label;
  final String value;
  final Map<String, String> items;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(labelText: label),
      dropdownColor: AC.surface,
      style: GoogleFonts.inter(fontSize: 13, color: AC.text),
      items: items.entries.map((e) =>
          DropdownMenuItem(value: e.key, child: Text(e.value))).toList(),
      onChanged: (v) { if (v != null) onChanged(v); },
    );
  }
}
