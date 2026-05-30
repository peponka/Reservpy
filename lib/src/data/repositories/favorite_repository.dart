import 'package:reservpy/src/core/supabase/supabase_config.dart';

class FavoriteRepository {
  final _client = SupabaseConfig.client;

  /// Get all favorite business IDs for the current user.
  Future<List<String>> fetchFavoriteIds(String userId) async {
    final data = await _client
        .from('favorites')
        .select('business_id')
        .eq('client_id', userId);
    return data.map<String>((r) => r['business_id'] as String).toList();
  }

  /// Toggle favorite - returns true if added, false if removed.
  Future<bool> toggle(String userId, String businessId) async {
    final existing = await _client
        .from('favorites')
        .select('id')
        .eq('client_id', userId)
        .eq('business_id', businessId)
        .limit(1);

    if (existing.isNotEmpty) {
      await _client
          .from('favorites')
          .delete()
          .eq('client_id', userId)
          .eq('business_id', businessId);
      return false;
    } else {
      await _client.from('favorites').insert({
        'client_id': userId,
        'business_id': businessId,
      });
      return true;
    }
  }
}
