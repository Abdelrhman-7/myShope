import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/app_providers.dart';
import '../../../core/utils/responsive.dart';
import '../../points/controller/points_controller.dart';

class ProfileView extends ConsumerWidget {
  const ProfileView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final locale = ref.watch(localeProvider);
    final isArabic = locale.languageCode == 'ar';
    final profile = ref.watch(profileProvider).value;
    final points = ref.watch(userPointsBalanceProvider);
    final padding = Responsive.getHorizontalPadding(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.translate('nav.profile')),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(padding),
          child: Column(
            children: [
              // ─── User Profile Card ─────────────────────────
              Container(
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkCard : AppColors.lightCard,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                  border: Border.all(
                    color: isDark
                        ? AppColors.darkDivider
                        : AppColors.lightDivider,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 36,
                      backgroundColor: AppColors.primary.withOpacity(0.12),
                      child: Text(
                        (profile?.fullName != null &&
                                profile!.fullName!.isNotEmpty)
                            ? profile.fullName![0].toUpperCase()
                            : 'U',
                        style: AppTextStyles.headlineMedium.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.lg),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  profile?.fullName ??
                                      loc.translate('common.no_data'),
                                  style: AppTextStyles.titleMedium.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: isDark
                                        ? AppColors.darkTextPrimary
                                        : AppColors.lightTextPrimary,
                                  ),
                                ),
                              ),
                              if (profile?.isAdmin ?? false)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: AppSpacing.sm,
                                    vertical: AppSpacing.xs,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.secondary.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(
                                        AppSpacing.radiusSm),
                                  ),
                                  child: Text(
                                    'ADMIN',
                                    style: AppTextStyles.labelSmall.copyWith(
                                      color: AppColors.secondaryDark,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            profile?.email ?? '',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: isDark
                                  ? AppColors.darkTextSecondary
                                  : AppColors.lightTextSecondary,
                            ),
                          ),
                          if (profile?.phone != null &&
                              profile!.phone!.isNotEmpty) ...[
                            const SizedBox(height: AppSpacing.xs),
                            Text(
                              profile.phone!,
                              style: AppTextStyles.bodySmall.copyWith(
                                color: isDark
                                    ? AppColors.darkTextSecondary
                                    : AppColors.lightTextSecondary,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.lg),

              // ─── Points Summary Card ───────────────────────
              InkWell(
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                onTap: () => context.push('/points'),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.md,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.secondary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    border: Border.all(
                      color: AppColors.secondary.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.stars_rounded,
                            color: AppColors.secondary,
                            size: 28,
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Text(
                            loc.translate('home.your_points'),
                            style: AppTextStyles.titleMedium.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Text(
                            '$points PTS',
                            style: AppTextStyles.titleMedium.copyWith(
                              color: AppColors.secondaryDark,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          Icon(
                            isArabic
                                ? Icons.arrow_back_ios_new
                                : Icons.arrow_forward_ios,
                            size: 14,
                            color: AppColors.secondaryDark,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: AppSpacing.xl),

              // ─── Menu Options ─────────────────────────────
              _buildMenuItem(
                context,
                isDark: isDark,
                isArabic: isArabic,
                icon: Icons.receipt_long_rounded,
                title: loc.translate('orders.title'),
                onTap: () => context.push('/orders'),
              ),
              _buildMenuItem(
                context,
                isDark: isDark,
                isArabic: isArabic,
                icon: Icons.location_on_outlined,
                title: loc.translate('addresses.title'),
                onTap: () => context.push('/addresses'),
              ),

              // Admin Panel link (ONLY visible if admin)
              if (profile?.isAdmin ?? false)
                _buildMenuItem(
                  context,
                  isDark: isDark,
                  isArabic: isArabic,
                  icon: Icons.admin_panel_settings_outlined,
                  title: loc.translate('admin.dashboard'),
                  iconColor: AppColors.secondaryDark,
                  onTap: () => context.push('/admin'),
                ),

              const Divider(height: AppSpacing.xxl),

              // Language Toggle Item
              _buildActionItem(
                context,
                isDark: isDark,
                icon: Icons.language_rounded,
                title: loc.translate('profile.language'),
                trailing: Text(
                  locale.languageCode == 'ar' ? 'العربية' : 'English',
                  style: AppTextStyles.labelMedium.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                onTap: () => ref.read(localeProvider.notifier).toggleLocale(),
              ),

              // Theme Toggle Item
              _buildActionItem(
                context,
                isDark: isDark,
                icon: isDark
                    ? Icons.dark_mode_outlined
                    : Icons.light_mode_outlined,
                title: loc.translate('profile.theme'),
                trailing: Switch.adaptive(
                  value: isDark,
                  activeColor: AppColors.secondary,
                  onChanged: (_) =>
                      ref.read(themeModeProvider.notifier).toggleTheme(),
                ),
                onTap: () =>
                    ref.read(themeModeProvider.notifier).toggleTheme(),
              ),

              const SizedBox(height: AppSpacing.xxl),

              // Logout Button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.error,
                    side: const BorderSide(color: AppColors.error),
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.md,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(AppSpacing.radiusMd),
                    ),
                  ),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: Text(loc.translate('auth.logout')),
                        content: Text(loc.translate('auth.logout_confirm')),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx),
                            child: Text(loc.translate('common.cancel')),
                          ),
                          TextButton(
                            onPressed: () async {
                              Navigator.pop(ctx);
                              await ref.read(authServiceProvider).signOut();
                              ref.read(profileProvider.notifier).clear();
                              if (context.mounted) {
                                context.go('/login');
                              }
                            },
                            child: Text(
                              loc.translate('auth.logout'),
                              style: const TextStyle(color: AppColors.error),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                  icon: const Icon(Icons.logout_rounded),
                  label: Text(
                    loc.translate('auth.logout'),
                    style: AppTextStyles.labelLarge.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.error,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xxxl),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuItem(
    BuildContext context, {
    required bool isDark,
    required bool isArabic,
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? iconColor,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
          color: isDark ? AppColors.darkDivider : AppColors.lightDivider,
        ),
      ),
      child: ListTile(
        leading: Icon(icon, color: iconColor ?? AppColors.primary),
        title: Text(
          title,
          style: AppTextStyles.bodyMedium.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        trailing: Icon(
          isArabic ? Icons.arrow_back_ios_new : Icons.arrow_forward_ios,
          size: 14,
          color: AppColors.grey500,
        ),
        onTap: onTap,
      ),
    );
  }

  Widget _buildActionItem(
    BuildContext context, {
    required bool isDark,
    required IconData icon,
    required String title,
    required Widget trailing,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
          color: isDark ? AppColors.darkDivider : AppColors.lightDivider,
        ),
      ),
      child: ListTile(
        leading: Icon(icon, color: AppColors.primary),
        title: Text(
          title,
          style: AppTextStyles.bodyMedium.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        trailing: trailing,
        onTap: onTap,
      ),
    );
  }
}
