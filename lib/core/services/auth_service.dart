import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/config/supabase_config.dart';
import '../../core/utils/app_logger.dart';
import '../../features/auth/models/profile_model.dart';
import '../../features/auth/models/customer_type_model.dart'; // Customer classification (gold/silver/etc) — NOT auth roles

/// Centralized authentication service.
/// Handles Supabase Auth + profile management.
class AuthService {
  final SupabaseClient _client = SupabaseConfig.client;

  // ─── Auth State ────────────────────────────────────────────────

  /// Current Supabase user (null if not logged in)
  User? get currentUser => _client.auth.currentUser;

  /// Current session
  Session? get currentSession => _client.auth.currentSession;

  /// Whether user is authenticated
  bool get isAuthenticated => currentUser != null;

  /// Stream of auth state changes
  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  // ─── Sign Up ──────────────────────────────────────────────────

  /// Register a new user.
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String fullName,
    required String phone,
    String role = 'customer',
  }) async {
    final stopwatch = Stopwatch()..start();
    AppLogger.auth(
      'SIGNUP START',
      email: email,
      role: role,
      data: {'full_name': fullName, 'phone': phone},
    );

    try {
      final response = await _client.auth.signUp(
        email: email,
        password: password,
        data: {
          'full_name': fullName,
          'phone': phone,
          'role': role,
          'language': 'ar',
          'theme': 'light',
        },
      );
      stopwatch.stop();

      AppLogger.auth(
        'SIGNUP SUCCESS',
        email: email,
        userId: response.user?.id,
        role: role,
        duration: stopwatch.elapsed,
      );

      return response;
    } catch (e, st) {
      stopwatch.stop();
      AppLogger.auth(
        'SIGNUP ERROR',
        email: email,
        role: role,
        duration: stopwatch.elapsed,
        error: e,
        stackTrace: st,
      );
      rethrow;
    }
  }

  // ─── Login ────────────────────────────────────────────────────

  /// Login with email and password
  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    final stopwatch = Stopwatch()..start();
    AppLogger.auth(
      'LOGIN START',
      email: email,
      data: {'password': password}, // Automatically redacted to ********
    );

    try {
      final response = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      stopwatch.stop();

      AppLogger.auth(
        'LOGIN SUCCESS',
        email: email,
        userId: response.user?.id,
        duration: stopwatch.elapsed,
      );

      return response;
    } catch (e, st) {
      stopwatch.stop();
      AppLogger.auth(
        'LOGIN ERROR',
        email: email,
        duration: stopwatch.elapsed,
        error: e,
        stackTrace: st,
      );
      rethrow;
    }
  }

  // ─── Logout ───────────────────────────────────────────────────

  /// Sign out the current user
  Future<void> signOut() async {
    final userId = currentUser?.id;
    final email = currentUser?.email;

    AppLogger.auth(
      'LOGOUT',
      userId: userId,
      email: email,
    );

    await _client.auth.signOut();
  }

  // ─── Password Reset ───────────────────────────────────────────

  /// Send password reset email
  Future<void> resetPassword(String email) async {
    AppLogger.auth('RESET PASSWORD REQUEST', email: email);
    await _client.auth.resetPasswordForEmail(email);
  }

  // ─── Profile ──────────────────────────────────────────────────

  /// Get the current user's profile
  Future<ProfileModel?> getProfile() async {
    if (currentUser == null) {
      AppLogger.auth('SESSION NOT FOUND');
      return null;
    }

    final stopwatch = Stopwatch()..start();
    try {
      final response = await _client
          .from('profiles')
          .select()
          .eq('id', currentUser!.id)
          .single();

      stopwatch.stop();

      // ── RAW DEBUG ── طباعة الاستجابة الخام من قاعدة البيانات
      // ignore: avoid_print
      print('\n╔══════════════════════════════════════════════════');
      // ignore: avoid_print
      print('║  getProfile() RAW RESPONSE FROM DB:');
      // ignore: avoid_print
      print('║  user.id  : ${currentUser!.id}');
      // ignore: avoid_print
      print('║  raw data : $response');
      // ignore: avoid_print
      print('╚══════════════════════════════════════════════════\n');

      final profile = ProfileModel.fromJson(response);

      // ignore: avoid_print
      print('╔══════════════════════════════════════════════════');
      // ignore: avoid_print
      print('║  ProfileModel PARSED:');
      // ignore: avoid_print
      print('║  id       : ${profile.id}');
      // ignore: avoid_print
      print('║  email    : ${profile.email}');
      // ignore: avoid_print
      print('║  role     : ${profile.role}  ← WILL ROUTE BASED ON THIS');
      // ignore: avoid_print
      print('║  isActive : ${profile.isActive}');
      // ignore: avoid_print
      print('╚══════════════════════════════════════════════════\n');

      AppLogger.database(
        'SELECT',
        table: 'profiles',
        rows: 1,
        duration: stopwatch.elapsed,
        data: {
          'id': profile.id,
          'role': profile.role,
          'email': profile.email,
        },
      );

      AppLogger.auth(
        'ROLE DETECTION',
        userId: profile.id,
        role: profile.role,
        email: profile.email,
      );

      return profile;
    } catch (e) {
      stopwatch.stop();
      AppLogger.database(
        'SELECT',
        table: 'profiles',
        duration: stopwatch.elapsed,
        error: e,
      );

      // ⚠️  DO NOT fallback to userMetadata['role'] here.
      // userMetadata is written at signUp time and can be stale.
      // The ONLY source of truth for role routing is public.profiles.role.
      // If we cannot reach the profiles table, we must surface the error
      // so the caller can handle it — not silently route to the wrong dashboard.
      AppLogger.warning(
        'Cannot read public.profiles — rethrowing to prevent wrong-role routing',
        tag: 'AUTH',
      );
      rethrow;
    }
  }

  /// Update the current user's profile
  Future<void> updateProfile(ProfileModel profile) async {
    if (currentUser == null) return;

    final stopwatch = Stopwatch()..start();
    try {
      await _client
          .from('profiles')
          .update(profile.toUpdateJson())
          .eq('id', currentUser!.id);

      stopwatch.stop();
      AppLogger.database(
        'UPDATE',
        table: 'profiles',
        rows: 1,
        duration: stopwatch.elapsed,
      );
    } catch (e) {
      stopwatch.stop();
      AppLogger.database(
        'UPDATE',
        table: 'profiles',
        duration: stopwatch.elapsed,
        error: e,
      );
      rethrow;
    }
  }

  // ─── Customer Classification ──────────────────────────────────
  //
  // NOTE: customer_types is a SEPARATE concept from auth roles.
  // It is used for customer loyalty tiers (e.g. gold/silver/regular)
  // and has nothing to do with admin / merchant / customer role routing.
  // Role routing always uses public.profiles.role via getProfile().

  /// Get a specific customer classification type (loyalty tier, etc.)
  /// This is NOT used for auth routing — use getProfile() for that.
  Future<CustomerTypeModel?> getCustomerType(String customerTypeId) async {
    final stopwatch = Stopwatch()..start();
    try {
      final response = await _client
          .from('customer_types')
          .select()
          .eq('id', customerTypeId)
          .single();

      stopwatch.stop();
      AppLogger.database(
        'SELECT',
        table: 'customer_types',
        rows: 1,
        duration: stopwatch.elapsed,
      );

      return CustomerTypeModel.fromJson(response);
    } catch (e) {
      stopwatch.stop();
      AppLogger.database(
        'SELECT',
        table: 'customer_types',
        duration: stopwatch.elapsed,
        error: e,
      );
      return null;
    }
  }

  /// Get all active customer types
  Future<List<CustomerTypeModel>> getCustomerTypes() async {
    final stopwatch = Stopwatch()..start();
    try {
      final response = await _client
          .from('customer_types')
          .select()
          .eq('is_active', true)
          .order('created_at');

      stopwatch.stop();
      final list = (response as List)
          .map((json) => CustomerTypeModel.fromJson(json))
          .toList();

      AppLogger.database(
        'SELECT',
        table: 'customer_types',
        rows: list.length,
        duration: stopwatch.elapsed,
      );

      return list;
    } catch (e) {
      stopwatch.stop();
      AppLogger.database(
        'SELECT',
        table: 'customer_types',
        duration: stopwatch.elapsed,
        error: e,
      );
      return [];
    }
  }
}


