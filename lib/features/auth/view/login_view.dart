import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/utils/app_providers.dart';
import '../../../core/routing/app_router.dart';
import '../widgets/auth_text_field.dart';
import '../widgets/auth_button.dart';

/// Login screen
class LoginView extends ConsumerStatefulWidget {
  const LoginView({super.key});

  @override
  ConsumerState<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends ConsumerState<LoginView> {
  final _formKey = GlobalKey<FormState>();

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

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
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text;

      // Debug
      debugPrint('==============================');
      debugPrint('LOGIN START');
      debugPrint('LOGIN EMAIL: $email');
      debugPrint('LOGIN PASSWORD LENGTH: ${password.length}');
      debugPrint('==============================');

      final authService = ref.read(authServiceProvider);

      // =========================
      // SUPABASE LOGIN
      // =========================
      await authService.signIn(email: email, password: password);

      debugPrint('LOGIN SUCCESS');
      debugPrint('Supabase authentication succeeded');

      // =========================
      // LOAD PROFILE
      // =========================
      debugPrint('LOADING PROFILE...');

      await ref.read(profileProvider.notifier).loadProfile();

      debugPrint('PROFILE LOAD FINISHED');

      final profileState = ref.read(profileProvider);

      debugPrint('PROFILE STATE: $profileState');

      if (!mounted) {
        return;
      }

      // =========================
      // HANDLE PROFILE
      // =========================
      profileState.when(
        data: (profile) {
          debugPrint('PROFILE DATA: $profile');

          if (profile != null) {
            debugPrint('CUSTOMER TYPE ID: ${profile.customerTypeId}');

            if (profile.customerTypeId != null) {
              ref
                  .read(customerTypeProvider.notifier)
                  .loadCustomerType(profile.customerTypeId!);
            }
          } else {
            debugPrint('WARNING: PROFILE IS NULL');
          }

          // =========================
          // GO HOME
          // =========================
          debugPrint('GOING TO HOME');

          context.go(AppRouter.home);
        },

        loading: () {
          debugPrint('PROFILE IS STILL LOADING');
        },

        error: (error, stackTrace) {
          debugPrint('==============================');
          debugPrint('PROFILE ERROR');
          debugPrint('ERROR: $error');
          debugPrint('STACK TRACE: $stackTrace');
          debugPrint('==============================');

          if (mounted) {
            setState(() {
              _errorMessage = 'Profile Error:\n$error';
            });
          }
        },
      );
    } catch (e, stackTrace) {
      // =========================
      // LOGIN ERROR
      // =========================
      debugPrint('==============================');
      debugPrint('LOGIN ERROR');
      debugPrint('ERROR: $e');
      debugPrint('STACK TRACE: $stackTrace');
      debugPrint('==============================');

      if (mounted) {
        setState(() {
          // Show the REAL error
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
