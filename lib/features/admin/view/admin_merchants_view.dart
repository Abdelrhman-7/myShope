import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../controller/admin_controller.dart';

class AdminMerchantsView extends ConsumerStatefulWidget {
  const AdminMerchantsView({super.key});

  @override
  ConsumerState<AdminMerchantsView> createState() => _AdminMerchantsViewState();
}

class _AdminMerchantsViewState extends ConsumerState<AdminMerchantsView> {
  String _searchQuery = '';
  String _filterActive = 'all'; // all, active, inactive
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    Future.microtask(() =>
        ref.read(adminMerchantsProvider.notifier).loadMerchants());
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final merchantsState = ref.watch(adminMerchantsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('التجار'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () =>
                ref.read(adminMerchantsProvider.notifier).loadMerchants(),
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Search + Filter ────────────────────────────
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              children: [
                TextField(
                  controller: _searchCtrl,
                  decoration: InputDecoration(
                    hintText: 'بحث بالاسم أو البريد...',
                    prefixIcon: const Icon(Icons.search_rounded),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchCtrl.clear();
                              setState(() => _searchQuery = '');
                            })
                        : null,
                    border: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(AppSpacing.radiusMd),
                    ),
                  ),
                  onChanged: (v) => setState(() => _searchQuery = v.trim()),
                ),
                const SizedBox(height: AppSpacing.sm),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      for (final f in ['all', 'active', 'inactive'])
                        Padding(
                          padding: const EdgeInsets.only(left: AppSpacing.xs),
                          child: FilterChip(
                            label: Text(f == 'all'
                                ? 'الكل'
                                : f == 'active'
                                    ? 'نشط'
                                    : 'غير نشط'),
                            selected: _filterActive == f,
                            onSelected: (_) =>
                                setState(() => _filterActive = f),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── List ──────────────────────────────────────
          Expanded(
            child: merchantsState.when(
              loading: () => const Center(
                  child: CircularProgressIndicator.adaptive()),
              error: (err, _) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline,
                        color: AppColors.error, size: 48),
                    const SizedBox(height: AppSpacing.md),
                    Text('فشل التحميل: $err',
                        style: AppTextStyles.bodyMedium),
                    const SizedBox(height: AppSpacing.md),
                    ElevatedButton(
                      onPressed: () => ref
                          .read(adminMerchantsProvider.notifier)
                          .loadMerchants(),
                      child: const Text('إعادة المحاولة'),
                    ),
                  ],
                ),
              ),
              data: (merchants) {
                var filtered = merchants.where((m) {
                  final q = _searchQuery.toLowerCase();
                  final matchSearch = q.isEmpty ||
                      (m.fullName?.toLowerCase().contains(q) ?? false) ||
                      (m.email?.toLowerCase().contains(q) ?? false) ||
                      (m.phone?.contains(q) ?? false);

                  final matchFilter = _filterActive == 'all'
                      ? true
                      : _filterActive == 'active'
                          ? m.isActive
                          : !m.isActive;

                  return matchSearch && matchFilter;
                }).toList();

                if (filtered.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.storefront_outlined,
                            size: 64, color: AppColors.grey400),
                        const SizedBox(height: AppSpacing.md),
                        Text('لا يوجد تجار',
                            style: AppTextStyles.bodyLarge.copyWith(
                                color: AppColors.grey500)),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () => ref
                      .read(adminMerchantsProvider.notifier)
                      .loadMerchants(),
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: AppSpacing.sm),
                    itemBuilder: (_, i) {
                      final m = filtered[i];
                      return Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(
                              AppSpacing.radiusMd),
                          border: Border.all(
                            color: isDark
                                ? AppColors.darkDivider
                                : AppColors.lightDivider,
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(
                              AppSpacing.radiusMd - 1),
                          child: Material(
                            color: isDark
                                ? AppColors.darkCard
                                : AppColors.lightCard,
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor:
                                    AppColors.secondary.withValues(alpha: 0.15),
                                child: Text(
                                  (m.fullName?.isNotEmpty == true)
                                      ? m.fullName![0].toUpperCase()
                                      : '?',
                                  style: AppTextStyles.labelLarge.copyWith(
                                      color: AppColors.secondaryDark),
                                ),
                              ),
                              title: Text(m.fullName ?? 'بدون اسم',
                                  style: AppTextStyles.labelLarge),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (m.email != null)
                                    Text(m.email!,
                                        style: AppTextStyles.bodySmall),
                                  if (m.phone != null)
                                    Text(m.phone!,
                                        style: AppTextStyles.bodySmall),
                                ],
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: AppSpacing.sm,
                                        vertical: AppSpacing.xs),
                                    decoration: BoxDecoration(
                                      color: m.isActive
                                          ? AppColors.success.withValues(alpha: 0.1)
                                          : AppColors.error.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(
                                          AppSpacing.radiusSm),
                                    ),
                                    child: Text(
                                      m.isActive ? 'نشط' : 'غير نشط',
                                      style: AppTextStyles.labelSmall.copyWith(
                                        color: m.isActive
                                            ? AppColors.success
                                            : AppColors.error,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: AppSpacing.xs),
                                  Switch.adaptive(
                                    value: m.isActive,
                                    activeColor: AppColors.success,
                                    onChanged: (val) async {
                                      final ok = await ref
                                          .read(adminMerchantsProvider.notifier)
                                          .toggleActive(m.id, val);
                                      if (!ok && mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                              content: Text('فشل تحديث الحالة')),
                                        );
                                      }
                                    },
                                  ),
                                ],
                              ),
                              isThreeLine: true,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
