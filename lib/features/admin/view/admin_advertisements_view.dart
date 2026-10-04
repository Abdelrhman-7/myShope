import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/app_providers.dart';
import '../controller/admin_controller.dart';

class AdminAdvertisementsView extends ConsumerStatefulWidget {
  const AdminAdvertisementsView({super.key});

  @override
  ConsumerState<AdminAdvertisementsView> createState() =>
      _AdminAdvertisementsViewState();
}

class _AdminAdvertisementsViewState
    extends ConsumerState<AdminAdvertisementsView> {
  String _searchQuery = '';
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(adminAdsProvider.notifier).loadAds());
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _showAdDialog({AdvertisementModel? existing}) async {
    final titleArCtrl =
        TextEditingController(text: existing?.titleAr ?? '');
    final titleEnCtrl =
        TextEditingController(text: existing?.titleEn ?? '');
    final descArCtrl =
        TextEditingController(text: existing?.descriptionAr ?? '');
    final imageUrlCtrl =
        TextEditingController(text: existing?.imageUrl ?? '');
    final targetUrlCtrl =
        TextEditingController(text: existing?.targetUrl ?? '');
    final formKey = GlobalKey<FormState>();

    // Get current admin id
    final profile = ref.read(profileProvider).value;

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
                    existing != null ? 'تعديل الإعلان' : 'إضافة إعلان',
                    style: AppTextStyles.titleLarge
                        .copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  TextFormField(
                    controller: titleArCtrl,
                    decoration: const InputDecoration(
                      labelText: 'العنوان (عربي) *',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) =>
                        v == null || v.isEmpty ? 'مطلوب' : null,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextFormField(
                    controller: titleEnCtrl,
                    decoration: const InputDecoration(
                      labelText: 'العنوان (إنجليزي)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextFormField(
                    controller: descArCtrl,
                    decoration: const InputDecoration(
                      labelText: 'الوصف (عربي)',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextFormField(
                    controller: imageUrlCtrl,
                    decoration: const InputDecoration(
                      labelText: 'رابط الصورة',
                      border: OutlineInputBorder(),
                      hintText: 'https://...',
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextFormField(
                    controller: targetUrlCtrl,
                    decoration: const InputDecoration(
                      labelText: 'رابط الهدف (target_url)',
                      border: OutlineInputBorder(),
                      hintText: 'https://...',
                    ),
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
                            'title_ar': titleArCtrl.text.trim(),
                            'title_en': titleEnCtrl.text.trim(),
                            'description_ar': descArCtrl.text.trim(),
                            'image_url': imageUrlCtrl.text.trim().isEmpty
                                ? null
                                : imageUrlCtrl.text.trim(),
                            'target_url': targetUrlCtrl.text.trim().isEmpty
                                ? null
                                : targetUrlCtrl.text.trim(),
                            'is_active': true,
                            'sort_order': existing?.sortOrder ?? 0,
                            if (existing == null && profile != null)
                              'created_by': profile.id,
                            'updated_at':
                                DateTime.now().toIso8601String(),
                          };

                          bool ok;
                          if (existing != null) {
                            ok = await ref
                                .read(adminAdsProvider.notifier)
                                .updateAd(existing.id, data);
                          } else {
                            ok = await ref
                                .read(adminAdsProvider.notifier)
                                .createAd(data);
                          }

                          if (!ok && mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  content: Text(existing != null
                                      ? 'فشل التعديل'
                                      : 'فشل الإضافة')),
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

  Future<void> _deleteDialog(String id, String title) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تأكيد الحذف'),
        content: Text('هل أنت متأكد من حذف الإعلان "$title"؟'),
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
      final ok =
          await ref.read(adminAdsProvider.notifier).deleteAd(id);
      if (!ok && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('فشل الحذف')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final state = ref.watch(adminAdsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('الإعلانات'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => ref.read(adminAdsProvider.notifier).loadAds(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAdDialog(),
        child: const Icon(Icons.add_rounded),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'بحث بالعنوان...',
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
                      onPressed: () =>
                          ref.read(adminAdsProvider.notifier).loadAds(),
                      child: const Text('إعادة المحاولة'),
                    ),
                  ],
                ),
              ),
              data: (ads) {
                final filtered = ads.where((a) {
                  final q = _searchQuery.toLowerCase();
                  return q.isEmpty ||
                      a.titleAr.toLowerCase().contains(q) ||
                      a.titleEn.toLowerCase().contains(q);
                }).toList();

                if (filtered.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.campaign_outlined,
                            size: 64, color: AppColors.grey400),
                        const SizedBox(height: AppSpacing.md),
                        Text('لا توجد إعلانات',
                            style: AppTextStyles.bodyLarge
                                .copyWith(color: AppColors.grey500)),
                        const SizedBox(height: AppSpacing.lg),
                        ElevatedButton.icon(
                          onPressed: () => _showAdDialog(),
                          icon: const Icon(Icons.add_rounded),
                          label: const Text('إضافة إعلان'),
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () =>
                      ref.read(adminAdsProvider.notifier).loadAds(),
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: AppSpacing.sm),
                    itemBuilder: (_, i) {
                      final ad = filtered[i];
                      return Container(
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppColors.darkCard
                              : AppColors.lightCard,
                          borderRadius: BorderRadius.circular(
                              AppSpacing.radiusMd),
                          border: Border.all(
                            color: isDark
                                ? AppColors.darkDivider
                                : AppColors.lightDivider,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (ad.imageUrl != null &&
                                ad.imageUrl!.isNotEmpty)
                              ClipRRect(
                                borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(
                                        AppSpacing.radiusMd)),
                                child: Image.network(
                                  ad.imageUrl!,
                                  height: 120,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Container(
                                    height: 80,
                                    color: AppColors.primary
                                        .withValues(alpha: 0.1),
                                    child: const Icon(Icons.campaign_rounded,
                                        color: AppColors.primary),
                                  ),
                                ),
                              ),
                            Padding(
                              padding: const EdgeInsets.all(AppSpacing.md),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(ad.titleAr,
                                            style: AppTextStyles.labelLarge
                                                .copyWith(
                                                    fontWeight:
                                                        FontWeight.bold)),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: AppSpacing.sm,
                                            vertical: AppSpacing.xs),
                                        decoration: BoxDecoration(
                                          color: ad.isActive
                                              ? AppColors.success
                                                  .withValues(alpha: 0.1)
                                              : AppColors.error
                                                  .withValues(alpha: 0.1),
                                          borderRadius:
                                              BorderRadius.circular(
                                                  AppSpacing.radiusSm),
                                        ),
                                        child: Text(
                                          ad.isActive ? 'نشط' : 'متوقف',
                                          style: AppTextStyles.labelSmall
                                              .copyWith(
                                            color: ad.isActive
                                                ? AppColors.success
                                                : AppColors.error,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (ad.descriptionAr != null) ...[
                                    const SizedBox(height: AppSpacing.xs),
                                    Text(ad.descriptionAr!,
                                        style: AppTextStyles.bodySmall),
                                  ],
                                  const SizedBox(height: AppSpacing.sm),
                                  Row(
                                    children: [
                                      IconButton(
                                        icon: Icon(
                                          ad.isActive
                                              ? Icons.visibility_off_rounded
                                              : Icons.visibility_rounded,
                                          color: ad.isActive
                                              ? AppColors.warning
                                              : AppColors.success,
                                          size: 20,
                                        ),
                                        tooltip: ad.isActive
                                            ? 'تعطيل'
                                            : 'تفعيل',
                                        onPressed: () {
                                          ref
                                              .read(adminAdsProvider.notifier)
                                              .toggleActive(
                                                  ad.id, !ad.isActive);
                                        },
                                      ),
                                      IconButton(
                                        icon: const Icon(
                                            Icons.edit_rounded,
                                            color: AppColors.info,
                                            size: 20),
                                        tooltip: 'تعديل',
                                        onPressed: () =>
                                            _showAdDialog(existing: ad),
                                      ),
                                      IconButton(
                                        icon: const Icon(
                                            Icons.delete_rounded,
                                            color: AppColors.error,
                                            size: 20),
                                        tooltip: 'حذف',
                                        onPressed: () => _deleteDialog(
                                            ad.id, ad.titleAr),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
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
