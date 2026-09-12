import 'package:reservpy/src/core/supabase/supabase_config.dart';
import 'package:reservpy/src/shared/models/models.dart';

class ClientPrivateNoteRepository {
  final _client = SupabaseConfig.client;

  Future<ClientPrivateNote?> getNote(String businessId, String clientId) async {
    final data = await _client
        .from('business_client_notes')
        .select()
        .eq('business_id', businessId)
        .eq('client_id', clientId)
        .maybeSingle();
    if (data == null) return null;
    return ClientPrivateNote.fromJson(data);
  }

  Future<void> saveNote({
    required String businessId,
    required String clientId,
    required String note,
  }) async {
    await _client.from('business_client_notes').upsert({
      'business_id': businessId,
      'client_id': clientId,
      'note': note,
      'updated_at': DateTime.now().toIso8601String(),
    }, onConflict: 'business_id,client_id');
  }

  Future<void> deleteNote(String businessId, String clientId) async {
    await _client
        .from('business_client_notes')
        .delete()
        .eq('business_id', businessId)
        .eq('client_id', clientId);
  }
}
