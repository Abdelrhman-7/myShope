import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/config/supabase_config.dart';
import '../../orders/models/order_model.dart';
import '../../products/models/product_model.dart';
import '../../auth/models/profile_model.dart';

// ─── Admin Metrics Model ─────────────────────────────────────────────────
class AdminMetrics {
  final int totalOrders;
  final int totalProducts;
  final int totalCustomers;
  final int totalMerchants;
  final double totalRevenue;
  final double netProfit;
  final double totalDiscount;
  final int pendingOrders;
  final int deliveredOrders;

  const AdminMetrics({
    this.totalOrders = 0,
    this.totalProducts = 0,
    this.totalCustomers = 0,
    this.totalMerchants = 0,
    this.totalRevenue = 0,
    this.netProfit = 0,
    this.totalDiscount = 0,
    this.pendingOrders = 0,
    this.deliveredOrders = 0,
  });
}

// ─── Admin Metrics Provider ───────────────────────────────────────────────
final adminMetricsProvider = FutureProvider<AdminMetrics>((ref) async {
  final ordersRes =
      await supabase.from('orders').select('id, total, discount_amount, status, cost');
  final productsRes = await supabase.from('products').select('id');
  final profilesRes =
      await supabase.from('profiles').select('id, role');

  final ordersList = ordersRes as List;
  final profilesList = profilesRes as List;

  final totalRevenue = ordersList.fold<double>(
    0.0,
    (sum, o) => sum + ((o['total'] as num?)?.toDouble() ?? 0.0),
  );
  final totalDiscount = ordersList.fold<double>(
    0.0,
    (sum, o) => sum + ((o['discount_amount'] as num?)?.toDouble() ?? 0.0),
  );
  final totalCost = ordersList.fold<double>(
    0.0,
    (sum, o) => sum + ((o['cost'] as num?)?.toDouble() ?? 0.0),
  );

  final pendingOrders =
      ordersList.where((o) => o['status'] == 'pending').length;
  final deliveredOrders =
      ordersList.where((o) => o['status'] == 'delivered').length;

  final totalMerchants =
      profilesList.where((p) => p['role'] == 'merchant').length;
  final totalCustomers =
      profilesList.where((p) => p['role'] == 'customer').length;

  // Net Profit = Revenue - Costs - Discounts
  final netProfit = totalRevenue - totalCost - totalDiscount;

  return AdminMetrics(
    totalOrders: ordersList.length,
    totalProducts: (productsRes as List).length,
    totalCustomers: totalCustomers,
    totalMerchants: totalMerchants,
    totalRevenue: totalRevenue,
    netProfit: netProfit,
    totalDiscount: totalDiscount,
    pendingOrders: pendingOrders,
    deliveredOrders: deliveredOrders,
  );
});

// ─── Admin Orders ─────────────────────────────────────────────────────────
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
          .update({'status': newStatus}).eq('id', orderId);

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

// ─── Admin Products ───────────────────────────────────────────────────────
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
          .update({'is_active': isActive}).eq('id', productId);

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

// ─── Admin Customers (Users) ──────────────────────────────────────────────
final adminCustomersProvider =
    StateNotifierProvider<AdminCustomersNotifier, AsyncValue<List<ProfileModel>>>(
  (ref) => AdminCustomersNotifier(),
);

class AdminCustomersNotifier
    extends StateNotifier<AsyncValue<List<ProfileModel>>> {
  AdminCustomersNotifier() : super(const AsyncValue.data([]));

  Future<void> loadCustomers() async {
    try {
      state = const AsyncValue.loading();
      final res = await supabase
          .from('profiles')
          .select()
          .order('created_at', ascending: false);

      final list = (res as List)
          .map((json) => ProfileModel.fromJson(json as Map<String, dynamic>))
          .toList();

      state = AsyncValue.data(list);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Update user role — admin only operation (enforced by Supabase RLS)
  Future<bool> updateUserRole(String userId, String newRole) async {
    try {
      await supabase
          .from('profiles')
          .update({'role': newRole}).eq('id', userId);

      final current = state.value ?? [];
      final idx = current.indexWhere((p) => p.id == userId);
      if (idx != -1) {
        final updated = List<ProfileModel>.from(current);
        updated[idx] = updated[idx].copyWith(role: newRole);
        state = AsyncValue.data(updated);
      }
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Toggle user active status
  Future<bool> toggleUserActive(String userId, bool isActive) async {
    try {
      await supabase
          .from('profiles')
          .update({'is_active': isActive}).eq('id', userId);

      final current = state.value ?? [];
      final idx = current.indexWhere((p) => p.id == userId);
      if (idx != -1) {
        final updated = List<ProfileModel>.from(current);
        updated[idx] = updated[idx].copyWith(isActive: isActive);
        state = AsyncValue.data(updated);
      }
      return true;
    } catch (e) {
      return false;
    }
  }
}

