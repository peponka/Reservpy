import 'package:flutter/foundation.dart';
import 'package:reservpy/src/core/supabase/supabase_config.dart';

/// Servicio de envío de emails transaccionales via Supabase Edge Function.
///
/// Todos los métodos son fire-and-forget: no bloquean la UI y
/// loguean errores sin interrumpir el flujo del usuario.
class EmailService {
  EmailService._();

  static Future<void> _invoke(String type, String to, Map<String, dynamic> data) async {
    try {
      await SupabaseConfig.client.functions.invoke(
        'send-email',
        body: {
          'type': type,
          'to': to,
          'data': data,
        },
      );
      debugPrint('[EmailService] ✅ Email "$type" enviado a $to');
    } catch (e) {
      // Fire-and-forget: log pero no interrumpir
      debugPrint('[EmailService] ⚠️ Error enviando email "$type" a $to: $e');
    }
  }

  // ─── 1. Email de Bienvenida ────────────────────────────────
  /// Envía email de bienvenida al registrarse un usuario nuevo.
  static Future<void> enviarEmailBienvenida({
    required String email,
    required String firstName,
    required String role,
  }) {
    return _invoke('welcome', email, {
      'firstName': firstName,
      'role': role,
    });
  }

  // ─── 2. Confirmación de Negocio ────────────────────────────
  /// Envía email al dueño cuando se crea un negocio exitosamente.
  static Future<void> enviarEmailConfirmacionNegocio({
    required String ownerEmail,
    required String ownerName,
    required String businessName,
    String? address,
  }) {
    return _invoke('business_created', ownerEmail, {
      'ownerName': ownerName,
      'businessName': businessName,
      'address': address ?? 'Sin dirección configurada',
    });
  }

  // ─── 3. Alta de Cliente ────────────────────────────────────
  /// Envía email de confirmación cuando un usuario se registra como cliente.
  static Future<void> enviarEmailAltaCliente({
    required String email,
    required String firstName,
  }) {
    return _invoke('client_registered', email, {
      'firstName': firstName,
    });
  }

  // ─── 4. Confirmación de Turno ──────────────────────────────
  /// Envía email de confirmación de turno al CLIENTE.
  static Future<void> enviarEmailConfirmacionTurnoCliente({
    required String clientEmail,
    required String clientName,
    required String businessName,
    required String serviceName,
    required DateTime startTime,
    String? address,
    String? notes,
  }) {
    return _invoke('reservation_confirmed', clientEmail, {
      'recipientName': clientName,
      'businessName': businessName,
      'serviceName': serviceName,
      'date': '${startTime.day.toString().padLeft(2, '0')}/${startTime.month.toString().padLeft(2, '0')}/${startTime.year}',
      'time': '${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}',
      'address': address,
      'notes': notes,
      'isBusinessCopy': false,
    });
  }

  /// Envía email de notificación de turno al NEGOCIO.
  static Future<void> enviarEmailConfirmacionTurnoNegocio({
    required String businessEmail,
    required String businessName,
    required String clientName,
    required String serviceName,
    required DateTime startTime,
    String? notes,
  }) {
    return _invoke('reservation_confirmed', businessEmail, {
      'recipientName': businessName,
      'clientName': clientName,
      'businessName': businessName,
      'serviceName': serviceName,
      'date': '${startTime.day.toString().padLeft(2, '0')}/${startTime.month.toString().padLeft(2, '0')}/${startTime.year}',
      'time': '${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}',
      'notes': notes,
      'isBusinessCopy': true,
    });
  }

  /// Conveniencia: envía confirmación de turno a AMBOS (cliente + negocio).
  static Future<void> enviarEmailConfirmacionTurno({
    required String clientEmail,
    required String clientName,
    required String businessEmail,
    required String businessName,
    required String serviceName,
    required DateTime startTime,
    String? address,
    String? notes,
  }) async {
    // Fire both in parallel, don't await sequentially
    await Future.wait([
      enviarEmailConfirmacionTurnoCliente(
        clientEmail: clientEmail,
        clientName: clientName,
        businessName: businessName,
        serviceName: serviceName,
        startTime: startTime,
        address: address,
        notes: notes,
      ),
      enviarEmailConfirmacionTurnoNegocio(
        businessEmail: businessEmail,
        businessName: businessName,
        clientName: clientName,
        serviceName: serviceName,
        startTime: startTime,
        notes: notes,
      ),
    ]);
  }

  // ─── 5. Recibo de Pago Mensual (Esqueleto) ────────────────
  /// Envía recibo de pago mensual. Esqueleto para futuro módulo de facturación.
  static Future<void> enviarEmailReciboPagoMensual({
    required String payerEmail,
    required String payerName,
    required String amount,
    required String period,
  }) {
    return _invoke('payment_receipt', payerEmail, {
      'payerName': payerName,
      'amount': amount,
      'period': period,
    });
  }
}
