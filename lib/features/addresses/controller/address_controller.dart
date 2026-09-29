import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/config/supabase_config.dart';
import '../models/address_model.dart';

final addressesProvider = StateNotifierProvider<AddressesNotifier,
    AsyncValue<List<AddressModel>>>(
  (ref) => AddressesNotifier(),
);

class AddressesNotifier extends StateNotifier<AsyncValue<List<AddressModel>>> {
  AddressesNotifier() : super(const AsyncValue.data([]));

  Future<void> loadAddresses() async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) {
      state = const AsyncValue.data([]);
      return;
    }

    try {
      state = const AsyncValue.loading();
      final response = await supabase
          .from('addresses')
          .select()
          .eq('user_id', userId)
          .order('is_default', ascending: false);

      final list = (response as List)
          .map((json) => AddressModel.fromJson(json as Map<String, dynamic>))
          .toList();

      state = AsyncValue.data(list);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> addAddress({
    required String title,
    required String fullAddress,
    String? city,
    String? phone,
    bool isDefault = false,
  }) async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return;

    try {
      if (isDefault) {
        // unset previous defaults
        await supabase
            .from('addresses')
            .update({'is_default': false})
            .eq('user_id', userId);
      }

      await supabase.from('addresses').insert({
        'user_id': userId,
        'title': title,
        'full_address': fullAddress,
        'city': city,
        'phone': phone,
        'is_default': isDefault,
      });

      await loadAddresses();
    } catch (e) {
      await loadAddresses();
    }
  }

  Future<void> deleteAddress(String id) async {
    try {
      await supabase.from('addresses').delete().eq('id', id);
      final current = state.value ?? [];
      state = AsyncValue.data(current.where((a) => a.id != id).toList());
    } catch (e) {
      await loadAddresses();
    }
  }
}

