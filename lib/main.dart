import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/config/supabase_config.dart';
import 'core/localization/app_localizations.dart';
import 'core/routing/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/utils/app_providers.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase client
  try {
    await SupabaseConfig.initialize();
  } catch (e) {
    debugPrint('Supabase initialization error: $e');
  }

  runApp(
    const ProviderScope(
      child: ElectricalStoreApp(),
    ),
  );
}

class ElectricalStoreApp extends ConsumerStatefulWidget {
  const ElectricalStoreApp({super.key});

  @override
  ConsumerState<ElectricalStoreApp> createState() => _ElectricalStoreAppState();
}

class _ElectricalStoreAppState extends ConsumerState<ElectricalStoreApp> {
  @override
  void initState() {
    super.initState();
    // Load saved preferences
    Future.microtask(() async {
      await ref.read(localeProvider.notifier).initialize();
      await ref.read(themeModeProvider.notifier).initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentLocale = ref.watch(localeProvider);
    final currentThemeMode = ref.watch(themeModeProvider);

    return MaterialApp.router(
      title: 'Electrical Tools Store',
      debugShowCheckedModeBanner: false,

      // Routing
      routerConfig: AppRouter.router,

      // Localization & RTL support
      locale: currentLocale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],

      // Themes (Light & Dark)
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: currentThemeMode,
    );
  }
}
