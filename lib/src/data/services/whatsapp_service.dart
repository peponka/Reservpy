import 'package:flutter/foundation.dart';
import 'package:reservpy/src/core/supabase/supabase_config.dart';

/// Servicio de mensajes WhatsApp transaccionales via Supabase Edge Function.
/// Todos los métodos son fire-and-forget.
/// REQUISITO: teléfono en formato E.164: "+595981234567"
class WhatsAppService {
  WhatsAppService._();

  static Future<void> _invoke(String type, String? phone, Map<String, dynamic> data) async {
    if (phone == null || phone.trim().isEmpty) {
      debugPrint('[WhatsAppService] ⚠️ Sin teléfono para "$type" — skip');
      return;
    }
    final normalized = _normalizePhone(phone);
    if (normalized == null) {
      debugPrint('[WhatsAppService] ⚠️ Teléfono inválido "$phone" ℔ skip');
      return;
    }
    try {
      await SupabaseConfig.client.functions.invoke('send-whatsapp', body: {'type': type, 'to': normalized, 'data': data});
      debugPrint('[WhatsAppService] ✅ "$type" enviado a $normalized');
    } catch (e) {
      debugPrint('[WhatsAppService] ⚠️ Error "$type" a $normalized: $e');
    }
  }

  static String? _normalizePhone(String raw) {
    final digits = raw.replaceAll(RegExp(r'[^\d]'), '');
    if (digits.startsWith('595') && digits.length == 12) return '+$digits';
    if (digits.startsWith('0') && digits.length == 10) return '+595${digits.substring(1)}';
    if (digits.length == 9) return '+595$digits';
    if (raw.startsWith('+')) return raw;
    return null;
  }

  static String _fd(DateTime d) => '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  static String _ft(DateTime d) => '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

  static Future<void> enviarConfirmacionTurnoCliente({required String? clientPhone, required String clientName, required String businessName, required String serviceName, required DateTime startTime, String? address}) =>
      _invoke('reservation_confirmed_client', clientPhone, {'recipientName':clientName,'businessName':businessName,'serviceName':serviceName,'date':_fd(startTime),'time':_ft(startTime),'address':address??''});

  static Future<void> enviarConfirmacionTurnoNegocio({required String? ownerPhone, required String ownerName, required String businessName, required String clientName, required String serviceName, required DateTime startTime}) =>
      _invoke('reservation_confirmed_business', ownerPhone, {'recipientName':ownerName,'businessName':businessName,'clientName':clientName,'serviceName':serviceName,'date':_fd(startTime),'time':_ft(startTime)});

  static Future<void> enviarCancelacionTurnoCliente({required String? clientPhone, required String clientName, required String businessName, required String serviceName, required DateTime startTime, String? reason}) =>
      _invoke('reservation_cancelled_client', clientPhone, {'recipientName':clientName,'businessName':businessName,'serviceName':serviceName,'date':_fd(startTime),'time':_ft(startTime),'reason':reason??''});

  static Future<void> enviarCancelacionTurnoNegocio({required String? ownerPhone, required String ownerName, required String businessName, required String clientName, required String serviceName, required DateTime startTime, String? reason}) =>
      _invoke('reservation_cancelled_business', ownerPhone, {'recipientName':ownerName,'businessName':businessName,'clientName':clientName,'serviceName':serviceName,'date':_fd(startTime),'time':_ft(startTime),'reason':reason??''});

  static Future<void> enviarRecordatorio24h({required String? clientPhone, required String clientName, required String businessName, required String serviceName, required DateTime startTime, String? address}) =>
      _invoke('reservation_reminder_24h', clientPhone, {'recipientName':clientName,'businessName':businessName,'serviceName':serviceName,'date':_fd(startTime),'time':_ft(startTime),'address':address??''});
}
