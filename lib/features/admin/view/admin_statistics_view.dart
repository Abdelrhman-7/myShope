import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../controller/admin_controller.dart';

class AdminStatisticsView extends ConsumerWidget {
  const AdminStatisticsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final metricsAsync = ref.watch(adminMetricsProvider);
    final bestSellingAsync = ref.watch(bestSellingProductsProvider);
    final lowStockAsync = ref.watch(lowStockProductsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('الإحصائيات'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () {
              ref.invalidate(adminMetricsProvider);
              ref.invalidate(bestSellingProductsProvider);
              ref.invalidate(lowStockProductsProvider);
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(adminMetricsProvider);
          ref.invalidate(bestSellingProductsProvider);
          ref.invalidate(lowStockProductsProvider);
        },
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            // ── Overview Summary ─────────────────────────
            _SectionHeader('نظرة عامة', isDark: isDark),
            const SizedBox(height: AppSpacing.md),
            metricsAsync.when(
              loading: () => const Center(
                  child: Padding(
                padding: EdgeInsets.all(AppSpacing.xl),
                child: CircularProgressIndicator.adaptive(),
              )),
              error: (err, _) => _ErrorWidget(
                message: 'فشل تحميل الإحصائيات: $err',
                onRetry: () => ref.invalidate(adminMetricsProvider),
              ),
              data: (m) => Column(
                children: [
                  // Orders by status
                  _SectionHeader('الطلبات حسب الحالة', isDark: isDark),
                  const SizedBox(height: AppSpacing.sm),
                  _StatBar(
                      label: 'معلقة',
                      count: m.pendingOrders,
                      total: m.totalOrders,
                      color: AppColors.warning,
                      isDark: isDark),
                  const SizedBox(height: AppSpacing.xs),
                  _StatBar(
                      label: 'قيد التنفيذ',
                      count: m.processingOrders,
                      total: m.totalOrders,
                      color: AppColors.info,
                      isDark: isDark),
                  const SizedBox(height: AppSpacing.xs),
                  _StatBar(
                      label: 'مكتملة',
                      count: m.deliveredOrders,
                      total: m.totalOrders,
                      color: AppColors.success,
                      isDark: isDark),
                  const SizedBox(height: AppSpacing.xs),
                  _StatBar(
                      label: 'ملغاة',
                      count: m.cancelledOrders,
                      total: m.totalOrders,
                      color: AppColors.error,
                      isDark: isDark),

                  const SizedBox(height: AppSpacing.xl),

                  // Users summary
                  _SectionHeader('المستخدمون', isDark: isDark),
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    children: [
                      Expanded(
                        child: _StatCard(
                          label: 'العملاء',
                          value: '${m.totalCustomers}',
                          icon: Icons.person_rounded,
                          color: AppColors.accent,
                          isDark: isDark,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: _StatCard(
                          label: 'التجار',
                          value: '${m.totalMerchants}',
                          icon: Icons.storefront_rounded,
                          color: AppColors.secondaryDark,
                          isDark: isDark,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: AppSpacing.xl),

                  // Products summary
                  _SectionHeader('المنتجات', isDark: isDark),
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    children: [
                      Expanded(
                        child: _StatCard(
                          label: 'إجمالي',
                          value: '${m.totalProducts}',
                          icon: Icons.inventory_2_rounded,
                          color: AppColors.primary,
                          isDark: isDark,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: _StatCard(
                          label: 'مخزون منخفض',
                          value: '${m.lowStockProducts}',
                          icon: Icons.warning_rounded,
                          color: AppColors.warning,
                          isDark: isDark,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: _StatCard(
                          label: 'غير نشطة',
                          value: '${m.inactiveProducts}',
                          icon: Icons.visibility_off_rounded,
                          color: AppColors.grey500,
                          isDark: isDark,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.xxl),

            // ── Best Selling ─────────────────────────────
            _SectionHeader('المنتجات الأعلى مبيعاً', isDark: isDark),
            const SizedBox(height: AppSpacing.md),
            bestSellingAsync.when(
              loading: () => const Center(
                  child: CircularProgressIndicator.adaptive()),
              error: (_, __) => const Text('تعذر تحميل المنتجات'),
              data: (products) {
                if (products.isEmpty) {
                  return _EmptyState(
                    icon: Icons.trending_up_rounded,
                    message: 'لا توجد بيانات مبيعات حتى الآن',
                  );
                }
                return Column(
                  children: products.map((p) {
                    return Padding(
                      padding:
                          const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: Container(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppColors.darkCard
                              : AppColors.lightCard,
                          borderRadius: BorderRadius.circular(
                              AppSpacing.radiusMd),
                          border: Border.all(
                            color: isDark
                                ? AppColors.darkDivider
                                : AppColors.lightDivider,
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                p['name_ar'] as String? ?? '',
                                style: AppTextStyles.labelMedium,
                              ),
                            ),
                            Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '${p['quantity_sold']} وحدة',
                                  style: AppTextStyles.labelSmall
                                      .copyWith(
                                          color: AppColors.primary),
                                ),
                                Text(
                                  '${(p['revenue'] as double).toStringAsFixed(0)} ج.م',
                                  style: AppTextStyles.labelSmall
                                      .copyWith(
                                          color: AppColors.success),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            ),

            const SizedBox(height: AppSpacing.xxl),

            // ── Low Stock ────────────────────────────────
            _SectionHeader('منتجات المخزون المنخفض', isDark: isDark),
            const SizedBox(height: AppSpacing.md),
            lowStockAsync.when(
              loading: () => const Center(
                  child: CircularProgressIndicator.adaptive()),
              error: (_, __) =>
                  const Text('تعذر تحميل المنتجات'),
              data: (products) {
                if (products.isEmpty) {
                  return _EmptyState(
                    icon: Icons.check_circle_outline_rounded,
                    message: 'جميع المنتجات لديها مخزون كافٍ',
                  );
                }
                return Column(
                  children: products.map((p) {
                    final isOut = p.stockQuantity == 0;
                    return Padding(
                      padding: const EdgeInsets.only(
                          bottom: AppSpacing.sm),
                      child: Container(
                        padding:
                            const EdgeInsets.all(AppSpacing.md),
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppColors.darkCard
                              : AppColors.lightCard,
                          borderRadius: BorderRadius.circular(
                              AppSpacing.radiusMd),
                          border: Border.all(
                            color: isOut
                                ? AppColors.error
                                    .withValues(alpha: 0.4)
                                : AppColors.warning
                                    .withValues(alpha: 0.4),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              isOut
                                  ? Icons.remove_shopping_cart_rounded
                                  : Icons.warning_rounded,
                              color: isOut
                                  ? AppColors.error
                                  : AppColors.warning,
                              size: 20,
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(p.nameAr,
                                      style:
                                          AppTextStyles.labelMedium),
                                  Text(
                                    isOut
                                        ? 'نفذ المخزون'
                                        : 'المخزون: ${p.stockQuantity} / الحد الأدنى: ${p.minStock}',
                                    style: AppTextStyles.bodySmall
                                        .copyWith(
                                      color: isOut
                                          ? AppColors.error
                                          : AppColors.warning,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            ),

            const SizedBox(height: AppSpacing.xxxl),
          ],
        ),
      ),
    );
  }
}

// ─── Helpers ──────────────────────────────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  final String title;
  final bool isDark;
  const _SectionHeader(this.title, {required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(title,
              style: AppTextStyles.titleMedium
                  .copyWith(fontWeight: FontWeight.bold)),
        ),
        Divider(
            color: isDark
                ? AppColors.darkDivider
                : AppColors.lightDivider),
      ],
    );
  }
}

class _StatBar extends StatelessWidget {
  final String label;
  final int count;
  final int total;
  final Color color;
  final bool isDark;

  const _StatBar({
    required this.label,
    required this.count,
    required this.total,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final pct = total == 0 ? 0.0 : count / total;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
            color:
                isDark ? AppColors.darkDivider : AppColors.lightDivider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: AppTextStyles.labelMedium),
              Text('$count (${(pct * 100).toStringAsFixed(1)}%)',
                  style: AppTextStyles.labelMedium
                      .copyWith(color: color)),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          ClipRRect(
            borderRadius:
                BorderRadius.circular(AppSpacing.radiusFull),
            child: LinearProgressIndicator(
              value: pct,
              backgroundColor:
                  color.withValues(alpha: 0.1),
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final bool isDark;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
            color: isDark
                ? AppColors.darkDivider
                : AppColors.lightDivider),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: AppSpacing.xs),
          Text(value,
              style: AppTextStyles.titleMedium.copyWith(
                  fontWeight: FontWeight.bold, color: color)),
          Text(label,
              style: AppTextStyles.bodySmall.copyWith(
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.lightTextSecondary),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;
  const _EmptyState({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Center(
        child: Column(
          children: [
            Icon(icon, size: 48, color: AppColors.grey400),
            const SizedBox(height: AppSpacing.md),
            Text(message,
                style: AppTextStyles.bodyMedium
                    .copyWith(color: AppColors.grey500),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

class _ErrorWidget extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorWidget({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        children: [
          const Icon(Icons.error_outline, color: AppColors.error, size: 48),
          const SizedBox(height: AppSpacing.md),
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: AppSpacing.md),
          ElevatedButton(
              onPressed: onRetry, child: const Text('إعادة المحاولة')),
        ],
      ),
    );
  }
}
