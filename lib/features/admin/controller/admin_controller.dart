import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shope/core/utils/app_logger.dart';
import '../../../core/config/supabase_config.dart';
import '../../orders/models/order_model.dart';
import '../../products/models/product_model.dart';
import '../../auth/models/profile_model.dart';

// ─── Admin Metrics Model ─────────────────────────────────────────────────────
class AdminMetrics {
  final int totalOrders;
  final int totalProducts;
  final int totalCustomers;
  final int totalMerchants;
  final double totalRevenue;
  final double todayRevenue;
  final double weekRevenue;
  final double monthRevenue;
  final double netProfit;
  final double totalDiscount;
  final int pendingOrders;
  final int processingOrders;
  final int deliveredOrders;
  final int cancelledOrders;
  final int lowStockProducts;
  final int inactiveProducts;
  final int activeAds;

  const AdminMetrics({
    this.totalOrders = 0,
    this.totalProducts = 0,
    this.totalCustomers = 0,
    this.totalMerchants = 0,
    this.totalRevenue = 0,
    this.todayRevenue = 0,
    this.weekRevenue = 0,
    this.monthRevenue = 0,
    this.netProfit = 0,
    this.totalDiscount = 0,
    this.pendingOrders = 0,
    this.processingOrders = 0,
    this.deliveredOrders = 0,
    this.cancelledOrders = 0,
    this.lowStockProducts = 0,
    this.inactiveProducts = 0,
    this.activeAds = 0,
  });
}

// ─── Admin Metrics Provider ───────────────────────────────────────────────────
final adminMetricsProvider = FutureProvider<AdminMetrics>((ref) async {
  final now = DateTime.now();
  final todayStart = DateTime(now.year, now.month, now.day);
  final weekStart = todayStart.subtract(Duration(days: now.weekday - 1));
  final monthStart = DateTime(now.year, now.month, 1);

  final ordersRes = await supabase
      .from('orders')
      .select('id, total, discount_amount, status, cost, created_at');
  final productsRes = await supabase
      .from('products')
      .select('id, stock_quantity, min_stock, is_active');
  final profilesRes = await supabase.from('profiles').select('id, role');

  // Ads — gracefully handle if table doesn't exist
  List adsRes = [];
  try {
    adsRes = await supabase.from('advertisements').select('id, is_active');
  } catch (_) {}

  final ordersList = ordersRes as List;
  final productsList = productsRes as List;
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

  // Date-based revenue
  double todayRev = 0, weekRev = 0, monthRev = 0;
  for (final o in ordersList) {
    final createdAt = o['created_at'] != null
        ? DateTime.tryParse(o['created_at'] as String)
        : null;
    if (createdAt == null) continue;
    final amount = (o['total'] as num?)?.toDouble() ?? 0.0;
    if (createdAt.isAfter(todayStart)) todayRev += amount;
    if (createdAt.isAfter(weekStart)) weekRev += amount;
    if (createdAt.isAfter(monthStart)) monthRev += amount;
  }

  return AdminMetrics(
    totalOrders: ordersList.length,
    totalProducts: productsList.length,
    totalCustomers: profilesList.where((p) => p['role'] == 'customer').length,
    totalMerchants: profilesList.where((p) => p['role'] == 'merchant').length,
    totalRevenue: totalRevenue,
    todayRevenue: todayRev,
    weekRevenue: weekRev,
    monthRevenue: monthRev,
    netProfit: totalRevenue - totalCost - totalDiscount,
    totalDiscount: totalDiscount,
    pendingOrders: ordersList.where((o) => o['status'] == 'pending').length,
    processingOrders: ordersList
        .where((o) => o['status'] == 'processing')
        .length,
    deliveredOrders: ordersList.where((o) => o['status'] == 'delivered').length,
    cancelledOrders: ordersList.where((o) => o['status'] == 'cancelled').length,
    lowStockProducts: productsList.where((p) {
      final qty = (p['stock_quantity'] as num?)?.toInt() ?? 0;
      final min = (p['min_stock'] as num?)?.toInt() ?? 0;
      return qty <= min && qty > 0;
    }).length,
    inactiveProducts: productsList.where((p) => p['is_active'] == false).length,
    activeAds: adsRes.where((a) => a['is_active'] == true).length,
  );
});

// ─── Admin Orders ─────────────────────────────────────────────────────────────
final adminOrdersProvider =
    StateNotifierProvider<AdminOrdersNotifier, AsyncValue<List<OrderModel>>>(
      (ref) => AdminOrdersNotifier(),
    );

class AdminOrdersNotifier extends StateNotifier<AsyncValue<List<OrderModel>>> {
  StreamSubscription? _realtimeSubscription;

  AdminOrdersNotifier() : super(const AsyncValue.data([])) {
    loadOrders();
    _subscribeRealtime();
  }

  @override
  void dispose() {
    _realtimeSubscription?.cancel();
    super.dispose();
  }

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

  void _subscribeRealtime() {
    try {
      _realtimeSubscription = supabase
          .from('orders')
          .stream(primaryKey: ['id'])
          .order('created_at', ascending: false)
          .listen((data) {
            final list = data.map((json) => OrderModel.fromJson(json)).toList();

            state = AsyncValue.data(list);
          });
    } catch (e) {
      AppLogger.error('Admin orders realtime stream error: $e');
    }
  }

  /// Accept order (orders.status = 'accepted')
  Future<bool> acceptOrder(String orderId) async {
    return updateStatus(orderId, 'accepted');
  }

  /// Reject order (orders.status = 'rejected') and restore stock
  Future<bool> rejectOrder(String orderId) async {
    return updateStatus(orderId, 'rejected');
  }

  /// Update order status with customer notification & stock restoration on rejection
  Future<bool> updateStatus(String orderId, String newStatus) async {
    try {
      final current = state.value ?? [];
      final idx = current.indexWhere((o) => o.id == orderId);
      final order = idx != -1 ? current[idx] : null;

      // 1. If rejecting an order that was not previously rejected, restore product stock
      if (newStatus == 'rejected' &&
          order != null &&
          order.status != 'rejected') {
        try {
          final itemsRes = await supabase
              .from('order_items')
              .select('product_id, quantity')
              .eq('order_id', orderId);

          for (final item in itemsRes as List) {
            final pid = (item['product_id'] as num).toInt();
            final qty = (item['quantity'] as num).toInt();

            final pRes = await supabase
                .from('products')
                .select('stock_quantity')
                .eq('id', pid)
                .maybeSingle();

            if (pRes != null) {
              final oldStock = (pRes['stock_quantity'] as num?)?.toInt() ?? 0;
              final newStock = oldStock + qty;
              await supabase
                  .from('products')
                  .update({'stock_quantity': newStock})
                  .eq('id', pid);

              AppLogger.logStock(
                productId: pid,
                oldStock: oldStock,
                newStock: newStock,
              );
            }
          }
        } catch (err) {
          AppLogger.error(
            'Failed to restore stock for rejected order $orderId',
            error: err,
          );
        }
      }

      // 2. Update order status in Supabase
      await supabase
          .from('orders')
          .update({
            'status': newStatus,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', orderId);

      // 3. Send notification to Customer
      if (order != null) {
        String notifTitle = 'تحديث حالة الطلب';
        String notifMsg =
            'تم تغيير حالة طلبك رقم ${order.orderNumber ?? orderId.substring(0, 8)} إلى ${_translateStatus(newStatus)}.';

        if (newStatus == 'accepted') {
          notifTitle = 'تم قبول طلبك';
          notifMsg =
              'تهانينا! تمت الموافقة على طلبك رقم ${order.orderNumber ?? orderId.substring(0, 8)} وهو قيد التجهيز الآن.';
          AppLogger.logAdmin(
            'ADMIN_ORDER_ACCEPTED',
            orderId: orderId,
            orderStatus: newStatus,
          );
        } else if (newStatus == 'rejected') {
          notifTitle = 'تم رفض طلبك';
          notifMsg =
              'عذراً، تم رفض طلبك رقم ${order.orderNumber ?? orderId.substring(0, 8)}.';
          AppLogger.logAdmin(
            'ADMIN_ORDER_REJECTED',
            orderId: orderId,
            orderStatus: newStatus,
          );
        }

        try {
          await supabase.from('notifications').insert({
            'user_id': order.userId,
            'title': notifTitle,
            'message': notifMsg,
            'type': 'order',
            'related_order_id': orderId,
            'is_read': false,
          });
        } catch (_) {}
      }

      await loadOrders();
      return true;
    } catch (e) {
      AppLogger.error('Error updating order status for $orderId', error: e);
      await loadOrders();
      return false;
    }
  }

  String _translateStatus(String s) {
    switch (s) {
      case 'accepted':
        return 'مقبول';
      case 'rejected':
        return 'مرفوض';
      case 'preparing':
        return 'قيد التجهيز';
      case 'shipped':
        return 'تم الشحن';
      case 'delivered':
        return 'تم التسليم';
      case 'cancelled':
        return 'ملغى';
      default:
        return 'قيد الانتظار';
    }
  }
}

// ─── Admin Products ───────────────────────────────────────────────────────────
final adminProductsProvider =
    StateNotifierProvider<
      AdminProductsNotifier,
      AsyncValue<List<ProductModel>>
    >((ref) => AdminProductsNotifier());

class AdminProductsNotifier
    extends StateNotifier<AsyncValue<List<ProductModel>>> {
  AdminProductsNotifier() : super(const AsyncValue.data([]));

  Future<void> loadProducts() async {
    try {
      print('=== DATABASE: PRODUCTS LOAD START ===');
      state = const AsyncValue.loading();
      final res = await supabase
          .from('products')
          .select()
          .order('created_at', ascending: false);

      print(
        '=== DATABASE: PRODUCTS RECEIVED, COUNT: ${(res as List).length} ===',
      );

      final list = (res as List)
          .map((json) => ProductModel.fromJson(json as Map<String, dynamic>))
          .toList();

      state = AsyncValue.data(list);
      print('=== DATABASE: PRODUCTS LOAD SUCCESS ===');
    } catch (e, st) {
      print('=== DATABASE: PRODUCTS LOAD ERROR ===');
      print('Error: $e');
      print('Type: ${e.runtimeType}');
      print('Stacktrace: $st');
      state = AsyncValue.error(e, st);
    }
  }

  Future<bool> toggleActive(int productId, bool isActive) async {
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
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<String?> createProduct(Map<String, dynamic> data) async {
    try {
      await supabase.from('products').insert(data);
      await loadProducts();
      return null; // success
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> updateProduct(
    int productId,
    Map<String, dynamic> data,
  ) async {
    try {
      await supabase.from('products').update(data).eq('id', productId);
      await loadProducts();
      return null; // success
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> deleteProduct(int productId) async {
    try {
      // Delete images first (FK constraint)
      await supabase
          .from('product_images')
          .delete()
          .eq('product_id', productId);
      // Delete from cart & favorites
      await supabase.from('cart_items').delete().eq('product_id', productId);
      await supabase.from('favorites').delete().eq('product_id', productId);
      // Finally delete product
      await supabase.from('products').delete().eq('id', productId);

      final current = state.value ?? [];
      state = AsyncValue.data(current.where((p) => p.id != productId).toList());
      return null; // success
    } catch (e) {
      return e.toString();
    }
  }
}

// ─── Admin Customers ──────────────────────────────────────────────────────────
final adminCustomersProvider =
    StateNotifierProvider<
      AdminCustomersNotifier,
      AsyncValue<List<ProfileModel>>
    >((ref) => AdminCustomersNotifier());

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

  Future<bool> updateUserRole(String userId, String newRole) async {
    try {
      await supabase
          .from('profiles')
          .update({'role': newRole})
          .eq('id', userId);

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

  Future<bool> toggleUserActive(String userId, bool isActive) async {
    try {
      await supabase
          .from('profiles')
          .update({'is_active': isActive})
          .eq('id', userId);

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

  Future<bool> deleteCustomer(String userId) async {
    try {
      // Very strict safe delete, handle foreign keys manually if needed
      await supabase.from('profiles').delete().eq('id', userId);
      final current = state.value ?? [];
      state = AsyncValue.data(current.where((p) => p.id != userId).toList());
      return true;
    } catch (e) {
      return false;
    }
  }
}

// ─── Category Model ───────────────────────────────────────────────────────────
class CategoryModel {
  final int id;
  final String nameAr;
  final String nameEn;
  final String? descriptionAr;
  final String? descriptionEn;
  final String? imageUrl;
  final bool isActive;
  final int sortOrder;
  final DateTime? createdAt;

  const CategoryModel({
    required this.id,
    required this.nameAr,
    required this.nameEn,
    this.descriptionAr,
    this.descriptionEn,
    this.imageUrl,
    this.isActive = true,
    this.sortOrder = 0,
    this.createdAt,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: (json['id'] as num).toInt(),
      nameAr: json['name_ar'] as String? ?? '',
      nameEn: json['name_en'] as String? ?? '',
      descriptionAr: json['description_ar'] as String?,
      descriptionEn: json['description_en'] as String?,
      imageUrl: json['image_url'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      sortOrder: (json['sort_order'] as num?)?.toInt() ?? 0,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
    );
  }

  CategoryModel copyWith({bool? isActive, String? nameAr, String? nameEn}) {
    return CategoryModel(
      id: id,
      nameAr: nameAr ?? this.nameAr,
      nameEn: nameEn ?? this.nameEn,
      descriptionAr: descriptionAr,
      descriptionEn: descriptionEn,
      imageUrl: imageUrl,
      isActive: isActive ?? this.isActive,
      sortOrder: sortOrder,
      createdAt: createdAt,
    );
  }
}

// ─── Admin Categories ─────────────────────────────────────────────────────────
final adminCategoriesProvider =
    StateNotifierProvider<
      AdminCategoriesNotifier,
      AsyncValue<List<CategoryModel>>
    >((ref) => AdminCategoriesNotifier());

class AdminCategoriesNotifier
    extends StateNotifier<AsyncValue<List<CategoryModel>>> {
  AdminCategoriesNotifier() : super(const AsyncValue.data([]));

  Future<void> loadCategories() async {
    try {
      state = const AsyncValue.loading();
      final res = await supabase
          .from('categories')
          .select()
          .order('sort_order', ascending: true);

      final list = (res as List).map((json) {
        // print('CATEGORIES RAW: $json');
        return CategoryModel.fromJson(json as Map<String, dynamic>);
      }).toList();
      // print('CATEGORIES PARSED: ${list.length}');

      state = AsyncValue.data(list);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<bool> toggleActive(int categoryId, bool isActive) async {
    try {
      await supabase
          .from('categories')
          .update({'is_active': isActive})
          .eq('id', categoryId);

      final current = state.value ?? [];
      final idx = current.indexWhere((c) => c.id == categoryId);
      if (idx != -1) {
        final updated = List<CategoryModel>.from(current);
        updated[idx] = updated[idx].copyWith(isActive: isActive);
        state = AsyncValue.data(updated);
      }
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> deleteCategory(int categoryId) async {
    try {
      await supabase.from('categories').delete().eq('id', categoryId);
      final current = state.value ?? [];
      state = AsyncValue.data(
        current.where((c) => c.id != categoryId).toList(),
      );
      return true;
    } catch (e) {
      return false;
    }
  }
}

// ─── Advertisement Model ──────────────────────────────────────────────────────
class AdvertisementModel {
  final String id;
  final String titleAr;
  final String titleEn;
  final String? descriptionAr;
  final String? descriptionEn;
  final String? imageUrl;
  final String? targetUrl;
  final bool isActive;
  final DateTime? startAt;
  final DateTime? endAt;
  final int sortOrder;
  final String? createdBy;
  final DateTime? createdAt;

  const AdvertisementModel({
    required this.id,
    required this.titleAr,
    required this.titleEn,
    this.descriptionAr,
    this.descriptionEn,
    this.imageUrl,
    this.targetUrl,
    this.isActive = true,
    this.startAt,
    this.endAt,
    this.sortOrder = 0,
    this.createdBy,
    this.createdAt,
  });

  factory AdvertisementModel.fromJson(Map<String, dynamic> json) {
    return AdvertisementModel(
      id: json['id'] as String,
      titleAr: json['title_ar'] as String? ?? '',
      titleEn: json['title_en'] as String? ?? '',
      descriptionAr: json['description_ar'] as String?,
      descriptionEn: json['description_en'] as String?,
      imageUrl: json['image_url'] as String?,
      targetUrl: json['target_url'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      startAt: json['start_at'] != null
          ? DateTime.tryParse(json['start_at'] as String)
          : null,
      endAt: json['end_at'] != null
          ? DateTime.tryParse(json['end_at'] as String)
          : null,
      sortOrder: json['sort_order'] as int? ?? 0,
      createdBy: json['created_by'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
    );
  }

  AdvertisementModel copyWith({bool? isActive}) {
    return AdvertisementModel(
      id: id,
      titleAr: titleAr,
      titleEn: titleEn,
      descriptionAr: descriptionAr,
      descriptionEn: descriptionEn,
      imageUrl: imageUrl,
      targetUrl: targetUrl,
      isActive: isActive ?? this.isActive,
      startAt: startAt,
      endAt: endAt,
      sortOrder: sortOrder,
      createdBy: createdBy,
      createdAt: createdAt,
    );
  }
}

// ─── Admin Advertisements ─────────────────────────────────────────────────────
final adminAdsProvider =
    StateNotifierProvider<
      AdminAdsNotifier,
      AsyncValue<List<AdvertisementModel>>
    >((ref) => AdminAdsNotifier());

class AdminAdsNotifier
    extends StateNotifier<AsyncValue<List<AdvertisementModel>>> {
  AdminAdsNotifier() : super(const AsyncValue.data([]));

  Future<void> loadAds() async {
    try {
      state = const AsyncValue.loading();
      final res = await supabase
          .from('advertisements')
          .select()
          .order('sort_order', ascending: true);

      final list = (res as List)
          .map(
            (json) => AdvertisementModel.fromJson(json as Map<String, dynamic>),
          )
          .toList();

      state = AsyncValue.data(list);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<bool> createAd(Map<String, dynamic> data) async {
    try {
      await supabase.from('advertisements').insert(data);
      await loadAds();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> updateAd(String adId, Map<String, dynamic> data) async {
    try {
      await supabase.from('advertisements').update(data).eq('id', adId);
      await loadAds();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> toggleActive(String adId, bool isActive) async {
    try {
      await supabase
          .from('advertisements')
          .update({'is_active': isActive})
          .eq('id', adId);

      final current = state.value ?? [];
      final idx = current.indexWhere((a) => a.id == adId);
      if (idx != -1) {
        final updated = List<AdvertisementModel>.from(current);
        updated[idx] = updated[idx].copyWith(isActive: isActive);
        state = AsyncValue.data(updated);
      }
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> deleteAd(String adId) async {
    try {
      await supabase.from('advertisements').delete().eq('id', adId);
      final current = state.value ?? [];
      state = AsyncValue.data(current.where((a) => a.id != adId).toList());
      return true;
    } catch (e) {
      return false;
    }
  }
}

// ─── Sales Stats Model ────────────────────────────────────────────────────────
class SalesStats {
  final double totalSales;
  final double todaySales;
  final double weekSales;
  final double monthSales;
  final int totalOrders;
  final double avgOrderValue;
  final List<Map<String, dynamic>> recentOrders;

  const SalesStats({
    this.totalSales = 0,
    this.todaySales = 0,
    this.weekSales = 0,
    this.monthSales = 0,
    this.totalOrders = 0,
    this.avgOrderValue = 0,
    this.recentOrders = const [],
  });
}

// ─── Admin Sales Provider ─────────────────────────────────────────────────────
final adminSalesProvider = FutureProvider<SalesStats>((ref) async {
  final now = DateTime.now();
  final todayStart = DateTime(now.year, now.month, now.day);
  final weekStart = todayStart.subtract(Duration(days: now.weekday - 1));
  final monthStart = DateTime(now.year, now.month, 1);

  final res = await supabase
      .from('orders')
      .select('id, total, status, created_at, customer_name, order_number')
      .order('created_at', ascending: false);

  final orders = res as List;

  double total = 0, todayS = 0, weekS = 0, monthS = 0;
  for (final o in orders) {
    final amount = (o['total'] as num?)?.toDouble() ?? 0.0;
    final createdAt = o['created_at'] != null
        ? DateTime.tryParse(o['created_at'] as String)
        : null;

    total += amount;
    if (createdAt != null) {
      if (createdAt.isAfter(todayStart)) todayS += amount;
      if (createdAt.isAfter(weekStart)) weekS += amount;
      if (createdAt.isAfter(monthStart)) monthS += amount;
    }
  }

  return SalesStats(
    totalSales: total,
    todaySales: todayS,
    weekSales: weekS,
    monthSales: monthS,
    totalOrders: orders.length,
    avgOrderValue: orders.isEmpty ? 0 : total / orders.length,
    recentOrders: orders
        .take(10)
        .map((o) => Map<String, dynamic>.from(o as Map))
        .toList(),
  );
});

// ─── Best Selling Products ────────────────────────────────────────────────────
final bestSellingProductsProvider = FutureProvider<List<Map<String, dynamic>>>((
  ref,
) async {
  try {
    // Join order_items with products
    final res = await supabase
        .from('order_items')
        .select('product_id, quantity, products(name_ar, name_en, price)')
        .order('quantity', ascending: false)
        .limit(10);

    // Aggregate by product
    final Map<String, Map<String, dynamic>> aggregated = {};
    for (final item in res as List) {
      final pid = item['product_id'] as String;
      final qty = (item['quantity'] as num?)?.toInt() ?? 0;
      final product = item['products'] as Map<String, dynamic>?;
      final price = (product?['price'] as num?)?.toDouble() ?? 0.0;

      if (!aggregated.containsKey(pid)) {
        aggregated[pid] = {
          'product_id': pid,
          'name_ar': product?['name_ar'] ?? '',
          'name_en': product?['name_en'] ?? '',
          'quantity_sold': 0,
          'revenue': 0.0,
        };
      }
      aggregated[pid]!['quantity_sold'] =
          (aggregated[pid]!['quantity_sold'] as int) + qty;
      aggregated[pid]!['revenue'] =
          (aggregated[pid]!['revenue'] as double) + (qty * price);
    }

    final list = aggregated.values.toList()
      ..sort(
        (a, b) =>
            (b['quantity_sold'] as int).compareTo(a['quantity_sold'] as int),
      );

    return list;
  } catch (e) {
    return [];
  }
});

// ─── Low Stock Products ───────────────────────────────────────────────────────
final lowStockProductsProvider = FutureProvider<List<ProductModel>>((
  ref,
) async {
  try {
    final res = await supabase
        .from('products')
        .select()
        .order('stock_quantity', ascending: true);

    final all = (res as List)
        .map((j) => ProductModel.fromJson(j as Map<String, dynamic>))
        .toList();

    return all.where((p) => p.isLowStock || p.stockQuantity == 0).toList();
  } catch (e) {
    return [];
  }
});

// ─── Admin Merchants (from profiles table, role = merchant) ──────────────────
final adminMerchantsProvider =
    StateNotifierProvider<
      AdminMerchantsNotifier,
      AsyncValue<List<ProfileModel>>
    >((ref) => AdminMerchantsNotifier());

class AdminMerchantsNotifier
    extends StateNotifier<AsyncValue<List<ProfileModel>>> {
  AdminMerchantsNotifier() : super(const AsyncValue.data([]));

  Future<void> loadMerchants() async {
    try {
      state = const AsyncValue.loading();
      final res = await supabase
          .from('profiles')
          .select()
          .eq('role', 'merchant')
          .order('created_at', ascending: false);

      final list = (res as List)
          .map((json) => ProfileModel.fromJson(json as Map<String, dynamic>))
          .toList();

      state = AsyncValue.data(list);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<bool> toggleActive(String userId, bool isActive) async {
    try {
      await supabase
          .from('profiles')
          .update({'is_active': isActive})
          .eq('id', userId);

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
