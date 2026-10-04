import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/utils/app_providers.dart';
import '../../../core/routing/app_router.dart';
import '../../../core/utils/app_logger.dart';
import '../widgets/auth_text_field.dart';
import '../widgets/auth_button.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Login screen
class LoginView extends ConsumerStatefulWidget {
  const LoginView({super.key});

  @override
  ConsumerState<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends ConsumerState<LoginView> {
  final _formKey = GlobalKey<FormState>();

  final _emailController = TextEditingController(
    text: kDebugMode ? 'abdo@gmail.com' : '',
  );
  final _passwordController = TextEditingController(
    text: kDebugMode ? '01008765502' : '',
  );

  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    // Validate form
    if (!_formKey.currentState!.validate()) {
      AppLogger.warning('Login form validation failed', tag: 'FORM');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final loginStopwatch = Stopwatch()..start();

    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text;

      AppLogger.auth(
        'LOGIN START',
        email: email,
        data: {'password': password}, // Redacted automatically
      );

      final authService = ref.read(authServiceProvider);

      // =========================
      // 1. SUPABASE LOGIN
      // =========================
      AppLogger.info('Sending Supabase authentication request...', tag: 'AUTH');
      await authService.signIn(email: email, password: password);

      // =========================
      // 2. LOAD PROFILE FROM public.profiles
      // Role is ALWAYS determined from the database, never from UI state
      // or SharedPreferences, to prevent routing to wrong dashboard.
      // =========================
      AppLogger.info(
        'Querying role from public.profiles WHERE id = user.id ...',
        tag: 'PROFILE',
      );
      final profile = await authService.getProfile();

      loginStopwatch.stop();

      if (!mounted) return;

      // =========================
      // 3. INACTIVE ACCOUNT CHECK
      // =========================
      if (profile != null && !profile.isActive) {
        await authService.signOut();
        throw Exception('الحساب غير مفعّل. يرجى التواصل مع الدعم.');
      }

      // =========================
      // 4. DETERMINE TARGET ROUTE BASED ON ROLE FROM DB
      // =========================
      if (profile == null) {
        await authService.signOut();
        throw Exception('لم يتم العثور على حساب مرتبط في قاعدة البيانات.');
      }

      final role = profile.role;
      if (role.isEmpty || (role != 'admin' && role != 'merchant' && role != 'customer')) {
        await authService.signOut();
        throw Exception('صلاحية الحساب غير معروفة أو غير صالحة: $role');
      }

      final isActive = profile.isActive;

      // --- ADMIN RPC TEST ---
      final client = Supabase.instance.client;
      final user = client.auth.currentUser;

      // ignore: avoid_print
      print('\n================ ADMIN TEST ================');
      // ignore: avoid_print
      print('USER ID: ${user?.id}');
      // ignore: avoid_print
      print('EMAIL: ${user?.email}');
      
      try {
        final result = await client.rpc('is_admin');
        // ignore: avoid_print
        print('IS ADMIN RPC RESULT: $result');
      } catch(e) {
        // ignore: avoid_print
        print('IS ADMIN RPC ERROR: $e');
      }
      // ignore: avoid_print
      print('=============================================\n');
      // ----------------------

      String targetRoute;
      switch (role) {
        case 'admin':
          targetRoute = AppRouter.admin;
          break;
        case 'merchant':
          targetRoute = AppRouter.merchantCenter;
          break;
        case 'customer':
          targetRoute = AppRouter.home;
          break;
        default:
          throw Exception('صلاحية الحساب غير مدعومة.');
      }

      // =========================
      // 5. PRETTY LOGIN SUCCESS LOGGER
      // =========================
      AppLogger.success(
        '════════════════════════════════════════\n'
        '  LOGIN SUCCESS\n'
        '  Email       : $email\n'
        '  User ID     : ${profile?.id ?? "unknown"}\n'
        '  Role        : $role\n'
        '  Active      : $isActive\n'
        '  Target Route: $targetRoute\n'
        '════════════════════════════════════════',
        tag: 'LOGIN',
      );

      AppLogger.auth(
        'LOGIN SUCCESS',
        email: email,
        userId: profile?.id,
        role: role,
        route: targetRoute,
        duration: loginStopwatch.elapsed,
      );

      // =========================
      // 6. SYNC PROVIDERS & NAVIGATE
      // =========================
      if (profile != null) {
        // Update profileProvider with the loaded profile
        ref.read(profileProvider.notifier).setProfile(profile);

        // Sync userRoleProvider from actual DB role (not UI selection)
        if (profile.role.isNotEmpty) {
          ref.read(userRoleProvider.notifier).setRole(profile.role);
        }

      }

      AppLogger.navigation(
        from: AppRouter.login,
        to: targetRoute,
        role: role,
      );

      if (!mounted) return;
      context.go(targetRoute);
    } catch (e, stackTrace) {
      loginStopwatch.stop();

      AppLogger.error(
        'LOGIN ERROR',
        error: e,
        stackTrace: stackTrace,
        location: 'LoginView._handleLogin',
        data: {'email': _emailController.text.trim()},
      );

      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final selectedRole = ref.watch(userRoleProvider);
    final isMerchant = selectedRole == 'merchant';

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.xxl),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // =========================
                    // ROLE BANNER
                    // =========================
                    Container(
                      margin: const EdgeInsets.only(bottom: AppSpacing.lg),
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.sm,
                      ),
                      decoration: BoxDecoration(
                        color: (isMerchant ? AppColors.secondary : AppColors.primary)
                            .withValues(alpha: 0.1),
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusMd),
                        border: Border.all(
                          color: (isMerchant ? AppColors.secondary : AppColors.primary)
                              .withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            isMerchant
                                ? Icons.storefront_rounded
                                : Icons.person_rounded,
                            color: isMerchant
                                ? AppColors.secondary
                                : AppColors.primary,
                            size: 20,
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Text(
                              isMerchant
                                  ? 'الدخول كـ: 🏪 تاجر'
                                  : 'الدخول كـ: 👤 عميل عادي',
                              style: AppTextStyles.bodyMedium.copyWith(
                                fontWeight: FontWeight.bold,
                                color: isMerchant
                                    ? AppColors.secondaryDark
                                    : AppColors.primary,
                              ),
                            ),
                          ),
                          TextButton(
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.xs,
                              ),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            onPressed: () => context.push(AppRouter.roleSelection),
                            child: const Text('تغيير'),
                          ),
                        ],
                      ),
                    ),

                    // =========================
                    // LOGO
                    // =========================
                    Container(
                      width: 80,
                      height: 80,
                      margin: const EdgeInsets.only(bottom: AppSpacing.lg),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Icon(
                        Icons.electrical_services_rounded,
                        size: 44,
                        color: AppColors.primary,
                      ),
                    ),

                    // =========================
                    // TITLE
                    // =========================
                    Text(
                      context.tr('auth.login'),
                      style: AppTextStyles.h2,
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: AppSpacing.sm),

                    Text(
                      context.tr('app.slogan'),
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.lightTextSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: AppSpacing.xxxl),

                    // =========================
                    // ERROR MESSAGE
                    // =========================
                    if (_errorMessage != null) ...[
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        decoration: BoxDecoration(
                          color: AppColors.error.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(
                            AppSpacing.radiusMd,
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.error_outline,
                              color: AppColors.error,
                              size: 20,
                            ),

                            const SizedBox(width: AppSpacing.sm),

                            Expanded(
                              child: Text(
                                _errorMessage!,
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: AppColors.error,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: AppSpacing.lg),
                    ],

                    // =========================
                    // EMAIL
                    // =========================
                    AuthTextField(
                      controller: _emailController,
                      label: context.tr('auth.email'),
                      hintText: 'example@email.com',
                      keyboardType: TextInputType.emailAddress,
                      prefixIcon: Icons.email_outlined,

                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return context.tr('validation.required');
                        }

                        if (!RegExp(
                          r'^[\w-.]+@([\w-]+\.)+[\w-]{2,4}$',
                        ).hasMatch(value)) {
                          return context.tr('validation.email');
                        }

                        return null;
                      },
                    ),

                    const SizedBox(height: AppSpacing.lg),

                    // =========================
                    // PASSWORD
                    // =========================
                    AuthTextField(
                      controller: _passwordController,
                      label: context.tr('auth.password'),
                      hintText: '••••••••',
                      obscureText: _obscurePassword,
                      prefixIcon: Icons.lock_outline,

                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          size: 20,
                        ),

                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),

                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return context.tr('validation.required');
                        }

                        if (value.length < 6) {
                          return context.tr('validation.password_weak');
                        }

                        return null;
                      },
                    ),

                    const SizedBox(height: AppSpacing.sm),

                    // =========================
                    // FORGOT PASSWORD
                    // =========================
                    Align(
                      alignment: AlignmentDirectional.centerEnd,
                      child: TextButton(
                        onPressed: () {
                          context.push(AppRouter.forgotPassword);
                        },
                        child: Text(context.tr('auth.forgot_password')),
                      ),
                    ),

                    const SizedBox(height: AppSpacing.xxl),

                    // =========================
                    // LOGIN BUTTON
                    // =========================
                    AuthButton(
                      label: context.tr('auth.login'),
                      isLoading: _isLoading,
                      onPressed: _handleLogin,
                    ),

                    const SizedBox(height: AppSpacing.xxl),

                    // =========================
                    // REGISTER
                    // =========================
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          context.tr('auth.no_account'),
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.lightTextSecondary,
                          ),
                        ),

                        TextButton(
                          onPressed: () {
                            context.push(AppRouter.register);
                          },
                          child: Text(
                            context.tr('auth.register'),
                            style: AppTextStyles.labelLarge.copyWith(
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

