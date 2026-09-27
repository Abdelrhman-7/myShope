/// Product model matching the `products` table in Supabase.
class ProductModel {
  final String id;
  final String categoryId;
  final String nameAr;
  final String nameEn;
  final String? descriptionAr;
  final String? descriptionEn;
  final String? sku;
  final double price;
  final double? oldPrice;
  final int stockQuantity;
  final int minStock;
  final String? imageUrl;
  final bool isActive;
  final bool isFeatured;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const ProductModel({
    required this.id,
    required this.categoryId,
    required this.nameAr,
    required this.nameEn,
    this.descriptionAr,
    this.descriptionEn,
    this.sku,
    required this.price,
    this.oldPrice,
    this.stockQuantity = 0,
    this.minStock = 0,
    this.imageUrl,
    this.isActive = true,
    this.isFeatured = false,
    this.createdAt,
    this.updatedAt,
  });

  /// Whether the product has a discount (old_price > price)
  bool get hasDiscount => oldPrice != null && oldPrice! > price;

  /// Discount percentage
  int get discountPercentage {
    if (!hasDiscount) return 0;
    return (((oldPrice! - price) / oldPrice!) * 100).round();
  }

  /// Whether the product is in stock
  bool get inStock => stockQuantity > 0;

  /// Whether stock is low
  bool get isLowStock => stockQuantity > 0 && stockQuantity <= minStock;

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      id: json['id'] as String,
      categoryId: json['category_id'] as String,
      nameAr: json['name_ar'] as String? ?? '',
      nameEn: json['name_en'] as String? ?? '',
      descriptionAr: json['description_ar'] as String?,
      descriptionEn: json['description_en'] as String?,
      sku: json['sku'] as String?,
      price: (json['price'] as num).toDouble(),
      oldPrice: json['old_price'] != null
          ? (json['old_price'] as num).toDouble()
          : null,
      stockQuantity: json['stock_quantity'] as int? ?? 0,
      minStock: json['min_stock'] as int? ?? 0,
      imageUrl: json['image_url'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      isFeatured: json['is_featured'] as bool? ?? false,
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
      'category_id': categoryId,
      'name_ar': nameAr,
      'name_en': nameEn,
      'description_ar': descriptionAr,
      'description_en': descriptionEn,
      'sku': sku,
      'price': price,
      'old_price': oldPrice,
      'stock_quantity': stockQuantity,
      'min_stock': minStock,
      'image_url': imageUrl,
      'is_active': isActive,
      'is_featured': isFeatured,
    };
  }

  ProductModel copyWith({
    String? categoryId,
    String? nameAr,
    String? nameEn,
    String? descriptionAr,
    String? descriptionEn,
    String? sku,
    double? price,
    double? oldPrice,
    int? stockQuantity,
    int? minStock,
    String? imageUrl,
    bool? isActive,
    bool? isFeatured,
  }) {
    return ProductModel(
      id: id,
      categoryId: categoryId ?? this.categoryId,
      nameAr: nameAr ?? this.nameAr,
      nameEn: nameEn ?? this.nameEn,
      descriptionAr: descriptionAr ?? this.descriptionAr,
      descriptionEn: descriptionEn ?? this.descriptionEn,
      sku: sku ?? this.sku,
      price: price ?? this.price,
      oldPrice: oldPrice ?? this.oldPrice,
      stockQuantity: stockQuantity ?? this.stockQuantity,
      minStock: minStock ?? this.minStock,
      imageUrl: imageUrl ?? this.imageUrl,
      isActive: isActive ?? this.isActive,
      isFeatured: isFeatured ?? this.isFeatured,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}
