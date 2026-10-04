import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/config/supabase_config.dart';
import '../../../core/utils/app_logger.dart';
import '../models/favorite_model.dart';

final favoritesProvider =
    StateNotifierProvider<FavoritesNotifier, AsyncValue<List<FavoriteModel>>>(
  (ref) => FavoritesNotifier(),
);

class FavoritesNotifier extends StateNotifier<AsyncValue<List<FavoriteModel>>> {
  FavoritesNotifier() : super(const AsyncValue.data([]));

  /// Load user favorites from Supabase with joined product data
  Future<void> loadFavorites() async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) {
      state = const AsyncValue.data([]);
      return;
    }

    try {
      state = const AsyncValue.loading();

      debugPrint('========== FAVORITE DEBUG: loadFavorites ==========');
      debugPrint('AUTH USER ID: ${supabase.auth.currentUser?.id}');
      debugPrint('OPERATION: SELECT');
      debugPrint('====================================================');

      final response = await supabase
          .from('favorites')
          .select('*, products(*)')
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      debugPrint('FAVORITES RAW DATA: $response');

      final favorites = (response as List)
          .map((json) => FavoriteModel.fromJson(json as Map<String, dynamic>))
          .toList();

      state = AsyncValue.data(favorites);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  bool isFavorite(int productId) {
    return state.maybeWhen(
      data: (favorites) => favorites.any((fav) => fav.productId == productId),
      orElse: () => false,
    );
  }

  /// Toggle favorite status in Supabase.
  /// Returns null on success or Arabic error message string.
  Future<String?> toggleFavorite(int productId) async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) {
      AppLogger.warning(
        'toggleFavorite called without authenticated user',
        tag: 'FAVORITES',
      );
      return 'يرجى تسجيل الدخول أولاً لإضافة المنتجات للمفضلة';
    }

    final currentFavorites = state.value ?? [];
    final existingIndex =
        currentFavorites.indexWhere((fav) => fav.productId == productId);

    try {
      if (existingIndex >= 0) {
        final fav = currentFavorites[existingIndex];

        debugPrint('========== FAVORITE DEBUG ==========');
        debugPrint('AUTH USER ID: ${supabase.auth.currentUser?.id}');
        debugPrint('PRODUCT ID: $productId');
        debugPrint('FAVORITE ROW ID: ${fav.id}');
        debugPrint('OPERATION: DELETE');
        debugPrint('====================================');

        await supabase.from('favorites').delete().eq('id', fav.id);

        final updated = List<FavoriteModel>.from(currentFavorites)
          ..removeAt(existingIndex);
        state = AsyncValue.data(updated);

        AppLogger.logFavorite(
          'FAVORITE_REMOVED',
          userId: userId,
          productId: productId,
        );
        return null;
      } else {
        debugPrint('========== FAVORITE DEBUG ==========');
        debugPrint('AUTH USER ID: ${supabase.auth.currentUser?.id}');
        debugPrint('PRODUCT ID: $productId');
        debugPrint('OPERATION: INSERT');
        debugPrint('PAYLOAD: {user_id: $userId, product_id: $productId}');
        debugPrint('====================================');

        final response = await supabase
            .from('favorites')
            .insert({
              'user_id': userId,
              'product_id': productId,
            })
            .select('*, products(*)')
            .single();

        debugPrint('INSERT RESPONSE: $response');

        final newFav = FavoriteModel.fromJson(response);
        state = AsyncValue.data([newFav, ...currentFavorites]);

        AppLogger.logFavorite(
          'FAVORITE_ADDED',
          userId: userId,
          productId: productId,
        );
        return null;
      }
    } catch (e) {
      debugPrint('========== FAVORITE ERROR ==========');
      debugPrint('AUTH USER ID: ${supabase.auth.currentUser?.id}');
      debugPrint('PRODUCT ID: $productId');
      debugPrint('OPERATION: ${existingIndex >= 0 ? "DELETE" : "INSERT"} FAILED');
      debugPrint('ERROR: $e');
      debugPrint('ERROR TYPE: ${e.runtimeType}');
      debugPrint('====================================');

      AppLogger.error(
        'FAVORITE_FAILED',
        error: e,
        location: 'FavoritesNotifier.toggleFavorite',
        data: {
          'userId': userId,
          'productId': productId,
          'operation': existingIndex >= 0 ? 'DELETE' : 'INSERT',
        },
      );

      await loadFavorites();
      return 'حدث خطأ أثناء تحديث المفضلة';
    }
  }
}
