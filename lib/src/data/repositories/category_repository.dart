import 'package:reservpy/src/core/supabase/supabase_config.dart';
import 'package:reservpy/src/shared/models/models.dart';

class CategoryRepository {
  final _client = SupabaseConfig.client;

  /// Get all categories
  Future<List<BusinessCategory>> getAll() async {
    final data = await _client
        .from('categories')
        .select()
        .order('sort_order');
    return data.map((json) => BusinessCategory.fromJson(json)).toList();
  }

  /// Create a new category
  Future<BusinessCategory> create(String name, {String icon = 'category', String color = '#00C896'}) async {
    final data = await _client
        .from('categories')
        .insert({'name': name, 'icon': icon, 'color': color, 'sort_order': 50})
        .select()
        .single();
    return BusinessCategory.fromJson(data);
  }

  /// Check if category exists by name
  Future<bool> existsByName(String name) async {
    final data = await _client
        .from('categories')
        .select('id')
        .ilike('name', name)
        .maybeSingle();
    return data != null;
  }
}
