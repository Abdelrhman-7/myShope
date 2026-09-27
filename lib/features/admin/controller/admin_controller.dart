import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/config/supabase_config.dart';
import '../../orders/models/order_model.dart';
import '../../products/models/product_model.dart';
import '../../auth/models/profile_model.dart';

class AdminMetrics {
  final int totalOrders;
  final int totalProducts;
  final int totalCustomers;
  final double totalRevenue;

  const AdminMetrics({
    this.totalOrders = 0,
    this.totalProducts = 0,
    this.totalCustomers = 0,
    this.totalRevenue = 0,
  });
}

final adminMetricsProvider = FutureProvider<AdminMetrics>((ref) async {
  // Fetch counts from Supabase
  final ordersRes = await supabase.from('orders').select('id, total');
  final productsRes = await supabase.from('products').select('id');
  final profilesRes = await supabase.from('profiles').select('id');

  final ordersList = ordersRes as List;
  final totalRevenue = ordersList.fold<double>(
    0.0,
    (sum, o) => sum + ((o['total'] as num?)?.toDouble() ?? 0.0),
  );

  return AdminMetrics(
    totalOrders: ordersList.length,
    totalProducts: (productsRes as List).length,
    totalCustomers: (profilesRes as List).length,
    totalRevenue: totalRevenue,
  );
});

// Admin Orders
final adminOrdersProvider =
    StateNotifierProvider<AdminOrdersNotifier, AsyncValue<List<OrderModel>>>(
  (ref) => AdminOrdersNotifier(),
);

class AdminOrdersNotifier extends StateNotifier<AsyncValue<List<OrderModel>>> {
  AdminOrdersNotifier() : super(const AsyncValue.data([]));

  Future<void> loadOrders() async {
    try {
      state = const AsyncValue.loading();
      final res = await supabase
          .from('orders')
          .select()
          .order('created_at', ascending: false);

      final list = (res as List)
          .map((json) => OrderModel.fromJson(json as Map<String, dynamic>))
          .toList();

      state = AsyncValue.data(list);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> updateStatus(String orderId, String newStatus) async {
    try {
      await supabase
          .from('orders')
          .update({'status': newStatus})
          .eq('id', orderId);

      final current = state.value ?? [];
      final idx = current.indexWhere((o) => o.id == orderId);
      if (idx != -1) {
        final updated = List<OrderModel>.from(current);
        updated[idx] = updated[idx].copyWith(status: newStatus);
        state = AsyncValue.data(updated);
      }
    } catch (e) {
      await loadOrders();
    }
  }
}

// Admin Products
final adminProductsProvider = StateNotifierProvider<AdminProductsNotifier,
    AsyncValue<List<ProductModel>>>(
  (ref) => AdminProductsNotifier(),
);

class AdminProductsNotifier
    extends StateNotifier<AsyncValue<List<ProductModel>>> {
  AdminProductsNotifier() : super(const AsyncValue.data([]));

  Future<void> loadProducts() async {
    try {
      state = const AsyncValue.loading();
      final res = await supabase
          .from('products')
          .select()
          .order('created_at', ascending: false);

      final list = (res as List)
          .map((json) => ProductModel.fromJson(json as Map<String, dynamic>))
          .toList();

      state = AsyncValue.data(list);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> toggleActive(String productId, bool isActive) async {
    try {
      await supabase
          .from('products')
          .update({'is_active': isActive})
          .eq('id', productId);

      final current = state.value ?? [];
      final idx = current.indexWhere((p) => p.id == productId);
      if (idx != -1) {
        final updated = List<ProductModel>.from(current);
        updated[idx] = updated[idx].copyWith(isActive: isActive);
        state = AsyncValue.data(updated);
      }
    } catch (e) {
      await loadProducts();
    }
  }
}

// Admin Customers
final adminCustomersProvider = FutureProvider<List<ProfileModel>>((ref) async {
  final res = await supabase
      .from('profiles')
      .select()
      .order('created_at', ascending: false);

  return (res as List)
      .map((json) => ProfileModel.fromJson(json as Map<String, dynamic>))
      .toList();
});
