import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/responsive.dart';
import '../controller/admin_controller.dart';

class AdminProductsView extends ConsumerStatefulWidget {
  const AdminProductsView({super.key});

  @override
  ConsumerState<AdminProductsView> createState() => _AdminProductsViewState();
}

class _AdminProductsViewState extends ConsumerState<AdminProductsView> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(adminProductsProvider.notifier).loadProducts();
    });
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final productsState = ref.watch(adminProductsProvider);
    final padding = Responsive.getHorizontalPadding(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.translate('admin.products')),
        centerTitle: true,
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            await ref.read(adminProductsProvider.notifier).loadProducts();
          },
          child: productsState.when(
            loading: () => const Center(
              child: CircularProgressIndicator.adaptive(),
            ),
            error: (err, _) => Center(
              child: Text(loc.translate('common.error')),
            ),
            data: (products) {
              if (products.isEmpty) {
                return Center(child: Text(loc.translate('common.no_data')));
              }

              return ListView.separated(
                padding: EdgeInsets.all(padding),
                itemCount: products.length,
                separatorBuilder: (_, __) =>
                    const SizedBox(height: AppSpacing.sm),
                itemBuilder: (context, idx) {
                  final p = products[idx];
                  return Container(
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
                    child: ListTile(
                      leading: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius:
                              BorderRadius.circular(AppSpacing.radiusSm),
                        ),
                        child: p.imageUrl != null && p.imageUrl!.isNotEmpty
                            ? ClipRRect(
                                borderRadius:
                                    BorderRadius.circular(AppSpacing.radiusSm),
                                child: Image.network(
                                  p.imageUrl!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => const Icon(
                                      Icons.handyman_outlined,
                                      color: AppColors.primary),
                                ),
                              )
                            : const Icon(Icons.handyman_outlined,
                                color: AppColors.primary),
                      ),
                      title: Text(
                        p.nameAr,
                        style: AppTextStyles.titleSmall.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Text(
                        '${p.price.toStringAsFixed(0)} ${loc.translate('common.currency')} • ${loc.translate('products.in_stock')}: ${p.stockQuantity}',
                        style: AppTextStyles.bodySmall,
                      ),
                      trailing: Switch.adaptive(
                        value: p.isActive,
                        activeColor: AppColors.success,
                        onChanged: (val) {
                          ref
                              .read(adminProductsProvider.notifier)
                              .toggleActive(p.id, val);
                        },
                      ),
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

