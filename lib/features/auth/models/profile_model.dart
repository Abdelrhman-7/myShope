/// Profile model matching the `profiles` table in Supabase.
class ProfileModel {
  final String id;
  final String? fullName;
  final String? phone;
  final String? email;
  final String? avatarUrl;
  final String role;
  final String? customerTypeId;
  final bool isActive;
  final String language;
  final String theme;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const ProfileModel({
    required this.id,
    this.fullName,
    this.phone,
    this.email,
    this.avatarUrl,
    this.role = 'customer',
    this.customerTypeId,
    this.isActive = true,
    this.language = 'ar',
    this.theme = 'light',
    this.createdAt,
    this.updatedAt,
  });

  bool get isAdmin => role == 'admin';
  bool get isCustomer => role == 'customer';
  bool get isMerchant => role == 'merchant';

  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    return ProfileModel(
      id: json['id'] as String,
      fullName: json['full_name'] as String?,
      phone: json['phone'] as String?,
      email: json['email'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      role: json['role'] as String? ?? 'customer',
      customerTypeId: json['customer_type_id'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      language: json['language'] as String? ?? 'ar',
      theme: json['theme'] as String? ?? 'light',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'full_name': fullName,
      'phone': phone,
      'email': email,
      'avatar_url': avatarUrl,
      'role': role,
      'customer_type_id': customerTypeId,
      'is_active': isActive,
      'language': language,
      'theme': theme,
    };
  }

  /// Only fields a customer is allowed to update
  Map<String, dynamic> toUpdateJson() {
    return {
      'full_name': fullName,
      'phone': phone,
      'avatar_url': avatarUrl,
      'language': language,
      'theme': theme,
      'updated_at': DateTime.now().toIso8601String(),
    };
  }

  ProfileModel copyWith({
    String? fullName,
    String? phone,
    String? email,
    String? avatarUrl,
    String? role,
    String? customerTypeId,
    bool? isActive,
    String? language,
    String? theme,
  }) {
    return ProfileModel(
      id: id,
      fullName: fullName ?? this.fullName,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      role: role ?? this.role,
      customerTypeId: customerTypeId ?? this.customerTypeId,
      isActive: isActive ?? this.isActive,
      language: language ?? this.language,
      theme: theme ?? this.theme,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}

