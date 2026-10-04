import 'package:supabase/supabase.dart';

void main() async {
  final client = SupabaseClient(
    'https://bdbcdoglgfblfnxjwqdd.supabase.co',
    'sb_publishable_0hfiDMhVvfkq6zZHwtGyDA_V0RmTTeR',
  );

  print('=== AUTHENTICATED PRODUCTS DIAGNOSTIC ===');

  try {
    // Try querying products as public / anon
    final anonRes = await client.from('products').select('*');
    print('Anon products count: ${anonRes.length}');
    if (anonRes.isNotEmpty) {
      print('First row: ${anonRes.first}');
    }

    // Try logging in with a customer/merchant account if one exists
    try {
      final authRes = await client.auth.signInWithPassword(
        email: 'customer@test.com',
        password: 'password123',
      );
      print('Logged in user: ${authRes.user?.email}');
      
      final authProducts = await client.from('products').select('*');
      print('Authenticated products count: ${authProducts.length}');
      for (final p in authProducts) {
        print('Product: id=${p['id']} | category_id=${p['category_id']} | name_ar=${p['name_ar']} | is_active=${p['is_active']} | is_featured=${p['is_featured']}');
      }
    } catch (authError) {
      print('Login attempt failed: $authError');
    }

  } catch (e, st) {
    print('Error: $e');
    print('StackTrace: $st');
  }
}
