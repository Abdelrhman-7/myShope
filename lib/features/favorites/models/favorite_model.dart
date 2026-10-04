/// Favorite model matching the `favorites` table in Supabase.
import '../../products/models/product_model.dart';

class FavoriteModel {
  final String id;
  final String userId;
  final int productId;
  final DateTime? createdAt;

  // Joined product data
  final ProductModel? product;

  const FavoriteModel({
    required this.id,
    required this.userId,
    required this.productId,
    this.createdAt,
    this.product,
  });

  factory FavoriteModel.fromJson(Map<String, dynamic> json) {
    return FavoriteModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      productId: (json['product_id'] as num).toInt(),
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      product: json['products'] != null
          ? ProductModel.fromJson(json['products'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'product_id': productId,
    };
  }
}

