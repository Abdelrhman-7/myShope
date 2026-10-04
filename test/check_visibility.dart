import 'package:supabase/supabase.dart';

/// Quick diagnostic script for Supabase RLS on products and advertisements.
/// Run: dart test/check_visibility.dart
///
/// This checks if anon/authenticated users can read products & ads.

void main() async {
  const supabaseUrl = 'https://bdbcdoglgfblfnxjwqdd.supabase.co';
  const anonKey = 'sb_publishable_0hfiDMhVvfkq6zZHwtGyDA_V0RmTTeR';

  final client = SupabaseClient(supabaseUrl, anonKey);

  print('====================================');
  print(' SUPABASE VISIBILITY DIAGNOSTIC');
  print('====================================\n');

  // ── 1. Check products (anon - no auth) ──
  try {
    print('--- TEST 1: products (anon, no auth) ---');
    final res = await client.from('products').select('id, name_ar, is_active').limit(5);
    final list = res as List;
    print('COUNT: ${list.length}');
    for (final p in list) {
      print('  product id=${p['id']} name_ar=${p['name_ar']} is_active=${p['is_active']}');
    }
  } catch (e) {
    print('ERROR (products anon): $e');
  }

  print('');

  // ── 2. Check advertisements (anon - no auth) ──
  try {
    print('--- TEST 2: advertisements (anon, no auth) ---');
    final res = await client.from('advertisements').select('id, title_ar, is_active').limit(5);
    final list = res as List;
    print('COUNT: ${list.length}');
    for (final a in list) {
      print('  ad id=${a['id']} title_ar=${a['title_ar']} is_active=${a['is_active']}');
    }
  } catch (e) {
    print('ERROR (ads anon): $e');
  }

  print('');

  // ── 3. Sign in as customer and test ──
  try {
    print('--- TEST 3: Sign in as customer, then query products ---');
    await client.auth.signInWithPassword(
      email: 'customer@gmail.com',
      password: 'Test1234!',
    );
    final user = client.auth.currentUser;
    print('Signed in as: ${user?.email} id=${user?.id}');

    final res = await client.from('products').select('id, name_ar, is_active').limit(5);
    final list = res as List;
    print('PRODUCTS COUNT (as customer): ${list.length}');
    for (final p in list) {
      print('  product id=${p['id']} name_ar=${p['name_ar']} is_active=${p['is_active']}');
    }

    final adsRes = await client.from('advertisements').select('id, title_ar, is_active').limit(5);
    final adsList = adsRes as List;
    print('ADS COUNT (as customer): ${adsList.length}');
    for (final a in adsList) {
      print('  ad id=${a['id']} title_ar=${a['title_ar']} is_active=${a['is_active']}');
    }

    await client.auth.signOut();
  } catch (e) {
    print('ERROR (customer test): $e');
  }

  print('');
  print('====================================');
  print(' DIAGNOSTIC COMPLETE');
  print('====================================');

  client.dispose();
}
