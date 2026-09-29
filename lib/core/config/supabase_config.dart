import 'package:supabase_flutter/supabase_flutter.dart';

/// Centralized Supabase configuration.
/// Never create multiple Supabase clients — use [supabase] everywhere.
class SupabaseConfig {
  SupabaseConfig._();

  static const String _supabaseUrl = 'https://bdbcdoglgfblfnxjwqdd.supabase.co';
  static const String _supabaseAnonKey = 'sb_publishable_0hfiDMhVvfkq6zZHwtGyDA_V0RmTTeR';

  /// Initialize Supabase — call once in main.dart
  static Future<void> initialize() async {
    await Supabase.initialize(
      url: _supabaseUrl,
      anonKey: _supabaseAnonKey,
    );
  }

  /// The single Supabase client instance
  static SupabaseClient get client => Supabase.instance.client;
}

/// Convenience accessor for the Supabase client
final supabase = SupabaseConfig.client;

