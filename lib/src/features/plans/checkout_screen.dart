import 'package:flutter/material.dart';

import 'package:reservpy/src/features/subscription/bancard_payment_screen.dart';

/// Legacy entry point kept for the plans tab.
///
/// The real card checkout is still pending credentials, so this screen now
/// reuses the honest Pro activation flow instead of simulating a payment form.
class CheckoutScreen extends StatelessWidget {
  const CheckoutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const BancardPaymentScreen();
  }
}
