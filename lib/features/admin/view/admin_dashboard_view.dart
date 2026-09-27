import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/app_providers.dart';
import '../../../core/utils/responsive.dart';
import '../controller/admin_controller.dart';

class AdminDashboardView extends ConsumerWidget {
  const AdminDashboardView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final profile = ref.watch(profileProvider).value;

    // Strict security check: only admin can view this view
    if (profile == null || !profile.isAdmin) {
      return Scaffold(
        appBar: AppBar(title: Text(loc.translate('admin.dashboard'))),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.lock_person_rounded,
                  size: 72,
                  color: AppColors.error,
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  loc.translate('common.unauthorized'),
                  style: AppTextStyles.headlineSmall.copyWith(
                    color: AppColors.error,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                ElevatedButton(
                  onPressed: () => context.go('/home'),
                  child: Text(loc.translate('common.back')),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final metricsAsync = ref.watch(adminMetricsProvider);
    final padding = Responsive.getHorizontalPadding(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.translate('admin.dashboard')),
        centerTitle: true,
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(adminMetricsProvider);
          },
          child: SingleChildScrollView(
            padding: EdgeInsets.all(padding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Metrics overview
                metricsAsync.when(
                  loading: () => const Center(
                    child: CircularProgressIndicator.adaptive(),
                  ),
                  error: (_, __) => Center(
                    child: Text(loc.translate('common.error')),
                  ),
                  data: (m) {
                    final isDesktop = Responsive.isDesktop(context);
                    final isTablet = Responsive.isTablet(context);
                    final crossAxisCount = isDesktop ? 4 : (isTablet ? 2 : 2);

                    return GridView.count(
                      crossAxisCount: crossAxisCount,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: AppSpacing.md,
                      mainAxisSpacing: AppSpacing.md,
                      childAspectRatio: 1.4,
                      children: [
                        _buildMetricCard(
                          isDark,
                          title: loc.translate('admin.total_revenue'),
                          value:
                              '${m.totalRevenue.toStringAsFixed(0)} ${loc.translate('common.currency')}',
                          icon: Icons.payments_outlined,
                          color: AppColors.success,
                        ),
                        _buildMetricCard(
                          isDark,
                          title: loc.translate('admin.total_orders'),
                          value: '${m.totalOrders}',
                          icon: Icons.receipt_long_outlined,
                          color: AppColors.primary,
                        ),
                        _buildMetricCard(
                          isDark,
                          title: loc.translate('admin.total_products'),
                          value: '${m.totalProducts}',
                          icon: Icons.inventory_2_outlined,
                          color: AppColors.secondary,
                        ),
                        _buildMetricCard(
                          isDark,
                          title: loc.translate('admin.total_customers'),
                          value: '${m.totalCustomers}',
                          icon: Icons.people_outline,
                          color: AppColors.accent,
                        ),
                      ],
                    );
                  },
                ),

                const SizedBox(height: AppSpacing.xxl),

                Text(
                  loc.translate('admin.management'),
                  style: AppTextStyles.titleLarge.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),

                // Management links
                _buildNavTile(
                  context,
                  isDark: isDark,
                  icon: Icons.inventory_2_rounded,
                  title: loc.translate('admin.products'),
                  subtitle: loc.translate('admin.manage_products_desc'),
                  onTap: () => context.push('/admin/products'),
                ),
                const SizedBox(height: AppSpacing.sm),
                _buildNavTile(
                  context,
                  isDark: isDark,
                  icon: Icons.shopping_bag_rounded,
                  title: loc.translate('admin.orders'),
                  subtitle: loc.translate('admin.manage_orders_desc'),
                  onTap: () => context.push('/admin/orders'),
                ),
                const SizedBox(height: AppSpacing.sm),
                _buildNavTile(
                  context,
                  isDark: isDark,
                  icon: Icons.people_alt_rounded,
                  title: loc.translate('admin.customers'),
                  subtitle: loc.translate('admin.manage_customers_desc'),
                  onTap: () => context.push('/admin/customers'),
                ),

                const SizedBox(height: AppSpacing.xxxl),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMetricCard(
    bool isDark, {
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
          color: isDark ? AppColors.darkDivider : AppColors.lightDivider,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: AppTextStyles.bodySmall.copyWith(
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.lightTextSecondary,
                ),
              ),
              Icon(icon, color: color, size: 20),
            ],
          ),
          Text(
            value,
            style: AppTextStyles.titleMedium.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavTile(
    BuildContext context, {
    required bool isDark,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
          color: isDark ? AppColors.darkDivider : AppColors.lightDivider,
        ),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(AppSpacing.sm),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          ),
          child: Icon(icon, color: AppColors.primary),
        ),
        title: Text(
          title,
          style: AppTextStyles.titleMedium.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(subtitle, style: AppTextStyles.bodySmall),
        trailing: const Icon(Icons.arrow_forward_ios, size: 14),
        onTap: onTap,
      ),
    );
  }
}
