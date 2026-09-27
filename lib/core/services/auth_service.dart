import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/config/supabase_config.dart';
import '../../features/auth/models/profile_model.dart';
import '../../features/auth/models/customer_type_model.dart';

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
  ///
  /// The user's profile is created automatically by the
  /// Supabase database trigger after the auth user is created.
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String fullName,
    required String phone,
  }) async {
    return await _client.auth.signUp(
      email: email,
      password: password,
      data: {
        'full_name': fullName,
        'phone': phone,
        'language': 'ar',
        'theme': 'light',
      },
    );
  }

  // ─── Login ────────────────────────────────────────────────────

  /// Login with email and password
  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    return await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  // ─── Logout ───────────────────────────────────────────────────

  /// Sign out the current user
  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  // ─── Password Reset ───────────────────────────────────────────

  /// Send password reset email
  Future<void> resetPassword(String email) async {
    await _client.auth.resetPasswordForEmail(email);
  }

  // ─── Profile ──────────────────────────────────────────────────

  /// Get the current user's profile
  Future<ProfileModel?> getProfile() async {
    if (currentUser == null) return null;

    final response = await _client
        .from('profiles')
        .select()
        .eq('id', currentUser!.id)
        .single();

    return ProfileModel.fromJson(response);
  }

  /// Update the current user's profile
  Future<void> updateProfile(ProfileModel profile) async {
    if (currentUser == null) return;

    await _client
        .from('profiles')
        .update(profile.toUpdateJson())
        .eq('id', currentUser!.id);
  }

  // ─── Customer Type ────────────────────────────────────────────

  /// Get the customer type for the current user
  Future<CustomerTypeModel?> getCustomerType(String customerTypeId) async {
    final response = await _client
        .from('customer_types')
        .select()
        .eq('id', customerTypeId)
        .single();

    return CustomerTypeModel.fromJson(response);
  }

  /// Get all active customer types
  Future<List<CustomerTypeModel>> getCustomerTypes() async {
    final response = await _client
        .from('customer_types')
        .select()
        .eq('is_active', true)
        .order('created_at');

    return (response as List)
        .map((json) => CustomerTypeModel.fromJson(json))
        .toList();
  }
}
