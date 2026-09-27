import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/config/supabase_config.dart';
import '../models/points_transaction_model.dart';

final pointsTransactionsProvider = StateNotifierProvider<
    PointsTransactionsNotifier,
    AsyncValue<List<PointsTransactionModel>>>(
  (ref) => PointsTransactionsNotifier(),
);

class PointsTransactionsNotifier
    extends StateNotifier<AsyncValue<List<PointsTransactionModel>>> {
  PointsTransactionsNotifier() : super(const AsyncValue.data([]));

  Future<void> loadTransactions() async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) {
      state = const AsyncValue.data([]);
      return;
    }

    try {
      state = const AsyncValue.loading();
      final response = await supabase
          .from('points_transactions')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      final transactions = (response as List)
          .map((json) =>
              PointsTransactionModel.fromJson(json as Map<String, dynamic>))
          .toList();

      state = AsyncValue.data(transactions);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final userPointsBalanceProvider = Provider<int>((ref) {
  final transactions = ref.watch(pointsTransactionsProvider).value ?? [];
  return transactions.fold<int>(0, (sum, tx) {
    if (tx.isCredit) {
      return sum + tx.points.abs();
    } else if (tx.isDebit) {
      return sum - tx.points.abs();
    }
    return sum + tx.points;
  });
});
