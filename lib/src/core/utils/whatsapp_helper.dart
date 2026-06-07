import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:reservpy/src/core/constants/app_colors.dart';

/// Utility to build and launch WhatsApp reminder messages.
class WhatsAppHelper {
  WhatsAppHelper._();

  /// Build a client reminder message.
  static String _buildClientReminder({
    required String clientName,
    required String businessName,
    required String serviceName,
    required DateTime startTime,
    String? address,
  }) {
    final dayName = DateFormat('EEEE', 'es').format(startTime);
    final capitalDay = dayName[0].toUpperCase() + dayName.substring(1);
    final date = DateFormat('dd/MM/yyyy').format(startTime);
    final time = DateFormat('HH:mm').format(startTime);

    return '¡Hola $clientName! 👋\n\n'
        'Te recordamos tu turno:\n\n'
        '📅 $capitalDay $date\n'
        '🕐 $time\n'
        '💇 $serviceName\n'
        '🏪 $businessName\n'
        '${address != null && address.isNotEmpty ? '📍 $address\n' : ''}\n'
        '¡Te esperamos! ✨';
  }

  /// Build a business-to-client reminder message.
  static String _buildBusinessReminder({
    required String clientName,
    required String businessName,
    required String serviceName,
    required DateTime startTime,
    String? address,
  }) {
    final dayName = DateFormat('EEEE', 'es').format(startTime);
    final capitalDay = dayName[0].toUpperCase() + dayName.substring(1);
    final date = DateFormat('dd/MM/yyyy').format(startTime);
    final time = DateFormat('HH:mm').format(startTime);

    return '¡Hola $clientName! 👋\n\n'
        'Desde *$businessName* te recordamos tu turno:\n\n'
        '📅 $capitalDay $date\n'
        '🕐 $time\n'
        '💇 $serviceName\n'
        '${address != null && address.isNotEmpty ? '📍 $address\n' : ''}\n'
        '¡Te esperamos! ✨';
  }

  /// Open WhatsApp with a pre-built message.
  /// [phone] should include country code, e.g., '5491155551234'.
  /// If phone is null/empty, opens WhatsApp without a recipient.
  static Future<void> sendReminder({
    required String? phone,
    required String message,
  }) async {
    final encoded = Uri.encodeComponent(message);
    final url = phone != null && phone.isNotEmpty
        ? 'https://wa.me/$phone?text=$encoded'
        : 'https://wa.me/?text=$encoded';

    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  /// Send a reminder from business to client.
  static Future<void> sendBusinessToClientReminder({
    required String? clientPhone,
    required String clientName,
    required String businessName,
    required String serviceName,
    required DateTime startTime,
    String? address,
  }) async {
    final message = _buildBusinessReminder(
      clientName: clientName,
      businessName: businessName,
      serviceName: serviceName,
      startTime: startTime,
      address: address,
    );
    await sendReminder(phone: clientPhone, message: message);
  }

  /// Send a reminder from client to business.
  static Future<void> sendClientToBizReminder({
    required String? businessPhone,
    required String clientName,
    required String businessName,
    required String serviceName,
    required DateTime startTime,
  }) async {
    final message = _buildClientReminder(
      clientName: clientName,
      businessName: businessName,
      serviceName: serviceName,
      startTime: startTime,
    );
    await sendReminder(phone: businessPhone, message: message);
  }
}

/// WhatsApp icon button used in reservation cards.
class WhatsAppButton extends StatelessWidget {
  final VoidCallback onPressed;
  final String label;

  const WhatsAppButton({
    super.key,
    required this.onPressed,
    this.label = 'WhatsApp',
  });

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: onPressed,
      icon: const Icon(Icons.message_rounded, size: 15, color: Color(0xFF20A482)),
      label: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: const Color(0xFF20A482),
        ),
      ),
    );
  }
}
