import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/supabase_config.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../controller/admin_controller.dart';

class AdminCategoriesView extends ConsumerStatefulWidget {
  const AdminCategoriesView({super.key});

  @override
  ConsumerState<AdminCategoriesView> createState() =>
      _AdminCategoriesViewState();
}

class _AdminCategoriesViewState extends ConsumerState<AdminCategoriesView> {
  String _searchQuery = '';
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    Future.microtask(
        () => ref.read(adminCategoriesProvider.notifier).loadCategories());
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _addCategoryDialog() async {
    final nameArCtrl = TextEditingController();
    final nameEnCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('إضافة تصنيف جديد'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameArCtrl,
                decoration: const InputDecoration(labelText: 'الاسم (عربي) *'),
                validator: (v) =>
                    v == null || v.isEmpty ? 'مطلوب' : null,
              ),
              const SizedBox(height: AppSpacing.sm),
              TextFormField(
                controller: nameEnCtrl,
                decoration:
                    const InputDecoration(labelText: 'الاسم (إنجليزي)'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              Navigator.pop(ctx);
              try {
                await supabase.from('categories').insert({
                  'name_ar': nameArCtrl.text.trim(),
                  'name_en': nameEnCtrl.text.trim(),
                  'is_active': true,
                  'sort_order': 0,
                });
                ref.read(adminCategoriesProvider.notifier).loadCategories();
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('خطأ: $e')),
                  );
                }
              }
            },
            child: const Text('إضافة'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteDialog(int id, String name) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تأكيد الحذف'),
        content: Text('هل أنت متأكد من حذف تصنيف "$name"؟'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('إلغاء')),
          ElevatedButton(
            style:
                ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(ctx, true),
            child:
                const Text('حذف', style: TextStyle(color: AppColors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final ok = await ref
          .read(adminCategoriesProvider.notifier)
          .deleteCategory(id);
      if (!ok && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text(
                  'فشل الحذف — قد يكون التصنيف مرتبط بمنتجات')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final state = ref.watch(adminCategoriesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('التصنيفات'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () =>
                ref.read(adminCategoriesProvider.notifier).loadCategories(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addCategoryDialog,
        child: const Icon(Icons.add_rounded),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'بحث بالاسم...',
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
                        BorderRadius.circular(AppSpacing.radiusMd)),
              ),
              onChanged: (v) => setState(() => _searchQuery = v.trim()),
            ),
          ),
          Expanded(
            child: state.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator.adaptive()),
              error: (err, _) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline,
                        color: AppColors.error, size: 48),
                    const SizedBox(height: AppSpacing.md),
                    Text('فشل التحميل: $err'),
                    const SizedBox(height: AppSpacing.md),
                    ElevatedButton(
                      onPressed: () => ref
                          .read(adminCategoriesProvider.notifier)
                          .loadCategories(),
                      child: const Text('إعادة المحاولة'),
                    ),
                  ],
                ),
              ),
              data: (cats) {
                final filtered = cats.where((c) {
                  final q = _searchQuery.toLowerCase();
                  return q.isEmpty ||
                      c.nameAr.toLowerCase().contains(q) ||
                      c.nameEn.toLowerCase().contains(q);
                }).toList();

                if (filtered.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.category_outlined,
                            size: 64, color: AppColors.grey400),
                        const SizedBox(height: AppSpacing.md),
                        Text('لا توجد تصنيفات',
                            style: AppTextStyles.bodyLarge
                                .copyWith(color: AppColors.grey500)),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () => ref
                      .read(adminCategoriesProvider.notifier)
                      .loadCategories(),
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: AppSpacing.sm),
                    itemBuilder: (_, i) {
                      final c = filtered[i];
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
                              leading: c.imageUrl != null
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(
                                          AppSpacing.radiusSm),
                                      child: Image.network(
                                        c.imageUrl!,
                                        width: 48,
                                        height: 48,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) => const Icon(
                                            Icons.category_rounded,
                                            color: AppColors.primary),
                                      ),
                                    )
                                  : const Icon(Icons.category_rounded,
                                      color: AppColors.primary),
                              title: Text(c.nameAr,
                                  style: AppTextStyles.labelLarge),
                              subtitle: Text(c.nameEn,
                                  style: AppTextStyles.bodySmall),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Switch.adaptive(
                                    value: c.isActive,
                                    activeColor: AppColors.success,
                                    onChanged: (val) {
                                      ref
                                          .read(adminCategoriesProvider.notifier)
                                          .toggleActive(c.id, val);
                                    },
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_rounded,
                                        color: AppColors.error, size: 20),
                                    onPressed: () =>
                                        _deleteDialog(c.id, c.nameAr),
                                  ),
                                ],
                              ),
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
