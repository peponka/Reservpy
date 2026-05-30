import 'dart:typed_data';
import 'package:reservpy/src/core/supabase/supabase_config.dart';

class BusinessPhoto {
  final String id;
  final String businessId;
  final String url;
  final String caption;
  final int sortOrder;
  final DateTime createdAt;

  const BusinessPhoto({
    required this.id,
    required this.businessId,
    required this.url,
    this.caption = '',
    this.sortOrder = 0,
    required this.createdAt,
  });

  factory BusinessPhoto.fromJson(Map<String, dynamic> json) => BusinessPhoto(
    id: json['id'] as String,
    businessId: json['business_id'] as String,
    url: json['url'] as String,
    caption: json['caption'] as String? ?? '',
    sortOrder: json['sort_order'] as int? ?? 0,
    createdAt: DateTime.parse(json['created_at'] as String),
  );
}

class BusinessPhotoRepository {
  final _client = SupabaseConfig.client;

  /// Fetch all photos for a business.
  Future<List<BusinessPhoto>> fetchPhotos(String businessId) async {
    final data = await _client
        .from('business_photos')
        .select()
        .eq('business_id', businessId)
        .order('sort_order')
        .order('created_at');
    return data.map((json) => BusinessPhoto.fromJson(json)).toList();
  }

  /// Upload a photo to Supabase Storage and insert a record.
  Future<BusinessPhoto> uploadPhoto({
    required String businessId,
    required Uint8List bytes,
    required String fileName,
  }) async {
    final path = 'business-photos/$businessId/${DateTime.now().millisecondsSinceEpoch}_$fileName';
    
    await _client.storage
        .from('business-photos')
        .uploadBinary(path, bytes);

    final url = _client.storage
        .from('business-photos')
        .getPublicUrl(path);

    final data = await _client.from('business_photos').insert({
      'business_id': businessId,
      'url': url,
    }).select().single();

    return BusinessPhoto.fromJson(data);
  }

  /// Delete a photo from Storage and database.
  Future<void> deletePhoto(BusinessPhoto photo) async {
    // Extract storage path from public URL
    final uri = Uri.parse(photo.url);
    final pathSegments = uri.pathSegments;
    final bucketIndex = pathSegments.indexOf('business-photos');
    if (bucketIndex >= 0) {
      final storagePath = pathSegments.sublist(bucketIndex + 1).join('/');
      await _client.storage
          .from('business-photos')
          .remove([storagePath]);
    }
    
    await _client
        .from('business_photos')
        .delete()
        .eq('id', photo.id);
  }
}
