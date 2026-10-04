import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/config/supabase_config.dart';
import '../models/product_model.dart';

/// Provider for loading all active products from public.products
final productsProvider = StateNotifierProvider<ProductsNotifier, AsyncValue<List<ProductModel>>>(
  (ref) => ProductsNotifier(),
);

class ProductsNotifier extends StateNotifier<AsyncValue<List<ProductModel>>> {
  ProductsNotifier() : super(const AsyncValue.loading()) {
    loadProducts();
  }

  Future<void> loadProducts() async {
    try {
      state = const AsyncValue.loading();
      print('=== PRODUCTS NOTIFIER: FETCHING FROM SUPABASE ===');

      final response = await SupabaseConfig.client
          .from('products')
          .select('*')
          .order('created_at', ascending: false);

      final rawList = response as List;
      print('=== PRODUCTS NOTIFIER: RECEIVED ${rawList.length} ROWS ===');

      final products = rawList
          .map((json) => ProductModel.fromJson(json as Map<String, dynamic>))
          .toList();

      state = AsyncValue.data(products);
      print('=== PRODUCTS NOTIFIER: SUCCESS (${products.length} PRODUCTS) ===');
    } catch (e, st) {
      print('=== PRODUCTS NOTIFIER: ERROR $e ===');
      state = AsyncValue.error(e, st);
    }
  }
}
