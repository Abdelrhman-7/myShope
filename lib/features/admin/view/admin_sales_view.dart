import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../controller/admin_controller.dart';

class AdminSalesView extends ConsumerWidget {
  const AdminSalesView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final salesAsync = ref.watch(adminSalesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('المبيعات'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => ref.invalidate(adminSalesProvider),
          ),
        ],
      ),
      body: salesAsync.when(
        loading: () =>
            const Center(child: CircularProgressIndicator.adaptive()),
        error: (err, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline,
                  color: AppColors.error, size: 48),
              const SizedBox(height: AppSpacing.md),
              Text('فشل التحميل: $err', textAlign: TextAlign.center),
              const SizedBox(height: AppSpacing.md),
              ElevatedButton(
                onPressed: () => ref.invalidate(adminSalesProvider),
                child: const Text('إعادة المحاولة'),
              ),
            ],
          ),
        ),
        data: (stats) => RefreshIndicator(
          onRefresh: () async => ref.invalidate(adminSalesProvider),
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              // ── Summary Cards ────────────────────────────
              Text('ملخص المبيعات',
                  style: AppTextStyles.titleLarge
                      .copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: AppSpacing.md),
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount:
                    MediaQuery.of(context).size.width >= 600 ? 3 : 2,
                crossAxisSpacing: AppSpacing.sm,
                mainAxisSpacing: AppSpacing.sm,
                childAspectRatio: 1.4,
                children: [
                  _SalesCard(
                    isDark: isDark,
                    title: 'إجمالي المبيعات',
                    value: '${stats.totalSales.toStringAsFixed(0)} ج.م',
                    icon: Icons.payments_rounded,
                    color: AppColors.success,
                  ),
                  _SalesCard(
                    isDark: isDark,
                    title: 'مبيعات اليوم',
                    value: '${stats.todaySales.toStringAsFixed(0)} ج.م',
                    icon: Icons.today_rounded,
                    color: AppColors.info,
                  ),
                  _SalesCard(
                    isDark: isDark,
                    title: 'مبيعات الأسبوع',
                    value: '${stats.weekSales.toStringAsFixed(0)} ج.م',
                    icon: Icons.date_range_rounded,
                    color: AppColors.secondary,
                  ),
                  _SalesCard(
                    isDark: isDark,
                    title: 'مبيعات الشهر',
                    value: '${stats.monthSales.toStringAsFixed(0)} ج.م',
                    icon: Icons.calendar_month_rounded,
                    color: AppColors.accent,
                  ),
                  _SalesCard(
                    isDark: isDark,
                    title: 'عدد الطلبات',
                    value: '${stats.totalOrders}',
                    icon: Icons.receipt_long_rounded,
                    color: AppColors.primary,
                  ),
                  _SalesCard(
                    isDark: isDark,
                    title: 'متوسط قيمة الطلب',
                    value:
                        '${stats.avgOrderValue.toStringAsFixed(0)} ج.م',
                    icon: Icons.trending_up_rounded,
                    color: AppColors.primaryLight,
                  ),
                ],
              ),

              const SizedBox(height: AppSpacing.xxl),

              // ── Note about profits ───────────────────────
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.08),
                  borderRadius:
                      BorderRadius.circular(AppSpacing.radiusMd),
                  border: Border.all(
                    color: AppColors.warning.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.info_outline_rounded,
                        color: AppColors.warning, size: 20),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        'ملاحظة: لا يوجد عمود cost_price في جدول products حالياً. '
                        'الأرباح الحقيقية تحتاج تكلفة الشراء لكل منتج. '
                        'لحساب الربح الصافي، أضف عمود cost_price إلى جدول products في Supabase.',
                        style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.warning),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.xxl),

              // ── Recent Orders ────────────────────────────
              if (stats.recentOrders.isNotEmpty) ...[
                Text('آخر الطلبات',
                    style: AppTextStyles.titleMedium
                        .copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: AppSpacing.md),
                for (final o in stats.recentOrders) ...[
                  _RecentOrderTile(order: o, isDark: isDark),
                  const SizedBox(height: AppSpacing.sm),
                ],
              ] else
                Center(
                  child: Padding(
                    padding:
                        const EdgeInsets.all(AppSpacing.massive),
                    child: Text(
                      'لا توجد طلبات حتى الآن',
                      style: AppTextStyles.bodyLarge
                          .copyWith(color: AppColors.grey500),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SalesCard extends StatelessWidget {
  final bool isDark;
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _SalesCard({
    required this.isDark,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
          color:
              isDark ? AppColors.darkDivider : AppColors.lightDivider,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value,
                  style: AppTextStyles.titleMedium.copyWith(
                      fontWeight: FontWeight.bold, color: color)),
              Text(title,
                  style: AppTextStyles.bodySmall.copyWith(
                      fontSize: 10,
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary)),
            ],
          ),
        ],
      ),
    );
  }
}

class _RecentOrderTile extends StatelessWidget {
  final Map<String, dynamic> order;
  final bool isDark;

  const _RecentOrderTile({required this.order, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final total =
        (order['total'] as num?)?.toStringAsFixed(0) ?? '0';
    final status = order['status'] as String? ?? '';
    final customerName = order['customer_name'] as String? ?? 'عميل';
    final orderNum = order['order_number'] as String? ??
        (order['id'] as String).substring(0, 8);

    Color statusColor;
    switch (status) {
      case 'delivered':
        statusColor = AppColors.success;
        break;
      case 'cancelled':
        statusColor = AppColors.error;
        break;
      case 'processing':
        statusColor = AppColors.info;
        break;
      default:
        statusColor = AppColors.warning;
    }

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
          color:
              isDark ? AppColors.darkDivider : AppColors.lightDivider,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('#$orderNum',
                    style: AppTextStyles.labelMedium
                        .copyWith(fontWeight: FontWeight.bold)),
                Text(customerName,
                    style: AppTextStyles.bodySmall),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('$total ج.م',
                  style: AppTextStyles.labelMedium.copyWith(
                      color: AppColors.success,
                      fontWeight: FontWeight.bold)),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: AppSpacing.xs),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius:
                      BorderRadius.circular(AppSpacing.radiusSm),
                ),
                child: Text(status,
                    style: AppTextStyles.labelSmall
                        .copyWith(color: statusColor)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
