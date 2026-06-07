import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../../data/repositories/business_repository.dart';
import '../../data/services/email_service.dart';
import '../../shared/providers/providers.dart';

/// Simulated Bancard payment screen.
/// In production, this would redirect to Bancard's hosted payment page.
class BancardPaymentScreen extends ConsumerStatefulWidget {
  const BancardPaymentScreen({super.key});

  @override
  ConsumerState<BancardPaymentScreen> createState() =>
      _BancardPaymentScreenState();
}

class _BancardPaymentScreenState
    extends ConsumerState<BancardPaymentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _cardNumberCtrl = TextEditingController();
  final _cardNameCtrl = TextEditingController();
  final _expiryCtrl = TextEditingController();
  final _cvvCtrl = TextEditingController();
  bool _isProcessing = false;
  bool _obscureCvv = true;

  @override
  void dispose() {
    _cardNumberCtrl.dispose();
    _cardNameCtrl.dispose();
    _expiryCtrl.dispose();
    _cvvCtrl.dispose();
    super.dispose();
  }

  String _formatCardNumber(String value) {
    final digits = value.replaceAll(' ', '');
    final buffer = StringBuffer();
    for (int i = 0; i < digits.length; i++) {
      if (i > 0 && i % 4 == 0) buffer.write(' ');
      buffer.write(digits[i]);
    }
    return buffer.toString();
  }

  Future<void> _processPayment() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isProcessing = true);

    // Simulate processing delay
    await Future.delayed(const Duration(seconds: 2));

    final business = ref.read(currentBusinessProvider);
    if (business == null) {
      setState(() => _isProcessing = false);
      return;
    }

    try {
      // Update plan in DB
      await BusinessRepository().upgradeToPro(business.id);

      // Refresh business data
      ref.invalidate(ownerBusinessProvider);
      ref.invalidate(currentBusinessProvider);
      ref.invalidate(businessesProvider);

      // Get owner profile for email
      final user = ref.read(currentUserProvider);
      if (user != null) {
        await EmailService.enviarEmailPlanUpgraded(
          ownerEmail: user.email,
          ownerName: user.firstName,
          businessName: business.name,
          planName: 'Pro',
          amount: 'Gs. 99.000',
        );
      }

      if (!mounted) return;
      // Navigate to success
      context.go('/upgrade/success');
    } catch (e) {
      if (!mounted) return;
      setState(() => _isProcessing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al procesar el pago: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: () => context.pop()),
        title: Row(
          children: [
            Image.asset('assets/bancard_logo.png',
                height: 22,
                errorBuilder: (_, __, ___) => const Text(
                      'Bancard',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF003087),
                          fontSize: 18),
                    )),
          ],
        ),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSizes.s24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Order summary ───────────────────────────────
              Container(
                padding: const EdgeInsets.all(AppSizes.s16),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                      color: AppColors.primary.withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.workspace_premium_rounded,
                        color: Color(0xFFFFA000), size: 28),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Plan Pro — ReservPy',
                              style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.bold)),
                          Text('Suscripción mensual',
                              style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurface
                                      .withOpacity(0.55))),
                        ],
                      ),
                    ),
                    Text('Gs. 99.000',
                        style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary)),
                  ],
                ),
              ),
              const SizedBox(height: AppSizes.s24),

              // ── Card form ───────────────────────────────────
              Text('Datos de tu tarjeta',
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: AppSizes.s16),

              // Card number
              TextFormField(
                controller: _cardNumberCtrl,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(16),
                  _CardNumberFormatter(),
                ],
                decoration: _inputDecoration(
                  label: 'Número de tarjeta',
                  icon: Icons.credit_card_rounded,
                  hint: '0000 0000 0000 0000',
                ),
                validator: (v) {
                  final digits = (v ?? '').replaceAll(' ', '');
                  if (digits.length < 16) return 'Ingresá un número válido';
                  return null;
                },
              ),
              const SizedBox(height: AppSizes.s16),

              // Card name
              TextFormField(
                controller: _cardNameCtrl,
                textCapitalization: TextCapitalization.characters,
                decoration: _inputDecoration(
                  label: 'Nombre en la tarjeta',
                  icon: Icons.person_outline_rounded,
                  hint: 'JUAN PEREZ',
                ),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Ingresá el nombre'
                    : null,
              ),
              const SizedBox(height: AppSizes.s16),

              // Expiry + CVV row
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _expiryCtrl,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(4),
                        _ExpiryFormatter(),
                      ],
                      decoration: _inputDecoration(
                        label: 'Vencimiento',
                        icon: Icons.calendar_month_outlined,
                        hint: 'MM/AA',
                      ),
                      validator: (v) {
                        if (v == null || v.length < 5) return 'Inválido';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: AppSizes.s12),
                  Expanded(
                    child: TextFormField(
                      controller: _cvvCtrl,
                      obscureText: _obscureCvv,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(4),
                      ],
                      decoration: _inputDecoration(
                        label: 'CVV',
                        icon: Icons.lock_outline_rounded,
                        hint: '•••',
                      ).copyWith(
                        suffixIcon: IconButton(
                          icon: Icon(_obscureCvv
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                              size: 18),
                          onPressed: () =>
                              setState(() => _obscureCvv = !_obscureCvv),
                        ),
                      ),
                      validator: (v) {
                        if (v == null || v.length < 3) return 'Inválido';
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSizes.s32),

              // ── Pay button ──────────────────────────────────
              FilledButton(
                onPressed: _isProcessing ? null : _processPayment,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF003087),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: _isProcessing
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Pagar Gs. 99.000',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: AppSizes.s16),

              // ── Security note ───────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.verified_user_outlined,
                      size: 14,
                      color:
                          theme.colorScheme.onSurface.withOpacity(0.4)),
                  const SizedBox(width: 4),
                  Text('Transacción segura — encriptada con SSL',
                      style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface
                              .withOpacity(0.4))),
                ],
              ),
              const SizedBox(height: AppSizes.s24),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String label,
    required IconData icon,
    required String hint,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icon, size: 20),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      filled: true,
    );
  }
}

// ── Payment success screen ─────────────────────────────────────
class PaymentSuccessScreen extends StatelessWidget {
  const PaymentSuccessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.s32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              // Success icon
              Center(
                child: Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check_circle_rounded,
                      size: 56, color: AppColors.primary),
                ),
              ),
              const SizedBox(height: AppSizes.s24),
              Text('¡Pago exitoso!',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineMedium
                      ?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: AppSizes.s12),
              Text(
                'Tu negocio ya tiene el Plan Pro activo.\nRevisá tu email — te enviamos el comprobante.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                    color:
                        theme.colorScheme.onSurface.withOpacity(0.6)),
              ),
              const SizedBox(height: AppSizes.s16),
              Container(
                padding: const EdgeInsets.all(AppSizes.s16),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.workspace_premium_rounded,
                        color: Color(0xFFFFA000)),
                    SizedBox(width: 8),
                    Text('Plan Pro activado',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFFFA000))),
                  ],
                ),
              ),
              const Spacer(),
              FilledButton(
                onPressed: () => context.go('/business'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text('Ir a mi negocio',
                    style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Input formatters ──────────────────────────────────────────
class _CardNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    final digits = newValue.text.replaceAll(' ', '');
    final buffer = StringBuffer();
    for (int i = 0; i < digits.length; i++) {
      if (i > 0 && i % 4 == 0) buffer.write(' ');
      buffer.write(digits[i]);
    }
    final string = buffer.toString();
    return newValue.copyWith(
      text: string,
      selection: TextSelection.collapsed(offset: string.length),
    );
  }
}

class _ExpiryFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    final digits = newValue.text.replaceAll('/', '');
    final buffer = StringBuffer();
    for (int i = 0; i < digits.length && i < 4; i++) {
      if (i == 2) buffer.write('/');
      buffer.write(digits[i]);
    }
    final string = buffer.toString();
    return newValue.copyWith(
      text: string,
      selection: TextSelection.collapsed(offset: string.length),
    );
  }
}
