import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/config/supabase_config.dart';
import '../models/favorite_model.dart';

final favoritesProvider =
    StateNotifierProvider<FavoritesNotifier, AsyncValue<List<FavoriteModel>>>(
  (ref) => FavoritesNotifier(),
);

class FavoritesNotifier extends StateNotifier<AsyncValue<List<FavoriteModel>>> {
  FavoritesNotifier() : super(const AsyncValue.data([]));

  Future<void> loadFavorites() async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) {
      state = const AsyncValue.data([]);
      return;
    }

    try {
      state = const AsyncValue.loading();
      final response = await supabase
          .from('favorites')
          .select('*, products(*)')
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      final favorites = (response as List)
          .map((json) => FavoriteModel.fromJson(json as Map<String, dynamic>))
          .toList();

      state = AsyncValue.data(favorites);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  bool isFavorite(String productId) {
    return state.maybeWhen(
      data: (favorites) => favorites.any((fav) => fav.productId == productId),
      orElse: () => false,
    );
  }

  Future<bool> toggleFavorite(String productId) async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return false;

    final currentFavorites = state.value ?? [];
    final existingIndex =
        currentFavorites.indexWhere((fav) => fav.productId == productId);

    try {
      if (existingIndex >= 0) {
        final fav = currentFavorites[existingIndex];
        await supabase.from('favorites').delete().eq('id', fav.id);
        final updated = List<FavoriteModel>.from(currentFavorites)
          ..removeAt(existingIndex);
        state = AsyncValue.data(updated);
        return false;
      } else {
        final response = await supabase
            .from('favorites')
            .insert({
              'user_id': userId,
              'product_id': productId,
            })
            .select('*, products(*)')
            .single();

        final newFav =
            FavoriteModel.fromJson(response);
        state = AsyncValue.data([newFav, ...currentFavorites]);
        return true;
      }
    } catch (e) {
      // Revert or reload
      await loadFavorites();
      return isFavorite(productId);
    }
  }
}

