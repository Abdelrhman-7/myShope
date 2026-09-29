import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/responsive.dart';
import '../../../core/utils/app_providers.dart';
import '../widgets/home_header.dart';
import '../widgets/home_search_bar.dart';
import '../widgets/categories_section.dart';
import '../widgets/featured_products_section.dart';
import '../widgets/offers_section.dart';
import '../widgets/points_card.dart';
import '../controller/home_controller.dart';

/// Home page view
class HomeView extends ConsumerStatefulWidget {
  const HomeView({super.key});

  @override
  ConsumerState<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends ConsumerState<HomeView> {
  @override
  void initState() {
    super.initState();
    // Load home data
    Future.microtask(() {
      ref.read(homeCategoriesProvider.notifier).loadCategories();
      ref.read(homeFeaturedProductsProvider.notifier).loadFeaturedProducts();
      ref.read(homeOffersProvider.notifier).loadOffers();
    });
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(profileProvider);
    final selectedRole = ref.watch(userRoleProvider);
    final isMerchantRole = selectedRole == 'merchant' || (profile.value?.isMerchant ?? false);
    final padding = Responsive.getHorizontalPadding(context);

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            await ref
                .read(homeCategoriesProvider.notifier)
                .loadCategories();
            await ref
                .read(homeFeaturedProductsProvider.notifier)
                .loadFeaturedProducts();
            await ref.read(homeOffersProvider.notifier).loadOffers();
          },
          child: CustomScrollView(
            slivers: [
              // ─── Header ──────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    padding,
                    AppSpacing.lg,
                    padding,
                    0,
                  ),
                  child: HomeHeader(
                    userName: profile.value?.fullName,
                  ),
                ),
              ),

              // ─── Merchant Welcome Banner ─────────────────
              if (isMerchantRole)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      padding,
                      AppSpacing.sm,
                      padding,
                      0,
                    ),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.sm,
                      ),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppColors.secondary, AppColors.secondaryDark],
                        ),
                        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.secondary.withValues(alpha: 0.25),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.storefront_rounded,
                            color: AppColors.white,
                            size: 24,
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'أهلاً بك في حساب التاجر 🏪',
                                  style: AppTextStyles.bodyMedium.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.white,
                                  ),
                                ),
                                Text(
                                  'تتمتع بجميع وظائف العميل العادي + مميزات وخصومات الجملة 15%',
                                  style: AppTextStyles.bodySmall.copyWith(
                                    color: AppColors.white.withValues(alpha: 0.95),
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

              // ─── Search Bar ──────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: padding,
                    vertical: AppSpacing.lg,
                  ),
                  child: const HomeSearchBar(),
                ),
              ),

              // ─── Points Card ─────────────────────────────
              if (profile.value != null)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: padding,
                    ),
                    child: const PointsCard(),
                  ),
                ),

              // ─── Categories ──────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.only(top: AppSpacing.xxl),
                  child: CategoriesSection(horizontalPadding: padding),
                ),
              ),

              // ─── Featured Products ───────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.only(top: AppSpacing.xxl),
                  child: FeaturedProductsSection(
                      horizontalPadding: padding),
                ),
              ),

              // ─── Offers ──────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.only(
                    top: AppSpacing.xxl,
                    bottom: AppSpacing.xxxl,
                  ),
                  child: OffersSection(horizontalPadding: padding),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

