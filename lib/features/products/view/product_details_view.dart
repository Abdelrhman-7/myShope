import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/config/supabase_config.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/app_providers.dart';
import '../../../core/utils/responsive.dart';
import '../../cart/controller/cart_controller.dart';
import '../../favorites/controller/favorites_controller.dart';
import '../models/product_model.dart';
import '../models/product_image_model.dart';

final productDetailsFutureProvider =
    FutureProvider.family<ProductModel?, String>((ref, productId) async {
  final response = await supabase
      .from('products')
      .select()
      .eq('id', productId)
      .maybeSingle();

  if (response == null) return null;
  return ProductModel.fromJson(response);
});

final productImagesFutureProvider =
    FutureProvider.family<List<ProductImageModel>, String>(
        (ref, productId) async {
  final response = await supabase
      .from('product_images')
      .select()
      .eq('product_id', productId)
      .order('sort_order', ascending: true);

  return (response as List)
      .map((json) => ProductImageModel.fromJson(json as Map<String, dynamic>))
      .toList();
});

class ProductDetailsView extends ConsumerStatefulWidget {
  final String productId;

  const ProductDetailsView({
    super.key,
    required this.productId,
  });

  @override
  ConsumerState<ProductDetailsView> createState() => _ProductDetailsViewState();
}

class _ProductDetailsViewState extends ConsumerState<ProductDetailsView> {
  int _quantity = 1;
  int _selectedImageIndex = 0;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final locale = ref.watch(localeProvider);
    final isArabic = locale.languageCode == 'ar';

    final productAsync =
        ref.watch(productDetailsFutureProvider(widget.productId));
    final imagesAsync =
        ref.watch(productImagesFutureProvider(widget.productId));

    final favorites = ref.watch(favoritesProvider);
    final isFav = favorites.maybeWhen(
      data: (list) => list.any((f) => f.productId == widget.productId),
      orElse: () => false,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.translate('products.details')),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(
              isFav ? Icons.favorite : Icons.favorite_border,
              color: isFav ? AppColors.favorite : null,
            ),
            onPressed: () {
              ref
                  .read(favoritesProvider.notifier)
                  .toggleFavorite(widget.productId);
            },
          ),
        ],
      ),
      body: productAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator.adaptive(),
        ),
        error: (err, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline_rounded,
                color: AppColors.error,
                size: 48,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(loc.translate('common.error'), style: AppTextStyles.bodyLarge),
              const SizedBox(height: AppSpacing.sm),
              ElevatedButton(
                onPressed: () => ref
                    .invalidate(productDetailsFutureProvider(widget.productId)),
                child: Text(loc.translate('common.retry')),
              ),
            ],
          ),
        ),
        data: (product) {
          if (product == null) {
            return Center(
              child: Text(
                loc.translate('common.no_results'),
                style: AppTextStyles.bodyLarge,
              ),
            );
          }

          final name = isArabic ? product.nameAr : product.nameEn;
          final description =
              isArabic ? product.descriptionAr : product.descriptionEn;

          // Combine main image with additional images
          final allImages = <String>[];
          if (product.imageUrl != null && product.imageUrl!.isNotEmpty) {
            allImages.add(product.imageUrl!);
          }
          final extraImages = imagesAsync.value?.map((e) => e.imageUrl) ?? [];
          for (final img in extraImages) {
            if (!allImages.contains(img)) {
              allImages.add(img);
            }
          }

          final padding = Responsive.getHorizontalPadding(context);

          return Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: padding),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: AppSpacing.md),

                        // ─── Image Gallery ─────────────────────────
                        Center(
                          child: Container(
                            height: 300,
                            width: double.infinity,
                            constraints: const BoxConstraints(maxWidth: 500),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? AppColors.darkSurfaceVariant
                                  : AppColors.lightSurfaceVariant,
                              borderRadius:
                                  BorderRadius.circular(AppSpacing.radiusLg),
                              border: Border.all(
                                color: isDark
                                    ? AppColors.darkDivider
                                    : AppColors.lightDivider,
                              ),
                            ),
                            child: ClipRRect(
                              borderRadius:
                                  BorderRadius.circular(AppSpacing.radiusLg),
                              child: allImages.isNotEmpty
                                  ? Image.network(
                                      allImages[
                                          _selectedImageIndex.clamp(
                                              0, allImages.length - 1)],
                                      fit: BoxFit.contain,
                                      errorBuilder: (_, __, ___) =>
                                          const Center(
                                        child: Icon(
                                          Icons.handyman_outlined,
                                          size: 80,
                                          color: AppColors.primaryLight,
                                        ),
                                      ),
                                    )
                                  : const Center(
                                      child: Icon(
                                        Icons.handyman_outlined,
                                        size: 80,
                                        color: AppColors.primaryLight,
                                      ),
                                    ),
                            ),
                          ),
                        ),

                        // Image Thumbnails if more than 1 image
                        if (allImages.length > 1) ...[
                          const SizedBox(height: AppSpacing.md),
                          SizedBox(
                            height: 60,
                            child: Center(
                              child: ListView.separated(
                                shrinkWrap: true,
                                scrollDirection: Axis.horizontal,
                                itemCount: allImages.length,
                                separatorBuilder: (_, __) =>
                                    const SizedBox(width: AppSpacing.sm),
                                itemBuilder: (context, idx) {
                                  final isSelected =
                                      _selectedImageIndex == idx;
                                  return GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        _selectedImageIndex = idx;
                                      });
                                    },
                                    child: Container(
                                      width: 60,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(
                                            AppSpacing.radiusSm),
                                        border: Border.all(
                                          color: isSelected
                                              ? AppColors.primary
                                              : (isDark
                                                  ? AppColors.darkDivider
                                                  : AppColors.lightDivider),
                                          width: isSelected ? 2 : 1,
                                        ),
                                      ),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(
                                            AppSpacing.radiusSm - 1),
                                        child: Image.network(
                                          allImages[idx],
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                        ],

                        const SizedBox(height: AppSpacing.lg),

                        // ─── Title & Stock Status ───────────────────
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                name,
                                style: AppTextStyles.headlineSmall.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: isDark
                                      ? AppColors.darkTextPrimary
                                      : AppColors.lightTextPrimary,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.sm,
                                vertical: AppSpacing.xs,
                              ),
                              decoration: BoxDecoration(
                                color: product.inStock
                                    ? AppColors.inStock.withValues(alpha: 0.12)
                                    : AppColors.outOfStock.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(
                                    AppSpacing.radiusSm),
                              ),
                              child: Text(
                                product.inStock
                                    ? loc.translate('products.in_stock')
                                    : loc.translate('products.out_of_stock'),
                                style: AppTextStyles.labelMedium.copyWith(
                                  color: product.inStock
                                      ? AppColors.inStock
                                      : AppColors.outOfStock,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),

                        // SKU if available
                        if (product.sku != null && product.sku!.isNotEmpty) ...[
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            '${loc.translate('products.sku')}: ${product.sku}',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: isDark
                                  ? AppColors.darkTextSecondary
                                  : AppColors.lightTextSecondary,
                            ),
                          ),
                        ],

                        const SizedBox(height: AppSpacing.md),

                        // ─── Price Section ──────────────────────────
                        Row(
                          children: [
                            Text(
                              '${product.price.toStringAsFixed(0)} ${loc.translate('common.currency')}',
                              style: AppTextStyles.headlineMedium.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (product.hasDiscount) ...[
                              const SizedBox(width: AppSpacing.md),
                              Text(
                                '${product.oldPrice!.toStringAsFixed(0)} ${loc.translate('common.currency')}',
                                style: AppTextStyles.titleMedium.copyWith(
                                  color: AppColors.grey500,
                                  decoration: TextDecoration.lineThrough,
                                ),
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.sm,
                                  vertical: AppSpacing.xs,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.discount,
                                  borderRadius: BorderRadius.circular(
                                      AppSpacing.radiusSm),
                                ),
                                child: Text(
                                  '-${product.discountPercentage}%',
                                  style: AppTextStyles.labelSmall.copyWith(
                                    color: AppColors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),

                        const Divider(height: AppSpacing.xxl),

                        // ─── Description ───────────────────────────
                        Text(
                          loc.translate('products.description'),
                          style: AppTextStyles.titleMedium.copyWith(
                            fontWeight: FontWeight.bold,
                            color: isDark
                                ? AppColors.darkTextPrimary
                                : AppColors.lightTextPrimary,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          description != null && description.isNotEmpty
                              ? description
                              : loc.translate('common.no_data'),
                          style: AppTextStyles.bodyLarge.copyWith(
                            color: isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.lightTextSecondary,
                            height: 1.6,
                          ),
                        ),

                        const SizedBox(height: AppSpacing.xxxl),
                      ],
                    ),
                  ),
                ),
              ),

              // ─── Bottom Sticky Action Bar ────────────────────────
              Container(
                padding: EdgeInsets.all(padding),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkCard : AppColors.lightCard,
                  border: Border(
                    top: BorderSide(
                      color: isDark
                          ? AppColors.darkDivider
                          : AppColors.lightDivider,
                    ),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 10,
                      offset: const Offset(0, -3),
                    ),
                  ],
                ),
                child: SafeArea(
                  child: Row(
                    children: [
                      // Quantity Selector
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: isDark
                                ? AppColors.darkDivider
                                : AppColors.lightDivider,
                          ),
                          borderRadius:
                              BorderRadius.circular(AppSpacing.radiusMd),
                        ),
                        child: Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove, size: 18),
                              onPressed: _quantity > 1
                                  ? () => setState(() => _quantity--)
                                  : null,
                            ),
                            Text(
                              '$_quantity',
                              style: AppTextStyles.titleMedium.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.add, size: 18),
                              onPressed: product.inStock &&
                                      _quantity < product.stockQuantity
                                  ? () => setState(() => _quantity++)
                                  : null,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),

                      // Add to Cart Button
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: AppColors.white,
                            padding: const EdgeInsets.symmetric(
                              vertical: AppSpacing.md,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(AppSpacing.radiusMd),
                            ),
                          ),
                          onPressed: product.inStock
                              ? () {
                                  ref.read(cartProvider.notifier).addToCart(
                                        product.id,
                                        quantity: _quantity,
                                      );
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        loc.translate('products.added_to_cart'),
                                      ),
                                      backgroundColor: AppColors.success,
                                    ),
                                  );
                                }
                              : null,
                          icon: const Icon(Icons.add_shopping_cart),
                          label: Text(
                            loc.translate('products.add_to_cart'),
                            style: AppTextStyles.labelLarge.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

