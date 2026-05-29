/// Employee / staff member of a business.
class Employee {
  final String id;
  final String businessId;
  final String name;
  final String? email;
  final String? phone;
  final String? role; // e.g. 'staff', 'admin'
  final String? avatarUrl;
  final bool isActive;
  final DateTime createdAt;

  const Employee({
    required this.id,
    required this.businessId,
    required this.name,
    this.email,
    this.phone,
    this.role,
    this.avatarUrl,
    this.isActive = true,
    required this.createdAt,
  });

  /// Create an Employee from a Supabase JSON row.
  factory Employee.fromJson(Map<String, dynamic> json) => Employee(
    id: json['id'] as String,
    businessId: json['business_id'] as String,
    name: json['name'] as String,
    email: json['email'] as String?,
    phone: json['phone'] as String?,
    role: json['role'] as String?,
    avatarUrl: json['avatar_url'] as String?,
    isActive: json['is_active'] as bool? ?? true,
    createdAt: DateTime.parse(json['created_at'] as String),
  );

  /// Serialize to JSON for Supabase insert/update.
  /// Does NOT include `id` or `created_at` — Supabase generates those.
  Map<String, dynamic> toJson() => {
    'business_id': businessId,
    'name': name,
    'email': email,
    'phone': phone,
    'role': role,
    'avatar_url': avatarUrl,
    'is_active': isActive,
  };

  /// First letter of the first two words in [name].
  String get initials {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return '';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  Employee copyWith({
    String? id,
    String? businessId,
    String? name,
    String? email,
    String? phone,
    String? role,
    String? avatarUrl,
    bool? isActive,
    DateTime? createdAt,
  }) {
    return Employee(
      id: id ?? this.id,
      businessId: businessId ?? this.businessId,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
