import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/view/login_view.dart';
import '../../features/auth/view/register_view.dart';
import '../../features/auth/view/forgot_password_view.dart';
import '../../features/auth/view/role_selection_view.dart';
import '../../features/home/view/home_shell.dart';
import '../../features/home/view/home_view.dart';
import '../../features/categories/view/categories_view.dart';
import '../../features/categories/view/category_products_view.dart';
import '../../features/products/view/product_details_view.dart';
import '../../features/products/view/products_search_view.dart';
import '../../features/cart/view/cart_view.dart';
import '../../features/cart/view/checkout_view.dart';
import '../../features/favorites/view/favorites_view.dart';
import '../../features/profile/view/profile_view.dart';
import '../../features/orders/view/orders_view.dart';
import '../../features/orders/view/order_details_view.dart';
import '../../features/addresses/view/addresses_view.dart';
import '../../features/points/view/points_view.dart';
import '../../features/admin/view/admin_dashboard_view.dart';
import '../../features/admin/view/admin_products_view.dart';
import '../../features/admin/view/admin_orders_view.dart';
import '../../features/admin/view/admin_customers_view.dart';
import '../../features/admin/view/admin_merchants_view.dart';
import '../../features/admin/view/admin_categories_view.dart';
import '../../features/admin/view/admin_advertisements_view.dart';
import '../../features/admin/view/admin_sales_view.dart';
import '../../features/admin/view/admin_statistics_view.dart';
import '../../features/admin/view/admin_settings_view.dart';
import '../../features/splash/view/splash_view.dart';
import '../../features/merchant/view/merchant_center_view.dart';

/// Centralized routing configuration using GoRouter.
class AppRouter {
  AppRouter._();

  static final GlobalKey<NavigatorState> _rootNavigatorKey =
      GlobalKey<NavigatorState>(debugLabel: 'root');
  static final GlobalKey<NavigatorState> _shellNavigatorKey =
      GlobalKey<NavigatorState>(debugLabel: 'shell');

  // ─── Route names ───────────────────────────────────────────────────
  static const String splash = '/';
  static const String roleSelection = '/role-selection';
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';
  static const String home = '/home';
  static const String categories = '/categories';
  static const String categoryProducts = '/categories/:categoryId';
  static const String productDetails = '/products/:productId';
  static const String search = '/search';
  static const String cart = '/cart';
  static const String checkout = '/checkout';
  static const String favorites = '/favorites';
  static const String profile = '/profile';
  static const String orders = '/orders';
  static const String orderDetails = '/orders/:orderId';
  static const String addresses = '/addresses';
  static const String points = '/points';

  // Admin
  static const String admin = '/admin';
  static const String adminDashboard = '/admin';
  static const String adminProducts = '/admin/products';
  static const String adminOrders = '/admin/orders';
  static const String adminCustomers = '/admin/customers';
  static const String adminMerchants = '/admin/merchants';
  static const String adminCategories = '/admin/categories';
  static const String adminAdvertisements = '/admin/advertisements';
  static const String adminSales = '/admin/sales';
  static const String adminStatistics = '/admin/statistics';
  static const String adminSettings = '/admin/settings';

  // Merchant
  static const String merchantCenter = '/merchant';
  static const String merchantDashboard = '/merchant';

  static final GoRouter router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: splash,
    debugLogDiagnostics: false,
    routes: [
      // ─── Splash ────────────────────────────────────────────
      GoRoute(
        path: splash,
        builder: (context, state) => const SplashView(),
      ),

      // ─── Auth Routes ───────────────────────────────────────
      GoRoute(
        path: roleSelection,
        builder: (context, state) => const RoleSelectionView(),
      ),
      GoRoute(
        path: login,
        builder: (context, state) => const LoginView(),
      ),
      GoRoute(
        path: register,
        builder: (context, state) => const RegisterView(),
      ),
      GoRoute(
        path: forgotPassword,
        builder: (context, state) => const ForgotPasswordView(),
      ),

      // ─── Main App Shell (with bottom nav) ──────────────────
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) => HomeShell(child: child),
        routes: [
          GoRoute(
            path: home,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: HomeView(),
            ),
          ),
          GoRoute(
            path: categories,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: CategoriesView(),
            ),
          ),
          GoRoute(
            path: cart,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: CartView(),
            ),
          ),
          GoRoute(
            path: favorites,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: FavoritesView(),
            ),
          ),
          GoRoute(
            path: profile,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: ProfileView(),
            ),
          ),
        ],
      ),

      // ─── Detail Routes ─────────────────────────────────────
      GoRoute(
        path: categoryProducts,
        builder: (context, state) => CategoryProductsView(
          categoryId: state.pathParameters['categoryId']!,
        ),
      ),
      GoRoute(
        path: productDetails,
        builder: (context, state) => ProductDetailsView(
          productId: int.parse(state.pathParameters['productId']!),
        ),
      ),
      GoRoute(
        path: search,
        builder: (context, state) => const ProductsSearchView(),
      ),
      GoRoute(
        path: checkout,
        builder: (context, state) => CheckoutView(
          extra: state.extra as Map<String, dynamic>?,
        ),
      ),
      GoRoute(
        path: orders,
        builder: (context, state) => const OrdersView(),
      ),
      GoRoute(
        path: orderDetails,
        builder: (context, state) => OrderDetailsView(
          orderId: state.pathParameters['orderId']!,
        ),
      ),
      GoRoute(
        path: addresses,
        builder: (context, state) => const AddressesView(),
      ),
      GoRoute(
        path: points,
        builder: (context, state) => const PointsView(),
      ),

      // ─── Admin Routes ──────────────────────────────────────
      GoRoute(
        path: admin,
        builder: (context, state) => const AdminDashboardView(),
      ),
      GoRoute(
        path: adminProducts,
        builder: (context, state) => const AdminProductsView(),
      ),
      GoRoute(
        path: adminOrders,
        builder: (context, state) => const AdminOrdersView(),
      ),
      GoRoute(
        path: adminCustomers,
        builder: (context, state) => const AdminCustomersView(),
      ),
      GoRoute(
        path: adminMerchants,
        builder: (context, state) => const AdminMerchantsView(),
      ),
      GoRoute(
        path: adminCategories,
        builder: (context, state) => const AdminCategoriesView(),
      ),
      GoRoute(
        path: adminAdvertisements,
        builder: (context, state) => const AdminAdvertisementsView(),
      ),
      GoRoute(
        path: adminSales,
        builder: (context, state) => const AdminSalesView(),
      ),
      GoRoute(
        path: adminStatistics,
        builder: (context, state) => const AdminStatisticsView(),
      ),
      GoRoute(
        path: adminSettings,
        builder: (context, state) => const AdminSettingsView(),
      ),

      // ─── Merchant Routes ────────────────────────────────────
      GoRoute(
        path: merchantCenter,
        builder: (context, state) => const MerchantCenterView(),
      ),
    ],
  );
}
