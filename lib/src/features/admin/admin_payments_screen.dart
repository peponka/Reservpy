import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import 'package:reservpy/src/core/constants/app_colors.dart';
import 'package:reservpy/src/data/repositories/admin_repository.dart';

// ── Providers ─────────────────────────────────────────────────────────────────

final billingListProvider = FutureProvider<List<BusinessBilling>>((ref) async {
  return AdminRepository().getBillingRecords();
});

final businessesForBillingProvider = FutureProvider((ref) async {
  return AdminRepository().getAllBusinessesAdmin();
});

// ── Screen ────────────────────────────────────────────────────────────────────

class AdminPaymentsScreen extends ConsumerStatefulWidget {
  const AdminPaymentsScreen({super.key});

  @override
  ConsumerState<AdminPaymentsScreen> createState() => _AdminPaymentsScreenState();
}

class _AdminPaymentsScreenState extends ConsumerState<AdminPaymentsScreen> {
  String _filter = 'all'; // all | overdue | expiring | active | suspended

  @override
  Widget build(BuildContext context) {
    final billingAsync    = ref.watch(billingListProvider);
    final businessesAsync = ref.watch(businessesForBillingProvider);
    final theme           = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(28, 28, 28, 0),
            child: Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Pagos y Facturación', style: GoogleFonts.inter(
                      fontSize: 24, fontWeight: FontWeight.w800,
                      color: theme.colorScheme.onSurface,
                    )),
                    Text('Seguimiento de suscripciones y cobros',
                        style: GoogleFonts.inter(fontSize: 13, color: Colors.grey.shade500)),
                  ],
                ),
                const Spacer(),
                OutlinedButton.icon(
                  onPressed: () {
                    ref.invalidate(billingListProvider);
                    ref.invalidate(businessesForBillingProvider);
                  },
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

          const SizedBox(height: 20),

          // ── Alert banners ─────────────────────────────────
          billingAsync.when(
            loading: () => const SizedBox.shrink(),
            error:   (_, __) => const SizedBox.shrink(),
            data:    (records) {
              final overdue    = records.where((r) => r.status == 'overdue').length;
              final expiring3  = records.where((r) => r.expiresIn3Days).length;
              final expiring7  = records.where((r) => r.expiresIn7Days && !r.expiresIn3Days).length;
              return Column(
                children: [
                  if (overdue > 0)    _AlertBanner(label: '$overdue negocios con pago vencido',   type: 'critical'),
                  if (expiring3 > 0)  _AlertBanner(label: '$expiring3 negocios vencen en 3 días', type: 'warning'),
                  if (expiring7 > 0)  _AlertBanner(label: '$expiring7 negocios vencen en 7 días', type: 'info'),
                ],
              );
            },
          ),

          // ── Filter chips ──────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(28, 8, 28, 0),
            child: Wrap(
              spacing: 8,
              children: [
                _FilterChip(label: 'Todos',     value: 'all',      current: _filter, onTap: (v) => setState(() => _filter = v)),
                _FilterChip(label: 'Vencidos',  value: 'overdue',  current: _filter, onTap: (v) => setState(() => _filter = v), color: const Color(0xFFEF4444)),
                _FilterChip(label: 'Por vencer',value: 'expiring', current: _filter, onTap: (v) => setState(() => _filter = v), color: const Color(0xFFF59E0B)),
                _FilterChip(label: 'Activos',   value: 'active',   current: _filter, onTap: (v) => setState(() => _filter = v), color: const Color(0xFF10B981)),
                _FilterChip(label: 'Suspendidos',value: 'suspended',current: _filter, onTap: (v) => setState(() => _filter = v), color: Colors.grey),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ── Table ─────────────────────────────────────────
          Expanded(
            child: billingAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error:   (e, _) => Center(child: Text('Error: $e')),
              data: (records) {
                final businesses = businessesAsync.value ?? [];
                final businessMap = {for (final b in businesses) b.id: b};

                final filtered = records.where((r) {
                  if (_filter == 'overdue')   return r.status == 'overdue' || r.isOverdue;
                  if (_filter == 'expiring')  return r.expiresIn7Days;
                  if (_filter == 'active')    return r.status == 'active';
                  if (_filter == 'suspended') return r.status == 'suspended';
                  return true;
                }).toList();

                if (filtered.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.receipt_long_rounded, size: 48, color: Colors.grey.shade300),
                        const SizedBox(height: 12),
                        Text('Sin registros', style: GoogleFonts.inter(color: Colors.grey.shade400, fontSize: 15)),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(28, 0, 28, 28),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (_, i) {
                    final billing  = filtered[i];
                    final business = businessMap[billing.businessId];
                    return _BillingRow(
                      billing:      billing,
                      businessName: business?.name ?? billing.businessId,
                      onAction:     (action) => _handleAction(action, billing),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _handleAction(String action, BusinessBilling billing) async {
    final repo = AdminRepository();
    switch (action) {
      case 'suspend':
        await repo.upsertBilling(
          businessId: billing.businessId, plan: billing.plan,
          status: 'suspended', amountGuaranies: billing.amountGuaranies,
        );
        break;
      case 'reactivate':
        await repo.upsertBilling(
          businessId: billing.businessId, plan: billing.plan,
          status: 'active', amountGuaranies: billing.amountGuaranies,
          nextBillingAt: DateTime.now().add(const Duration(days: 30)),
        );
        break;
      case 'register_payment':
        await repo.upsertBilling(
          businessId: billing.businessId, plan: billing.plan,
          status: 'active', amountGuaranies: billing.amountGuaranies,
          nextBillingAt: DateTime.now().add(const Duration(days: 30)),
        );
        await repo.logAction(
          action: 'billing.payment_registered',
          entityType: 'business',
          entityId: billing.businessId,
          details: {'plan': billing.plan, 'amount': billing.amountGuaranies},
        );
        break;
    }
    ref.invalidate(billingListProvider);
  }
}

// ── Billing Row ───────────────────────────────────────────────────────────────

class _BillingRow extends StatelessWidget {
  const _BillingRow({
    required this.billing,
    required this.businessName,
    required this.onAction,
  });

  final BusinessBilling billing;
  final String businessName;
  final ValueChanged<String> onAction;

  Color get _statusColor {
    switch (billing.status) {
      case 'active':    return const Color(0xFF10B981);
      case 'overdue':   return const Color(0xFFEF4444);
      case 'suspended': return Colors.grey;
      case 'pending':   return const Color(0xFFF59E0B);
      case 'cancelled': return const Color(0xFF6B7280);
      default:          return Colors.grey;
    }
  }

  String get _statusLabel {
    switch (billing.status) {
      case 'active':    return 'Activo';
      case 'overdue':   return 'Vencido';
      case 'suspended': return 'Suspendido';
      case 'pending':   return 'Pendiente';
      case 'cancelled': return 'Cancelado';
      default:          return billing.status;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme   = Theme.of(context);
    final fmt     = NumberFormat('#,###', 'es_PY');
    final dateFmt = DateFormat('dd/MM/yyyy');

    final isUrgent = billing.isOverdue || billing.expiresIn3Days;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: isUrgent
            ? const Color(0xFFEF4444).withValues(alpha: 0.04)
            : theme.colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isUrgent
              ? const Color(0xFFEF4444).withValues(alpha: 0.25)
              : theme.dividerColor.withValues(alpha: 0.25),
        ),
      ),
      child: Row(
        children: [
          // Business name + plan
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(businessName, style: GoogleFonts.inter(
                  fontSize: 14, fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                )),
                const SizedBox(height: 2),
                Text(billing.plan.toUpperCase(), style: GoogleFonts.inter(
                  fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                )),
              ],
            ),
          ),

          // Amount
          Expanded(
            flex: 2,
            child: Text('₲ ${fmt.format(billing.amountGuaranies)}',
                style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface)),
          ),

          // Next billing
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Próximo venc.',
                    style: GoogleFonts.inter(fontSize: 10, color: Colors.grey.shade400)),
                Text(
                  billing.nextBillingAt != null
                      ? dateFmt.format(billing.nextBillingAt!)
                      : '—',
                  style: GoogleFonts.inter(
                    fontSize: 13, fontWeight: FontWeight.w500,
                    color: billing.isOverdue
                        ? const Color(0xFFEF4444)
                        : billing.expiresIn3Days
                            ? const Color(0xFFF59E0B)
                            : theme.colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),

          // Status badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: _statusColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(_statusLabel, style: GoogleFonts.inter(
              fontSize: 11, fontWeight: FontWeight.w600, color: _statusColor,
            )),
          ),
          const SizedBox(width: 12),

          // Actions
          PopupMenuButton<String>(
            onSelected: onAction,
            icon: Icon(Icons.more_vert_rounded, size: 18,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5)),
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'register_payment',
                  child: ListTile(dense: true, leading: Icon(Icons.check_circle_outline_rounded),
                      title: Text('Registrar pago'))),
              const PopupMenuItem(value: 'reactivate',
                  child: ListTile(dense: true, leading: Icon(Icons.play_circle_outline_rounded),
                      title: Text('Reactivar'))),
              const PopupMenuItem(value: 'suspend',
                  child: ListTile(dense: true, leading: Icon(Icons.pause_circle_outline_rounded),
                      title: Text('Suspender'))),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Alert Banner ─────────────────────────────────────────────────────────────

class _AlertBanner extends StatelessWidget {
  const _AlertBanner({required this.label, required this.type});
  final String label;
  final String type; // critical | warning | info

  Color get _color {
    switch (type) {
      case 'critical': return const Color(0xFFEF4444);
      case 'warning':  return const Color(0xFFF59E0B);
      default:         return const Color(0xFF0EA5E9);
    }
  }

  IconData get _icon {
    switch (type) {
      case 'critical': return Icons.error_rounded;
      case 'warning':  return Icons.warning_rounded;
      default:         return Icons.info_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(28, 0, 28, 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _color.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Icon(_icon, size: 16, color: _color),
          const SizedBox(width: 8),
          Text(label, style: GoogleFonts.inter(
            fontSize: 13, fontWeight: FontWeight.w500, color: _color,
          )),
        ],
      ),
    );
  }
}

// ── Filter Chip ───────────────────────────────────────────────────────────────

class _FilterChip extends StatelessWidget {
  const _FilterChip({
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
    final c      = color ?? AppColors.primary;
    return GestureDetector(
      onTap: () => onTap(value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color:        active ? c.withValues(alpha: 0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border:       Border.all(color: active ? c : Colors.grey.shade300),
        ),
        child: Text(label, style: GoogleFonts.inter(
          fontSize: 12, fontWeight: active ? FontWeight.w600 : FontWeight.w400,
          color: active ? c : Colors.grey.shade500,
        )),
      ),
    );
  }
}
