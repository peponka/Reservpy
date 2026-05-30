import 'package:reservpy/src/core/supabase/supabase_config.dart';

class Promotion {
  final String id;
  final String businessId;
  final String title;
  final String description;
  final int discountPercent;
  final DateTime? validFrom;
  final DateTime? validTo;
  final bool isActive;
  final DateTime createdAt;

  const Promotion({
    required this.id,
    required this.businessId,
    required this.title,
    this.description = '',
    required this.discountPercent,
    this.validFrom,
    this.validTo,
    this.isActive = true,
    required this.createdAt,
  });

  factory Promotion.fromJson(Map<String, dynamic> json) => Promotion(
    id: json['id'] as String,
    businessId: json['business_id'] as String,
    title: json['title'] as String,
    description: json['description'] as String? ?? '',
    discountPercent: json['discount_percent'] as int,
    validFrom: json['valid_from'] != null ? DateTime.parse(json['valid_from'] as String) : null,
    validTo: json['valid_to'] != null ? DateTime.parse(json['valid_to'] as String) : null,
    isActive: json['is_active'] as bool? ?? true,
    createdAt: DateTime.parse(json['created_at'] as String),
  );

  bool get isCurrentlyValid {
    final now = DateTime.now();
    if (!isActive) return false;
    if (validFrom != null && now.isBefore(validFrom!)) return false;
    if (validTo != null && now.isAfter(validTo!.add(const Duration(days: 1)))) return false;
    return true;
  }
}

class PromotionRepository {
  final _client = SupabaseConfig.client;

  Future<List<Promotion>> fetchForBusiness(String businessId) async {
    final data = await _client
        .from('promotions')
        .select()
        .eq('business_id', businessId)
        .order('created_at', ascending: false);
    return data.map((json) => Promotion.fromJson(json)).toList();
  }

  Future<List<Promotion>> fetchActiveForBusiness(String businessId) async {
    final all = await fetchForBusiness(businessId);
    return all.where((p) => p.isCurrentlyValid).toList();
  }

  Future<void> create({
    required String businessId,
    required String title,
    String description = '',
    required int discountPercent,
    DateTime? validFrom,
    DateTime? validTo,
  }) async {
    await _client.from('promotions').insert({
      'business_id': businessId,
      'title': title,
      'description': description,
      'discount_percent': discountPercent,
      'valid_from': validFrom?.toIso8601String().split('T').first,
      'valid_to': validTo?.toIso8601String().split('T').first,
    });
  }

  Future<void> toggleActive(String id, bool isActive) async {
    await _client.from('promotions').update({'is_active': isActive}).eq('id', id);
  }

  Future<void> delete(String id) async {
    await _client.from('promotions').delete().eq('id', id);
  }
}
