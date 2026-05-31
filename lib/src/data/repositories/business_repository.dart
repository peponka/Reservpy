import 'package:reservpy/src/core/supabase/supabase_config.dart';
import 'package:reservpy/src/shared/models/models.dart';
import 'package:reservpy/src/data/repositories/profile_repository.dart';
import 'package:reservpy/src/data/services/email_service.dart';

class BusinessRepository {
  final _client = SupabaseConfig.client;

  /// Get all active businesses
  Future<List<Business>> getAllBusinesses() async {
    final data = await _client
        .from('businesses')
        .select()
        .eq('is_active', true)
        .order('created_at', ascending: false);
    return data.map((json) => Business.fromJson(json)).toList();
  }

  /// Get businesses by category
  Future<List<Business>> getByCategory(String categoryId) async {
    final data = await _client
        .from('businesses')
        .select()
        .eq('category_id', categoryId)
        .eq('is_active', true);
    return data.map((json) => Business.fromJson(json)).toList();
  }

  /// Get business by ID
  Future<Business?> getById(String id) async {
    final data = await _client
        .from('businesses')
        .select()
        .eq('id', id)
        .maybeSingle();
    if (data == null) return null;
    return Business.fromJson(data);
  }

  /// Get businesses owned by user
  Future<List<Business>> getByOwner(String ownerId) async {
    final data = await _client
        .from('businesses')
        .select()
        .eq('owner_id', ownerId)
        .order('created_at', ascending: false);
    return data.map((json) => Business.fromJson(json)).toList();
  }

  /// Create business
  Future<Business> create(Business business) async {
    final data = await _client
        .from('businesses')
        .insert(business.toJson())
        .select()
        .single();
    final created = Business.fromJson(data);

    // ── Send confirmation email to owner (fire-and-forget) ──
    ProfileRepository().getProfile(created.ownerId).then((owner) {
      if (owner != null && owner.email.isNotEmpty) {
        EmailService.enviarEmailConfirmacionNegocio(
          ownerEmail: owner.email,
          ownerName: owner.fullName,
          businessName: created.name,
          address: created.address,
        );
      }
    }).catchError((_) {});

    return created;
  }

  /// Update business
  Future<void> update(Business business) async {
    await _client
        .from('businesses')
        .update(business.toJson())
        .eq('id', business.id);
  }

  /// Delete business
  Future<void> delete(String id) async {
    await _client.from('businesses').delete().eq('id', id);
  }

  /// Upgrade business to Pro plan
  Future<void> upgradeToPro(String businessId) async {
    await _client.from('businesses').update({
      'plan': 'pro',
      'plan_activated_at': DateTime.now().toIso8601String(),
    }).eq('id', businessId);
  }

  /// Downgrade business to Free plan
  Future<void> downgradeToFree(String businessId) async {
    await _client.from('businesses').update({
      'plan': 'free',
      'plan_activated_at': null,
    }).eq('id', businessId);
  }
}
