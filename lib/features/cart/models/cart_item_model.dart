/// CartItem model matching the `cart_items` table in Supabase.
import '../../products/models/product_model.dart';

class CartItemModel {
  final String id;
  final String userId;
  final int productId;
  final int quantity;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  // Joined product data (populated via Supabase select with join)
  final ProductModel? product;

  const CartItemModel({
    required this.id,
    required this.userId,
    required this.productId,
    this.quantity = 1,
    this.createdAt,
    this.updatedAt,
    this.product,
  });

  /// Total price for this cart item line
  double get lineTotal => (product?.price ?? 0) * quantity;

  factory CartItemModel.fromJson(Map<String, dynamic> json) {
    return CartItemModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      productId: (json['product_id'] as num).toInt(),
      quantity: json['quantity'] as int? ?? 1,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
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
      'quantity': quantity,
    };
  }

  CartItemModel copyWith({int? quantity}) {
    return CartItemModel(
      id: id,
      userId: userId,
      productId: productId,
      quantity: quantity ?? this.quantity,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
      product: product,
    );
  }
}

