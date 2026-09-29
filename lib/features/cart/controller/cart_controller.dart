import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/config/supabase_config.dart';
import '../models/cart_item_model.dart';

final cartProvider =
    StateNotifierProvider<CartNotifier, AsyncValue<List<CartItemModel>>>(
  (ref) => CartNotifier(),
);

class CartNotifier extends StateNotifier<AsyncValue<List<CartItemModel>>> {
  CartNotifier() : super(const AsyncValue.data([]));

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

  Future<void> addToCart(String productId, {int quantity = 1}) async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return;

    final currentItems = state.value ?? [];
    final existingIndex =
        currentItems.indexWhere((item) => item.productId == productId);

    try {
      if (existingIndex >= 0) {
        final existingItem = currentItems[existingIndex];
        final newQty = existingItem.quantity + quantity;
        await supabase
            .from('cart_items')
            .update({'quantity': newQty})
            .eq('id', existingItem.id);

        final updatedList = List<CartItemModel>.from(currentItems);
        updatedList[existingIndex] = existingItem.copyWith(quantity: newQty);
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

        final newItem =
            // ignore: unnecessary_cast
            CartItemModel.fromJson(response as Map<String, dynamic>);
        state = AsyncValue.data([newItem, ...currentItems]);
      }
    } catch (e) {
      await loadCart();
    }
  }

  Future<void> updateQuantity(String cartItemId, int newQuantity) async {
    if (newQuantity <= 0) {
      await removeFromCart(cartItemId);
      return;
    }

    final currentItems = state.value ?? [];
    final index = currentItems.indexWhere((item) => item.id == cartItemId);
    if (index == -1) return;

    try {
      await supabase
          .from('cart_items')
          .update({'quantity': newQuantity})
          .eq('id', cartItemId);

      final updatedList = List<CartItemModel>.from(currentItems);
      updatedList[index] = updatedList[index].copyWith(quantity: newQuantity);
      state = AsyncValue.data(updatedList);
    } catch (e) {
      await loadCart();
    }
  }

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

