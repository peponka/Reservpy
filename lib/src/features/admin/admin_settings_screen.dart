import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';

import 'package:reservpy/src/data/repositories/admin_repository.dart';
import 'admin_theme.dart';

// ── Providers ─────────────────────────────────────────────────────────────────

final plansProvider = FutureProvider<List<Plan>>((ref) async {
  return AdminRepository().getPlans();
});

// ── Screen ────────────────────────────────────────────────────────────────────

class AdminSettingsScreen extends ConsumerStatefulWidget {
  const AdminSettingsScreen({super.key});

  @override
  ConsumerState<AdminSettingsScreen> createState() => _AdminSettingsScreenState();
}

class _AdminSettingsScreenState extends ConsumerState<AdminSettingsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;

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
    return Scaffold(
      backgroundColor: AC.bg,
      body: Column(
        children: [
          // ── Header ──────────────────────────────────────
          Container(
            decoration: const BoxDecoration(
              color: AC.surface,
              border: Border(bottom: BorderSide(color: AC.border)),
            ),
            padding: const EdgeInsets.fromLTRB(28, 24, 28, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AdminSectionHeader(
                  title:    'Configuración',
                  subtitle: 'Planes, emails y ajustes del sistema',
                ),
                const SizedBox(height: 16),
                TabBar(
                  controller: _tabs,
                  tabs: const [
                    Tab(text: 'Planes'),
                    Tab(text: 'Emails'),
                    Tab(text: 'Sistema'),
                  ],
                  labelColor:       AC.violet,
                  unselectedLabelColor: AC.textSec,
                  indicatorColor:   AC.violet,
                  indicatorWeight:  2,
                  labelStyle:       GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600),
                  dividerColor:     Colors.transparent,
                ),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabs,
              children: const [
                _PlansTab(),
                _EmailsTab(),
                _SystemTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Plans Tab ─────────────────────────────────────────────────────────────────

class _PlansTab extends ConsumerWidget {
  const _PlansTab();

  static const _planColors = <String, Color>{
    'free': Color(0xFF4A4A6A), 'basic': Color(0xFF0EA5E9),
    'pro': AC.violet, 'enterprise': AC.warning,
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plansAsync = ref.watch(plansProvider);

    return plansAsync.when(
      loading: () => const Center(child: CircularProgressIndicator(color: AC.violet)),
      error:   (e, _) => Center(child: Text('Error: $e',
          style: GoogleFonts.inter(color: AC.textSec))),
      data: (plans) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text('Planes disponibles', style: GoogleFonts.inter(
                      fontSize: 14, fontWeight: FontWeight.w600, color: AC.text)),
                  const Spacer(),
                  OutlinedButton.icon(
                    onPressed: () => _showPlanDialog(context, ref),
                    icon: const Icon(Icons.add_rounded, size: 14),
                    label: const Text('Nuevo plan'),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              if (plans.isEmpty)
                Center(child: Text('Sin planes configurados',
                    style: GoogleFonts.inter(color: AC.textSec)))
              else
                Wrap(
                  spacing: 16, runSpacing: 16,
                  children: plans.asMap().entries.map((e) {
                    final plan  = e.value;
                    final color = _planColors[plan.slug] ?? AC.violet;
                    return _PlanCard(plan: plan, color: color,
                        onEdit: () => _showPlanDialog(context, ref, plan: plan))
                        .animate(delay: Duration(milliseconds: 60 * e.key))
                        .fadeIn(duration: 300.ms);
                  }).toList(),
                ),
            ],
          ),
        );
      },
    );
  }

  void _showPlanDialog(BuildContext ctx, WidgetRef ref, {Plan? plan}) {
    showDialog(
      context: ctx,
      builder: (_) => Theme(
        data: adminTheme(),
        child: _PlanDialog(
          plan: plan,
          onSave: (data) async {
            await AdminRepository().upsertPlan(data);
            ref.invalidate(plansProvider);
          },
        ),
      ),
    );
  }
}

// ── Plan Card ─────────────────────────────────────────────────────────────────

class _PlanCard extends StatelessWidget {
  const _PlanCard({required this.plan, required this.color, required this.onEdit});
  final Plan plan;
  final Color color;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,###', 'es_PY');

    return Container(
      width: 260,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AC.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: plan.isActive ? color.withValues(alpha: 0.3) : AC.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(plan.name, style: GoogleFonts.spaceGrotesk(
                  fontSize: 16, fontWeight: FontWeight.w700, color: AC.text)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: (plan.isActive ? AC.success : AC.textMut).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(plan.isActive ? 'Activo' : 'Inactivo',
                    style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600,
                        color: plan.isActive ? AC.success : AC.textMut)),
              ),
              const SizedBox(width: 6),
              GestureDetector(
                onTap: onEdit,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AC.surfaceHigh,
                    borderRadius: BorderRadius.circular(7),
                  ),
                  child: const Icon(Icons.edit_outlined, size: 13, color: AC.textSec),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text.rich(TextSpan(children: [
            TextSpan(text: '₲ ${fmt.format(plan.priceMonthly)}',
                style: GoogleFonts.spaceGrotesk(
                    fontSize: 24, fontWeight: FontWeight.w700, color: color)),
            TextSpan(text: '/mes',
                style: GoogleFonts.inter(fontSize: 12, color: AC.textSec)),
          ])),
          if (plan.priceYearly != null) ...[
            const SizedBox(height: 2),
            Text('₲ ${NumberFormat('#,###', 'es_PY').format(plan.priceYearly)}/año',
                style: GoogleFonts.inter(fontSize: 11, color: AC.textSec)),
          ],
          const SizedBox(height: 16),
          ...plan.features.take(4).map((f) => Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.check_rounded, size: 13, color: color),
                const SizedBox(width: 6),
                Expanded(child: Text(f, style: GoogleFonts.inter(
                    fontSize: 11, color: AC.textSec))),
              ],
            ),
          )),
        ],
      ),
    );
  }
}

// ── Plan Dialog ───────────────────────────────────────────────────────────────

class _PlanDialog extends StatefulWidget {
  const _PlanDialog({this.plan, required this.onSave});
  final Plan? plan;
  final Future<void> Function(Map<String, dynamic>) onSave;

  @override
  State<_PlanDialog> createState() => _PlanDialogState();
}

class _PlanDialogState extends State<_PlanDialog> {
  late final _nameCtrl     = TextEditingController(text: widget.plan?.name ?? '');
  late final _slugCtrl     = TextEditingController(text: widget.plan?.slug ?? '');
  late final _monthlyCtrl  = TextEditingController(
      text: widget.plan?.priceMonthly.toStringAsFixed(0) ?? '');
  late final _yearlyCtrl   = TextEditingController(
      text: widget.plan?.priceYearly?.toStringAsFixed(0) ?? '');
  bool _isActive = true;
  bool _loading  = false;

  @override
  void initState() {
    super.initState();
    _isActive = widget.plan?.isActive ?? true;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AC.surface,
      title: Text(widget.plan == null ? 'Nuevo plan' : 'Editar plan',
          style: GoogleFonts.spaceGrotesk(
              fontSize: 18, fontWeight: FontWeight.w700, color: AC.text)),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _Field(_nameCtrl,    'Nombre del plan',      'Pro'),
            const SizedBox(height: 12),
            _Field(_slugCtrl,    'Slug (clave interna)', 'pro'),
            const SizedBox(height: 12),
            _Field(_monthlyCtrl, 'Precio mensual (PYG)', '75000',
                keyboardType: TextInputType.number),
            const SizedBox(height: 12),
            _Field(_yearlyCtrl,  'Precio anual (PYG)',   '810000',
                keyboardType: TextInputType.number),
            const SizedBox(height: 12),
            Row(
              children: [
                Switch(
                  value:        _isActive,
                  onChanged:    (v) => setState(() => _isActive = v),
                  activeColor:  AC.success,
                ),
                const SizedBox(width: 8),
                Text(_isActive ? 'Plan activo' : 'Plan inactivo',
                    style: GoogleFonts.inter(fontSize: 13, color: AC.text)),
              ],
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
            setState(() => _loading = true);
            await widget.onSave({
              'name':          _nameCtrl.text.trim(),
              'slug':          _slugCtrl.text.trim(),
              'price_monthly': double.tryParse(_monthlyCtrl.text) ?? 0,
              'price_yearly':  double.tryParse(_yearlyCtrl.text),
              'currency':      'PYG',
              'is_active':     _isActive,
              'updated_at':    DateTime.now().toIso8601String(),
            });
            if (mounted) Navigator.pop(context);
          },
          child: _loading
              ? const SizedBox.square(dimension: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : Text('Guardar', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _slugCtrl.dispose();
    _monthlyCtrl.dispose();
    _yearlyCtrl.dispose();
    super.dispose();
  }
}

class _Field extends StatelessWidget {
  const _Field(this.ctrl, this.label, this.hint, {this.keyboardType});
  final TextEditingController ctrl;
  final String label;
  final String hint;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: ctrl,
      keyboardType: keyboardType,
      style: GoogleFonts.inter(fontSize: 13, color: AC.text),
      decoration: InputDecoration(labelText: label, hintText: hint),
    );
  }
}

// ── Emails Tab ────────────────────────────────────────────────────────────────

class _EmailsTab extends StatelessWidget {
  const _EmailsTab();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Templates de emails', style: GoogleFonts.inter(
              fontSize: 14, fontWeight: FontWeight.w600, color: AC.text)),
          const SizedBox(height: 8),
          Text('Personalizá los mensajes que reciben los clientes',
              style: GoogleFonts.inter(fontSize: 12, color: AC.textSec)),
          const SizedBox(height: 20),
          _TemplateCard(
            title:    'Recordatorio de pago',
            slug:     'payment_reminder',
            desc:     'Se envía automáticamente cuando un pago está próximo a vencer',
            icon:     Icons.schedule_send_rounded,
            color:    AC.warning,
          ),
          const SizedBox(height: 12),
          _TemplateCard(
            title:    'Pago vencido',
            slug:     'payment_overdue',
            desc:     'Se envía cuando un pago lleva más de 1 día vencido',
            icon:     Icons.warning_amber_rounded,
            color:    AC.danger,
          ),
          const SizedBox(height: 12),
          _TemplateCard(
            title:    'Bienvenida',
            slug:     'welcome',
            desc:     'Se envía cuando un nuevo cliente se registra',
            icon:     Icons.waving_hand_rounded,
            color:    AC.success,
          ),
        ],
      ),
    );
  }
}

class _TemplateCard extends StatelessWidget {
  const _TemplateCard({
    required this.title,
    required this.slug,
    required this.desc,
    required this.icon,
    required this.color,
  });
  final String title;
  final String slug;
  final String desc;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AC.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AC.border),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: GoogleFonts.inter(
                    fontSize: 13, fontWeight: FontWeight.w600, color: AC.text)),
                const SizedBox(height: 2),
                Text(desc, style: GoogleFonts.inter(fontSize: 11, color: AC.textSec)),
              ],
            ),
          ),
          OutlinedButton(
            onPressed: () => _showEditDialog(context),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              textStyle: GoogleFonts.inter(fontSize: 12),
            ),
            child: const Text('Editar'),
          ),
        ],
      ),
    );
  }

  void _showEditDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => Theme(
        data: adminTheme(),
        child: AlertDialog(
          backgroundColor: AC.surface,
          title: Text('Editar: $title',
              style: GoogleFonts.spaceGrotesk(
                  fontSize: 17, fontWeight: FontWeight.w700, color: AC.text)),
          content: SizedBox(
            width: 500,
            child: Text(
              'Editor de template próximamente.\nPor ahora podés editar los templates '
              'directamente en la tabla email_templates de Supabase.',
              style: GoogleFonts.inter(fontSize: 13, color: AC.textSec),
            ),
          ),
          actions: [
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: AC.violet),
              onPressed: () => Navigator.pop(context),
              child: Text('OK', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }
}

// ── System Tab ────────────────────────────────────────────────────────────────

class _SystemTab extends StatelessWidget {
  const _SystemTab();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Información del sistema', style: GoogleFonts.inter(
              fontSize: 14, fontWeight: FontWeight.w600, color: AC.text)),
          const SizedBox(height: 20),
          AdminCard(
            child: Column(
              children: [
                _InfoRow(label: 'Plataforma',    value: 'ReservPy SaaS'),
                _InfoRow(label: 'Zona horaria',  value: 'America/Asuncion (GMT-4)'),
                _InfoRow(label: 'Moneda',        value: 'Guaraní Paraguayo (PYG)'),
                _InfoRow(label: 'Backend',       value: 'Supabase (PostgreSQL)'),
                _InfoRow(label: 'Super Admin',   value: 'pepeq68@gmail.com'),
                _InfoRow(label: 'Versión app',   value: '1.0.0', isLast: true),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AC.danger.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AC.danger.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                const Icon(Icons.security_rounded, size: 18, color: AC.danger),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Zona de seguridad', style: GoogleFonts.inter(
                          fontSize: 13, fontWeight: FontWeight.w600, color: AC.danger)),
                      const SizedBox(height: 2),
                      Text('El Super Admin (pepeq68@gmail.com) no puede ser modificado ni eliminado por ningún miembro del equipo.',
                          style: GoogleFonts.inter(fontSize: 12, color: AC.textSec)),
                    ],
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

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value, this.isLast = false});
  final String label;
  final String value;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        border: isLast ? null : const Border(
          bottom: BorderSide(color: AC.border),
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 160,
            child: Text(label, style: GoogleFonts.inter(
                fontSize: 13, color: AC.textSec)),
          ),
          Text(value, style: GoogleFonts.inter(
              fontSize: 13, fontWeight: FontWeight.w500, color: AC.text)),
        ],
      ),
    );
  }
}
