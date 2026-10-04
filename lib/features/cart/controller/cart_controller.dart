import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/config/supabase_config.dart';
import '../../../core/utils/app_logger.dart';
import '../models/cart_item_model.dart';
import '../../products/models/product_model.dart';

final cartProvider =
    StateNotifierProvider<CartNotifier, AsyncValue<List<CartItemModel>>>(
  (ref) => CartNotifier(),
);

class CartNotifier extends StateNotifier<AsyncValue<List<CartItemModel>>> {
  CartNotifier() : super(const AsyncValue.data([]));

  /// Load user cart items from Supabase with joined product data
  Future<void> loadCart() async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) {
      state = const AsyncValue.data([]);
      return;
    }

    try {
      state = const AsyncValue.loading();
      final response = await supabase
          .from('cart_items')
          .select('*, products(*)')
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      final items = (response as List)
          .map((json) => CartItemModel.fromJson(json as Map<String, dynamic>))
          .toList();

      state = AsyncValue.data(items);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Add product to cart with strict stock validation & user auth check.
  /// Returns null on success, or an Arabic error string on failure.
  Future<String?> addToCart(int productId, {int quantity = 1}) async {
    final stopwatch = Stopwatch()..start();
    final userId = supabase.auth.currentUser?.id;

    if (userId == null) {
      AppLogger.logCart(
        'ADD_TO_CART_FAILED',
        userId: 'ANONYMOUS',
        productId: productId,
        quantity: quantity,
        error: 'User not logged in',
        duration: stopwatch.elapsed,
      );
      return 'يرجى تسجيل الدخول أولاً لإضافة منتجات للسلة';
    }

    try {
      // 1. Fetch current product data from Supabase for fresh stock quantity
      final productRes = await supabase
          .from('products')
          .select()
          .eq('id', productId)
          .maybeSingle();

      if (productRes == null) {
        AppLogger.logCart(
          'ADD_TO_CART_FAILED',
          userId: userId,
          productId: productId,
          quantity: quantity,
          error: 'Product not found',
          duration: stopwatch.elapsed,
        );
        return 'عذرًا، المنتج غير موجود';
      }

      final product = ProductModel.fromJson(productRes);

      // 2. Verify stock
      if (product.stockQuantity <= 0 || !product.isActive) {
        AppLogger.logCart(
          'ADD_TO_CART_FAILED',
          userId: userId,
          productId: productId,
          quantity: quantity,
          error: 'Product out of stock',
          duration: stopwatch.elapsed,
        );
        return 'المنتج غير متوفر حاليًا في المخزون';
      }

      final currentItems = state.value ?? [];
      final existingIndex =
          currentItems.indexWhere((item) => item.productId == productId);

      int targetQuantity = quantity;
      if (existingIndex >= 0) {
        targetQuantity += currentItems[existingIndex].quantity;
      }

      // 3. Prevent quantity from exceeding stock_quantity
      if (targetQuantity > product.stockQuantity) {
        AppLogger.logCart(
          'ADD_TO_CART_FAILED',
          userId: userId,
          productId: productId,
          quantity: quantity,
          error: 'Requested quantity ($targetQuantity) exceeds stock (${product.stockQuantity})',
          duration: stopwatch.elapsed,
        );
        return 'عذرًا، الكمية المتاحة في المخزون هي ${product.stockQuantity} فقط';
      }

      // 4. Perform DB operation in Supabase
      if (existingIndex >= 0) {
        final existingItem = currentItems[existingIndex];
        await supabase
            .from('cart_items')
            .update({'quantity': targetQuantity})
            .eq('id', existingItem.id);

        final updatedList = List<CartItemModel>.from(currentItems);
        updatedList[existingIndex] = existingItem.copyWith(
          quantity: targetQuantity,
        );
        state = AsyncValue.data(updatedList);
      } else {
        final response = await supabase
            .from('cart_items')
            .insert({
              'user_id': userId,
              'product_id': productId,
              'quantity': quantity,
            })
            .select('*, products(*)')
            .single();

        final newItem = CartItemModel.fromJson(response);
        state = AsyncValue.data([newItem, ...currentItems]);
      }

      stopwatch.stop();
      AppLogger.logCart(
        'ADD_TO_CART_SUCCESS',
        userId: userId,
        productId: productId,
        quantity: quantity,
        duration: stopwatch.elapsed,
      );
      return null; // Success
    } catch (e) {
      stopwatch.stop();
      AppLogger.logCart(
        'ADD_TO_CART_FAILED',
        userId: userId,
        productId: productId,
        quantity: quantity,
        error: e,
        duration: stopwatch.elapsed,
      );
      await loadCart();
      return 'حدث خطأ أثناء الإضافة للسلة، يرجى المحاولة لاحقاً';
    }
  }

  /// Update cart item quantity with stock boundary check.
  /// Returns null on success or error string.
  Future<String?> updateQuantity(String cartItemId, int newQuantity) async {
    if (newQuantity <= 0) {
      await removeFromCart(cartItemId);
      return null;
    }

    final currentItems = state.value ?? [];
    final index = currentItems.indexWhere((item) => item.id == cartItemId);
    if (index == -1) return 'العنصر غير موجود في السلة';

    final item = currentItems[index];

    // Verify stock bound
    if (item.product != null && newQuantity > item.product!.stockQuantity) {
      return 'عذرًا، الكمية المتاحة في المخزون هي ${item.product!.stockQuantity} فقط';
    }

    try {
      await supabase
          .from('cart_items')
          .update({'quantity': newQuantity})
          .eq('id', cartItemId);

      final updatedList = List<CartItemModel>.from(currentItems);
      updatedList[index] = item.copyWith(quantity: newQuantity);
      state = AsyncValue.data(updatedList);
      return null;
    } catch (e) {
      await loadCart();
      return 'فشل تحديث الكمية';
    }
  }

  /// Remove item from cart table in Supabase
  Future<void> removeFromCart(String cartItemId) async {
    final currentItems = state.value ?? [];
    try {
      await supabase.from('cart_items').delete().eq('id', cartItemId);
      final updatedList =
          currentItems.where((item) => item.id != cartItemId).toList();
      state = AsyncValue.data(updatedList);
    } catch (e) {
      await loadCart();
    }
  }

  /// Clear all cart items for logged in user
  Future<void> clearCart() async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return;

    try {
      await supabase.from('cart_items').delete().eq('user_id', userId);
      state = const AsyncValue.data([]);
    } catch (e) {
      await loadCart();
    }
  }

  double get subtotal {
    final items = state.value ?? [];
    return items.fold(0.0, (sum, item) => sum + item.lineTotal);
  }

  int get totalItemCount {
    final items = state.value ?? [];
    return items.fold(0, (sum, item) => sum + item.quantity);
  }
}
