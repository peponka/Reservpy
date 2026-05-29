import 'package:reservpy/src/core/supabase/supabase_config.dart';
import 'package:reservpy/src/shared/models/models.dart';

class ServiceRepository {
  final _client = SupabaseConfig.client;

  /// Get services for a business
  Future<List<ServiceModel>> getByBusiness(String businessId) async {
    final data = await _client
        .from('services')
        .select()
        .eq('business_id', businessId)
        .order('sort_order');
    return data.map((json) => ServiceModel.fromJson(json)).toList();
  }

  /// Get active services for a business
  Future<List<ServiceModel>> getActiveByBusiness(String businessId) async {
    final data = await _client
        .from('services')
        .select()
        .eq('business_id', businessId)
        .eq('is_active', true)
        .order('sort_order');
    return data.map((json) => ServiceModel.fromJson(json)).toList();
  }

  /// Create service
  Future<ServiceModel> create(ServiceModel service) async {
    final data = await _client
        .from('services')
        .insert(service.toJson())
        .select()
        .single();
    return ServiceModel.fromJson(data);
  }

  /// Update service
  Future<void> update(ServiceModel service) async {
    await _client
        .from('services')
        .update(service.toJson())
        .eq('id', service.id);
  }

  /// Delete service
  Future<void> delete(String id) async {
    await _client.from('services').delete().eq('id', id);
  }

  /// Toggle active status
  Future<void> toggleActive(String id, bool isActive) async {
    await _client
        .from('services')
        .update({'is_active': isActive})
        .eq('id', id);
  }
}
