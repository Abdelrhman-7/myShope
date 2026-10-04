import 'package:supabase/supabase.dart';

void main() async {
  final client = SupabaseClient(
    'https://bdbcdoglgfblfnxjwqdd.supabase.co',
    'sb_publishable_0hfiDMhVvfkq6zZHwtGyDA_V0RmTTeR',
  );

  print('=== DIAGNOSTIC: Checking categories ===');
  
  try {
    final categories = await client.from('categories').select().limit(1);
    if (categories.isEmpty) {
      print('No categories found.');
      return;
    }
    
    final catId = categories[0]['id'];
    
    final merchants = await client.from('profiles').select().eq('role', 'merchant').limit(1);
    if (merchants.isEmpty) {
        print('No merchants found.');
        return;
    }
    final merchId = merchants[0]['id'];

    print('Inserting product with cat_id: $catId and merch_id: $merchId');
    
    final res = await client.from('products').insert({
      'name_ar': 'Test Product',
      'name_en': 'Test Product',
      'price': 100,
      'stock_quantity': 10,
      'min_stock': 2,
      'sku': '12345',
      'category_id': catId,
      'merchant_id': merchId,
      'is_active': true,
      'is_featured': false,
    }).select();
    
    print('Insert response: $res');
    
  } catch (e) {
    print('Error: $e');
  }
}
