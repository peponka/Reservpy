import 'package:reservpy/src/core/supabase/supabase_config.dart';
import 'package:reservpy/src/shared/models/models.dart';

class ProfileRepository {
  final _client = SupabaseConfig.client;

  /// Get profile by user ID
  Future<AppUser?> getProfile(String userId) async {
    final data = await _client
        .from('profiles')
        .select()
        .eq('id', userId)
        .maybeSingle();
    if (data == null) return null;
    return AppUser.fromJson(data);
  }

  /// Update profile
  Future<void> updateProfile(AppUser user) async {
    await _client
        .from('profiles')
        .update(user.toJson())
        .eq('id', user.id);
  }

  /// Update role
  Future<void> updateRole(String userId, String role) async {
    await _client
        .from('profiles')
        .update({'role': role})
        .eq('id', userId);
  }

  /// Upsert profile (create if not exists, update if exists)
  Future<void> upsert(AppUser user) async {
    await _client
        .from('profiles')
        .upsert(user.toJson());
  }
}
