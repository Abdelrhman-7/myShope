/// Address model matching the `addresses` table in Supabase.
class AddressModel {
  final String id;
  final String userId;
  final String title;
  final String fullAddress;
  final String? city;
  final String? phone;
  final bool isDefault;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const AddressModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.fullAddress,
    this.city,
    this.phone,
    this.isDefault = false,
    this.createdAt,
    this.updatedAt,
  });

  factory AddressModel.fromJson(Map<String, dynamic> json) {
    return AddressModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      title: json['title'] as String? ?? '',
      fullAddress: json['full_address'] as String? ?? '',
      city: json['city'] as String?,
      phone: json['phone'] as String?,
      isDefault: json['is_default'] as bool? ?? false,
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
      'user_id': userId,
      'title': title,
      'full_address': fullAddress,
      'city': city,
      'phone': phone,
      'is_default': isDefault,
    };
  }

  AddressModel copyWith({
    String? title,
    String? fullAddress,
    String? city,
    String? phone,
    bool? isDefault,
  }) {
    return AddressModel(
      id: id,
      userId: userId,
      title: title ?? this.title,
      fullAddress: fullAddress ?? this.fullAddress,
      city: city ?? this.city,
      phone: phone ?? this.phone,
      isDefault: isDefault ?? this.isDefault,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}
