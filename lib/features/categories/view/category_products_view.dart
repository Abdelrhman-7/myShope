import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/config/supabase_config.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/responsive.dart';
import '../../products/models/product_model.dart';
import '../../products/widgets/product_card.dart';

final categoryProductsFutureProvider =
    FutureProvider.family<List<ProductModel>, String>((ref, categoryId) async {
  final response = await supabase
      .from('products')
      .select()
      .eq('category_id', categoryId)
      .eq('is_active', true)
      .order('created_at', ascending: false);

  return (response as List)
      .map((json) => ProductModel.fromJson(json as Map<String, dynamic>))
      .toList();
});

class CategoryProductsView extends ConsumerWidget {
  final String categoryId;

  const CategoryProductsView({
    super.key,
    required this.categoryId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final productsAsync = ref.watch(categoryProductsFutureProvider(categoryId));
    final padding = Responsive.getHorizontalPadding(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.translate('products.title')),
        centerTitle: true,
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(categoryProductsFutureProvider(categoryId));
          },
          child: productsAsync.when(
            loading: () => const Center(
              child: CircularProgressIndicator.adaptive(),
            ),
            error: (error, _) => Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline_rounded,
                    color: AppColors.error,
                    size: 48,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    loc.translate('common.error'),
                    style: AppTextStyles.bodyLarge,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  ElevatedButton(
                    onPressed: () => ref
                        .invalidate(categoryProductsFutureProvider(categoryId)),
                    child: Text(loc.translate('common.retry')),
                  ),
                ],
              ),
            ),
            data: (products) {
              if (products.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.inventory_2_outlined,
                        size: 64,
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.lightTextSecondary,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        loc.translate('common.no_results'),
                        style: AppTextStyles.bodyLarge.copyWith(
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.lightTextSecondary,
                        ),
                      ),
                    ],
                  ),
                );
              }

              final columns = Responsive.getGridColumns(context);
              final aspectRatio = Responsive.getProductAspectRatio(context);

              return GridView.builder(
                padding: EdgeInsets.all(padding),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: columns,
                  crossAxisSpacing: AppSpacing.md,
                  mainAxisSpacing: AppSpacing.md,
                  childAspectRatio: aspectRatio,
                ),
                itemCount: products.length,
                itemBuilder: (context, index) {
                  return ProductCard(
                    product: products[index],
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
