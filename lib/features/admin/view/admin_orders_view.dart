import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/responsive.dart';
import '../controller/admin_controller.dart';

class AdminOrdersView extends ConsumerStatefulWidget {
  const AdminOrdersView({super.key});

  @override
  ConsumerState<AdminOrdersView> createState() => _AdminOrdersViewState();
}

class _AdminOrdersViewState extends ConsumerState<AdminOrdersView> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(adminOrdersProvider.notifier).loadOrders();
    });
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ordersState = ref.watch(adminOrdersProvider);
    final padding = Responsive.getHorizontalPadding(context);

    final statuses = [
      'pending',
      'processing',
      'shipped',
      'delivered',
      'cancelled'
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.translate('admin.orders')),
        centerTitle: true,
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            await ref.read(adminOrdersProvider.notifier).loadOrders();
          },
          child: ordersState.when(
            loading: () => const Center(
              child: CircularProgressIndicator.adaptive(),
            ),
            error: (_, __) => Center(
              child: Text(loc.translate('common.error')),
            ),
            data: (orders) {
              if (orders.isEmpty) {
                return Center(child: Text(loc.translate('common.no_data')));
              }

              return ListView.separated(
                padding: EdgeInsets.all(padding),
                itemCount: orders.length,
                separatorBuilder: (_, __) =>
                    const SizedBox(height: AppSpacing.sm),
                itemBuilder: (context, idx) {
                  final o = orders[idx];

                  return Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkCard : AppColors.lightCard,
                      borderRadius:
                          BorderRadius.circular(AppSpacing.radiusMd),
                      border: Border.all(
                        color: isDark
                            ? AppColors.darkDivider
                            : AppColors.lightDivider,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              o.orderNumber ?? o.id.substring(0, 8),
                              style: AppTextStyles.titleMedium.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            DropdownButton<String>(
                              value: statuses.contains(o.status)
                                  ? o.status
                                  : 'pending',
                              underline: const SizedBox.shrink(),
                              items: statuses.map((s) {
                                return DropdownMenuItem(
                                  value: s,
                                  child: Text(
                                    loc.translate('orders.status_$s'),
                                    style: AppTextStyles.labelMedium,
                                  ),
                                );
                              }).toList(),
                              onChanged: (newStatus) {
                                if (newStatus != null) {
                                  ref
                                      .read(adminOrdersProvider.notifier)
                                      .updateStatus(o.id, newStatus);
                                }
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          '${o.customerName ?? ''} • ${o.customerPhone ?? ''}',
                          style: AppTextStyles.bodySmall,
                        ),
                        if (o.address != null) ...[
                          const SizedBox(height: AppSpacing.xs),
                          Text(o.address!, style: AppTextStyles.bodySmall),
                        ],
                        const SizedBox(height: AppSpacing.sm),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${loc.translate('orders.total')}:',
                              style: AppTextStyles.bodyMedium,
                            ),
                            Text(
                              '${o.total.toStringAsFixed(0)} ${loc.translate('common.currency')}',
                              style: AppTextStyles.titleMedium.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}

