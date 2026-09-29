import 'package:supabase/supabase.dart';

/// ─── DIAGNOSTIC SCRIPT ───────────────────────────────────────────
/// Run with: dart test/check_users.dart
/// Purpose : Show the actual role stored in public.profiles for every user.
///           This tells us if the DB data is correct.
/// ─────────────────────────────────────────────────────────────────
void main() async {
  final client = SupabaseClient(
    'https://bdbcdoglgfblfnxjwqdd.supabase.co',
    'sb_publishable_0hfiDMhVvfkq6zZHwtGyDA_V0RmTTeR',
  );

  print('\n════════════════════════════════════════════════════');
  print('   DIAGNOSTIC: public.profiles table contents');
  print('════════════════════════════════════════════════════\n');

  try {
    // 1. Read all profiles (id, email, role, is_active)
    final profiles = await client
        .from('profiles')
        .select('id, email, full_name, role, is_active')
        .order('role');

    if ((profiles as List).isEmpty) {
      print('⚠️  NO PROFILES FOUND in public.profiles!');
      print('   Either the table is empty or RLS is blocking anonymous read.\n');
    } else {
      print('✅ Found ${profiles.length} profile(s):\n');
      for (final p in profiles) {
        final id = (p['id'] as String?)?.substring(0, 8) ?? '?';
        final email = p['email'] ?? '(no email)';
        final name = p['full_name'] ?? '(no name)';
        final role = p['role'] ?? '(NO ROLE — will default to customer!)';
        final active = p['is_active'] ?? false;

        print('  ┌─ ID       : $id...');
        print('  │  Email    : $email');
        print('  │  Name     : $name');
        print('  │  Role     : $role  ← THIS IS WHAT ROUTES THE USER');
        print('  │  Active   : $active');
        print('  └─────────────────────────────────────────');
      }
    }
  } catch (e) {
    print('❌ ERROR querying profiles: $e');
    print('   Possible: RLS blocking read, table missing, or network issue.');
  }

  // 2. Authenticate as admin and check what profile.role DB returns
  print('\n════════════════════════════════════════════════════');
  print('   TEST: Sign in + check profile.role from DB');
  print('════════════════════════════════════════════════════');
  print('⬇️  Fill testEmail & testPassword below and re-run to test.\n');

  // ← change these to test:
  const testEmail = 'admin@gmail.com';
  const testPassword = ''; // ← fill in your admin password

  if (testPassword.isNotEmpty) {
    try {
      final response = await client.auth.signInWithPassword(
        email: testEmail,
        password: testPassword,
      );
      final user = response.user;
      if (user == null) {
        print('❌ signInWithPassword returned null user!');
      } else {
        print('✅ Auth success');
        print('   User ID   : ${user.id}');
        print('   Email     : ${user.email}');
        print('   Metadata role (JWT): ${user.userMetadata?['role']}');
        print('');

        final profile = await client
            .from('profiles')
            .select('id, email, role, is_active')
            .eq('id', user.id)
            .single();

        print('✅ Profile from public.profiles:');
        print('   role     : ${profile['role']}  ← MUST be "admin"');
        print('   is_active: ${profile['is_active']}');

        await client.auth.signOut();
      }
    } catch (e) {
      print('❌ Error during auth test: $e');
    }
  } else {
    print('ℹ️  Auth test skipped. Fill testPassword above and re-run.');
  }

  print('\n════════════════════════════════════════════════════\n');
}

