import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/config/supabase_config.dart';
import '../../categories/models/category_model.dart';
import '../../products/models/product_model.dart';

// ─── Categories Provider ────────────────────────────────────────

final homeCategoriesProvider =
    StateNotifierProvider<HomeCategoriesNotifier, AsyncValue<List<CategoryModel>>>(
  (ref) => HomeCategoriesNotifier(),
);

class HomeCategoriesNotifier
    extends StateNotifier<AsyncValue<List<CategoryModel>>> {
  HomeCategoriesNotifier() : super(const AsyncValue.loading());

  Future<void> loadCategories() async {
    try {
      state = const AsyncValue.loading();
      final response = await SupabaseConfig.client
          .from('categories')
          .select()
          .eq('is_active', true)
          .order('sort_order');

      final categories = (response as List)
          .map((json) => CategoryModel.fromJson(json))
          .toList();

      state = AsyncValue.data(categories);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

// ─── Featured Products Provider ─────────────────────────────────

final homeFeaturedProductsProvider = StateNotifierProvider<
    HomeFeaturedProductsNotifier, AsyncValue<List<ProductModel>>>(
  (ref) => HomeFeaturedProductsNotifier(),
);

class HomeFeaturedProductsNotifier
    extends StateNotifier<AsyncValue<List<ProductModel>>> {
  HomeFeaturedProductsNotifier() : super(const AsyncValue.loading());

  Future<void> loadFeaturedProducts() async {
    try {
      state = const AsyncValue.loading();
      final response = await SupabaseConfig.client
          .from('products')
          .select()
          .eq('is_active', true)
          .eq('is_featured', true)
          .order('created_at', ascending: false)
          .limit(10);

      final products = (response as List)
          .map((json) => ProductModel.fromJson(json))
          .toList();

      state = AsyncValue.data(products);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

// ─── Offers (Products with old_price) ───────────────────────────

final homeOffersProvider =
    StateNotifierProvider<HomeOffersNotifier, AsyncValue<List<ProductModel>>>(
  (ref) => HomeOffersNotifier(),
);

class HomeOffersNotifier
    extends StateNotifier<AsyncValue<List<ProductModel>>> {
  HomeOffersNotifier() : super(const AsyncValue.loading());

  Future<void> loadOffers() async {
    try {
      state = const AsyncValue.loading();
      final response = await SupabaseConfig.client
          .from('products')
          .select()
          .eq('is_active', true)
          .not('old_price', 'is', null)
          .order('created_at', ascending: false)
          .limit(10);

      final products = (response as List)
          .map((json) => ProductModel.fromJson(json))
          .toList();

      state = AsyncValue.data(products);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}
