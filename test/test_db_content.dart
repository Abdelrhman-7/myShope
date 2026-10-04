import 'package:supabase/supabase.dart';

void main() async {
  final client = SupabaseClient(
    'https://bdbcdoglgfblfnxjwqdd.supabase.co',
    'sb_publishable_0hfiDMhVvfkq6zZHwtGyDA_V0RmTTeR',
  );

  print('=== DIAGNOSTIC START ===');

  try {
    print('1. Testing profiles query...');
    final profiles = await client.from('profiles').select('id, email, role');
    print('Profiles count: ${profiles.length}');
    for (final p in profiles) {
      print('Profile: ${p['email']} | role: ${p['role']}');
    }

    print('\n2. Testing products query...');
    final allProducts = await client.from('products').select();
    print('All products count: ${allProducts.length}');

    print('\n3. Testing advertisements query...');
    final allAds = await client.from('advertisements').select();
    print('All advertisements count: ${allAds.length}');

    print('\n4. Testing categories query...');
    final allCats = await client.from('categories').select();
    print('All categories count: ${allCats.length}');

  } catch (e, st) {
    print('Error: $e');
    print('StackTrace: $st');
  }

  print('=== DIAGNOSTIC END ===');
}
