import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/supabase_config.dart';
import '../../../core/utils/app_logger.dart';

import '../models/order_model.dart';
import '../models/order_item_model.dart';

import '../../cart/controller/cart_controller.dart';
import '../../cart/models/cart_item_model.dart';

final ordersProvider =
    StateNotifierProvider<OrdersNotifier, AsyncValue<List<OrderModel>>>(
      (ref) => OrdersNotifier(ref),
    );

class OrderCreationResult {
  final String? orderId;
  final String? errorMessage;

  bool get isSuccess => orderId != null;

  OrderCreationResult.success(this.orderId) : errorMessage = null;

  OrderCreationResult.failure(this.errorMessage) : orderId = null;
}

class OrdersNotifier extends StateNotifier<AsyncValue<List<OrderModel>>> {
  final Ref ref;

  OrdersNotifier(this.ref) : super(const AsyncValue.data([]));

  // ============================================================
  // LOAD ORDERS
  // ============================================================

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

  // ============================================================
  // CREATE ORDER — uses create_order RPC (atomic transaction)
  // ============================================================

  Future<OrderCreationResult> createOrder({
    required String customerName,
    required String customerPhone,
    required String address,
    String? notes,
    int pointsUsed = 0,
    double discount = 0,
    String paymentMethod = 'cash_on_delivery',
    List<CartItemModel>? overrideItems,
  }) async {
    final stopwatch = Stopwatch()..start();

    final currentUser = supabase.auth.currentUser;
    if (currentUser == null) {
      stopwatch.stop();
      AppLogger.logOrder(
        'ORDER_CREATE_FAILED',
        userId: 'NO_SESSION',
        error: 'User not authenticated',
        duration: stopwatch.elapsed,
      );
      return OrderCreationResult.failure(
        'انتهت جلسة تسجيل الدخول، يرجى تسجيل الدخول مرة أخرى',
      );
    }

    final userId = currentUser.id;

    final itemsToPurchase =
        overrideItems ?? ref.read(cartProvider).value ?? [];

    if (itemsToPurchase.isEmpty) {
      stopwatch.stop();
      AppLogger.logOrder(
        'ORDER_CREATE_FAILED',
        userId: userId,
        error: 'Cart is empty',
        duration: stopwatch.elapsed,
      );
      return OrderCreationResult.failure(
        'السلة فارغة، يرجى إضافة منتجات أولاً',
      );
    }

    const double deliveryFee = 30.0;

    final itemsPayload = itemsToPurchase
        .map((item) => {
              'product_id': item.productId,
              'quantity': item.quantity,
            })
        .toList();

    AppLogger.logOrder(
      'ORDER_CREATE_START',
      userId: userId,
      quantity: itemsToPurchase.length,
      paymentMethod: paymentMethod,
      duration: stopwatch.elapsed,
    );

    try {
      AppLogger.info(
        '━━━━━━━━━━━━ ORDER_RPC_START ━━━━━━━━━━━━\n'
        'USER ID      : $userId\n'
        'ITEMS COUNT  : ${itemsToPurchase.length}\n'
        'PAYMENT      : $paymentMethod\n'
        'ADDRESS      : $address\n'
        'DELIVERY FEE : $deliveryFee\n'
        'DISCOUNT     : $discount\n'
        'POINTS USED  : $pointsUsed\n'
        'TIME         : ${DateTime.now()}\n'
        'ITEMS PAYLOAD: $itemsPayload\n'
        '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━',
        tag: 'ORDERS',
      );

      final dynamic rpcResponse = await supabase.rpc(
        'create_order',
        params: {
          'p_customer_name':  customerName,
          'p_customer_phone': customerPhone,
          'p_address':        address,
          'p_payment_method': paymentMethod,
          'p_notes':          notes,
          'p_discount':       discount,
          'p_points_used':    pointsUsed,
          'p_delivery_fee':   deliveryFee,
          'p_items':          itemsPayload,
        },
      );

      final Map<String, dynamic> result =
          Map<String, dynamic>.from(rpcResponse as Map);

      stopwatch.stop();

      final bool success = result['success'] as bool? ?? false;

      if (!success) {
        final String rawMessage =
            result['message'] as String? ?? 'حدث خطأ غير متوقع';
        final int? availableStock = result['available_stock'] as int?;

        AppLogger.info(
          '━━━━━━━━━━━━ ORDER_RPC_FAILED ━━━━━━━━━━━━\n'
          'MESSAGE        : $rawMessage\n'
          'AVAILABLE STOCK: ${availableStock ?? "N/A"}\n'
          'DURATION       : ${stopwatch.elapsedMilliseconds} ms\n'
          'TIME           : ${DateTime.now()}\n'
          '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━',
          tag: 'ORDERS',
        );

        AppLogger.logOrder(
          'ORDER_CREATE_FAILED',
          userId: userId,
          error: rawMessage,
          duration: stopwatch.elapsed,
        );

        return OrderCreationResult.failure(
          _translateOrderError(rawMessage, availableStock: availableStock),
        );
      }

      final String orderId     = result['order_id']     as String;
      final String orderNumber = result['order_number'] as String? ?? '';
      final num    total       = result['total']        as num? ?? 0;

      AppLogger.info(
        '━━━━━━━━━━━━ ORDER_RPC_SUCCESS ━━━━━━━━━━━━\n'
        'ORDER ID    : $orderId\n'
        'ORDER NUMBER: $orderNumber\n'
        'TOTAL       : $total\n'
        'ITEMS COUNT : ${itemsToPurchase.length}\n'
        'DURATION    : ${stopwatch.elapsedMilliseconds} ms\n'
        'TIME        : ${DateTime.now()}\n'
        '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━',
        tag: 'ORDERS',
      );

      AppLogger.logOrder(
        'ORDER_CREATED',
        userId: userId,
        orderId: orderId,
        quantity: itemsToPurchase.length,
        paymentMethod: paymentMethod,
        orderStatus: 'pending',
        duration: stopwatch.elapsed,
      );

      if (overrideItems == null) {
        try {
          await ref.read(cartProvider.notifier).clearCart();
        } catch (cartError) {
          AppLogger.warning(
            'CLEAR_CART_FAILED after order $orderId: $cartError',
            tag: 'CART',
          );
        }
      }

      await loadOrders();

      return OrderCreationResult.success(orderId);

    } catch (e) {
      stopwatch.stop();

      String errorCode    = '';
      String errorMessage = e.toString();
      String errorDetails = '';
      String errorHint    = '';

      try {
        final dynamic dynErr = e;
        errorCode    = (dynErr.code    as String?) ?? '';
        errorMessage = (dynErr.message as String?) ?? e.toString();
        errorDetails = (dynErr.details as String?) ?? '';
        errorHint    = (dynErr.hint    as String?) ?? '';
      } catch (_) {}

      AppLogger.info(
        '━━━━━━━━━━━━ ORDER_RPC_FAILED (EXCEPTION) ━━━━━━━━━━━━\n'
        'ERROR CODE   : $errorCode\n'
        'ERROR MESSAGE: $errorMessage\n'
        'ERROR DETAILS: $errorDetails\n'
        'ERROR HINT   : $errorHint\n'
        'DURATION     : ${stopwatch.elapsedMilliseconds} ms\n'
        'TIME         : ${DateTime.now()}\n'
        '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━',
        tag: 'ORDERS',
      );

      AppLogger.error(
        'ORDER_CREATE_EXCEPTION',
        error: e,
        location: 'OrdersNotifier.createOrder',
        data: {
          'userId':        userId,
          'items':         itemsToPurchase.length,
          'paymentMethod': paymentMethod,
          'errorCode':     errorCode,
        },
      );

      AppLogger.logOrder(
        'ORDER_CREATE_FAILED',
        userId: userId,
        error: e,
        duration: stopwatch.elapsed,
      );

      if (errorCode == 'PGRST202') {
        return OrderCreationResult.failure(
          'خطأ في النظام: الدالة غير موجودة في قاعدة البيانات. '
          'يرجى التواصل مع الدعم الفني. (PGRST202)',
        );
      }

      return OrderCreationResult.failure(
        _translateOrderError(errorMessage),
      );
    }
  }

  // ============================================================
  // TRANSLATE ORDER ERRORS (DB → Arabic UI messages)
  // ============================================================

  String _translateOrderError(
    String rawMessage, {
    int? availableStock,
  }) {
    if (rawMessage.contains('out of stock')) {
      return 'عذراً، المنتج غير متوفر في المخزون حالياً';
    }
    if (rawMessage.contains('Insufficient stock')) {
      return availableStock != null
          ? 'عذراً، الكمية المتاحة في المخزون هي $availableStock فقط'
          : 'عذراً، الكمية المطلوبة غير متوفرة في المخزون';
    }
    if (rawMessage.contains('Cart is empty')) {
      return 'السلة فارغة، يرجى إضافة منتجات أولاً';
    }
    if (rawMessage.contains('not active')) {
      return 'عذراً، أحد المنتجات لم يعد متوفراً';
    }
    if (rawMessage.contains('not found')) {
      return 'عذراً، أحد المنتجات غير موجود';
    }
    if (rawMessage.contains('Unauthorized')) {
      return 'يرجى تسجيل الدخول أولاً لإتمام الطلب';
    }
    if (rawMessage.contains('PGRST202')) {
      return 'خطأ في النظام: دالة إنشاء الطلب غير موجودة. (PGRST202)';
    }
    return 'حدث خطأ أثناء إرسال الطلب، يرجى المحاولة مرة أخرى';
  }
}

// ================================================================
// ORDER ITEMS
// ================================================================

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