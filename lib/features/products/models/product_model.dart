/// Product model matching the `products` table in Supabase.
class ProductModel {
  final int id;
  final int categoryId;
  final String? merchantId;
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
    this.merchantId,
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
    final rawNameAr = json['name_ar'] as String?;
    final rawNameEn = json['name_en'] as String?;
    final nameArVal = (rawNameAr != null && rawNameAr.isNotEmpty)
        ? rawNameAr
        : (rawNameEn ?? '');
    final nameEnVal = (rawNameEn != null && rawNameEn.isNotEmpty)
        ? rawNameEn
        : nameArVal;

    return ProductModel(
      id: (json['id'] as num).toInt(),
      categoryId: (json['category_id'] as num?)?.toInt() ?? 0,
      merchantId: json['merchant_id'] as String?,
      nameAr: nameArVal,
      nameEn: nameEnVal,
      descriptionAr: json['description_ar'] as String?,
      descriptionEn: json['description_en'] as String?,
      sku: json['sku'] as String?,
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      oldPrice: json['old_price'] != null
          ? (json['old_price'] as num).toDouble()
          : null,
      stockQuantity: (json['stock_quantity'] as num?)?.toInt() ?? 0,
      minStock: (json['min_stock'] as num?)?.toInt() ?? 0,
      imageUrl: json['image_url'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      isFeatured: json['is_featured'] as bool? ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'category_id': categoryId,
      'merchant_id': merchantId,
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
    int? categoryId,
    String? merchantId,
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
      merchantId: merchantId ?? this.merchantId,
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

