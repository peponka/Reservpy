import 'package:reservpy/src/core/supabase/supabase_config.dart';
import 'package:reservpy/src/shared/models/models.dart';

class ReviewRepository {
  final _client = SupabaseConfig.client;

  /// Fetch all reviews for a business, newest first.
  Future<List<Review>> fetchForBusiness(String businessId) async {
    final data = await _client
        .from('reviews')
        .select('*, profiles!client_id(first_name, last_name)')
        .eq('business_id', businessId)
        .order('created_at', ascending: false)
        .limit(50);
    return data.map((json) {
      final profile = json['profiles'] as Map<String, dynamic>?;
      final clientName = profile != null
          ? '${profile['first_name'] ?? ''} ${profile['last_name'] ?? ''}'.trim()
          : null;
      return Review.fromJson({...json, 'client_name': clientName});
    }).toList();
  }

  /// Check if user already reviewed a specific reservation.
  Future<bool> hasReviewed(String clientId, String businessId, {String? reservationId}) async {
    var query = _client
        .from('reviews')
        .select('id')
        .eq('client_id', clientId)
        .eq('business_id', businessId);
    if (reservationId != null) {
      query = query.eq('reservation_id', reservationId);
    }
    final data = await query.limit(1);
    return data.isNotEmpty;
  }

  /// Create a new review.
  Future<void> create({
    required String businessId,
    required String clientId,
    String? reservationId,
    required int rating,
    String comment = '',
  }) async {
    await _client.from('reviews').insert({
      'business_id': businessId,
      'client_id': clientId,
      'reservation_id': reservationId,
      'rating': rating,
      'comment': comment,
    });
  }
}
