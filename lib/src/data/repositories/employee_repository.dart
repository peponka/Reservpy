import 'package:reservpy/src/core/supabase/supabase_config.dart';
import 'package:reservpy/src/shared/models/employee.dart';

class EmployeeRepository {
  final _client = SupabaseConfig.client;

  /// Get all employees for a business, ordered by name.
  Future<List<Employee>> getByBusiness(String businessId) async {
    final data = await _client
        .from('employees')
        .select()
        .eq('business_id', businessId)
        .order('name');
    return data.map((json) => Employee.fromJson(json)).toList();
  }

  /// Get only active employees for a business.
  Future<List<Employee>> getActiveByBusiness(String businessId) async {
    final data = await _client
        .from('employees')
        .select()
        .eq('business_id', businessId)
        .eq('is_active', true)
        .order('name');
    return data.map((json) => Employee.fromJson(json)).toList();
  }

  /// Create a new employee and return it with the generated id.
  Future<Employee> create(Employee employee) async {
    final data = await _client
        .from('employees')
        .insert(employee.toJson())
        .select()
        .single();
    return Employee.fromJson(data);
  }

  /// Update an existing employee.
  Future<void> update(Employee employee) async {
    await _client
        .from('employees')
        .update(employee.toJson())
        .eq('id', employee.id);
  }

  /// Delete an employee by id.
  Future<void> delete(String id) async {
    await _client.from('employees').delete().eq('id', id);
  }

  /// Toggle the is_active flag on an employee.
  Future<void> toggleActive(String id, bool isActive) async {
    await _client
        .from('employees')
        .update({'is_active': isActive})
        .eq('id', id);
  }
}
