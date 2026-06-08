import 'package:reservpy/src/core/supabase/supabase_config.dart';
import 'package:reservpy/src/shared/models/models.dart';

/// Admin-only repository for platform-wide statistics and management.
class AdminRepository {
  final _client = SupabaseConfig.client;

  // ── Stats ──────────────────────────────────────────────

  Future<int> getTotalBusinesses() async {
    final data = await _client.from('businesses').select('id');
    return (data as List).length;
  }

  Future<int> getActiveBusinesses() async {
    final data = await _client.from('businesses').select('id').eq('is_active', true);
    return (data as List).length;
  }

  Future<int> getTotalUsers() async {
    final data = await _client.from('profiles').select('id');
    return (data as List).length;
  }

  Future<int> getTotalReservations() async {
    final data = await _client.from('reservations').select('id');
    return (data as List).length;
  }

  Future<int> getReservationsThisMonth() async {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, 1).toIso8601String();
    final data = await _client
        .from('reservations')
        .select('id')
        .gte('start_time', start);
    return (data as List).length;
  }

  Future<Map<String, int>> getBusinessesByPlan() async {
    final data = await _client.from('businesses').select('plan');
    final counts = <String, int>{};
    for (final row in (data as List)) {
      final plan = row['plan'] as String? ?? 'free';
      counts[plan] = (counts[plan] ?? 0) + 1;
    }
    return counts;
  }

  // ── Businesses ────────────────────────────────────────

  Future<List<Business>> getAllBusinessesAdmin() async {
    final data = await _client
        .from('businesses')
        .select()
        .order('created_at', ascending: false);
    return data.map((json) => Business.fromJson(json)).toList();
  }

  Future<void> setBusinessActive(String id, bool active) async {
    await _client.from('businesses').update({'is_active': active}).eq('id', id);
  }

  // ── Users ─────────────────────────────────────────────

  Future<List<AppUser>> getAllUsers() async {
    final data = await _client
        .from('profiles')
        .select()
        .order('created_at', ascending: false);
    return data.map((json) => AppUser.fromJson(json)).toList();
  }

  // ── Recent activity ───────────────────────────────────

  Future<List<Map<String, dynamic>>> getRecentReservations({int limit = 10}) async {
    final data = await _client
        .from('reservations')
        .select('id, start_time, status, business_id, user_id')
        .order('created_at', ascending: false)
        .limit(limit);
    return List<Map<String, dynamic>>.from(data as List);
  }
}
