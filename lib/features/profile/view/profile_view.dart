import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/routing/app_router.dart';
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

    final selectedRole = ref.watch(userRoleProvider);
    final isMerchantRole = selectedRole == 'merchant' || (profile?.isMerchant ?? false);

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
                      color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 36,
                      backgroundColor: AppColors.primary.withValues(alpha: 0.12),
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
                              if (profile?.isAdmin ?? false) ...[
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: AppSpacing.sm,
                                    vertical: AppSpacing.xs,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.secondary.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(
                                        AppSpacing.radiusSm),
                                  ),
                                  child: Text(
                                    '🛡️ مسؤول',
                                    style: AppTextStyles.labelSmall.copyWith(
                                      color: AppColors.secondaryDark,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ] else if (isMerchantRole) ...[
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: AppSpacing.sm,
                                    vertical: AppSpacing.xs,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.secondary.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(
                                        AppSpacing.radiusSm),
                                    border: Border.all(
                                      color: AppColors.secondary.withValues(alpha: 0.4),
                                    ),
                                  ),
                                  child: Text(
                                    '🏪 تاجر',
                                    style: AppTextStyles.labelSmall.copyWith(
                                      color: AppColors.secondaryDark,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ] else ...[
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: AppSpacing.sm,
                                    vertical: AppSpacing.xs,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(
                                        AppSpacing.radiusSm),
                                  ),
                                  child: Text(
                                    '👤 عميل',
                                    style: AppTextStyles.labelSmall.copyWith(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
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
                    color: AppColors.secondary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    border: Border.all(
                      color: AppColors.secondary.withValues(alpha: 0.3),
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

              // ─── Merchant Features Section (Exclusive for Merchant Role) ───
              if (isMerchantRole) ...[
                Container(
                  margin: const EdgeInsets.only(bottom: AppSpacing.lg),
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.secondary.withValues(alpha: isDark ? 0.12 : 0.06),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                    border: Border.all(
                      color: AppColors.secondary.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.storefront_rounded,
                            color: AppColors.secondaryDark,
                            size: 24,
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Text(
                            'مميزات التاجر الإضافية 🏪',
                            style: AppTextStyles.titleMedium.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.secondaryDark,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        'تستمتع بتجربة العميل الكاملة + مميزات الجملة التالية:',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.lightTextSecondary,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: 2,
                        childAspectRatio: 2.2,
                        crossAxisSpacing: AppSpacing.sm,
                        mainAxisSpacing: AppSpacing.sm,
                        children: [
                          _buildMerchantFeatureCard(
                            context,
                            isDark: isDark,
                            icon: Icons.inventory_2_outlined,
                            title: 'طلب كميات جملة',
                            subtitle: 'خصم 15% إضافي',
                            onTap: () => _showMerchantWholesaleDialog(context),
                          ),
                          _buildMerchantFeatureCard(
                            context,
                            isDark: isDark,
                            icon: Icons.sell_outlined,
                            title: 'حسومات التجار',
                            subtitle: 'كتالوج بالجملة',
                            onTap: () => _showMerchantDiscountsDialog(context),
                          ),
                          _buildMerchantFeatureCard(
                            context,
                            isDark: isDark,
                            icon: Icons.analytics_outlined,
                            title: 'إحصائيات التاجر',
                            subtitle: 'ملخص الشراء',
                            onTap: () => _showMerchantAnalyticsDialog(context),
                          ),
                          _buildMerchantFeatureCard(
                            context,
                            isDark: isDark,
                            icon: Icons.contact_support_outlined,
                            title: 'دعم تجار فوري',
                            subtitle: 'مباشر 24/7',
                            onTap: () => _showMerchantSupportDialog(context),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],

              // Merchant Center quick link
              if (isMerchantRole) ...[
                _buildMenuItem(
                  context,
                  isDark: isDark,
                  isArabic: isArabic,
                  icon: Icons.storefront_rounded,
                  title: 'مركز التاجر 🏪',
                  iconColor: AppColors.secondaryDark,
                  onTap: () => context.push(AppRouter.merchantCenter),
                ),
              ],

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

              // Role Selector Item
              _buildActionItem(
                context,
                isDark: isDark,
                icon: isMerchantRole
                    ? Icons.storefront_rounded
                    : Icons.person_rounded,
                title: 'نوع الحساب الحالي',
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      isMerchantRole ? '🏪 تاجر' : '👤 عميل عادي',
                      style: AppTextStyles.labelMedium.copyWith(
                        color: isMerchantRole
                            ? AppColors.secondaryDark
                            : AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    const Icon(Icons.swap_horiz_rounded, size: 18),
                  ],
                ),
                onTap: () => context.push(AppRouter.roleSelection),
              ),

              // Admin Panel link (ONLY visible if admin in backend)
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
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
          color: isDark ? AppColors.darkDivider : AppColors.lightDivider,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd - 1),
        child: Material(
          color: isDark ? AppColors.darkCard : AppColors.lightCard,
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
        ),
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
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
          color: isDark ? AppColors.darkDivider : AppColors.lightDivider,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd - 1),
        child: Material(
          color: isDark ? AppColors.darkCard : AppColors.lightCard,
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
        ),
      ),
    );
  }

  Widget _buildMerchantFeatureCard(
    BuildContext context, {
    required bool isDark,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.xs),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : AppColors.lightCard,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(
            color: AppColors.secondary.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.secondary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              ),
              child: Icon(icon, color: AppColors.secondaryDark, size: 20),
            ),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.bodySmall.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.bodySmall.copyWith(
                      fontSize: 10,
                      color: AppColors.secondaryDark,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showMerchantWholesaleDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.inventory_2_outlined, color: AppColors.secondaryDark),
            SizedBox(width: 8),
            Text('📦 طلب الكميات والجملة'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'ميزة خاصة بحساب التاجر 🏪\n\n'
              '• خصم تلقائي 15% على كافة طلبيات الجملة.\n'
              '• إمكانية تحديد كميات مخصصة للورَش والمحلات.\n'
              '• أولوية والشحن السريع لطلبات التجار.',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('حسناً'),
          ),
        ],
      ),
    );
  }

  void _showMerchantDiscountsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.sell_outlined, color: AppColors.secondaryDark),
            SizedBox(width: 8),
            Text('🏷️ أسعار وحسومات التجار'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'كتالوج أسعار الجملة مفعل للتاجر!\n\n'
              '• يظهر خصم التاجر مباشرة في المنتجات والسلة.\n'
              '• شارة خصم التاجر مفعّلة في تصفح الأدوات الكهربائية.',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إغلاق'),
          ),
        ],
      ),
    );
  }

  void _showMerchantAnalyticsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.analytics_outlined, color: AppColors.secondaryDark),
            SizedBox(width: 8),
            Text('📊 إحصائيات التاجر'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'ملخص مشتريات التاجر:\n\n'
              '• إجمالي الوفر المالي للتاجر: 15% عروض جارية.\n'
              '• التقرير الشهري لمشتريات الأجهزة والأدوات.',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('تم'),
          ),
        ],
      ),
    );
  }

  void _showMerchantSupportDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.contact_support_outlined, color: AppColors.secondaryDark),
            SizedBox(width: 8),
            Text('📞 دعم التجار المباشر'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'خدمة خاصة بالتجار:\n\n'
              '• خط مباشر ومسؤول مبيعات مخصص للتجار.\n'
              '• للتواصل المباشر عبر واتساب أو الهاتف.',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('موافق'),
          ),
        ],
      ),
    );
  }
}

