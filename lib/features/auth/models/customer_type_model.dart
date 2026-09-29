/// CustomerType model matching the `customer_types` table in Supabase.
class CustomerTypeModel {
  final String id;
  final String nameAr;
  final String nameEn;
  final double discountPercentage;
  final double pointsMultiplier;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const CustomerTypeModel({
    required this.id,
    required this.nameAr,
    required this.nameEn,
    this.discountPercentage = 0,
    this.pointsMultiplier = 1,
    this.isActive = true,
    this.createdAt,
    this.updatedAt,
  });

  factory CustomerTypeModel.fromJson(Map<String, dynamic> json) {
    return CustomerTypeModel(
      id: json['id'] as String,
      nameAr: json['name_ar'] as String? ?? '',
      nameEn: json['name_en'] as String? ?? '',
      discountPercentage:
          (json['discount_percentage'] as num?)?.toDouble() ?? 0,
      pointsMultiplier:
          (json['points_multiplier'] as num?)?.toDouble() ?? 1,
      isActive: json['is_active'] as bool? ?? true,
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
      'name_ar': nameAr,
      'name_en': nameEn,
      'discount_percentage': discountPercentage,
      'points_multiplier': pointsMultiplier,
      'is_active': isActive,
    };
  }

  CustomerTypeModel copyWith({
    String? nameAr,
    String? nameEn,
    double? discountPercentage,
    double? pointsMultiplier,
    bool? isActive,
  }) {
    return CustomerTypeModel(
      id: id,
      nameAr: nameAr ?? this.nameAr,
      nameEn: nameEn ?? this.nameEn,
      discountPercentage: discountPercentage ?? this.discountPercentage,
      pointsMultiplier: pointsMultiplier ?? this.pointsMultiplier,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}

