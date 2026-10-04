import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/config/supabase_config.dart';
import '../../categories/models/category_model.dart';
import '../../products/models/product_model.dart';
import '../../admin/controller/admin_controller.dart' show AdvertisementModel; // For AdvertisementModel

// ─── Ads Provider ───────────────────────────────────────────────

final homeAdsProvider =
    StateNotifierProvider<HomeAdsNotifier, AsyncValue<List<AdvertisementModel>>>(
  (ref) => HomeAdsNotifier(),
);

class HomeAdsNotifier
    extends StateNotifier<AsyncValue<List<AdvertisementModel>>> {
  HomeAdsNotifier() : super(const AsyncValue.loading());

  Future<void> loadAds() async {
    try {
      state = const AsyncValue.loading();
      final now = DateTime.now().toIso8601String();
      print('=== HOME ADS: LOAD START, now=$now ===');

      final response = await SupabaseConfig.client
          .from('advertisements')
          .select()
          .eq('is_active', true)
          .or('start_at.is.null,start_at.lte.$now')
          .or('end_at.is.null,end_at.gte.$now')
          .order('sort_order', ascending: true)
          .order('created_at', ascending: false);

      final rawList = response as List;
      print('=== HOME ADS: RECEIVED COUNT=${rawList.length} ===');
      for (final item in rawList) {
        print('  AD: id=${item['id']} title_ar=${item['title_ar']} is_active=${item['is_active']}');
      }

      final ads = rawList
          .map((json) => AdvertisementModel.fromJson(json))
          .toList();

      state = AsyncValue.data(ads);
      print('=== HOME ADS: LOAD SUCCESS count=${ads.length} ===');
    } catch (e, st) {
      print('=== HOME ADS: LOAD ERROR ===');
      print('Error: $e');
      print('Type: ${e.runtimeType}');
      print('Stacktrace: $st');
      state = AsyncValue.error(e, st);
    }
  }
}

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
      print('=== HOME CATEGORIES: LOAD START ===');
      final response = await SupabaseConfig.client
          .from('categories')
          .select()
          .eq('is_active', true)
          .order('sort_order');

      final rawList = response as List;
      print('CATEGORIES RAW DATA: $rawList');

      final categories = rawList
          .map((json) => CategoryModel.fromJson(json as Map<String, dynamic>))
          .toList();

      print('=== HOME CATEGORIES: LOAD SUCCESS count=${categories.length} ===');
      state = AsyncValue.data(categories);
    } catch (e, st) {
      print('=== HOME CATEGORIES: LOAD ERROR: $e ===');
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
      print('=== HOME FEATURED: LOAD START ===');

      // Query products table directly from Supabase
      final response = await SupabaseConfig.client
          .from('products')
          .select('*')
          .order('created_at', ascending: false);

      final rawList = response as List;
      print('=== HOME FEATURED: RECEIVED COUNT=${rawList.length} ===');

      final allProducts = rawList
          .map((json) => ProductModel.fromJson(json as Map<String, dynamic>))
          .where((p) => p.isActive)
          .toList();

      // If featured products exist, show them; otherwise show all active products so the user sees their database items
      final featured = allProducts.where((p) => p.isFeatured).toList();
      final productsToShow = featured.isNotEmpty ? featured : allProducts;

      state = AsyncValue.data(productsToShow);
      print('=== HOME FEATURED: LOAD SUCCESS count=${productsToShow.length} ===');
    } catch (e, st) {
      print('=== HOME FEATURED: LOAD ERROR: $e | type=${e.runtimeType} ===');
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
      print('=== HOME OFFERS: LOAD START ===');
      final response = await SupabaseConfig.client
          .from('products')
          .select('*')
          .order('created_at', ascending: false);

      final rawList = response as List;
      print('=== HOME OFFERS: RECEIVED COUNT=${rawList.length} ===');

      final allProducts = rawList
          .map((json) => ProductModel.fromJson(json as Map<String, dynamic>))
          .where((p) => p.isActive)
          .toList();

      final offers = allProducts.where((p) => p.hasDiscount).toList();

      state = AsyncValue.data(offers);
      print('=== HOME OFFERS: LOAD SUCCESS count=${offers.length} ===');
    } catch (e, st) {
      print('=== HOME OFFERS: LOAD ERROR: $e | type=${e.runtimeType} ===');
      state = AsyncValue.error(e, st);
    }
  }
}
