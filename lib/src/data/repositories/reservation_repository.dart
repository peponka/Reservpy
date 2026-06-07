import 'package:reservpy/src/core/supabase/supabase_config.dart';
import 'package:reservpy/src/shared/models/models.dart';

class ReservationRepository {
  final _client = SupabaseConfig.client;

  /// Get reservations for a business (with joined client/service names)
  Future<List<Reservation>> getByBusiness(String businessId) async {
    final data = await _client
        .from('reservations')
        .select('*, profiles!client_id(first_name, last_name), services(name), businesses(name), is_manual, manual_client_name, manual_client_phone')
        .eq('business_id', businessId)
        .order('start_time', ascending: false);
    return data.map((json) => Reservation.fromJson(json)).toList();
  }

  /// Get reservations for a client
  Future<List<Reservation>> getByClient(String clientId) async {
    final data = await _client
        .from('reservations')
        .select('*, services(name), businesses(name)')
        .eq('client_id', clientId)
        .order('start_time', ascending: false);
    return data.map((json) => Reservation.fromJson(json)).toList();
  }

  /// Get reservations for a business on a specific date
  Future<List<Reservation>> getByBusinessAndDate(String businessId, DateTime date) async {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    final data = await _client
        .from('reservations')
        .select('*, profiles!client_id(first_name, last_name), services(name), is_manual, manual_client_name, manual_client_phone')
        .eq('business_id', businessId)
        .gte('start_time', startOfDay.toIso8601String())
        .lt('start_time', endOfDay.toIso8601String())
        .order('start_time');
    return data.map((json) => Reservation.fromJson(json)).toList();
  }

  /// Create reservation
  Future<Reservation> create(Reservation reservation) async {
    final data = await _client
        .from('reservations')
        .insert(reservation.toJson())
        .select('*, profiles!client_id(first_name, last_name), services(name), businesses(name), is_manual, manual_client_name, manual_client_phone')
        .single();
    return Reservation.fromJson(data);
  }

  /// Update status
  Future<void> updateStatus(String id, String status, {String? cancellationReason}) async {
    final updates = <String, dynamic>{'status': status, 'updated_at': DateTime.now().toIso8601String()};
    if (cancellationReason != null) updates['cancellation_reason'] = cancellationReason;
    await _client.from('reservations').update(updates).eq('id', id);
  }

  /// Check if a time slot is available
  Future<bool> isSlotAvailable(String businessId, DateTime startTime, DateTime endTime) async {
    final data = await _client
        .from('reservations')
        .select('id')
        .eq('business_id', businessId)
        .neq('status', 'cancelled')
        .lt('start_time', endTime.toIso8601String())
        .gt('end_time', startTime.toIso8601String());
    return (data as List).isEmpty;
  }
}
