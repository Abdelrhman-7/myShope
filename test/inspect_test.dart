import 'package:supabase/supabase.dart';

void main() async {
  final client = SupabaseClient(
    'https://bdbcdoglgfblfnxjwqdd.supabase.co',
    'sb_publishable_0hfiDMhVvfkq6zZHwtGyDA_V0RmTTeR',
    authOptions: const AuthClientOptions(
      authFlowType: AuthFlowType.implicit,
    ),
  );

  print('\n--- Testing SignUp with gmail.com ---');
  final email = 'testuser_${DateTime.now().millisecondsSinceEpoch}@gmail.com';
  try {
    final res = await client.auth.signUp(
      email: email,
      password: 'StrongPassword123!',
    );
    print('User created: id=${res.user?.id}, email=${res.user?.email}');
    if (res.user != null) {
      print('Attempting profile insert for userId: ${res.user!.id} ...');
      try {
        final profileInsert = await client.from('profiles').insert({
          'id': res.user!.id,
          'full_name': 'Test User',
          'phone': '01000000000',
          'email': email,
          'role': 'customer',
          'is_active': true,
          'language': 'ar',
          'theme': 'light',
        }).select();
        print('Profile insert SUCCESS: $profileInsert');
      } catch (e) {
        print('Profile insert FAILED: $e');
      }
    }
  } catch (e, st) {
    print('SignUp failed: $e\n$st');
  }
}
