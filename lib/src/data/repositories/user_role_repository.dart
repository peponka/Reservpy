import 'package:reservpy/src/core/supabase/supabase_config.dart';
import 'package:reservpy/src/shared/models/models.dart';

/// Repository for managing user roles in the user_roles table.
class UserRoleRepository {
  final _client = SupabaseConfig.client;

  /// Get all roles for a user
  Future<List<UserRole>> getRoles(String userId) async {
    try {
      final data = await _client
          .from('user_roles')
          .select('role')
          .eq('user_id', userId);
      return data
          .map((row) => UserRole.fromDbString(row['role'] as String?))
          .where((r) => r != UserRole.business) // normalize to businessOwner
          .toList();
    } catch (_) {
      // Fallback: if user_roles table doesn't exist yet, return from profile
      return [UserRole.client];
    }
  }

  /// Add a role to a user
  Future<void> addRole(String userId, UserRole role) async {
    await _client
        .from('user_roles')
        .upsert({
          'user_id': userId,
          'role': role.dbValue,
        });
  }

  /// Add multiple roles to a user
  Future<void> addRoles(String userId, List<UserRole> roles) async {
    final rows = roles.map((r) => {
      'user_id': userId,
      'role': r.dbValue,
    }).toList();
    await _client.from('user_roles').upsert(rows);
  }

  /// Check if user has a specific role
  Future<bool> hasRole(String userId, UserRole role) async {
    final data = await _client
        .from('user_roles')
        .select('id')
        .eq('user_id', userId)
        .eq('role', role.dbValue)
        .maybeSingle();
    return data != null;
  }

  /// Remove a role from a user
  Future<void> removeRole(String userId, UserRole role) async {
    await _client
        .from('user_roles')
        .delete()
        .eq('user_id', userId)
        .eq('role', role.dbValue);
  }
}
