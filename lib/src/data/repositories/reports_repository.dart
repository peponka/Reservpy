import 'package:reservpy/src/core/supabase/supabase_config.dart';
import 'package:reservpy/src/shared/models/models.dart';

/// Data class holding all reports metrics for a business.
class ReportsData {
  final List<Reservation> reservations;
  final List<ServiceModel> services;

  const ReportsData({
    required this.reservations,
    required this.services,
  });
}

/// Repository that fetches reports data from Supabase.
class ReportsRepository {
  final _client = SupabaseConfig.client;

  /// Fetch all reservations for a business within a date range,
  /// along with joined client/service names.
  Future<ReportsData> getReportsData({
    required String businessId,
    required DateTime from,
    required DateTime to,
  }) async {
    // Fetch reservations in the period with joined names
    final reservationData = await _client
        .from('reservations')
        .select(
            '*, profiles!client_id(first_name, last_name), services(name)')
        .eq('business_id', businessId)
        .gte('start_time', from.toIso8601String())
        .lte('start_time', to.toIso8601String())
        .order('start_time', ascending: false);

    final reservations =
        reservationData.map((json) => Reservation.fromJson(json)).toList();

    // Fetch all services for the business
    final serviceData = await _client
        .from('services')
        .select()
        .eq('business_id', businessId)
        .order('sort_order');

    final services =
        serviceData.map((json) => ServiceModel.fromJson(json)).toList();

    return ReportsData(
      reservations: reservations,
      services: services,
    );
  }
}
