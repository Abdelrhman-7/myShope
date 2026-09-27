import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/view/login_view.dart';
import '../../features/auth/view/register_view.dart';
import '../../features/auth/view/forgot_password_view.dart';
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
import '../../features/splash/view/splash_view.dart';

/// Centralized routing configuration using GoRouter.
class AppRouter {
  AppRouter._();

  static final GlobalKey<NavigatorState> _rootNavigatorKey =
      GlobalKey<NavigatorState>(debugLabel: 'root');
  static final GlobalKey<NavigatorState> _shellNavigatorKey =
      GlobalKey<NavigatorState>(debugLabel: 'shell');

  // ─── Route names ──────────────────────────────────────────────
  static const String splash = '/';
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
  static const String admin = '/admin';
  static const String adminProducts = '/admin/products';
  static const String adminOrders = '/admin/orders';
  static const String adminCustomers = '/admin/customers';

  static final GoRouter router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: splash,
    debugLogDiagnostics: false,
    routes: [
      // ─── Splash ─────────────────────────────────────────
      GoRoute(
        path: splash,
        builder: (context, state) => const SplashView(),
      ),

      // ─── Auth Routes ───────────────────────────────────
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

      // ─── Main App Shell (with bottom nav) ──────────────
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

      // ─── Detail Routes ─────────────────────────────────
      GoRoute(
        path: categoryProducts,
        builder: (context, state) => CategoryProductsView(
          categoryId: state.pathParameters['categoryId']!,
        ),
      ),
      GoRoute(
        path: productDetails,
        builder: (context, state) => ProductDetailsView(
          productId: state.pathParameters['productId']!,
        ),
      ),
      GoRoute(
        path: search,
        builder: (context, state) => const ProductsSearchView(),
      ),
      GoRoute(
        path: checkout,
        builder: (context, state) => const CheckoutView(),
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

      // ─── Admin Routes ──────────────────────────────────
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
    ],
  );
}
