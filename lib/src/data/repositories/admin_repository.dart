import 'package:reservpy/src/core/supabase/supabase_config.dart';

// ── Plan prices fallback ──────────────────────────────────────────────────────
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
    required this.overdueCount,
    required this.revenueThisMonth,
    required this.monthlyRevenue,
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
  final int mrr;
  final int arr;
  final int overdueCount;
  final int revenueThisMonth;
  final List<MonthlyRevenue> monthlyRevenue;

  double get churnRatePercent => totalBusinesses > 0
      ? (inactiveBusinesses / totalBusinesses * 100) : 0;
  double get completionRate => totalReservations > 0
      ? (completedReservations / totalReservations * 100) : 0;
}

class MonthlyRevenue {
  const MonthlyRevenue({required this.month, required this.total, required this.count});
  final DateTime month;
  final double total;
  final int count;

  factory MonthlyRevenue.fromJson(Map<String, dynamic> j) => MonthlyRevenue(
    month: DateTime.parse(j['month'] as String),
    total: (j['total_revenue'] as num?)?.toDouble() ?? 0,
    count: (j['payment_count'] as num?)?.toInt() ?? 0,
  );
}

class AdminBusiness {
  const AdminBusiness({
    required this.id,
    required this.name,
    required this.email,
    required this.plan,
    required this.isActive,
    required this.createdAt,
    this.logoUrl,
    this.phone,
    this.reservationCount = 0,
    this.nextPaymentDue,
    this.paymentStatus,
    this.daysOverdue = 0,
  });

  final String id;
  final String name;
  final String email;
  final String plan;
  final bool isActive;
  final DateTime createdAt;
  final String? logoUrl;
  final String? phone;
  final int reservationCount;
  final DateTime? nextPaymentDue;
  final String? paymentStatus;
  final int daysOverdue;

  String get initials {
    final parts = name.split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  factory AdminBusiness.fromJson(Map<String, dynamic> j) => AdminBusiness(
    id:        j['id'] as String,
    name:      j['name'] as String? ?? '',
    email:     j['email'] as String? ?? '',
    plan:      j['plan'] as String? ?? 'free',
    isActive:  j['is_active'] as bool? ?? true,
    createdAt: DateTime.parse(j['created_at'] as String),
    logoUrl:   j['logo_url'] as String?,
    phone:     j['phone'] as String?,
  );
}

class OverduePayment {
  const OverduePayment({
    required this.businessId,
    required this.businessName,
    required this.businessEmail,
    required this.paymentId,
    required this.amount,
    required this.currency,
    required this.dueDate,
    required this.daysOverdue,
    required this.severity,
    this.currentPlan = 'free',
    this.lastReminderSent,
  });

  final String businessId;
  final String businessName;
  final String businessEmail;
  final String paymentId;
  final double amount;
  final String currency;
  final DateTime dueDate;
  final int daysOverdue;
  final String severity; // leve | moderado | critico
  final String currentPlan;
  final DateTime? lastReminderSent;

  factory OverduePayment.fromJson(Map<String, dynamic> j) => OverduePayment(
    businessId:   j['business_id'] as String,
    businessName: j['business_name'] as String? ?? '',
    businessEmail: j['business_email'] as String? ?? '',
    paymentId:    j['payment_id'] as String,
    amount:       (j['amount'] as num?)?.toDouble() ?? 0,
    currency:     j['currency'] as String? ?? 'PYG',
    dueDate:      DateTime.parse(j['due_date'] as String),
    daysOverdue:  (j['days_overdue'] as num?)?.toInt() ?? 0,
    severity:     j['severity'] as String? ?? 'leve',
    currentPlan:  j['current_plan'] as String? ?? 'free',
    lastReminderSent: j['last_reminder_sent'] != null
        ? DateTime.parse(j['last_reminder_sent'] as String) : null,
  );
}

class Payment {
  const Payment({
    required this.id,
    required this.businessId,
    required this.amount,
    required this.currency,
    required this.status,
    required this.dueDate,
    this.paidAt,
    this.planName,
    this.paymentMethod,
    this.reference,
    this.notes,
    this.billingPeriodStart,
    this.billingPeriodEnd,
  });

  final String id;
  final String businessId;
  final double amount;
  final String currency;
  final String status;
  final DateTime dueDate;
  final DateTime? paidAt;
  final String? planName;
  final String? paymentMethod;
  final String? reference;
  final String? notes;
  final DateTime? billingPeriodStart;
  final DateTime? billingPeriodEnd;

  factory Payment.fromJson(Map<String, dynamic> j) => Payment(
    id:           j['id'] as String,
    businessId:   j['business_id'] as String,
    amount:       (j['amount'] as num?)?.toDouble() ?? 0,
    currency:     j['currency'] as String? ?? 'PYG',
    status:       j['status'] as String? ?? 'pending',
    dueDate:      DateTime.parse(j['due_date'] as String),
    paidAt:       j['paid_at'] != null ? DateTime.parse(j['paid_at'] as String) : null,
    paymentMethod: j['payment_method'] as String?,
    reference:    j['reference'] as String?,
    notes:        j['notes'] as String?,
    billingPeriodStart: j['billing_period_start'] != null
        ? DateTime.parse(j['billing_period_start'] as String) : null,
    billingPeriodEnd: j['billing_period_end'] != null
        ? DateTime.parse(j['billing_period_end'] as String) : null,
  );
}

class TeamMember {
  const TeamMember({
    required this.id,
    required this.email,
    required this.role,
    required this.status,
    this.userId,
    this.fullName,
    this.lastLoginAt,
    this.acceptedAt,
    this.invitedAt,
  });

  final String id;
  final String email;
  final String role; // super_admin | admin | manager | soporte
  final String status; // active | pending | revoked
  final String? userId;
  final String? fullName;
  final DateTime? lastLoginAt;
  final DateTime? acceptedAt;
  final DateTime? invitedAt;

  String get displayName => fullName ?? email.split('@').first;
  String get initials {
    final n = displayName;
    final parts = n.split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return n.isNotEmpty ? n[0].toUpperCase() : '?';
  }

  factory TeamMember.fromJson(Map<String, dynamic> j) => TeamMember(
    id:       j['id'] as String,
    email:    j['email'] as String,
    role:     j['role'] as String? ?? 'soporte',
    status:   j['status'] as String? ?? 'pending',
    userId:   j['user_id'] as String?,
    fullName: j['full_name'] as String?,
    lastLoginAt: j['last_login_at'] != null
        ? DateTime.parse(j['last_login_at'] as String) : null,
    acceptedAt: j['accepted_at'] != null
        ? DateTime.parse(j['accepted_at'] as String) : null,
    invitedAt: j['invited_at'] != null
        ? DateTime.parse(j['invited_at'] as String) : null,
  );
}

class Plan {
  const Plan({
    required this.id,
    required this.name,
    required this.slug,
    required this.priceMonthly,
    this.priceYearly,
    this.currency = 'PYG',
    this.features = const [],
    this.isActive = true,
    this.isDefault = false,
    this.maxReservations,
  });

  final String id;
  final String name;
  final String slug;
  final double priceMonthly;
  final double? priceYearly;
  final String currency;
  final List<String> features;
  final bool isActive;
  final bool isDefault;
  final int? maxReservations;

  factory Plan.fromJson(Map<String, dynamic> j) => Plan(
    id:            j['id'] as String,
    name:          j['name'] as String,
    slug:          j['slug'] as String,
    priceMonthly:  (j['price_monthly'] as num?)?.toDouble() ?? 0,
    priceYearly:   (j['price_yearly']  as num?)?.toDouble(),
    currency:      j['currency'] as String? ?? 'PYG',
    features:      (j['features'] as List?)?.cast<String>() ?? [],
    isActive:      j['is_active'] as bool? ?? true,
    isDefault:     j['is_default'] as bool? ?? false,
    maxReservations: j['max_reservations'] as int?,
  );
}

class ActivityLog {
  const ActivityLog({
    required this.id,
    required this.action,
    required this.createdAt,
    this.userId,
    this.userEmail,
    this.entityType,
    this.entityId,
    this.entityName,
    this.description,
  });

  final String id;
  final String action;
  final DateTime createdAt;
  final String? userId;
  final String? userEmail;
  final String? entityType;
  final String? entityId;
  final String? entityName;
  final String? description;

  factory ActivityLog.fromJson(Map<String, dynamic> j) => ActivityLog(
    id:          j['id'] as String,
    action:      j['action'] as String,
    createdAt:   DateTime.parse(j['created_at'] as String),
    userId:      j['user_id'] as String?,
    userEmail:   j['user_email'] as String?,
    entityType:  j['entity_type'] as String?,
    entityId:    j['entity_id'] as String?,
    entityName:  j['entity_name'] as String?,
    description: j['description'] as String?,
  );
}

// ── Repository ────────────────────────────────────────────────────────────────

class AdminRepository {
  final _db = SupabaseConfig.client;

  // ── Stats ──────────────────────────────────────────────────────────────────

  Future<AdminStats> getStats() async {
    final now        = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day).toIso8601String();
    final monthStart = DateTime(now.year, now.month, 1).toIso8601String();

    final results = await Future.wait([
      _db.from('businesses').select('id, is_active, plan, created_at'),
      _db.from('profiles').select('id, created_at'),
      _db.from('reservations').select('id, status, start_time, created_at'),
    ]);

    final businesses = List<Map<String, dynamic>>.from(results[0] as List);
    final users      = List<Map<String, dynamic>>.from(results[1] as List);
    final reservs    = List<Map<String, dynamic>>.from(results[2] as List);

    final activeB  = businesses.where((b) => b['is_active'] == true).length;
    final newToday = businesses.where((b) =>
        (b['created_at'] as String).compareTo(todayStart) >= 0).length;
    final newMonth = businesses.where((b) =>
        (b['created_at'] as String).compareTo(monthStart) >= 0).length;

    final planCounts = <String, int>{};
    for (final b in businesses) {
      final plan = b['plan'] as String? ?? 'free';
      planCounts[plan] = (planCounts[plan] ?? 0) + 1;
    }

    var mrr = 0;
    for (final e in planCounts.entries) {
      mrr += (kPlanPrices[e.key] ?? 0) * e.value;
    }

    final completedR = reservs.where((r) => r['status'] == 'completed').length;
    final cancelledR = reservs.where((r) => r['status'] == 'cancelled').length;
    final todayR = reservs.where((r) {
      final st = r['start_time'] as String? ?? r['created_at'] as String? ?? '';
      return st.compareTo(todayStart) >= 0;
    }).length;
    final monthR = reservs.where((r) {
      final st = r['start_time'] as String? ?? r['created_at'] as String? ?? '';
      return st.compareTo(monthStart) >= 0;
    }).length;

    // Overdue count from payments table (with fallback to 0 if table doesn't exist)
    int overdueCount = 0;
    int revenueThisMonth = 0;
    List<MonthlyRevenue> monthlyRevenue = [];
    try {
      final overdueData = await _db
          .from('payments')
          .select('id')
          .eq('status', 'overdue');
      overdueCount = (overdueData as List).length;

      final revenueData = await _db
          .from('payments')
          .select('amount')
          .eq('status', 'paid')
          .gte('paid_at', monthStart);
      for (final r in revenueData as List) {
        revenueThisMonth += ((r['amount'] as num?)?.toInt() ?? 0);
      }

      final revData = await _db
          .from('v_monthly_revenue')
          .select()
          .limit(12);
      monthlyRevenue = (revData as List)
          .map((j) => MonthlyRevenue.fromJson(j))
          .toList();
    } catch (_) {}

    return AdminStats(
      totalBusinesses:        businesses.length,
      activeBusinesses:       activeB,
      inactiveBusinesses:     businesses.length - activeB,
      newBusinessesToday:     newToday,
      newBusinessesThisMonth: newMonth,
      totalUsers:             users.length,
      newUsersToday:          users.where((u) =>
          (u['created_at'] as String).compareTo(todayStart) >= 0).length,
      newUsersThisMonth:      users.where((u) =>
          (u['created_at'] as String).compareTo(monthStart) >= 0).length,
      totalReservations:      reservs.length,
      reservationsToday:      todayR,
      reservationsThisMonth:  monthR,
      completedReservations:  completedR,
      cancelledReservations:  cancelledR,
      businessesByPlan:       planCounts,
      mrr:                    mrr,
      arr:                    mrr * 12,
      overdueCount:           overdueCount,
      revenueThisMonth:       revenueThisMonth,
      monthlyRevenue:         monthlyRevenue,
    );
  }

  // ── Businesses ─────────────────────────────────────────────────────────────

  Future<List<AdminBusiness>> getAllBusinesses() async {
    final data = await _db
        .from('businesses')
        .select()
        .order('created_at', ascending: false);
    return (data as List).map((j) => AdminBusiness.fromJson(j)).toList();
  }

  Future<AdminBusiness?> getBusinessById(String id) async {
    final data = await _db
        .from('businesses')
        .select()
        .eq('id', id)
        .maybeSingle();
    if (data == null) return null;
    return AdminBusiness.fromJson(data);
  }

  Future<void> setBusinessActive(String id, bool active) async {
    await _db.from('businesses').update({'is_active': active}).eq('id', id);
    await logAction(
      action: 'business.${active ? 'activate' : 'deactivate'}',
      entityType: 'business', entityId: id,
    );
  }

  Future<void> changeBusinessPlan(String id, String plan) async {
    await _db.from('businesses').update({
      'plan': plan,
      'plan_activated_at': DateTime.now().toIso8601String(),
    }).eq('id', id);
    await logAction(
      action: 'business.plan_change', entityType: 'business', entityId: id,
      details: {'new_plan': plan},
    );
  }

  Future<List<Map<String, dynamic>>> getBusinessReservations(String businessId, {int limit = 50}) async {
    try {
      final data = await _db
          .from('reservations')
          .select()
          .eq('business_id', businessId)
          .order('start_time', ascending: false)
          .limit(limit);
      return List<Map<String, dynamic>>.from(data as List);
    } catch (_) { return []; }
  }

  // ── Payments ────────────────────────────────────────────────────────────────

  Future<List<OverduePayment>> getOverduePayments() async {
    try {
      final data = await _db
          .from('v_overdue_payments')
          .select()
          .order('days_overdue', ascending: false);
      return (data as List).map((j) => OverduePayment.fromJson(j)).toList();
    } catch (_) { return []; }
  }

  Future<List<Payment>> getBusinessPayments(String businessId) async {
    try {
      final data = await _db
          .from('payments')
          .select()
          .eq('business_id', businessId)
          .order('due_date', ascending: false);
      return (data as List).map((j) => Payment.fromJson(j)).toList();
    } catch (_) { return []; }
  }

  Future<void> registerPayment({
    required String businessId,
    required double amount,
    required String currency,
    required String status,
    required DateTime dueDate,
    String? planId,
    String? paymentMethod,
    String? reference,
    String? notes,
    DateTime? billingPeriodStart,
    DateTime? billingPeriodEnd,
  }) async {
    await _db.from('payments').insert({
      'business_id':          businessId,
      'plan_id':              planId,
      'amount':               amount,
      'currency':             currency,
      'status':               status,
      'due_date':             dueDate.toIso8601String().substring(0, 10),
      'paid_at':              status == 'paid' ? DateTime.now().toIso8601String() : null,
      'payment_method':       paymentMethod,
      'reference':            reference,
      'notes':                notes,
      'billing_period_start': billingPeriodStart?.toIso8601String().substring(0, 10),
      'billing_period_end':   billingPeriodEnd?.toIso8601String().substring(0, 10),
      'registered_by':        _db.auth.currentUser?.id,
    });
    await logAction(
      action: 'billing.payment_registered', entityType: 'business', entityId: businessId,
      details: {'amount': amount, 'status': status},
    );
  }

  Future<void> updatePaymentStatus(String paymentId, String status) async {
    await _db.from('payments').update({
      'status':  status,
      'paid_at': status == 'paid' ? DateTime.now().toIso8601String() : null,
    }).eq('id', paymentId);
  }

  Future<void> sendReminder(String businessId, String paymentId) async {
    await _db.from('payment_reminders').insert({
      'business_id': businessId,
      'payment_id':  paymentId,
      'sent_by':     _db.auth.currentUser?.id,
      'method':      'email',
    });
    await logAction(
      action: 'billing.reminder_sent', entityType: 'business', entityId: businessId,
    );
  }

  // ── Team ────────────────────────────────────────────────────────────────────

  Future<List<TeamMember>> getTeamMembers() async {
    try {
      final data = await _db
          .from('team_members')
          .select()
          .order('created_at');
      return (data as List).map((j) => TeamMember.fromJson(j)).toList();
    } catch (_) { return []; }
  }

  Future<void> inviteTeamMember({
    required String email,
    required String role,
    String? fullName,
  }) async {
    await _db.from('team_members').upsert({
      'email':      email,
      'full_name':  fullName,
      'role':       role,
      'status':     'pending',
      'invited_by': _db.auth.currentUser?.id,
      'invited_at': DateTime.now().toIso8601String(),
    }, onConflict: 'email');
    await logAction(
      action: 'team.member_invited', entityType: 'team', entityName: email,
      details: {'role': role},
    );
  }

  Future<void> updateTeamMemberRole(String id, String role) async {
    await _db.from('team_members').update({'role': role}).eq('id', id);
  }

  Future<void> revokeTeamMember(String id, String email) async {
    await _db.from('team_members').update({'status': 'revoked'}).eq('id', id);
    await logAction(
      action: 'team.member_revoked', entityType: 'team', entityName: email,
    );
  }

  // ── Plans ───────────────────────────────────────────────────────────────────

  Future<List<Plan>> getPlans() async {
    try {
      final data = await _db
          .from('plans')
          .select()
          .order('sort_order');
      return (data as List).map((j) => Plan.fromJson(j)).toList();
    } catch (_) { return []; }
  }

  Future<void> upsertPlan(Map<String, dynamic> data) async {
    await _db.from('plans').upsert(data, onConflict: 'slug');
  }

  // ── Activity Log ────────────────────────────────────────────────────────────

  Future<List<ActivityLog>> getActivityLog({int limit = 100}) async {
    try {
      final data = await _db
          .from('team_activity_log')
          .select()
          .order('created_at', ascending: false)
          .limit(limit);
      return (data as List).map((j) => ActivityLog.fromJson(j)).toList();
    } catch (_) { return []; }
  }

  Future<void> logAction({
    required String action,
    String? entityType,
    String? entityId,
    String? entityName,
    String? description,
    Map<String, dynamic>? details,
  }) async {
    try {
      final u = _db.auth.currentUser;
      await _db.from('team_activity_log').insert({
        'user_id':     u?.id,
        'user_email':  u?.email,
        'action':      action,
        'entity_type': entityType,
        'entity_id':   entityId,
        'entity_name': entityName,
        'description': description,
        'metadata':    details ?? {},
      });
    } catch (_) {}
  }
}
