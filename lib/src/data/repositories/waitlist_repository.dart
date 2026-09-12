import 'package:reservpy/src/core/supabase/supabase_config.dart';
import 'package:reservpy/src/shared/models/models.dart';
import 'package:reservpy/src/data/services/whatsapp_service.dart';

/// Lista de espera con relleno automático de cancelaciones (12/9/2026).
///
/// Cómo funciona: un cliente se anota para un negocio + fecha (opcionalmente
/// un servicio puntual). Cuando `ReservationRepository.updateStatus` cancela
/// un turno, llama a [tryFillFromCancellation], que busca al primero en la
/// fila para ese negocio+fecha y le avisa por WhatsApp que el horario quedó
/// libre. Tiene [ventanaConfirmacion] para entrar a la app y confirmarlo
/// ([confirm]) o rechazarlo ([decline]); si no contesta a tiempo,
/// [expireStaleNotifications] lo vence y se lo ofrece al siguiente.
///
/// No hay un scheduler en el servidor (ni acá ni en el resto del proyecto),
/// así que el vencimiento se chequea de forma "perezosa": cada vez que se
/// intenta rellenar una cancelación nueva para ese negocio, y cada vez que el
/// cliente o el negocio abren su pantalla de lista de espera. Si nadie abre
/// la app y no hay más cancelaciones ese día, una notificación vencida puede
/// tardar en liberarse — aceptable para el alcance actual; si se necesita
/// que sea puntual sin depender de que alguien abra la app, el mismo patrón
/// de GitHub Actions + endpoint protegido que se usó para los vencimientos
/// de ViaBarcazas serviría acá también.
class WaitlistRepository {
  final _client = SupabaseConfig.client;

  static const ventanaConfirmacion = Duration(hours: 2);

  static String _dateOnly(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  /// Anotarse en la lista de espera de un negocio para una fecha.
  Future<WaitlistEntry> join({
    required String businessId,
    required String clientId,
    String? serviceId,
    required DateTime preferredDate,
  }) async {
    final data = await _client
        .from('waitlist')
        .insert({
          'business_id': businessId,
          'client_id': clientId,
          'service_id': serviceId,
          'preferred_date': _dateOnly(preferredDate),
          'status': 'waiting',
        })
        .select('*, services(name), businesses(name)')
        .single();
    return WaitlistEntry.fromJson(data);
  }

  /// Anotaciones activas (esperando o con turno ofrecido) de un cliente.
  Future<List<WaitlistEntry>> getByClient(String clientId) async {
    final data = await _client
        .from('waitlist')
        .select('*, services(name), businesses(name)')
        .eq('client_id', clientId)
        .inFilter('status', ['waiting', 'notified'])
        .order('created_at');
    return data.map((j) => WaitlistEntry.fromJson(j)).toList();
  }

  /// Anotaciones activas de un negocio (para que el dueño la vea).
  Future<List<WaitlistEntry>> getByBusiness(String businessId) async {
    final data = await _client
        .from('waitlist')
        .select('*, profiles!client_id(first_name, last_name, phone), services(name)')
        .eq('business_id', businessId)
        .inFilter('status', ['waiting', 'notified'])
        .order('created_at');
    return data.map((j) => WaitlistEntry.fromJson(j)).toList();
  }

  /// El cliente se baja de la lista de espera (todavía esperando).
  Future<void> leave(String id) async {
    await _client.from('waitlist').update({
      'status': 'cancelled',
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', id);
  }

  /// El cliente confirma el turno que se le ofreció: crea la reserva real y
  /// cierra la fila de lista de espera. Devuelve el id de la reserva creada.
  Future<String> confirm(WaitlistEntry entry) async {
    if (entry.notifiedStartTime == null || entry.notifiedEndTime == null) {
      throw StateError('Esta anotación no tiene un turno ofrecido para confirmar');
    }
    final reservation = await _client
        .from('reservations')
        .insert({
          'business_id': entry.businessId,
          'client_id': entry.clientId,
          'service_id': entry.serviceId,
          'start_time': entry.notifiedStartTime!.toIso8601String(),
          'end_time': entry.notifiedEndTime!.toIso8601String(),
          'status': 'confirmed',
        })
        .select('id')
        .single();
    final reservationId = reservation['id'] as String;
    await _client.from('waitlist').update({
      'status': 'booked',
      'reservation_id': reservationId,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', entry.id);
    return reservationId;
  }

  /// El cliente rechaza el turno ofrecido (deja el slot libre para el
  /// siguiente en la fila la próxima vez que se chequee).
  Future<void> decline(String id) async {
    await _client.from('waitlist').update({
      'status': 'cancelled',
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', id);
  }

  /// Se llama al cancelarse un turno. Busca al primero en espera para ese
  /// negocio+fecha (prioriza a quien pidió el mismo servicio, si alguien lo
  /// hizo) y le ofrece el horario liberado por WhatsApp.
  Future<void> tryFillFromCancellation({
    required String businessId,
    required String? serviceId,
    required DateTime startTime,
    required DateTime endTime,
    required String businessName,
  }) async {
    // Primero liberar cualquier notificación vencida de este negocio, para
    // no dejar el slot "reservado" para alguien que ya no va a contestar.
    await expireStaleNotifications(businessId, businessName: businessName);

    final candidates = await _client
        .from('waitlist')
        .select('id, service_id, client_id, profiles!client_id(first_name, last_name, phone)')
        .eq('business_id', businessId)
        .eq('preferred_date', _dateOnly(startTime))
        .eq('status', 'waiting')
        .order('created_at')
        .limit(30);

    if ((candidates as List).isEmpty) return;

    Map<String, dynamic>? pick;
    if (serviceId != null) {
      for (final c in candidates) {
        if (c['service_id'] == serviceId) {
          pick = c;
          break;
        }
      }
    }
    pick ??= candidates.first as Map<String, dynamic>;

    await _offer(pick, startTime: startTime, endTime: endTime, businessName: businessName);
  }

  /// Marca como 'notified' la fila [row] con el horario ofrecido y manda el
  /// WhatsApp correspondiente.
  Future<void> _offer(
    Map<String, dynamic> row, {
    required DateTime startTime,
    required DateTime endTime,
    required String businessName,
  }) async {
    final expiresAt = DateTime.now().add(ventanaConfirmacion);
    await _client.from('waitlist').update({
      'status': 'notified',
      'notified_start_time': startTime.toIso8601String(),
      'notified_end_time': endTime.toIso8601String(),
      'notify_expires_at': expiresAt.toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', row['id']);

    final profile = row['profiles'] as Map<String, dynamic>?;
    final phone = profile?['phone'] as String?;
    final name = profile != null ? '${profile['first_name']} ${profile['last_name']}' : 'Cliente';
    await WhatsAppService.enviarTurnoLiberado(
      clientPhone: phone,
      clientName: name,
      businessName: businessName,
      startTime: startTime,
      horasParaConfirmar: ventanaConfirmacion.inHours,
    );
  }

  /// Vence las notificaciones de este negocio cuyo plazo ya pasó y pasa el
  /// turno liberado al siguiente en la fila para esa misma fecha+servicio.
  Future<void> expireStaleNotifications(String businessId, {required String businessName}) async {
    final nowIso = DateTime.now().toIso8601String();
    final stale = await _client
        .from('waitlist')
        .select('id, preferred_date, service_id, notified_start_time, notified_end_time')
        .eq('business_id', businessId)
        .eq('status', 'notified')
        .lt('notify_expires_at', nowIso);

    for (final row in stale) {
      await _client.from('waitlist').update({
        'status': 'expired',
        'updated_at': nowIso,
      }).eq('id', row['id']);

      final startStr = row['notified_start_time'] as String?;
      final endStr = row['notified_end_time'] as String?;
      if (startStr == null || endStr == null) continue;
      final startTime = DateTime.parse(startStr);
      final endTime = DateTime.parse(endStr);
      final serviceId = row['service_id'] as String?;
      final preferredDate = row['preferred_date'] as String;

      // Buscar al siguiente en la fila para esa misma fecha (sin volver a
      // llamar a expireStaleNotifications — ya estamos dentro de ese barrido).
      final next = await _client
          .from('waitlist')
          .select('id, service_id, client_id, profiles!client_id(first_name, last_name, phone)')
          .eq('business_id', businessId)
          .eq('preferred_date', preferredDate)
          .eq('status', 'waiting')
          .order('created_at')
          .limit(30);

      if ((next as List).isEmpty) continue;
      Map<String, dynamic>? pick;
      if (serviceId != null) {
        for (final c in next) {
          if (c['service_id'] == serviceId) {
            pick = c;
            break;
          }
        }
      }
      pick ??= next.first as Map<String, dynamic>;
      await _offer(pick, startTime: startTime, endTime: endTime, businessName: businessName);
    }
  }
}
