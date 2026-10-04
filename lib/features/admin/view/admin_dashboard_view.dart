import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final profile = ref.watch(profileProvider).value;
    final isWide = MediaQuery.of(context).size.width >= 900;

    if (profile == null || !profile.isAdmin) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.lock_rounded, size: 64, color: AppColors.error),
              const SizedBox(height: AppSpacing.lg),
              Text('غير مصرح بالدخول',
                  style: AppTextStyles.h3.copyWith(color: AppColors.error)),
              const SizedBox(height: AppSpacing.lg),
              ElevatedButton(
                onPressed: () => context.go('/login'),
                child: const Text('تسجيل الدخول'),
              ),
            ],
          ),
        ),
      );
    }

    final metricsAsync = ref.watch(adminMetricsProvider);
    final padding = Responsive.getHorizontalPadding(context);

    Widget body = CustomScrollView(
      slivers: [
        // ── AppBar ─────────────────────────────────────────
        SliverAppBar(
          expandedHeight: isWide ? 0 : 130,
          floating: false,
          pinned: true,
          centerTitle: true,
          backgroundColor: AppColors.primaryDark,
          leading: isWide
              ? null
              : Builder(
                  builder: (ctx) => IconButton(
                    icon: const Icon(Icons.menu_rounded, color: AppColors.white),
                    onPressed: () => Scaffold.of(ctx).openDrawer(),
                  ),
                ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh_rounded, color: AppColors.white),
              onPressed: () => ref.invalidate(adminMetricsProvider),
              tooltip: 'تحديث',
            ),
          ],
          flexibleSpace: isWide
              ? null
              : FlexibleSpaceBar(
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
                        padding: const EdgeInsets.fromLTRB(
                            AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, 0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text('لوحة الإدارة',
                                style: AppTextStyles.h3.copyWith(
                                    color: AppColors.white,
                                    fontWeight: FontWeight.bold)),
                            Text(profile.fullName ?? 'مدير النظام',
                                style: AppTextStyles.bodySmall.copyWith(
                                    color: AppColors.white
                                        .withValues(alpha: 0.8))),
                          ],
                        ),
                      ),
                    ),
                  ),
                  title: isWide
                      ? null
                      : Text('لوحة الإدارة',
                          style: AppTextStyles.titleMedium
                              .copyWith(color: AppColors.white)),
                  titlePadding:
                      const EdgeInsets.symmetric(horizontal: 60, vertical: 14),
                ),
        ),

        // ── Metrics ────────────────────────────────────────
        SliverPadding(
          padding: EdgeInsets.all(padding),
          sliver: SliverToBoxAdapter(
            child: metricsAsync.when(
              loading: () => const Padding(
                padding: EdgeInsets.all(AppSpacing.massive),
                child: Center(child: CircularProgressIndicator.adaptive()),
              ),
              error: (err, _) => _ErrorRetry(
                message: 'فشل تحميل البيانات: $err',
                onRetry: () => ref.invalidate(adminMetricsProvider),
              ),
              data: (m) => _MetricsGrid(m: m, isDark: isDark, padding: padding),
            ),
          ),
        ),

        // ── Section Tiles ──────────────────────────────────
        SliverPadding(
          padding: EdgeInsets.symmetric(horizontal: padding),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              _SectionTitle('إدارة المتجر', isDark: isDark),
              const SizedBox(height: AppSpacing.md),
              _NavGrid(isDark: isDark),
              const SizedBox(height: AppSpacing.xxxl),
            ]),
          ),
        ),
      ],
    );

    if (isWide) {
      return Row(
        children: [
          _AdminSidebar(
            currentPath: '/admin',
            profile: profile,
            isDark: isDark,
            ref: ref,
          ),
          const VerticalDivider(width: 1),
          Expanded(child: Scaffold(body: body)),
        ],
      );
    }

    return Scaffold(
      drawer: Drawer(
        child: _AdminSidebar(
          currentPath: '/admin',
          profile: profile,
          isDark: isDark,
          ref: ref,
          isDrawer: true,
        ),
      ),
      body: body,
    );
  }
}

// ─── Metrics Grid ─────────────────────────────────────────────────────────────
class _MetricsGrid extends StatelessWidget {
  final AdminMetrics m;
  final bool isDark;
  final double padding;

  const _MetricsGrid({
    required this.m,
    required this.isDark,
    required this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final cols = MediaQuery.of(context).size.width >= 900 ? 4 : 2;

    final cards = [
      _MetricCardData('إجمالي المبيعات', '${m.totalRevenue.toStringAsFixed(0)} ج.م', Icons.payments_rounded, AppColors.success),
      _MetricCardData('مبيعات اليوم', '${m.todayRevenue.toStringAsFixed(0)} ج.م', Icons.today_rounded, AppColors.info),
      _MetricCardData('مبيعات الأسبوع', '${m.weekRevenue.toStringAsFixed(0)} ج.م', Icons.date_range_rounded, AppColors.secondary),
      _MetricCardData('مبيعات الشهر', '${m.monthRevenue.toStringAsFixed(0)} ج.م', Icons.calendar_month_rounded, AppColors.accent),
      _MetricCardData('إجمالي الطلبات', '${m.totalOrders}', Icons.receipt_long_rounded, AppColors.primary),
      _MetricCardData('طلبات معلقة', '${m.pendingOrders}', Icons.hourglass_empty_rounded, AppColors.warning),
      _MetricCardData('طلبات قيد التنفيذ', '${m.processingOrders}', Icons.local_shipping_rounded, AppColors.info),
      _MetricCardData('طلبات مكتملة', '${m.deliveredOrders}', Icons.check_circle_rounded, AppColors.success),
      _MetricCardData('طلبات ملغاة', '${m.cancelledOrders}', Icons.cancel_rounded, AppColors.error),
      _MetricCardData('العملاء', '${m.totalCustomers}', Icons.person_rounded, AppColors.accent),
      _MetricCardData('التجار', '${m.totalMerchants}', Icons.storefront_rounded, AppColors.secondaryDark),
      _MetricCardData('المنتجات', '${m.totalProducts}', Icons.inventory_2_rounded, AppColors.primary),
      _MetricCardData('مخزون منخفض', '${m.lowStockProducts}', Icons.warning_rounded, AppColors.warning),
      _MetricCardData('منتجات غير نشطة', '${m.inactiveProducts}', Icons.visibility_off_rounded, AppColors.grey500),
      _MetricCardData('إعلانات نشطة', '${m.activeAds}', Icons.campaign_rounded, AppColors.secondary),
      _MetricCardData('صافي الربح', '${m.netProfit.toStringAsFixed(0)} ج.م', Icons.trending_up_rounded,
          m.netProfit >= 0 ? AppColors.success : AppColors.error),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: cols,
        crossAxisSpacing: AppSpacing.sm,
        mainAxisSpacing: AppSpacing.sm,
        childAspectRatio: 1.5,
      ),
      itemCount: cards.length,
      itemBuilder: (_, i) => _MetricCard(data: cards[i], isDark: isDark),
    );
  }
}

class _MetricCardData {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  const _MetricCardData(this.title, this.value, this.icon, this.color);
}

class _MetricCard extends StatelessWidget {
  final _MetricCardData data;
  final bool isDark;

  const _MetricCard({required this.data, required this.isDark});

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
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  data.title,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary,
                    fontSize: 10,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: data.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(data.icon, color: data.color, size: 14),
              ),
            ],
          ),
          Text(
            data.value,
            style: AppTextStyles.titleMedium.copyWith(
              fontWeight: FontWeight.bold,
              color: data.color,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Navigation Grid ──────────────────────────────────────────────────────────
class _NavGrid extends StatelessWidget {
  final bool isDark;
  const _NavGrid({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final items = [
      _NavItem('العملاء', Icons.people_rounded, AppColors.accent, '/admin/customers'),
      _NavItem('التجار', Icons.storefront_rounded, AppColors.secondaryDark, '/admin/merchants'),
      _NavItem('المنتجات', Icons.inventory_2_rounded, AppColors.primary, '/admin/products'),
      _NavItem('التصنيفات', Icons.category_rounded, AppColors.info, '/admin/categories'),
      _NavItem('الطلبات', Icons.receipt_long_rounded, AppColors.secondary, '/admin/orders'),
      _NavItem('الإعلانات', Icons.campaign_rounded, AppColors.warning, '/admin/advertisements'),
      _NavItem('المبيعات', Icons.bar_chart_rounded, AppColors.success, '/admin/sales'),
      _NavItem('الإحصائيات', Icons.analytics_rounded, AppColors.primaryLight, '/admin/statistics'),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: AppSpacing.sm,
        mainAxisSpacing: AppSpacing.sm,
        childAspectRatio: 2.5,
      ),
      itemCount: items.length,
      itemBuilder: (ctx, i) => _NavTile(item: items[i], isDark: isDark),
    );
  }
}

class _NavItem {
  final String label;
  final IconData icon;
  final Color color;
  final String route;
  const _NavItem(this.label, this.icon, this.color, this.route);
}

class _NavTile extends StatelessWidget {
  final _NavItem item;
  final bool isDark;
  const _NavTile({required this.item, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => context.push(item.route),
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : AppColors.lightCard,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(
              color: isDark ? AppColors.darkDivider : AppColors.lightDivider),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: item.color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              ),
              child: Icon(item.icon, color: item.color, size: 20),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(item.label,
                  style: AppTextStyles.labelMedium.copyWith(
                      fontWeight: FontWeight.bold)),
            ),
            Icon(Icons.arrow_forward_ios,
                size: 12, color: AppColors.grey500),
          ],
        ),
      ),
    );
  }
}

// ─── Helpers ──────────────────────────────────────────────────────────────────
class _SectionTitle extends StatelessWidget {
  final String title;
  final bool isDark;
  const _SectionTitle(this.title, {required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Text(title,
        style: AppTextStyles.titleLarge.copyWith(fontWeight: FontWeight.bold));
  }
}

class _ErrorRetry extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorRetry({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          children: [
            const Icon(Icons.error_outline, color: AppColors.error, size: 48),
            const SizedBox(height: AppSpacing.md),
            Text(message,
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyMedium.copyWith(color: AppColors.error)),
            const SizedBox(height: AppSpacing.md),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('إعادة المحاولة'),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Sidebar (inline for dashboard) ──────────────────────────────────────────
class _AdminSidebar extends ConsumerWidget {
  final String currentPath;
  final dynamic profile;
  final bool isDark;
  final WidgetRef ref;
  final bool isDrawer;

  const _AdminSidebar({
    required this.currentPath,
    required this.profile,
    required this.isDark,
    required this.ref,
    this.isDrawer = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      width: 240,
      color: isDark ? AppColors.darkSurface : AppColors.white,
      child: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.primaryDark, AppColors.primary],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.admin_panel_settings_rounded,
                      color: AppColors.white, size: 28),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    profile?.fullName ?? 'مدير النظام',
                    style: AppTextStyles.labelLarge
                        .copyWith(color: AppColors.white),
                  ),
                  Text(
                    profile?.email ?? '',
                    style: AppTextStyles.labelSmall.copyWith(
                        color: AppColors.white.withValues(alpha: 0.75)),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                children: [
                  for (int i = 0; i < kAdminSections.length; i++)
                    _SidebarTile(
                      icon: _kSectionIcons[i],
                      label: _kSectionLabels[i],
                      route: kAdminSections[i],
                      currentPath: currentPath,
                      isDark: isDark,
                      onTap: () {
                        if (isDrawer) Navigator.of(context).pop();
                        context.go(kAdminSections[i]);
                      },
                    ),
                ],
              ),
            ),
            const Divider(height: 1),
            _SidebarTile(
              icon: Icons.logout_rounded,
              label: 'تسجيل الخروج',
              route: '',
              currentPath: '',
              isDark: isDark,
              isDestructive: true,
              onTap: () async {
                final auth = ref.read(authServiceProvider);
                await auth.signOut();
                ref.read(profileProvider.notifier).clear();
                if (context.mounted) context.go('/login');
              },
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
        ),
      ),
    );
  }
}

const _kSectionLabels = [
  'الرئيسية', 'العملاء', 'التجار', 'المنتجات', 'التصنيفات',
  'الطلبات', 'الإعلانات', 'المبيعات', 'الإحصائيات', 'الإعدادات',
];

const _kSectionIcons = [
  Icons.dashboard_rounded, Icons.people_rounded, Icons.storefront_rounded,
  Icons.inventory_2_rounded, Icons.category_rounded, Icons.receipt_long_rounded,
  Icons.campaign_rounded, Icons.bar_chart_rounded, Icons.analytics_rounded,
  Icons.settings_rounded,
];

const kAdminSections = [
  '/admin', '/admin/customers', '/admin/merchants', '/admin/products',
  '/admin/categories', '/admin/orders', '/admin/advertisements',
  '/admin/sales', '/admin/statistics', '/admin/settings',
];

class _SidebarTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String route;
  final String currentPath;
  final bool isDark;
  final bool isDestructive;
  final VoidCallback onTap;

  const _SidebarTile({
    required this.icon,
    required this.label,
    required this.route,
    required this.currentPath,
    required this.isDark,
    required this.onTap,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = route.isNotEmpty && currentPath == route;
    final color = isDestructive
        ? AppColors.error
        : isSelected
            ? AppColors.primary
            : (isDark ? AppColors.darkTextSecondary : AppColors.grey600);

    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
      child: Material(
        color: isSelected
            ? AppColors.primary.withValues(alpha: 0.1)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          child: Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md, vertical: AppSpacing.md),
            child: Row(
              children: [
                Icon(icon, size: 18, color: color),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(label,
                      style: AppTextStyles.labelMedium.copyWith(
                          color: color,
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.normal)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
