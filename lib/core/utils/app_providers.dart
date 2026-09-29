import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_service.dart';
import '../../features/auth/models/profile_model.dart';
import '../../features/auth/models/customer_type_model.dart';

/// Provides the singleton AuthService
final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

/// Manages the current user's profile state
final profileProvider =
    StateNotifierProvider<ProfileNotifier, AsyncValue<ProfileModel?>>(
  (ref) => ProfileNotifier(ref.read(authServiceProvider)),
);

class ProfileNotifier extends StateNotifier<AsyncValue<ProfileModel?>> {
  final AuthService _authService;

  ProfileNotifier(this._authService) : super(const AsyncValue.loading());

  Future<void> loadProfile() async {
    try {
      state = const AsyncValue.loading();
      final profile = await _authService.getProfile();
      state = AsyncValue.data(profile);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> updateProfile(ProfileModel profile) async {
    try {
      await _authService.updateProfile(profile);
      state = AsyncValue.data(profile);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Directly set the profile from an already-fetched [ProfileModel].
  /// Used by LoginView after fetching the profile to avoid a second DB call.
  void setProfile(ProfileModel profile) {
    state = AsyncValue.data(profile);
  }

  void clear() {
    state = const AsyncValue.data(null);
  }
}

/// Manages the current user's customer type
final customerTypeProvider =
    StateNotifierProvider<CustomerTypeNotifier, AsyncValue<CustomerTypeModel?>>(
  (ref) => CustomerTypeNotifier(ref.read(authServiceProvider)),
);

class CustomerTypeNotifier
    extends StateNotifier<AsyncValue<CustomerTypeModel?>> {
  final AuthService _authService;

  CustomerTypeNotifier(this._authService) : super(const AsyncValue.loading());

  Future<void> loadCustomerType(String customerTypeId) async {
    try {
      state = const AsyncValue.loading();
      final type = await _authService.getCustomerType(customerTypeId);
      state = AsyncValue.data(type);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  void clear() {
    state = const AsyncValue.data(null);
  }
}

/// Manages locale (language) preference
final localeProvider = StateNotifierProvider<LocaleNotifier, Locale>(
  (ref) => LocaleNotifier(),
);

class LocaleNotifier extends StateNotifier<Locale> {
  LocaleNotifier() : super(const Locale('ar'));

  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    final lang = prefs.getString('language') ?? 'ar';
    state = Locale(lang);
  }

  Future<void> setLocale(String languageCode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language', languageCode);
    state = Locale(languageCode);
  }

  void toggleLocale() {
    if (state.languageCode == 'ar') {
      setLocale('en');
    } else {
      setLocale('ar');
    }
  }
}

/// Manages theme mode preference
final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, ThemeMode>(
  (ref) => ThemeModeNotifier(),
);

class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  ThemeModeNotifier() : super(ThemeMode.light);

  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    final theme = prefs.getString('theme') ?? 'light';
    state = theme == 'dark' ? ThemeMode.dark : ThemeMode.light;
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'theme',
      mode == ThemeMode.dark ? 'dark' : 'light',
    );
    state = mode;
  }

  void toggleTheme() {
    if (state == ThemeMode.dark) {
      setThemeMode(ThemeMode.light);
    } else {
      setThemeMode(ThemeMode.dark);
    }
  }
}

/// Tracks whether the app has finished initial loading
final appInitializedProvider = StateProvider<bool>((ref) => false);

/// Manages user role preference ('customer' | 'merchant' | 'admin')
final userRoleProvider = StateNotifierProvider<RoleNotifier, String>(
  (ref) => RoleNotifier(),
);

class RoleNotifier extends StateNotifier<String> {
  RoleNotifier() : super('customer');

  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    final role = prefs.getString('user_role') ?? 'customer';
    state = role;
  }

  /// Sets the user role. Accepts 'customer', 'merchant', or 'admin'.
  Future<void> setRole(String role) async {
    if (role != 'customer' && role != 'merchant' && role != 'admin') return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_role', role);
    state = role;
  }

  bool get isMerchant => state == 'merchant';
  bool get isCustomer => state == 'customer';
  bool get isAdmin => state == 'admin';
}


