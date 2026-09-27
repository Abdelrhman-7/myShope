/// Order model matching the `orders` table in Supabase.
class OrderModel {
  final String id;
  final String userId;
  final String? orderNumber;
  final String status;
  final double subtotal;
  final double discount;
  final int pointsUsed;
  final double deliveryFee;
  final double total;
  final String? paymentMethod;
  final String? paymentStatus;
  final String? customerName;
  final String? customerPhone;
  final String? address;
  final String? notes;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const OrderModel({
    required this.id,
    required this.userId,
    this.orderNumber,
    this.status = 'pending',
    this.subtotal = 0,
    this.discount = 0,
    this.pointsUsed = 0,
    this.deliveryFee = 0,
    this.total = 0,
    this.paymentMethod,
    this.paymentStatus,
    this.customerName,
    this.customerPhone,
    this.address,
    this.notes,
    this.createdAt,
    this.updatedAt,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    return OrderModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      orderNumber: json['order_number'] as String?,
      status: json['status'] as String? ?? 'pending',
      subtotal: (json['subtotal'] as num?)?.toDouble() ?? 0,
      discount: (json['discount'] as num?)?.toDouble() ?? 0,
      pointsUsed: json['points_used'] as int? ?? 0,
      deliveryFee: (json['delivery_fee'] as num?)?.toDouble() ?? 0,
      total: (json['total'] as num?)?.toDouble() ?? 0,
      paymentMethod: json['payment_method'] as String?,
      paymentStatus: json['payment_status'] as String?,
      customerName: json['customer_name'] as String?,
      customerPhone: json['customer_phone'] as String?,
      address: json['address'] as String?,
      notes: json['notes'] as String?,
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
      'order_number': orderNumber,
      'status': status,
      'subtotal': subtotal,
      'discount': discount,
      'points_used': pointsUsed,
      'delivery_fee': deliveryFee,
      'total': total,
      'payment_method': paymentMethod,
      'payment_status': paymentStatus,
      'customer_name': customerName,
      'customer_phone': customerPhone,
      'address': address,
      'notes': notes,
    };
  }

  OrderModel copyWith({
    String? status,
    String? paymentStatus,
    String? notes,
  }) {
    return OrderModel(
      id: id,
      userId: userId,
      orderNumber: orderNumber,
      status: status ?? this.status,
      subtotal: subtotal,
      discount: discount,
      pointsUsed: pointsUsed,
      deliveryFee: deliveryFee,
      total: total,
      paymentMethod: paymentMethod,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      customerName: customerName,
      customerPhone: customerPhone,
      address: address,
      notes: notes ?? this.notes,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}
