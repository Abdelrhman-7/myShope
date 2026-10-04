import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/responsive.dart';
import '../../products/models/product_model.dart';
import '../controller/admin_controller.dart';

class AdminProductsView extends ConsumerStatefulWidget {
  const AdminProductsView({super.key});

  @override
  ConsumerState<AdminProductsView> createState() => _AdminProductsViewState();
}

class _AdminProductsViewState extends ConsumerState<AdminProductsView> {
  String _searchQuery = '';
  String _filterActive = 'all';

  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(adminProductsProvider.notifier).loadProducts();
      ref.read(adminCategoriesProvider.notifier).loadCategories();
      ref.read(adminMerchantsProvider.notifier).loadMerchants();
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _showProductDialog({ProductModel? existing}) async {
    final categoriesAsync = ref.read(adminCategoriesProvider);
    final merchantsAsync = ref.read(adminMerchantsProvider);

    if (categoriesAsync.isLoading || merchantsAsync.isLoading) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('جاري تحميل البيانات...')),
      );
      return;
    }

    if (categoriesAsync.hasError || merchantsAsync.hasError) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('خطأ في تحميل البيانات')),
      );
      return;
    }

    final categories = categoriesAsync.value ?? [];
    final merchants = merchantsAsync.value ?? [];

    if (categories.isEmpty || merchants.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يجب إضافة تصنيفات وتجار أولاً')),
      );
      return;
    }

    final formKey = GlobalKey<FormState>();
    final nameArCtrl = TextEditingController(text: existing?.nameAr ?? '');
    final nameEnCtrl = TextEditingController(text: existing?.nameEn ?? '');
    final priceCtrl = TextEditingController(
        text: existing?.price.toStringAsFixed(2) ?? '');
    final oldPriceCtrl = TextEditingController(
        text: existing?.oldPrice?.toStringAsFixed(2) ?? '');
    final stockCtrl = TextEditingController(
        text: existing?.stockQuantity.toString() ?? '');
    final minStockCtrl = TextEditingController(
        text: existing?.minStock.toString() ?? '');
    final skuCtrl = TextEditingController(text: existing?.sku ?? '');
    final imageCtrl = TextEditingController(text: existing?.imageUrl ?? '');

    int selectedCategory = existing?.categoryId ?? categories.first.id;
    String selectedMerchant = existing?.merchantId ?? merchants.first.id;
    bool isFeatured = existing?.isFeatured ?? false;

    await showDialog(
      context: context,
      builder: (ctx) => Dialog(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    existing != null ? 'تعديل منتج' : 'إضافة منتج',
                    style: AppTextStyles.titleLarge
                        .copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  TextFormField(
                    controller: nameArCtrl,
                    decoration: const InputDecoration(
                      labelText: 'اسم المنتج (عربي) *',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) => v == null || v.isEmpty ? 'مطلوب' : null,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextFormField(
                    controller: nameEnCtrl,
                    decoration: const InputDecoration(
                      labelText: 'اسم المنتج (إنجليزي)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: priceCtrl,
                          decoration: const InputDecoration(
                            labelText: 'السعر *',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                          validator: (v) =>
                              v == null || v.isEmpty ? 'مطلوب' : null,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: TextFormField(
                          controller: oldPriceCtrl,
                          decoration: const InputDecoration(
                            labelText: 'السعر القديم',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: stockCtrl,
                          decoration: const InputDecoration(
                            labelText: 'المخزون *',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                          validator: (v) =>
                              v == null || v.isEmpty ? 'مطلوب' : null,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: TextFormField(
                          controller: minStockCtrl,
                          decoration: const InputDecoration(
                            labelText: 'الحد الأدنى',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextFormField(
                    controller: skuCtrl,
                    decoration: const InputDecoration(
                      labelText: 'SKU (الباركود)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextFormField(
                    controller: imageCtrl,
                    decoration: const InputDecoration(
                      labelText: 'رابط الصورة الأساسية',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  DropdownButtonFormField<int>(
                    value: selectedCategory,
                    decoration: const InputDecoration(
                      labelText: 'التصنيف *',
                      border: OutlineInputBorder(),
                    ),
                    items: categories
                        .map((c) => DropdownMenuItem(
                              value: c.id,
                              child: Text(c.nameAr),
                            ))
                        .toList(),
                    onChanged: (v) => selectedCategory = v!,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  DropdownButtonFormField<String>(
                    value: selectedMerchant,
                    decoration: const InputDecoration(
                      labelText: 'التاجر *',
                      border: OutlineInputBorder(),
                    ),
                    items: merchants
                        .map((m) => DropdownMenuItem(
                              value: m.id,
                              child: Text(m.fullName ?? m.email ?? m.id),
                            ))
                        .toList(),
                    onChanged: (v) => selectedMerchant = v!,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  StatefulBuilder(
                    builder: (context, setStateSB) {
                      return SwitchListTile.adaptive(
                        title: const Text('منتج مميز (Featured)'),
                        value: isFeatured,
                        onChanged: (v) => setStateSB(() => isFeatured = v),
                      );
                    },
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('إلغاء'),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      ElevatedButton(
                        onPressed: () async {
                          if (!formKey.currentState!.validate()) return;
                          Navigator.pop(ctx);

                          final data = {
                            'name_ar': nameArCtrl.text.trim(),
                            'name_en': nameEnCtrl.text.trim(),
                            'price': double.tryParse(priceCtrl.text) ?? 0,
                            'old_price': double.tryParse(oldPriceCtrl.text),
                            'stock_quantity':
                                int.tryParse(stockCtrl.text) ?? 0,
                            'min_stock': int.tryParse(minStockCtrl.text) ?? 5,
                            'sku': skuCtrl.text.trim(),
                            'image_url': imageCtrl.text.trim(),
                            'category_id': selectedCategory,
                            'merchant_id': selectedMerchant,
                            'is_featured': isFeatured,
                            'is_active': existing?.isActive ?? true,
                            if (existing == null)
                              'created_at': DateTime.now().toIso8601String(),
                          };

                          String? errorMsg;
                          if (existing != null) {
                            errorMsg = await ref
                                .read(adminProductsProvider.notifier)
                                .updateProduct(existing.id, data);
                          } else {
                            errorMsg = await ref
                                .read(adminProductsProvider.notifier)
                                .createProduct(data);
                          }

                          if (errorMsg != null && mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  content: Text(existing != null
                                      ? 'فشل التعديل: $errorMsg'
                                      : 'فشل الإضافة: $errorMsg')),
                            );
                          }
                        },
                        child: Text(
                            existing != null ? 'حفظ التعديلات' : 'إضافة'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _deleteDialog(int id, String name) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تأكيد الحذف'),
        content: Text('هل أنت متأكد من حذف المنتج "$name"؟\n\n'
            'سيتم حذف هذا المنتج من سلات التسوق والمفضلة للعملاء، لكن سيظل موجوداً في الطلبات القديمة للمحافظة على الفواتير.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('حذف', style: TextStyle(color: AppColors.white)),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    final errorMsg = await ref.read(adminProductsProvider.notifier).deleteProduct(id);
    if (errorMsg != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('فشل الحذف: $errorMsg')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final productsState = ref.watch(adminProductsProvider);
    final padding = Responsive.getHorizontalPadding(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('المنتجات'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () =>
                ref.read(adminProductsProvider.notifier).loadProducts(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showProductDialog(),
        icon: const Icon(Icons.add_rounded),
        label: const Text('إضافة منتج'),
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
                      hintText: 'بحث بالاسم أو SKU...',
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
                        for (final f in ['all', 'active', 'inactive', 'low_stock'])
                          Padding(
                            padding: const EdgeInsets.only(left: AppSpacing.xs),
                            child: FilterChip(
                              label: Text(f == 'all'
                                  ? 'الكل'
                                  : f == 'active'
                                      ? 'نشط'
                                      : f == 'inactive'
                                          ? 'غير نشط'
                                          : 'مخزون منخفض'),
                              selected: _filterActive == f,
                              selectedColor: AppColors.primary.withValues(alpha: 0.2),
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
            const SizedBox(height: AppSpacing.sm),

            // ── List ──────────────────────────────────────────
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  await ref.read(adminProductsProvider.notifier).loadProducts();
                },
                child: productsState.when(
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
                              .read(adminProductsProvider.notifier)
                              .loadProducts(),
                          child: const Text('إعادة المحاولة'),
                        ),
                      ],
                    ),
                  ),
                  data: (products) {
                    var filtered = products.where((p) {
                      final q = _searchQuery.toLowerCase();
                      final matchSearch = q.isEmpty ||
                          p.nameAr.toLowerCase().contains(q) ||
                          p.nameEn.toLowerCase().contains(q) ||
                          (p.sku?.toLowerCase().contains(q) ?? false);

                      bool matchFilter = true;
                      if (_filterActive == 'active') matchFilter = p.isActive;
                      if (_filterActive == 'inactive') matchFilter = !p.isActive;
                      if (_filterActive == 'low_stock') {
                        matchFilter = p.stockQuantity <= p.minStock;
                      }

                      return matchSearch && matchFilter;
                    }).toList();

                    if (filtered.isEmpty) {
                      return const Center(child: Text('لا توجد منتجات'));
                    }

                    return ListView.separated(
                      padding: EdgeInsets.all(padding),
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(height: AppSpacing.sm),
                      itemBuilder: (context, idx) {
                        final p = filtered[idx];
                        return Container(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          decoration: BoxDecoration(
                            color:
                                isDark ? AppColors.darkCard : AppColors.lightCard,
                            borderRadius:
                                BorderRadius.circular(AppSpacing.radiusMd),
                            border: Border.all(
                              color: isDark
                                  ? AppColors.darkDivider
                                  : AppColors.lightDivider,
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 60,
                                height: 60,
                                decoration: BoxDecoration(
                                  color:
                                      AppColors.primary.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(
                                      AppSpacing.radiusSm),
                                ),
                                child: p.imageUrl != null &&
                                        p.imageUrl!.isNotEmpty
                                    ? ClipRRect(
                                        borderRadius: BorderRadius.circular(
                                            AppSpacing.radiusSm),
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
                              const SizedBox(width: AppSpacing.md),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            p.nameAr,
                                            style: AppTextStyles.titleSmall
                                                .copyWith(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        if (p.isFeatured)
                                          const Icon(Icons.star_rounded,
                                              color: AppColors.warning, size: 16),
                                      ],
                                    ),
                                    const SizedBox(height: AppSpacing.xs),
                                    Text(
                                      '${p.price.toStringAsFixed(0)} ج.م • المخزون: ${p.stockQuantity}',
                                      style: AppTextStyles.bodySmall.copyWith(
                                        color: p.stockQuantity <= p.minStock
                                            ? AppColors.error
                                            : null,
                                        fontWeight: p.stockQuantity <= p.minStock
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                      ),
                                    ),
                                    if (p.sku != null && p.sku!.isNotEmpty)
                                      Text(
                                        'SKU: ${p.sku}',
                                        style: AppTextStyles.bodySmall.copyWith(
                                            color: AppColors.grey500),
                                      ),
                                  ],
                                ),
                              ),
                              Column(
                                children: [
                                  Switch.adaptive(
                                    value: p.isActive,
                                    activeColor: AppColors.success,
                                    onChanged: (val) {
                                      ref
                                          .read(adminProductsProvider.notifier)
                                          .toggleActive(p.id, val);
                                    },
                                  ),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.edit_rounded,
                                            size: 20, color: AppColors.info),
                                        onPressed: () =>
                                            _showProductDialog(existing: p),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete_rounded,
                                            size: 20, color: AppColors.error),
                                        onPressed: () =>
                                            _deleteDialog(p.id, p.nameAr),
                                      ),
                                    ],
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
          ],
        ),
      ),
    );
  }
}
