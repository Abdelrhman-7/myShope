import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/app_providers.dart';
import '../../../core/routing/app_router.dart';
import '../../../core/utils/app_logger.dart';

/// Splash screen — checks session and routes accordingly.
class SplashView extends ConsumerStatefulWidget {
  const SplashView({super.key});

  @override
  ConsumerState<SplashView> createState() => _SplashViewState();
}

class _SplashViewState extends ConsumerState<SplashView>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
          parent: _animationController, curve: Curves.easeOutBack),
    );

    _animationController.forward();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      AppLogger.info('Initializing app preferences...', tag: 'SPLASH');

      // Initialize preferences safely with timeout
      await Future.wait([
        ref.read(localeProvider.notifier).initialize(),
        ref.read(themeModeProvider.notifier).initialize(),
        ref.read(userRoleProvider.notifier).initialize(),
      ]).timeout(const Duration(seconds: 2), onTimeout: () => []);

      // Minimum splash delay
      await Future.delayed(const Duration(milliseconds: 1500));

      if (!mounted) return;

      final authService = ref.read(authServiceProvider);

      AppLogger.auth('SESSION CHECK');

      if (authService.isAuthenticated) {
        final currentUser = authService.currentUser;
        AppLogger.auth(
          'SESSION FOUND',
          userId: currentUser?.id,
          email: currentUser?.email,
        );

        try {
          await ref
              .read(profileProvider.notifier)
              .loadProfile()
              .timeout(const Duration(seconds: 3));
        } catch (e) {
          AppLogger.warning('Profile loading timed out on splash', tag: 'SPLASH');
        }

        if (!mounted) return;

        final profile = ref.read(profileProvider).value;
        if (profile != null) {
          if (profile.role.isNotEmpty) {
            ref.read(userRoleProvider.notifier).setRole(profile.role);
          }

          // Route based on role
          if (profile.isAdmin) {
            AppLogger.navigation(
              from: AppRouter.splash,
              to: AppRouter.admin,
              role: 'admin',
            );
            context.go(AppRouter.admin);
            return;
          }
          if (profile.isMerchant) {
            AppLogger.navigation(
              from: AppRouter.splash,
              to: AppRouter.merchantCenter,
              role: 'merchant',
            );
            context.go(AppRouter.merchantCenter);
            return;
          }

          // Default: customer
          AppLogger.navigation(
            from: AppRouter.splash,
            to: AppRouter.home,
            role: 'customer',
          );
          context.go(AppRouter.home);
          return;
        }
      } else {
        AppLogger.auth('SESSION NOT FOUND');
      }

      AppLogger.navigation(
        from: AppRouter.splash,
        to: AppRouter.roleSelection,
      );
      context.go(AppRouter.roleSelection);
    } catch (e, st) {
      AppLogger.error(
        'Splash initialization failed',
        error: e,
        stackTrace: st,
        location: 'SplashView._initializeApp',
      );
      if (mounted) {
        context.go(AppRouter.roleSelection);
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [
                    AppColors.darkBackground,
                    AppColors.primaryDark,
                    AppColors.darkBackground,
                  ]
                : [
                    AppColors.primary,
                    AppColors.primaryDark,
                    AppColors.primary,
                  ],
          ),
        ),
        child: AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            return FadeTransition(
              opacity: _fadeAnimation,
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Logo icon
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: AppColors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: const Icon(
                        Icons.electrical_services_rounded,
                        size: 64,
                        color: AppColors.white,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Electrical Tools',
                      style: AppTextStyles.h1.copyWith(
                        color: AppColors.white,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'متجر الأدوات الكهربائية',
                      style: AppTextStyles.bodyLarge.copyWith(
                        color: AppColors.white.withValues(alpha: 0.8),
                      ),
                    ),
                    const SizedBox(height: 48),
                    SizedBox(
                      width: 32,
                      height: 32,
                      child: CircularProgressIndicator(
                        strokeWidth: 3,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppColors.white.withValues(alpha: 0.7),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

