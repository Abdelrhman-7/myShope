import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/app_providers.dart';
import '../../products/widgets/product_card.dart';
import '../controller/home_controller.dart';

class FeaturedProductsSection extends ConsumerWidget {
  final double horizontalPadding;

  const FeaturedProductsSection({
    super.key,
    required this.horizontalPadding,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final locale = ref.watch(localeProvider);
    final isArabic = locale.languageCode == 'ar';
    final productsState = ref.watch(homeFeaturedProductsProvider);

    // Hide the entire section if no featured products exist
    final products = productsState.value;
    if (productsState is AsyncData && (products == null || products.isEmpty)) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header
        Padding(
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.star_rounded,
                    color: AppColors.secondary,
                    size: 24,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    loc.translate('home.featured'),
                    style: AppTextStyles.titleLarge.copyWith(
                      fontWeight: FontWeight.bold,
                      color: isDark
                          ? AppColors.darkTextPrimary
                          : AppColors.lightTextPrimary,
                    ),
                  ),
                ],
              ),
              TextButton(
                onPressed: () => context.push('/search'),
                child: Row(
                  children: [
                    Text(
                      loc.translate('common.see_all'),
                      style: AppTextStyles.labelMedium.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Icon(
                      isArabic
                          ? Icons.arrow_back_ios_new
                          : Icons.arrow_forward_ios,
                      size: 12,
                      color: AppColors.primary,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.sm),

        // Products Horizontal Scroll
        SizedBox(
          height: 250,
          child: productsState.when(
            loading: () => const Center(
              child: CircularProgressIndicator.adaptive(),
            ),
            error: (error, _) => const SizedBox.shrink(),
            data: (products) {
              // Already handled above, but guard here too
              if (products.isEmpty) return const SizedBox.shrink();

              return ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                itemCount: products.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(width: AppSpacing.md),
                itemBuilder: (context, index) {
                  return ProductCard(
                    product: products[index],
                    width: 170,
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

