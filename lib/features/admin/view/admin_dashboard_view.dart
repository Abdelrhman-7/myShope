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

    // ── Security: Only admin ───────────────────────────────────────
    if (profile == null || !profile.isAdmin) {
      return Scaffold(
        appBar: AppBar(title: Text(loc.translate('admin.dashboard'))),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.lock_person_rounded,
                    size: 72,
                    color: AppColors.error,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  loc.translate('common.unauthorized'),
                  style: AppTextStyles.headlineSmall.copyWith(
                    color: AppColors.error,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.lg),
                ElevatedButton.icon(
                  onPressed: () => context.go('/home'),
                  icon: const Icon(Icons.home_rounded),
                  label: Text(loc.translate('common.back')),
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
      body: CustomScrollView(
        slivers: [
          // ── Sliver AppBar ─────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 160,
            floating: false,
            pinned: true,
            centerTitle: true,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_rounded, color: AppColors.white),
              onPressed: () {
                if (context.canPop()) {
                  context.pop();
                } else {
                  context.go('/role-selection');
                }
              },
              tooltip: loc.translate('common.back'),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppColors.primaryDark, AppColors.primary],
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(AppSpacing.sm),
                              decoration: BoxDecoration(
                                color: AppColors.white.withValues(alpha: 0.2),
                                borderRadius:
                                    BorderRadius.circular(AppSpacing.radiusMd),
                              ),
                              child: const Icon(
                                Icons.admin_panel_settings_rounded,
                                color: AppColors.white,
                                size: 28,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'لوحة الإدارة',
                                  style: AppTextStyles.titleLarge.copyWith(
                                    color: AppColors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  profile.fullName ?? 'مدير النظام',
                                  style: AppTextStyles.bodySmall.copyWith(
                                    color: AppColors.white
                                        .withValues(alpha: 0.85),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              title: const Text(
                'لوحة الإدارة',
                style: TextStyle(color: AppColors.white),
              ),
              titlePadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),

          // ── Metrics Grid ──────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(padding),
              child: metricsAsync.when(
                loading: () => const Padding(
                  padding: EdgeInsets.all(AppSpacing.xl),
                  child: Center(child: CircularProgressIndicator.adaptive()),
                ),
                error: (_, __) => Center(
                  child: Column(
                    children: [
                      const Icon(Icons.error_outline,
                          color: AppColors.error, size: 48),
                      const SizedBox(height: AppSpacing.md),
                      Text(loc.translate('common.error'),
                          style: AppTextStyles.bodyMedium),
                      const SizedBox(height: AppSpacing.md),
                      ElevatedButton(
                        onPressed: () => ref.invalidate(adminMetricsProvider),
                        child: Text(loc.translate('common.retry')),
                      ),
                    ],
                  ),
                ),
                data: (m) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: AppSpacing.md),

                      // Revenue + Profit Row
                      Row(
                        children: [
                          Expanded(
                            child: _MetricCard(
                              isDark: isDark,
                              title: 'إجمالي الإيرادات',
                              value:
                                  '${m.totalRevenue.toStringAsFixed(0)} ج.م',
                              icon: Icons.payments_outlined,
                              color: AppColors.success,
                              subtitle: 'جميع الطلبات',
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: _MetricCard(
                              isDark: isDark,
                              title: 'صافي الربح',
                              value: '${m.netProfit.toStringAsFixed(0)} ج.م',
                              icon: Icons.trending_up_rounded,
                              color: m.netProfit >= 0
                                  ? AppColors.success
                                  : AppColors.error,
                              subtitle:
                                  'بعد الخصومات والتكاليف',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.sm),

                      // Orders Row
                      Row(
                        children: [
                          Expanded(
                            child: _MetricCard(
                              isDark: isDark,
                              title: 'إجمالي الطلبات',
                              value: '${m.totalOrders}',
                              icon: Icons.receipt_long_outlined,
                              color: AppColors.primary,
                              subtitle:
                                  '${m.pendingOrders} معلق • ${m.deliveredOrders} موصل',
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: _MetricCard(
                              isDark: isDark,
                              title: 'إجمالي المنتجات',
                              value: '${m.totalProducts}',
                              icon: Icons.inventory_2_outlined,
                              color: AppColors.secondary,
                              subtitle: 'في المتجر',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.sm),

                      // Users Row
                      Row(
                        children: [
                          Expanded(
                            child: _MetricCard(
                              isDark: isDark,
                              title: 'العملاء',
                              value: '${m.totalCustomers}',
                              icon: Icons.person_outline,
                              color: AppColors.accent,
                              subtitle: 'عميل عادي',
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: _MetricCard(
                              isDark: isDark,
                              title: 'التجار',
                              value: '${m.totalMerchants}',
                              icon: Icons.storefront_outlined,
                              color: AppColors.secondaryDark,
                              subtitle: 'حساب تاجر',
                            ),
                          ),
                        ],
                      ),

                      // Discount info
                      if (m.totalDiscount > 0) ...[
                        const SizedBox(height: AppSpacing.sm),
                        Container(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          decoration: BoxDecoration(
                            color: AppColors.error.withValues(alpha: 0.07),
                            borderRadius:
                                BorderRadius.circular(AppSpacing.radiusMd),
                            border: Border.all(
                              color: AppColors.error.withValues(alpha: 0.2),
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.discount_outlined,
                                  color: AppColors.error, size: 20),
                              const SizedBox(width: AppSpacing.sm),
                              Expanded(
                                child: Text(
                                  'إجمالي الخصومات الممنوحة: ${m.totalDiscount.toStringAsFixed(0)} ج.م',
                                  style: AppTextStyles.bodySmall.copyWith(
                                    color: AppColors.error,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      const SizedBox(height: AppSpacing.xxl),

                      // ── Management ─────────────────────────────────
                      Text(
                        'إدارة المتجر',
                        style: AppTextStyles.titleLarge.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                    ],
                  );
                },
              ),
            ),
          ),

          // ── Nav Tiles ─────────────────────────────────────────────
          SliverPadding(
            padding: EdgeInsets.symmetric(horizontal: padding),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildNavTile(
                  context,
                  isDark: isDark,
                  icon: Icons.inventory_2_rounded,
                  iconColor: AppColors.primary,
                  title: loc.translate('admin.products'),
                  subtitle: 'إدارة وتفعيل/تعطيل المنتجات',
                  onTap: () => context.push('/admin/products'),
                ),
                const SizedBox(height: AppSpacing.sm),
                _buildNavTile(
                  context,
                  isDark: isDark,
                  icon: Icons.shopping_bag_rounded,
                  iconColor: AppColors.secondary,
                  title: loc.translate('admin.orders'),
                  subtitle: 'عرض وتحديث حالة الطلبات',
                  onTap: () => context.push('/admin/orders'),
                ),
                const SizedBox(height: AppSpacing.sm),
                _buildNavTile(
                  context,
                  isDark: isDark,
                  icon: Icons.people_alt_rounded,
                  iconColor: AppColors.accent,
                  title: loc.translate('admin.customers'),
                  subtitle: 'إدارة المستخدمين وأدوارهم',
                  onTap: () => context.push('/admin/customers'),
                ),
                const SizedBox(height: AppSpacing.xxxl),
              ]),
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
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : AppColors.lightCard,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(
            color: isDark ? AppColors.darkDivider : AppColors.lightDivider,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              ),
              child: Icon(icon, color: iconColor, size: 24),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.titleSmall.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 14,
                color: AppColors.grey500),
          ],
        ),
      ),
    );
  }
}

// ─── Metric Card Widget ───────────────────────────────────────────────────
class _MetricCard extends StatelessWidget {
  final bool isDark;
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final String? subtitle;

  const _MetricCard({
    required this.isDark,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
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
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 16),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            value,
            style: AppTextStyles.titleMedium.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 2),
            Text(
              subtitle!,
              style: AppTextStyles.bodySmall.copyWith(
                fontSize: 10,
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.lightTextSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

