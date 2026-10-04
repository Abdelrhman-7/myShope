import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/responsive.dart';
import '../controller/admin_controller.dart';
import '../../orders/models/order_model.dart';

class AdminOrdersView extends ConsumerStatefulWidget {
  const AdminOrdersView({super.key});

  @override
  ConsumerState<AdminOrdersView> createState() => _AdminOrdersViewState();
}

class _AdminOrdersViewState extends ConsumerState<AdminOrdersView> {
  String _searchQuery = '';
  String _filterStatus = 'all';

  final _searchCtrl = TextEditingController();

  final _statuses = [
    'pending',
    'accepted',
    'rejected',
    'processing',
    'shipped',
    'delivered',
    'cancelled'
  ];

  String _translateStatus(String status) {
    switch (status) {
      case 'pending':
        return 'قيد الانتظار';
      case 'accepted':
        return 'مقبول';
      case 'rejected':
        return 'مرفوض';
      case 'processing':
        return 'قيد التجهيز';
      case 'shipped':
        return 'تم الشحن';
      case 'delivered':
        return 'مكتمل';
      case 'cancelled':
        return 'ملغى';
      default:
        return status;
    }
  }

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(adminOrdersProvider.notifier).loadOrders();
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ordersState = ref.watch(adminOrdersProvider);
    final padding = Responsive.getHorizontalPadding(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('الطلبات'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => ref.read(adminOrdersProvider.notifier).loadOrders(),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // ── Search & Filter ────────────────────────────────
            Padding(
              padding: EdgeInsets.fromLTRB(padding, AppSpacing.md, padding, 0),
              child: Column(
                children: [
                  TextField(
                    controller: _searchCtrl,
                    decoration: InputDecoration(
                      hintText: 'بحث برقم الطلب أو اسم العميل...',
                      prefixIcon: const Icon(Icons.search_rounded),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchCtrl.clear();
                                setState(() => _searchQuery = '');
                              },
                            )
                          : null,
                      filled: true,
                      fillColor:
                          isDark ? AppColors.darkCard : AppColors.lightCard,
                      border: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusMd),
                        borderSide: BorderSide(
                          color: isDark
                              ? AppColors.darkDivider
                              : AppColors.lightDivider,
                        ),
                      ),
                    ),
                    onChanged: (v) => setState(() => _searchQuery = v.trim()),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(left: AppSpacing.xs),
                          child: FilterChip(
                            label: const Text('الكل'),
                            selected: _filterStatus == 'all',
                            onSelected: (_) =>
                                setState(() => _filterStatus = 'all'),
                          ),
                        ),
                        for (final s in _statuses)
                          Padding(
                            padding: const EdgeInsets.only(left: AppSpacing.xs),
                            child: FilterChip(
                              label: Text(_translateStatus(s)),
                              selected: _filterStatus == s,
                              onSelected: (_) =>
                                  setState(() => _filterStatus = s),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.sm),

            // ── List ──────────────────────────────────────────
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  await ref.read(adminOrdersProvider.notifier).loadOrders();
                },
                child: ordersState.when(
                  loading: () => const Center(
                    child: CircularProgressIndicator.adaptive(),
                  ),
                  error: (_, __) => Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline,
                            color: AppColors.error, size: 48),
                        const SizedBox(height: AppSpacing.md),
                        const Text('خطأ في التحميل'),
                        ElevatedButton(
                          onPressed: () => ref
                              .read(adminOrdersProvider.notifier)
                              .loadOrders(),
                          child: const Text('إعادة المحاولة'),
                        ),
                      ],
                    ),
                  ),
                  data: (orders) {
                    var filtered = orders.where((o) {
                      final q = _searchQuery.toLowerCase();
                      final matchSearch = q.isEmpty ||
                          (o.orderNumber?.toLowerCase().contains(q) ?? false) ||
                          o.id.toLowerCase().contains(q) ||
                          (o.customerName?.toLowerCase().contains(q) ?? false);

                      final matchFilter =
                          _filterStatus == 'all' || o.status == _filterStatus;

                      return matchSearch && matchFilter;
                    }).toList();

                    if (filtered.isEmpty) {
                      return const Center(child: Text('لا توجد طلبات'));
                    }

                    return ListView.separated(
                      padding: EdgeInsets.all(padding),
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(height: AppSpacing.sm),
                      itemBuilder: (context, idx) {
                        final o = filtered[idx];
                        return _OrderTile(
                          order: o,
                          isDark: isDark,
                          statuses: _statuses,
                          translateStatus: _translateStatus,
                          onStatusChange: (newStatus) {
                            ref
                                .read(adminOrdersProvider.notifier)
                                .updateStatus(o.id, newStatus);
                          },
                        );
                      },
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OrderTile extends StatelessWidget {
  final OrderModel order;
  final bool isDark;
  final List<String> statuses;
  final String Function(String) translateStatus;
  final void Function(String) onStatusChange;

  const _OrderTile({
    required this.order,
    required this.isDark,
    required this.statuses,
    required this.translateStatus,
    required this.onStatusChange,
  });

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return AppColors.warning;
      case 'accepted':
        return AppColors.success;
      case 'rejected':
        return AppColors.error;
      case 'processing':
        return AppColors.info;
      case 'shipped':
        return AppColors.primary;
      case 'delivered':
        return AppColors.success;
      case 'cancelled':
        return AppColors.error;
      default:
        return AppColors.grey500;
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor(order.status);
    final isCancelled = order.status == 'cancelled' || order.status == 'rejected';
    final isDelivered = order.status == 'delivered';

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
          color: isDark ? AppColors.darkDivider : AppColors.lightDivider,
        ),
      ),
      child: ExpansionTile(
        title: Row(
          children: [
            Expanded(
              child: Text(
                order.orderNumber ?? order.id.substring(0, 8).toUpperCase(),
                style: AppTextStyles.titleMedium.copyWith(
                  fontWeight: FontWeight.bold,
                  decoration: isCancelled ? TextDecoration.lineThrough : null,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              ),
              child: Text(
                translateStatus(order.status),
                style: AppTextStyles.labelSmall.copyWith(color: statusColor),
              ),
            ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: AppSpacing.xs),
          child: Text(
            '${order.customerName ?? 'عميل'} • ${order.total.toStringAsFixed(0)} ج.م',
            style: AppTextStyles.bodySmall,
          ),
        ),
        children: [
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Info Grid
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _InfoRow(Icons.phone_rounded, order.customerPhone ?? 'غير محدد'),
                          const SizedBox(height: AppSpacing.xs),
                          _InfoRow(Icons.location_on_rounded, order.address ?? 'غير محدد'),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _InfoRow(Icons.payment_rounded,
                              order.paymentMethod ?? 'غير محدد'),
                          const SizedBox(height: AppSpacing.xs),
                          _InfoRow(Icons.date_range_rounded,
                              order.createdAt?.toString().split(' ')[0] ?? 'غير محدد'),
                        ],
                      ),
                    ),
                  ],
                ),
                if (order.notes != null && order.notes!.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.md),
                  Text('ملاحظات:',
                      style: AppTextStyles.labelSmall
                          .copyWith(color: AppColors.grey500)),
                  Text(order.notes!, style: AppTextStyles.bodySmall),
                ],
                const SizedBox(height: AppSpacing.md),

                // Accept / Reject Quick Action Buttons for pending orders
                if (order.status == 'pending') ...[
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.success,
                            foregroundColor: Colors.white,
                          ),
                          onPressed: () => onStatusChange('accepted'),
                          icon: const Icon(Icons.check_circle_outline, size: 18),
                          label: const Text('قبول الطلب'),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.error,
                            side: const BorderSide(color: AppColors.error),
                          ),
                          onPressed: () => onStatusChange('rejected'),
                          icon: const Icon(Icons.cancel_outlined, size: 18),
                          label: const Text('رفض الطلب'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],

                // Order Actions Dropdown
                Container(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    border: Border.all(
                      color: statusColor.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.edit_note_rounded,
                          size: 20, color: AppColors.grey500),
                      const SizedBox(width: AppSpacing.sm),
                      Text('تحديث الحالة:',
                          style: AppTextStyles.labelMedium),
                      const Spacer(),
                      DropdownButton<String>(
                        value: statuses.contains(order.status)
                            ? order.status
                            : 'pending',
                        underline: const SizedBox.shrink(),
                        isDense: true,
                        style: AppTextStyles.labelMedium
                            .copyWith(color: statusColor),
                        items: statuses.map((s) {
                          return DropdownMenuItem(
                            value: s,
                            child: Text(translateStatus(s)),
                          );
                        }).toList(),
                        onChanged: isDelivered
                            ? null // Prevent changing if already delivered
                            : (newStatus) {
                                if (newStatus != null) {
                                  onStatusChange(newStatus);
                                }
                              },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoRow(this.icon, this.text);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: AppColors.grey500),
        const SizedBox(width: AppSpacing.xs),
        Expanded(
          child: Text(
            text,
            style: AppTextStyles.bodySmall,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
