import 'package:reservpy/src/core/supabase/supabase_config.dart';
import 'package:reservpy/src/shared/models/models.dart';

class BlockedSlotRepository {
  final _client = SupabaseConfig.client;

  /// Get all blocked slots for a business
  Future<List<BlockedSlot>> getByBusiness(String businessId) async {
    final data = await _client
        .from('blocked_slots')
        .select()
        .eq('business_id', businessId)
        .order('start_time', ascending: true);
    return data.map((json) => BlockedSlot.fromJson(json)).toList();
  }

  /// Create a blocked slot
  Future<BlockedSlot> create(BlockedSlot slot) async {
    final data = await _client
        .from('blocked_slots')
        .insert(slot.toJson())
        .select()
        .single();
    return BlockedSlot.fromJson(data);
  }

  /// Delete a blocked slot
  Future<void> delete(String id) async {
    await _client.from('blocked_slots').delete().eq('id', id);
  }
}
