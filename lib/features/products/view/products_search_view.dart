import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/config/supabase_config.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/responsive.dart';
import '../models/product_model.dart';
import '../widgets/product_card.dart';

class ProductsSearchView extends ConsumerStatefulWidget {
  const ProductsSearchView({super.key});

  @override
  ConsumerState<ProductsSearchView> createState() => _ProductsSearchViewState();
}

class _ProductsSearchViewState extends ConsumerState<ProductsSearchView> {
  final TextEditingController _searchController = TextEditingController();
  List<ProductModel> _allProducts = [];
  List<ProductModel> _filteredProducts = [];
  bool _isLoading = true;
  String _selectedFilter = 'all'; // all, in_stock, discount, price_asc, price_desc

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    setState(() => _isLoading = true);
    try {
      final response = await supabase
          .from('products')
          .select()
          .eq('is_active', true)
          .order('created_at', ascending: false);

      final list = (response as List)
          .map((json) => ProductModel.fromJson(json as Map<String, dynamic>))
          .toList();

      setState(() {
        _allProducts = list;
        _filterAndSort();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _filterAndSort() {
    final query = _searchController.text.trim().toLowerCase();
    var list = _allProducts.where((p) {
      final matchesQuery = query.isEmpty ||
          p.nameAr.toLowerCase().contains(query) ||
          p.nameEn.toLowerCase().contains(query) ||
          (p.sku != null && p.sku!.toLowerCase().contains(query));

      if (!matchesQuery) return false;

      if (_selectedFilter == 'in_stock') return p.inStock;
      if (_selectedFilter == 'discount') return p.hasDiscount;

      return true;
    }).toList();

    if (_selectedFilter == 'price_asc') {
      list.sort((a, b) => a.price.compareTo(b.price));
    } else if (_selectedFilter == 'price_desc') {
      list.sort((a, b) => b.price.compareTo(a.price));
    }

    setState(() {
      _filteredProducts = list;
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final padding = Responsive.getHorizontalPadding(context);

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          autofocus: true,
          decoration: InputDecoration(
            hintText: loc.translate('home.search_hint'),
            border: InputBorder.none,
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _searchController.clear();
                      _filterAndSort();
                    },
                  )
                : null,
          ),
          onChanged: (_) => _filterAndSort(),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // ─── Filter Chips ──────────────────────────────
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(
                horizontal: padding,
                vertical: AppSpacing.sm,
              ),
              child: Row(
                children: [
                  _buildFilterChip('all', loc.translate('common.all')),
                  const SizedBox(width: AppSpacing.sm),
                  _buildFilterChip(
                      'discount', loc.translate('home.offers')),
                  const SizedBox(width: AppSpacing.sm),
                  _buildFilterChip(
                      'in_stock', loc.translate('products.in_stock')),
                  const SizedBox(width: AppSpacing.sm),
                  _buildFilterChip(
                      'price_asc', '${loc.translate('products.price')} ↑'),
                  const SizedBox(width: AppSpacing.sm),
                  _buildFilterChip(
                      'price_desc', '${loc.translate('products.price')} ↓'),
                ],
              ),
            ),

            const Divider(height: 1),

            // ─── Results Grid ──────────────────────────────
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator.adaptive())
                  : _filteredProducts.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.search_off_rounded,
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
                        )
                      : GridView.builder(
                          padding: EdgeInsets.all(padding),
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: Responsive.getGridColumns(context),
                            crossAxisSpacing: AppSpacing.md,
                            mainAxisSpacing: AppSpacing.md,
                            childAspectRatio:
                                Responsive.getProductAspectRatio(context),
                          ),
                          itemCount: _filteredProducts.length,
                          itemBuilder: (context, index) {
                            return ProductCard(
                              product: _filteredProducts[index],
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String value, String label) {
    final isSelected = _selectedFilter == value;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: AppColors.primary,
      labelStyle: TextStyle(
        color: isSelected ? AppColors.white : null,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      onSelected: (selected) {
        if (selected) {
          setState(() {
            _selectedFilter = value;
            _filterAndSort();
          });
        }
      },
    );
  }
}

