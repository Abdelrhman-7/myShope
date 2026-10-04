import 'package:supabase/supabase.dart';

void main() async {
  final client = SupabaseClient(
    'https://bdbcdoglgfblfnxjwqdd.supabase.co',
    'sb_publishable_0hfiDMhVvfkq6zZHwtGyDA_V0RmTTeR',
  );

  print('Testing database tables...');
  
  try {
    final notifs = await client.from('notifications').select().limit(1);
    print('notifications table ok, columns: ${notifs.isNotEmpty ? notifs.first.keys : 'empty'}');
  } catch (e) {
    print('notifications table error: $e');
  }

  try {
    final orders = await client.from('orders').select().limit(1);
    print('orders table ok, columns: ${orders.isNotEmpty ? orders.first.keys : 'empty'}');
  } catch (e) {
    print('orders table error: $e');
  }

  try {
    final orderItems = await client.from('order_items').select().limit(1);
    print('order_items table ok, columns: ${orderItems.isNotEmpty ? orderItems.first.keys : 'empty'}');
  } catch (e) {
    print('order_items table error: $e');
  }

  try {
    final cart = await client.from('cart_items').select().limit(1);
    print('cart_items table ok, columns: ${cart.isNotEmpty ? cart.first.keys : 'empty'}');
  } catch (e) {
    print('cart_items table error: $e');
  }

  try {
    final favs = await client.from('favorites').select().limit(1);
    print('favorites table ok, columns: ${favs.isNotEmpty ? favs.first.keys : 'empty'}');
  } catch (e) {
    print('favorites table error: $e');
  }
}
