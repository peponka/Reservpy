import 'package:flutter/material.dart';

/// Helper to parse TimeOfDay from 'HH:mm' or 'HH:mm:ss' string.
TimeOfDay _timeFromString(String time) {
  final parts = time.split(':');
  return TimeOfDay(
    hour: int.tryParse(parts[0]) ?? 9,
    minute: int.tryParse(parts[1]) ?? 0,
  );
}

/// Helper to parse Color from hex string like '#FF6B6B'.
Color _colorFromHex(String hex) {
  final buffer = StringBuffer();
  if (hex.length == 7) buffer.write('FF');
  buffer.write(hex.replaceFirst('#', ''));
  return Color(int.parse(buffer.toString(), radix: 16));
}

/// Icon name to IconData mapping for Supabase storage.
const _iconMap = <String, IconData>{
  'content_cut': Icons.content_cut,
  'face': Icons.face,
  'spa': Icons.spa,
  'local_hospital': Icons.local_hospital,
  'medical_services': Icons.medical_services,
  'psychology': Icons.psychology,
  'restaurant': Icons.restaurant,
  'fitness_center': Icons.fitness_center,
  'auto_awesome': Icons.auto_awesome,
  'pets': Icons.pets,
  'business_center': Icons.business_center,
  'school': Icons.school,
  'camera_alt': Icons.camera_alt,
  'build': Icons.build,
  'cleaning_services': Icons.cleaning_services,
  'sports_soccer': Icons.sports_soccer,
  'celebration': Icons.celebration,
  'category': Icons.category,
  'self_improvement': Icons.self_improvement,
  'hot_tub': Icons.hot_tub,
  'health_and_safety': Icons.health_and_safety,
  'gavel': Icons.gavel,
  'calculate': Icons.calculate,
  'brush': Icons.brush,
  'car_repair': Icons.car_repair,
  'work': Icons.work,
  'home_work': Icons.home_work,
};

IconData _iconFromString(String name) => _iconMap[name] ?? Icons.category;

String _iconToString(IconData icon) {
  for (final entry in _iconMap.entries) {
    if (entry.value == icon) return entry.key;
  }
  return 'category';
}

/// User roles in the system.
/// NOTE: 'business' is kept as an alias for backward compatibility with
/// existing DB records. The canonical value is 'businessOwner'.
enum UserRole {
  client,
  business,       // legacy alias — same as businessOwner
  businessOwner,  // canonical name
  employee,
  admin;

  /// Convert from DB string ('client', 'business_owner', 'business', 'employee', 'admin')
  static UserRole fromDbString(String? value) {
    switch (value) {
      case 'business_owner':
      case 'business':
        return UserRole.businessOwner;
      case 'employee':
        return UserRole.employee;
      case 'admin':
        return UserRole.admin;
      case 'client':
      default:
        return UserRole.client;
    }
  }

  /// Convert to DB string for user_roles table
  String get dbValue {
    switch (this) {
      case UserRole.business:
      case UserRole.businessOwner:
        return 'business_owner';
      case UserRole.employee:
        return 'employee';
      case UserRole.admin:
        return 'admin';
      case UserRole.client:
        return 'client';
    }
  }

  /// Human-readable label in Spanish
  String get label {
    switch (this) {
      case UserRole.business:
      case UserRole.businessOwner:
        return 'Negocio';
      case UserRole.employee:
        return 'Empleado';
      case UserRole.admin:
        return 'Administrador';
      case UserRole.client:
        return 'Cliente';
    }
  }

  /// Icon for role selector
  static String iconFor(UserRole role) {
    switch (role) {
      case UserRole.business:
      case UserRole.businessOwner:
        return 'store';
      case UserRole.employee:
        return 'badge';
      case UserRole.admin:
        return 'admin_panel_settings';
      case UserRole.client:
        return 'person';
    }
  }
}

/// Reservation status.
enum ReservationStatus { pending, confirmed, cancelled, completed }

/// Business category.
class BusinessCategory {
  final String id;
  final String name;
  final IconData icon;
  final Color color;

  const BusinessCategory({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
  });

  factory BusinessCategory.fromJson(Map<String, dynamic> json) => BusinessCategory(
    id: json['id'] as String,
    name: json['name'] as String,
    icon: _iconFromString(json['icon'] as String? ?? 'category'),
    color: _colorFromHex(json['color'] as String? ?? '#00C896'),
  );

  Map<String, dynamic> toJson() => {
    'name': name,
    'icon': _iconToString(icon),
    'color': '#${color.toARGB32().toRadixString(16).padLeft(8, '0').substring(2)}',
  };
}

/// App user profile with multi-role support.
class AppUser {
  final String id;
  final String firstName;
  final String lastName;
  final String email;
  final String? phone;
  final UserRole role;          // legacy single role from profiles table
  final List<UserRole> roles;   // all roles from user_roles table
  final String? avatarUrl;
  final DateTime createdAt;

  const AppUser({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    this.phone,
    required this.role,
    this.roles = const [UserRole.client],
    this.avatarUrl,
    required this.createdAt,
  });

  factory AppUser.fromJson(Map<String, dynamic> json) => AppUser(
    id: json['id'] as String,
    firstName: json['first_name'] as String? ?? '',
    lastName: json['last_name'] as String? ?? '',
    email: json['email'] as String? ?? '',
    phone: json['phone'] as String?,
    role: UserRole.fromDbString(json['role'] as String?),
    roles: const [UserRole.client], // will be populated from user_roles table
    avatarUrl: json['avatar_url'] as String?,
    createdAt: DateTime.parse(json['created_at'] as String),
  );

  Map<String, dynamic> toJson() => {
    'first_name': firstName,
    'last_name': lastName,
    'email': email,
    'phone': phone,
    'role': role == UserRole.businessOwner ? 'business' : role.name,
    'avatar_url': avatarUrl,
  };

  String get fullName => '$firstName $lastName';
  String get initials =>
      '${firstName.isNotEmpty ? firstName[0] : ''}${lastName.isNotEmpty ? lastName[0] : ''}'
          .toUpperCase();

  /// Whether this user has multiple roles
  bool get isMultiRole => roles.length > 1;

  /// Check if user has a specific role
  bool hasRole(UserRole r) {
    if (r == UserRole.business || r == UserRole.businessOwner) {
      return roles.contains(UserRole.business) || roles.contains(UserRole.businessOwner);
    }
    return roles.contains(r);
  }

  bool get canBeBusiness => hasRole(UserRole.businessOwner);
  bool get canBeClient => hasRole(UserRole.client);

  /// Create a copy with updated roles
  AppUser copyWith({
    String? id,
    String? firstName,
    String? lastName,
    String? email,
    String? phone,
    UserRole? role,
    List<UserRole>? roles,
    String? avatarUrl,
    DateTime? createdAt,
  }) {
    return AppUser(
      id: id ?? this.id,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      roles: roles ?? this.roles,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

/// Business entity.
class Business {
  final String id;
  final String ownerId;
  final String categoryId;
  final String name;
  final String? description;
  final String? address;
  final double? latitude;
  final double? longitude;
  final String? phone;
  final String? website;
  final String? logoUrl;
  final List<String> photos;
  final TimeOfDay openingTime;
  final TimeOfDay closingTime;
  final int slotDurationMinutes;
  final bool isActive;
  final DateTime createdAt;
  final int cancellationHoursPolicy;
  final bool remindersEnabled;
  final List<int> reminderHoursBefore;
  final String plan;
  final DateTime? planActivatedAt;
  /// Days of the week the business is open (1=Mon, 2=Tue, ..., 7=Sun).
  final List<int> workingDays;

  const Business({
    required this.id,
    required this.ownerId,
    required this.categoryId,
    required this.name,
    this.description,
    this.address,
    this.latitude,
    this.longitude,
    this.phone,
    this.website,
    this.logoUrl,
    this.photos = const [],
    required this.openingTime,
    required this.closingTime,
    this.slotDurationMinutes = 30,
    this.isActive = true,
    required this.createdAt,
    this.cancellationHoursPolicy = 2,
    this.remindersEnabled = true,
    this.reminderHoursBefore = const [24],
    this.plan = 'free',
    this.planActivatedAt,
    this.workingDays = const [1, 2, 3, 4, 5, 6],
  });

  factory Business.fromJson(Map<String, dynamic> json) => Business(
    id: json['id'] as String,
    ownerId: json['owner_id'] as String,
    categoryId: json['category_id'] as String? ?? '',
    name: json['name'] as String,
    description: json['description'] as String?,
    address: json['address'] as String?,
    latitude: (json['latitude'] as num?)?.toDouble(),
    longitude: (json['longitude'] as num?)?.toDouble(),
    phone: json['phone'] as String?,
    website: json['website'] as String?,
    logoUrl: json['logo_url'] as String?,
    photos: (json['photos'] as List<dynamic>?)?.cast<String>() ?? [],
    openingTime: _timeFromString(json['opening_time'] as String? ?? '09:00'),
    closingTime: _timeFromString(json['closing_time'] as String? ?? '18:00'),
    slotDurationMinutes: json['slot_duration_minutes'] as int? ?? 30,
    isActive: json['is_active'] as bool? ?? true,
    createdAt: DateTime.parse(json['created_at'] as String),
    cancellationHoursPolicy: json['cancellation_hours_policy'] as int? ?? 2,
    remindersEnabled: json['reminders_enabled'] as bool? ?? true,
    reminderHoursBefore: (json['reminder_hours_before'] as List<dynamic>?)?.cast<int>() ?? [24],
    plan: json['plan'] as String? ?? 'free',
    planActivatedAt: json['plan_activated_at'] != null
        ? DateTime.tryParse(json['plan_activated_at'] as String)
        : null,
    workingDays: (json['working_days'] as List<dynamic>?)?.cast<int>() ?? [1, 2, 3, 4, 5, 6],
  );

  Map<String, dynamic> toJson() => {
    'owner_id': ownerId,
    'category_id': categoryId.startsWith('cat-') ? null : (categoryId.isEmpty ? null : categoryId),
    'name': name,
    'description': description,
    'address': address,
    'latitude': latitude,
    'longitude': longitude,
    'phone': phone,
    'website': website,
    'logo_url': logoUrl,
    'photos': photos,
    'opening_time': '${openingTime.hour.toString().padLeft(2, '0')}:${openingTime.minute.toString().padLeft(2, '0')}',
    'closing_time': '${closingTime.hour.toString().padLeft(2, '0')}:${closingTime.minute.toString().padLeft(2, '0')}',
    'slot_duration_minutes': slotDurationMinutes,
    'is_active': isActive,
    'cancellation_hours_policy': cancellationHoursPolicy,
    'reminders_enabled': remindersEnabled,
    'reminder_hours_before': reminderHoursBefore,
    'working_days': workingDays,
  };

  bool get isCurrentlyOpen {
    final now = TimeOfDay.now();
    final nowMin = now.hour * 60 + now.minute;
    final openMin = openingTime.hour * 60 + openingTime.minute;
    final closeMin = closingTime.hour * 60 + closingTime.minute;
    return nowMin >= openMin && nowMin < closeMin;
  }

  String get openingTimeStr =>
      '${openingTime.hour.toString().padLeft(2, '0')}:${openingTime.minute.toString().padLeft(2, '0')}';
  String get closingTimeStr =>
      '${closingTime.hour.toString().padLeft(2, '0')}:${closingTime.minute.toString().padLeft(2, '0')}';

  /// Whether this business is on the Pro plan.
  bool get isPro => plan == 'pro';

  /// Whether the reservation can still be cancelled based on the policy.
  bool canCancelReservation(DateTime startTime) {
    final hoursUntil = startTime.difference(DateTime.now()).inHours;
    return hoursUntil >= cancellationHoursPolicy;
  }

  Business copyWith({
    String? id,
    String? ownerId,
    String? categoryId,
    String? name,
    String? description,
    String? address,
    double? latitude,
    double? longitude,
    String? phone,
    String? website,
    String? logoUrl,
    List<String>? photos,
    TimeOfDay? openingTime,
    TimeOfDay? closingTime,
    int? slotDurationMinutes,
    bool? isActive,
    DateTime? createdAt,
    int? cancellationHoursPolicy,
    bool? remindersEnabled,
    List<int>? reminderHoursBefore,
    String? plan,
    DateTime? planActivatedAt,
    List<int>? workingDays,
  }) {
    return Business(
      id: id ?? this.id,
      ownerId: ownerId ?? this.ownerId,
      categoryId: categoryId ?? this.categoryId,
      name: name ?? this.name,
      description: description ?? this.description,
      address: address ?? this.address,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      phone: phone ?? this.phone,
      website: website ?? this.website,
      logoUrl: logoUrl ?? this.logoUrl,
      photos: photos ?? this.photos,
      openingTime: openingTime ?? this.openingTime,
      closingTime: closingTime ?? this.closingTime,
      slotDurationMinutes: slotDurationMinutes ?? this.slotDurationMinutes,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      cancellationHoursPolicy: cancellationHoursPolicy ?? this.cancellationHoursPolicy,
      remindersEnabled: remindersEnabled ?? this.remindersEnabled,
      reminderHoursBefore: reminderHoursBefore ?? this.reminderHoursBefore,
      plan: plan ?? this.plan,
      planActivatedAt: planActivatedAt ?? this.planActivatedAt,
      workingDays: workingDays ?? this.workingDays,
    );
  }
}

/// Service offered by a business.
class ServiceModel {
  final String id;
  final String businessId;
  final String name;
  final String? description;
  final int durationMinutes;
  final double? price;
  final String currency;
  final bool isActive;
  final int sortOrder;

  const ServiceModel({
    required this.id,
    required this.businessId,
    required this.name,
    this.description,
    this.durationMinutes = 30,
    this.price,
    this.currency = 'PYG',
    this.isActive = true,
    this.sortOrder = 0,
  });

  factory ServiceModel.fromJson(Map<String, dynamic> json) => ServiceModel(
    id: json['id'] as String,
    businessId: json['business_id'] as String,
    name: json['name'] as String,
    description: json['description'] as String?,
    durationMinutes: json['duration_minutes'] as int? ?? 30,
    price: (json['price'] as num?)?.toDouble(),
    currency: json['currency'] as String? ?? 'PYG',
    isActive: json['is_active'] as bool? ?? true,
    sortOrder: json['sort_order'] as int? ?? 0,
  );

  Map<String, dynamic> toJson() => {
    'business_id': businessId,
    'name': name,
    'description': description,
    'duration_minutes': durationMinutes,
    'price': price,
    'currency': currency,
    'is_active': isActive,
    'sort_order': sortOrder,
  };

  String get formattedPrice {
    if (price == null) return 'Gratis';
    return '${price!.toStringAsFixed(0)} Gs.';
  }

  String get formattedDuration => '$durationMinutes min';
}

/// A reservation / booking.
class Reservation {
  final String id;
  final String businessId;
  final String? clientId;        // null para reservas manuales (CN-005)
  final String serviceId;
  final DateTime startTime;
  final DateTime endTime;
  final ReservationStatus status;
  final String? notes;
  final String? cancellationReason;
  final DateTime createdAt;

  // Reservas manuales (cargadas por el dueño — CN-005)
  final bool isManual;
  final String? manualClientName;
  final String? manualClientPhone;

  // Joined data (for display)
  final String? clientName;
  final String? serviceName;
  final String? businessName;
  final String? employeeId;
  final String? employeeName;

  const Reservation({
    required this.id,
    required this.businessId,
    this.clientId,
    required this.serviceId,
    required this.startTime,
    required this.endTime,
    this.status = ReservationStatus.pending,
    this.notes,
    this.cancellationReason,
    required this.createdAt,
    this.isManual = false,
    this.manualClientName,
    this.manualClientPhone,
    this.clientName,
    this.serviceName,
    this.businessName,
    this.employeeId,
    this.employeeName,
  });

  factory Reservation.fromJson(Map<String, dynamic> json) {
    // Para reservas manuales el nombre viene de manual_client_name;
    // para reservas normales viene del join con profiles.
    final profilesMap = json['profiles'] as Map<String, dynamic>?;
    final joinedName = profilesMap != null
        ? '${profilesMap['first_name']} ${profilesMap['last_name']}'
        : null;
    final manualName = json['manual_client_name'] as String?;

    return Reservation(
      id: json['id'] as String,
      businessId: json['business_id'] as String,
      clientId: json['client_id'] as String?,
      serviceId: json['service_id'] as String,
      startTime: DateTime.parse(json['start_time'] as String),
      endTime: DateTime.parse(json['end_time'] as String),
      status: ReservationStatus.values.firstWhere(
        (s) => s.name == (json['status'] as String? ?? 'pending'),
        orElse: () => ReservationStatus.pending,
      ),
      notes: json['notes'] as String?,
      cancellationReason: json['cancellation_reason'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      isManual: (json['is_manual'] as bool?) ?? false,
      manualClientName: manualName,
      manualClientPhone: json['manual_client_phone'] as String?,
      // Nombre para mostrar: join > manual > null
      clientName: joinedName ?? manualName,
      serviceName: json['services'] != null ? json['services']['name'] as String? : null,
      businessName: json['businesses'] != null ? json['businesses']['name'] as String? : null,
      employeeId: json['employee_id'] as String?,
      employeeName: json['employee_name'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'business_id': businessId,
      'service_id': serviceId,
      'start_time': startTime.toIso8601String(),
      'end_time': endTime.toIso8601String(),
      'status': status.name,
      'notes': notes,
      'cancellation_reason': cancellationReason,
      'employee_id': employeeId,
      'employee_name': employeeName,
      'is_manual': isManual,
      'manual_client_name': manualClientName,
      'manual_client_phone': manualClientPhone,
    };
    // Solo incluir client_id si tiene valor (reservas normales)
    if (clientId != null) map['client_id'] = clientId;
    return map;
  }

  Reservation copyWith({ReservationStatus? status, String? cancellationReason}) {
    return Reservation(
      id: id,
      businessId: businessId,
      clientId: clientId,
      serviceId: serviceId,
      startTime: startTime,
      endTime: endTime,
      status: status ?? this.status,
      notes: notes,
      cancellationReason: cancellationReason ?? this.cancellationReason,
      createdAt: createdAt,
      isManual: isManual,
      manualClientName: manualClientName,
      manualClientPhone: manualClientPhone,
      clientName: clientName,
      serviceName: serviceName,
      businessName: businessName,
      employeeId: employeeId,
      employeeName: employeeName,
    );
  }
}

/// Blocked time slot.
class BlockedSlot {
  final String id;
  final String businessId;
  final DateTime startTime;
  final DateTime endTime;
  final String? reason;

  const BlockedSlot({
    required this.id,
    required this.businessId,
    required this.startTime,
    required this.endTime,
    this.reason,
  });

  factory BlockedSlot.fromJson(Map<String, dynamic> json) => BlockedSlot(
    id: json['id'] as String,
    businessId: json['business_id'] as String,
    startTime: DateTime.parse(json['start_time'] as String),
    endTime: DateTime.parse(json['end_time'] as String),
    reason: json['reason'] as String?,
  );

  Map<String, dynamic> toJson() => {
    'business_id': businessId,
    'start_time': startTime.toIso8601String(),
    'end_time': endTime.toIso8601String(),
    'reason': reason,
  };
}

/// Dashboard statistics.
class DashboardStats {
  final int reservationsToday;
  final int uniqueClients;
  final int cancellationsToday;
  final double occupancyPercent;

  const DashboardStats({
    required this.reservationsToday,
    required this.uniqueClients,
    required this.cancellationsToday,
    required this.occupancyPercent,
  });
}

/// Business review left by a client.
class Review {
  final String id;
  final String businessId;
  final String clientId;
  final String? reservationId;
  final int rating;
  final String comment;
  final DateTime createdAt;
  final String? clientName;

  const Review({
    required this.id,
    required this.businessId,
    required this.clientId,
    this.reservationId,
    required this.rating,
    this.comment = '',
    required this.createdAt,
    this.clientName,
  });

  factory Review.fromJson(Map<String, dynamic> json) => Review(
    id: json['id'] as String,
    businessId: json['business_id'] as String,
    clientId: json['client_id'] as String,
    reservationId: json['reservation_id'] as String?,
    rating: json['rating'] as int,
    comment: json['comment'] as String? ?? '',
    createdAt: DateTime.parse(json['created_at'] as String),
    clientName: json['client_name'] as String?,
  );
}

/// In-app notification.
enum NotificationType { newReservation, cancellation, reminder, system }

class AppNotification {
  final String id;
  final String userId;
  final String? businessId;
  final NotificationType type;
  final String title;
  final String body;
  final bool isRead;
  final DateTime createdAt;
  final String? reservationId;

  const AppNotification({
    required this.id,
    required this.userId,
    this.businessId,
    required this.type,
    required this.title,
    required this.body,
    this.isRead = false,
    required this.createdAt,
    this.reservationId,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) => AppNotification(
    id: json['id'] as String,
    userId: json['user_id'] as String,
    businessId: json['business_id'] as String?,
    type: NotificationType.values.firstWhere(
      (e) => e.name == (json['type'] as String? ?? 'system'),
      orElse: () => NotificationType.system,
    ),
    title: json['title'] as String? ?? '',
    body: json['body'] as String? ?? '',
    isRead: json['is_read'] as bool? ?? false,
    createdAt: DateTime.parse(json['created_at'] as String),
    reservationId: json['reservation_id'] as String?,
  );
}

/// Enhanced dashboard statistics computed from real reservation data.
class EnhancedDashboardStats {
  final int reservationsToday;
  final int reservationsThisWeek;
  final int reservationsThisMonth;
  final double estimatedRevenue;
  final double occupancyPercent;
  final int pendingCount;
  final int confirmedCount;
  final int cancelledCount;
  final int completedCount;
  final List<Reservation> upcomingReservations;
  final List<Reservation> todayReservations;
  final List<int> weeklyBreakdown;
  final List<MapEntry<String, int>> topServices;

  const EnhancedDashboardStats({
    this.reservationsToday = 0,
    this.reservationsThisWeek = 0,
    this.reservationsThisMonth = 0,
    this.estimatedRevenue = 0,
    this.occupancyPercent = 0,
    this.pendingCount = 0,
    this.confirmedCount = 0,
    this.cancelledCount = 0,
    this.completedCount = 0,
    this.upcomingReservations = const [],
    this.todayReservations = const [],
    this.weeklyBreakdown = const [0, 0, 0, 0, 0, 0, 0],
    this.topServices = const [],
  });
}
