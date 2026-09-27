import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/config/supabase_config.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/responsive.dart';
import '../controller/orders_controller.dart';
import '../models/order_model.dart';

final singleOrderFutureProvider =
    FutureProvider.family<OrderModel?, String>((ref, orderId) async {
  final response =
      await supabase.from('orders').select().eq('id', orderId).maybeSingle();

  if (response == null) return null;
  return OrderModel.fromJson(response);
});

class OrderDetailsView extends ConsumerWidget {
  final String orderId;

  const OrderDetailsView({
    super.key,
    required this.orderId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final orderAsync = ref.watch(singleOrderFutureProvider(orderId));
    final itemsAsync = ref.watch(orderItemsFutureProvider(orderId));
    final padding = Responsive.getHorizontalPadding(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.translate('orders.details')),
        centerTitle: true,
      ),
      body: SafeArea(
        child: orderAsync.when(
          loading: () => const Center(
            child: CircularProgressIndicator.adaptive(),
          ),
          error: (error, _) => Center(
            child: Text(loc.translate('common.error')),
          ),
          data: (order) {
            if (order == null) {
              return Center(child: Text(loc.translate('common.no_results')));
            }

            return SingleChildScrollView(
              padding: EdgeInsets.all(padding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ─── Status & Number Card ───────────────────
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkCard : AppColors.lightCard,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                      border: Border.all(
                        color: isDark
                            ? AppColors.darkDivider
                            : AppColors.lightDivider,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${loc.translate('orders.number')}: ${order.orderNumber ?? order.id}',
                          style: AppTextStyles.titleMedium.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        if (order.createdAt != null)
                          Text(
                            order.createdAt!.toLocal().toString().split('.')[0],
                            style: AppTextStyles.bodySmall.copyWith(
                              color: isDark
                                  ? AppColors.darkTextSecondary
                                  : AppColors.lightTextSecondary,
                            ),
                          ),
                        const SizedBox(height: AppSpacing.md),
                        Row(
                          children: [
                            Text(
                              '${loc.translate('orders.status')}: ',
                              style: AppTextStyles.bodyMedium,
                            ),
                            Text(
                              loc.translate('orders.status_${order.status}'),
                              style: AppTextStyles.labelLarge.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: AppSpacing.lg),

                  // ─── Shipping & Customer Info ───────────────
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkCard : AppColors.lightCard,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                      border: Border.all(
                        color: isDark
                            ? AppColors.darkDivider
                            : AppColors.lightDivider,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          loc.translate('addresses.title'),
                          style: AppTextStyles.titleSmall.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        if (order.customerName != null)
                          Text('${order.customerName}'),
                        if (order.customerPhone != null)
                          Text('${order.customerPhone}'),
                        if (order.address != null) Text('${order.address}'),
                        if (order.notes != null && order.notes!.isNotEmpty) ...[
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            '${loc.translate('orders.notes')}: ${order.notes}',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.grey500,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: AppSpacing.lg),

                  // ─── Items List ─────────────────────────────
                  Text(
                    loc.translate('products.title'),
                    style: AppTextStyles.titleLarge.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),

                  itemsAsync.when(
                    loading: () => const Center(
                      child: CircularProgressIndicator.adaptive(),
                    ),
                    error: (_, __) => const SizedBox.shrink(),
                    data: (items) {
                      return ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: items.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: AppSpacing.sm),
                        itemBuilder: (context, idx) {
                          final it = items[idx];
                          return Container(
                            padding: const EdgeInsets.all(AppSpacing.md),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? AppColors.darkCard
                                  : AppColors.lightCard,
                              borderRadius:
                                  BorderRadius.circular(AppSpacing.radiusMd),
                              border: Border.all(
                                color: isDark
                                    ? AppColors.darkDivider
                                    : AppColors.lightDivider,
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        it.productName,
                                        style:
                                            AppTextStyles.bodyLarge.copyWith(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: AppSpacing.xs),
                                      Text(
                                        '${it.quantity} × ${it.unitPrice.toStringAsFixed(0)} ${loc.translate('common.currency')}',
                                        style:
                                            AppTextStyles.bodySmall.copyWith(
                                          color: isDark
                                              ? AppColors.darkTextSecondary
                                              : AppColors.lightTextSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  '${it.totalPrice.toStringAsFixed(0)} ${loc.translate('common.currency')}',
                                  style: AppTextStyles.titleMedium.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  ),

                  const SizedBox(height: AppSpacing.lg),

                  // ─── Price Breakdown ────────────────────────
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkCard : AppColors.lightCard,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                      border: Border.all(
                        color: isDark
                            ? AppColors.darkDivider
                            : AppColors.lightDivider,
                      ),
                    ),
                    child: Column(
                      children: [
                        _buildRow(
                          loc.translate('orders.subtotal'),
                          '${order.subtotal.toStringAsFixed(0)} ${loc.translate('common.currency')}',
                        ),
                        if (order.discount > 0)
                          _buildRow(
                            loc.translate('orders.discount'),
                            '-${order.discount.toStringAsFixed(0)} ${loc.translate('common.currency')}',
                            color: AppColors.discount,
                          ),
                        _buildRow(
                          loc.translate('orders.delivery_fee'),
                          '${order.deliveryFee.toStringAsFixed(0)} ${loc.translate('common.currency')}',
                        ),
                        const Divider(height: AppSpacing.lg),
                        _buildRow(
                          loc.translate('orders.total'),
                          '${order.total.toStringAsFixed(0)} ${loc.translate('common.currency')}',
                          isBold: true,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: AppSpacing.xxxl),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildRow(
    String label,
    String value, {
    bool isBold = false,
    Color? color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: isBold
                ? AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.bold)
                : AppTextStyles.bodyMedium,
          ),
          Text(
            value,
            style: isBold
                ? AppTextStyles.titleLarge.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color ?? AppColors.primary,
                  )
                : AppTextStyles.bodyMedium.copyWith(color: color),
          ),
        ],
      ),
    );
  }
}
