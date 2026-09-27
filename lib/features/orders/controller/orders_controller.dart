import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/config/supabase_config.dart';
import '../models/order_model.dart';
import '../models/order_item_model.dart';
import '../../cart/controller/cart_controller.dart';
import '../../points/controller/points_controller.dart';

final ordersProvider =
    StateNotifierProvider<OrdersNotifier, AsyncValue<List<OrderModel>>>(
  (ref) => OrdersNotifier(ref),
);

class OrdersNotifier extends StateNotifier<AsyncValue<List<OrderModel>>> {
  final Ref ref;

  OrdersNotifier(this.ref) : super(const AsyncValue.data([]));

  Future<void> loadOrders() async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) {
      state = const AsyncValue.data([]);
      return;
    }

    try {
      state = const AsyncValue.loading();
      final response = await supabase
          .from('orders')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      final orders = (response as List)
          .map((json) => OrderModel.fromJson(json as Map<String, dynamic>))
          .toList();

      state = AsyncValue.data(orders);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<String?> createOrder({
    required String customerName,
    required String customerPhone,
    required String address,
    String? notes,
    int pointsUsed = 0,
    double discount = 0,
  }) async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return null;

    final cartItems = ref.read(cartProvider).value ?? [];
    if (cartItems.isEmpty) return null;

    final subtotal = ref.read(cartProvider.notifier).subtotal;
    const double deliveryFee = 30.0;
    final total = (subtotal - discount + deliveryFee).clamp(0.0, double.infinity);
    final orderNumber =
        'ORD-${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}';

    try {
      // 1. Insert order
      final orderRes = await supabase
          .from('orders')
          .insert({
            'user_id': userId,
            'order_number': orderNumber,
            'status': 'pending',
            'subtotal': subtotal,
            'discount': discount,
            'points_used': pointsUsed,
            'delivery_fee': deliveryFee,
            'total': total,
            'payment_method': 'cash_on_delivery',
            'payment_status': 'pending',
            'customer_name': customerName,
            'customer_phone': customerPhone,
            'address': address,
            'notes': notes,
          })
          .select()
          .single();

      final newOrder = OrderModel.fromJson(orderRes);

      // 2. Insert order items
      final itemsToInsert = cartItems.map((ci) {
        return {
          'order_id': newOrder.id,
          'product_id': ci.productId,
          'product_name': ci.product?.nameAr ?? '',
          'quantity': ci.quantity,
          'unit_price': ci.product?.price ?? 0,
          'discount': 0,
          'total_price': ci.lineTotal,
        };
      }).toList();

      await supabase.from('order_items').insert(itemsToInsert);

      // 3. Insert points earned transaction (e.g. 1 point for every 10 EGP spent)
      final earnedPoints = (total / 10).floor();
      if (earnedPoints > 0) {
        await supabase.from('points_transactions').insert({
          'user_id': userId,
          'points': earnedPoints,
          'transaction_type': 'earned',
          'reference_id': newOrder.id,
          'description_ar': 'نقاط مكتسبة من الطلب $orderNumber',
          'description_en': 'Points earned from order $orderNumber',
        });
      }

      // If points were used/redeemed
      if (pointsUsed > 0) {
        await supabase.from('points_transactions').insert({
          'user_id': userId,
          'points': -pointsUsed,
          'transaction_type': 'redeemed',
          'reference_id': newOrder.id,
          'description_ar': 'خصم نقاط للطلب $orderNumber',
          'description_en': 'Points redeemed for order $orderNumber',
        });
      }

      // 4. Clear cart & reload points
      await ref.read(cartProvider.notifier).clearCart();
      await ref.read(pointsTransactionsProvider.notifier).loadTransactions();
      await loadOrders();

      return newOrder.id;
    } catch (e) {
      return null;
    }
  }
}

final orderItemsFutureProvider =
    FutureProvider.family<List<OrderItemModel>, String>((ref, orderId) async {
  final response = await supabase
      .from('order_items')
      .select()
      .eq('order_id', orderId);

  return (response as List)
      .map((json) => OrderItemModel.fromJson(json as Map<String, dynamic>))
      .toList();
});
