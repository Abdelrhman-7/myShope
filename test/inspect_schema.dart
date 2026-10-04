import 'package:supabase/supabase.dart';

void main() async {
  final client = SupabaseClient(
    'https://bdbcdoglgfblfnxjwqdd.supabase.co',
    'sb_publishable_0hfiDMhVvfkq6zZHwtGyDA_V0RmTTeR',
  );

  final tables = ['products', 'cart_items', 'favorites', 'orders', 'order_items', 'notifications', 'profiles'];

  for (final table in tables) {
    try {
      final res = await client.from(table).select().limit(1);
      print('=== TABLE: $table ===');
      if (res.isNotEmpty) {
        print('Columns: ${(res.first as Map<String, dynamic>).keys.toList()}');
      } else {
        print('Table exists but empty.');
      }
    } catch (e) {
      print('=== TABLE: $table ERROR: $e ===');
    }
  }
}
