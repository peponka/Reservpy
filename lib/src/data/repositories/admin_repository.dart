import 'package:reservpy/src/core/supabase/supabase_config.dart';
import 'package:reservpy/src/shared/models/models.dart';

// ── Plan prices in Guaraníes ──────────────────────────────────────────────────
const kPlanPrices = <String, int>{
  'free':       0,
  'basic':      25000,
  'pro':        75000,
  'enterprise': 200000,
};

// ── Models ────────────────────────────────────────────────────────────────────

class AdminStats {
  const AdminStats({
    required this.totalBusinesses,
    required this.activeBusinesses,
    required this.inactiveBusinesses,
    required this.newBusinessesToday,
    required this.newBusinessesThisMonth,
    required this.totalUsers,
    required this.newUsersToday,
    required this.newUsersThisMonth,
    required this.totalReservations,
    required this.reservationsToday,
    required this.reservationsThisMonth,
    required this.completedReservations,
    required this.cancelledReservations,
    required this.businessesByPlan,
    required this.mrr,
    required this.arr,
  });

  final int totalBusinesses;
  final int activeBusinesses;
  final int inactiveBusinesses;
  final int newBusinessesToday;
  final int newBusinessesThisMonth;
  final int totalUsers;
  final int newUsersToday;
  final int newUsersThisMonth;
  final int totalReservations;
  final int reservationsToday;
  final int reservationsThisMonth;
  final int completedReservations;
  final int cancelledReservations;
  final Map<String, int> businessesByPlan;
  final int mrr;  // Monthly Recurring Revenue in PYG
  final int arr;  // Annual Recurring Revenue in PYG

  double get churnRatePercent => totalBusinesses > 0
      ? (inactiveBusinesses / totalBusinesses * 100)
      : 0.0;

  double get avgTicketPyg => totalReservations > 0
      ? mrr / (totalReservations > 0 ? totalReservations : 1)
      : 0.0;
}

class AuditLog {
  const AuditLog({
    required this.id,
    required this.userId,
    required this.userEmail,
    required this.action,
    this.entityType,
    this.entityId,
    this.entityName,
    this.details,
    required this.createdAt,
  });

  final String id;
  final String? userId;
  final String? userEmail;
  final String action;
  final String? entityType;
  final String? entityId;
  final String? entityName;
  final Map<String, dynamic>? details;
  final DateTime createdAt;

  factory AuditLog.fromJson(Map<String, dynamic> json) => AuditLog(
    id:         json['id'] as String,
    userId:     json['user_id'] as String?,
    userEmail:  json['user_email'] as String?,
    action:     json['action'] as String,
    entityType: json['entity_type'] as String?,
    entityId:   json['entity_id'] as String?,
    entityName: json['entity_name'] as String?,
    details:    json['details'] as Map<String, dynamic>?,
    createdAt:  DateTime.parse(json['created_at'] as String),
  );
}

class AdminTeamMember {
  const AdminTeamMember({
    required this.id,
    required this.userId,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.adminRole,
    required this.permissions,
    required this.isActive,
    this.lastLogin,
    required this.createdAt,
  });

  final String id;
  final String userId;
  final String email;
  final String firstName;
  final String lastName;
  final String adminRole; // super_admin | admin | manager | operator | support
  final Map<String, dynamic> permissions;
  final bool isActive;
  final DateTime? lastLogin;
  final DateTime createdAt;

  String get fullName => '$firstName $lastName'.trim();
  String get initials =>
      '${firstName.isNotEmpty ? firstName[0] : ''}${lastName.isNotEmpty ? lastName[0] : ''}'.toUpperCase();

  factory AdminTeamMember.fromJson(Map<String, dynamic> json) => AdminTeamMember(
    id:         json['id'] as String,
    userId:     json['user_id'] as String,
    email:      json['email'] as String,
    firstName:  json['first_name'] as String? ?? '',
    lastName:   json['last_name'] as String? ?? '',
    adminRole:  json['admin_role'] as String? ?? 'operator',
    permissions: (json['permissions'] as Map<String, dynamic>?) ?? {},
    isActive:   json['is_active'] as bool? ?? true,
    lastLogin:  json['last_login'] != null ? DateTime.parse(json['last_login'] as String) : null,
    createdAt:  DateTime.parse(json['created_at'] as String),
  );
}

class BusinessBilling {
  const BusinessBilling({
    required this.id,
    required this.businessId,
    required this.plan,
    required this.status,
    required this.amountGuaranies,
    required this.billingCycle,
    required this.startedAt,
    this.nextBillingAt,
    this.cancelledAt,
    this.notes,
  });

  final String id;
  final String businessId;
  final String plan;
  final String status; // active | pending | overdue | suspended | cancelled
  final int amountGuaranies;
  final String billingCycle;
  final DateTime startedAt;
  final DateTime? nextBillingAt;
  final DateTime? cancelledAt;
  final String? notes;

  bool get isOverdue => nextBillingAt != null && nextBillingAt!.isBefore(DateTime.now()) && status != 'cancelled';
  bool get expiresIn7Days => nextBillingAt != null &&
      nextBillingAt!.isAfter(DateTime.now()) &&
      nextBillingAt!.isBefore(DateTime.now().add(const Duration(days: 7)));
  bool get expiresIn3Days => nextBillingAt != null &&
      nextBillingAt!.isAfter(DateTime.now()) &&
      nextBillingAt!.isBefore(DateTime.now().add(const Duration(days: 3)));

  factory BusinessBilling.fromJson(Map<String, dynamic> json) => BusinessBilling(
    id:               json['id'] as String,
    businessId:       json['business_id'] as String,
    plan:             json['plan'] as String? ?? 'free',
    status:           json['status'] as String? ?? 'active',
    amountGuaranies:  json['amount_guaranies'] as int? ?? 0,
    billingCycle:     json['billing_cycle'] as String? ?? 'monthly',
    startedAt:        DateTime.parse(json['started_at'] as String),
    nextBillingAt:    json['next_billing_at'] != null
        ? DateTime.parse(json['next_billing_at'] as String) : null,
    cancelledAt:      json['cancelled_at'] != null
        ? DateTime.parse(json['cancelled_at'] as String) : null,
    notes:            json['notes'] as String?,
  );
}

// ── Repository ────────────────────────────────────────────────────────────────

class AdminRepository {
  final _client = SupabaseConfig.client;

  // ── Stats ──────────────────────────────────────────────────────────────────

  Future<AdminStats> getStats() async {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day).toIso8601String();
    final monthStart = DateTime(now.year, now.month, 1).toIso8601String();

    final results = await Future.wait([
      _client.from('businesses').select('id, is_active, plan, created_at'),
      _client.from('profiles').select('id, created_at'),
      _client.from('reservations').select('id, status, start_time, created_at'),
    ]);

    final businesses = List<Map<String, dynamic>>.from(results[0] as List);
    final users      = List<Map<String, dynamic>>.from(results[1] as List);
    final reservs    = List<Map<String, dynamic>>.from(results[2] as List);

    // Business stats
    final activeB   = businesses.where((b) => b['is_active'] == true).length;
    final newToday  = businesses.where((b) => (b['created_at'] as String).compareTo(todayStart) >= 0).length;
    final newMonth  = businesses.where((b) => (b['created_at'] as String).compareTo(monthStart) >= 0).length;

    // Plan counts & MRR
    final planCounts = <String, int>{};
    for (final b in businesses) {
      final plan = b['plan'] as String? ?? 'free';
      planCounts[plan] = (planCounts[plan] ?? 0) + 1;
    }
    var mrr = 0;
    for (final entry in planCounts.entries) {
      mrr += (kPlanPrices[entry.key] ?? 0) * entry.value;
    }

    // User stats
    final newUsersToday  = users.where((u) => (u['created_at'] as String).compareTo(todayStart) >= 0).length;
    final newUsersMonth  = users.where((u) => (u['created_at'] as String).compareTo(monthStart) >= 0).length;

    // Reservation stats
    final totalR     = reservs.length;
    final todayR     = reservs.where((r) {
      final st = r['start_time'] as String? ?? r['created_at'] as String? ?? '';
      return st.compareTo(todayStart) >= 0;
    }).length;
    final monthR     = reservs.where((r) {
      final st = r['start_time'] as String? ?? r['created_at'] as String? ?? '';
      return st.compareTo(monthStart) >= 0;
    }).length;
    final completedR = reservs.where((r) => r['status'] == 'completed').length;
    final cancelledR = reservs.where((r) => r['status'] == 'cancelled').length;

    return AdminStats(
      totalBusinesses:       businesses.length,
      activeBusinesses:      activeB,
      inactiveBusinesses:    businesses.length - activeB,
      newBusinessesToday:    newToday,
      newBusinessesThisMonth: newMonth,
      totalUsers:            users.length,
      newUsersToday:         newUsersToday,
      newUsersThisMonth:     newUsersMonth,
      totalReservations:     totalR,
      reservationsToday:     todayR,
      reservationsThisMonth: monthR,
      completedReservations: completedR,
      cancelledReservations: cancelledR,
      businessesByPlan:      planCounts,
      mrr:                   mrr,
      arr:                   mrr * 12,
    );
  }

  // ── Businesses ─────────────────────────────────────────────────────────────

  Future<List<Business>> getAllBusinessesAdmin() async {
    final data = await _client
        .from('businesses')
        .select()
        .order('created_at', ascending: false);
    return data.map((json) => Business.fromJson(json)).toList();
  }

  Future<void> setBusinessActive(String id, bool active) async {
    await _client.from('businesses').update({'is_active': active}).eq('id', id);
  }

  Future<void> changeBusinessPlan(String id, String plan) async {
    await _client.from('businesses').update({
      'plan': plan,
      'plan_activated_at': DateTime.now().toIso8601String(),
    }).eq('id', id);
  }

  // ── Users ──────────────────────────────────────────────────────────────────

  Future<List<AppUser>> getAllUsers() async {
    final data = await _client
        .from('profiles')
        .select()
        .order('created_at', ascending: false);
    return data.map((json) => AppUser.fromJson(json)).toList();
  }

  // ── Team ───────────────────────────────────────────────────────────────────

  Future<List<AdminTeamMember>> getTeamMembers() async {
    try {
      final data = await _client
          .from('admin_team_members')
          .select()
          .order('created_at', ascending: false);
      return data.map((json) => AdminTeamMember.fromJson(json)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> addTeamMember({
    required String userId,
    required String email,
    required String firstName,
    required String lastName,
    required String adminRole,
    required Map<String, dynamic> permissions,
  }) async {
    await _client.from('admin_team_members').upsert({
      'user_id':    userId,
      'email':      email,
      'first_name': firstName,
      'last_name':  lastName,
      'admin_role': adminRole,
      'permissions': permissions,
      'is_active':  true,
    });
    await _client.from('user_roles').upsert({'user_id': userId, 'role': 'admin'});
  }

  Future<void> updateTeamMember(String id, {
    String? adminRole,
    Map<String, dynamic>? permissions,
    bool? isActive,
  }) async {
    final update = <String, dynamic>{};
    if (adminRole != null)    update['admin_role']  = adminRole;
    if (permissions != null)  update['permissions'] = permissions;
    if (isActive != null)     update['is_active']   = isActive;
    await _client.from('admin_team_members').update(update).eq('id', id);
  }

  Future<void> deleteTeamMember(String id, String userId) async {
    await _client.from('admin_team_members').delete().eq('id', id);
    await _client.from('user_roles').delete().eq('user_id', userId).eq('role', 'admin');
  }

  // ── Billing ────────────────────────────────────────────────────────────────

  Future<List<BusinessBilling>> getBillingRecords() async {
    try {
      final data = await _client
          .from('business_billing')
          .select()
          .order('next_billing_at', ascending: true);
      return data.map((json) => BusinessBilling.fromJson(json)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> upsertBilling({
    required String businessId,
    required String plan,
    required String status,
    required int amountGuaranies,
    DateTime? nextBillingAt,
    String? notes,
  }) async {
    await _client.from('business_billing').upsert({
      'business_id':       businessId,
      'plan':              plan,
      'status':            status,
      'amount_guaranies':  amountGuaranies,
      'next_billing_at':   nextBillingAt?.toIso8601String(),
      'notes':             notes,
      'updated_at':        DateTime.now().toIso8601String(),
    }, onConflict: 'business_id');
  }

  // ── Audit Logs ─────────────────────────────────────────────────────────────

  Future<List<AuditLog>> getAuditLogs({int limit = 100}) async {
    try {
      final data = await _client
          .from('audit_logs')
          .select()
          .order('created_at', ascending: false)
          .limit(limit);
      return data.map((json) => AuditLog.fromJson(json)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> logAction({
    required String action,
    String? entityType,
    String? entityId,
    String? entityName,
    Map<String, dynamic>? details,
  }) async {
    try {
      final user = _client.auth.currentUser;
      await _client.from('audit_logs').insert({
        'user_id':     user?.id,
        'user_email':  user?.email,
        'action':      action,
        'entity_type': entityType,
        'entity_id':   entityId,
        'entity_name': entityName,
        'details':     details ?? {},
      });
    } catch (_) {
      // Silently fail — audit log shouldn't break the app
    }
  }
}
