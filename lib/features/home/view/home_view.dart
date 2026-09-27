import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
