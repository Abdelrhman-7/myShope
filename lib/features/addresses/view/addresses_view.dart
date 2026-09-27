import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/responsive.dart';
import '../controller/address_controller.dart';
import '../models/address_model.dart';

class AddressesView extends ConsumerStatefulWidget {
  const AddressesView({super.key});

  @override
  ConsumerState<AddressesView> createState() => _AddressesViewState();
}

class _AddressesViewState extends ConsumerState<AddressesView> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(addressesProvider.notifier).loadAddresses();
    });
  }

  void _showAddAddressDialog() {
    final loc = AppLocalizations.of(context);
    final titleController = TextEditingController();
    final addressController = TextEditingController();
    final cityController = TextEditingController();
    final phoneController = TextEditingController();
    bool isDefault = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom + AppSpacing.lg,
            top: AppSpacing.lg,
            left: AppSpacing.lg,
            right: AppSpacing.lg,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                loc.translate('addresses.add_address'),
                style: AppTextStyles.titleLarge.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: titleController,
                decoration: InputDecoration(
                  labelText: loc.translate('addresses.title'),
                  hintText: 'Home, Work, Workshop...',
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              TextField(
                controller: addressController,
                decoration: InputDecoration(
                  labelText: loc.translate('addresses.full_address'),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: cityController,
                      decoration: InputDecoration(
                        labelText: loc.translate('addresses.city'),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: TextField(
                      controller: phoneController,
                      decoration: InputDecoration(
                        labelText: loc.translate('auth.phone'),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(loc.translate('addresses.default_address')),
                value: isDefault,
                onChanged: (val) {
                  setModalState(() => isDefault = val ?? false);
                },
              ),
              const SizedBox(height: AppSpacing.md),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.white,
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.md,
                    ),
                  ),
                  onPressed: () {
                    if (titleController.text.isEmpty ||
                        addressController.text.isEmpty) {
                      return;
                    }
                    ref.read(addressesProvider.notifier).addAddress(
                          title: titleController.text.trim(),
                          fullAddress: addressController.text.trim(),
                          city: cityController.text.trim().isNotEmpty
                              ? cityController.text.trim()
                              : null,
                          phone: phoneController.text.trim().isNotEmpty
                              ? phoneController.text.trim()
                              : null,
                          isDefault: isDefault,
                        );
                    Navigator.pop(ctx);
                  },
                  child: Text(loc.translate('common.save')),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final addressesState = ref.watch(addressesProvider);
    final padding = Responsive.getHorizontalPadding(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.translate('addresses.title')),
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddAddressDialog,
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add, color: AppColors.white),
        label: Text(
          loc.translate('addresses.add_address'),
          style: const TextStyle(color: AppColors.white),
        ),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            await ref.read(addressesProvider.notifier).loadAddresses();
          },
          child: addressesState.when(
            loading: () => const Center(
              child: CircularProgressIndicator.adaptive(),
            ),
            error: (error, _) => Center(
              child: Text(loc.translate('common.error')),
            ),
            data: (addresses) {
              if (addresses.isEmpty) {
                return Center(
                  child: Padding(
                    padding: EdgeInsets.all(padding),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.location_off_outlined,
                          size: 72,
                          color: AppColors.grey500,
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        Text(
                          loc.translate('addresses.empty'),
                          style: AppTextStyles.titleMedium,
                        ),
                      ],
                    ),
                  ),
                );
              }

              return ListView.builder(
                padding: EdgeInsets.all(padding),
                itemCount: addresses.length,
                itemBuilder: (context, index) {
                  final addr = addresses[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: AppSpacing.md),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkCard : AppColors.lightCard,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                      border: Border.all(
                        color: addr.isDefault
                            ? AppColors.primary
                            : (isDark
                                ? AppColors.darkDivider
                                : AppColors.lightDivider),
                        width: addr.isDefault ? 1.5 : 1,
                      ),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(AppSpacing.md),
                      leading: Icon(
                        addr.isDefault
                            ? Icons.check_circle_rounded
                            : Icons.location_on_outlined,
                        color: addr.isDefault
                            ? AppColors.primary
                            : AppColors.grey500,
                      ),
                      title: Row(
                        children: [
                          Text(
                            addr.title,
                            style: AppTextStyles.titleMedium.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (addr.isDefault) ...[
                            const SizedBox(width: AppSpacing.sm),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.sm,
                                vertical: AppSpacing.xs,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.12),
                                borderRadius:
                                    BorderRadius.circular(AppSpacing.radiusSm),
                              ),
                              child: Text(
                                loc.translate('addresses.default_address'),
                                style: AppTextStyles.labelSmall.copyWith(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: AppSpacing.xs),
                          Text(addr.fullAddress),
                          if (addr.city != null || addr.phone != null) ...[
                            const SizedBox(height: AppSpacing.xs),
                            Text(
                              [
                                if (addr.city != null) addr.city,
                                if (addr.phone != null) addr.phone,
                              ].join(' • '),
                              style: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.grey500,
                              ),
                            ),
                          ],
                        ],
                      ),
                      trailing: IconButton(
                        icon: const Icon(
                          Icons.delete_outline,
                          color: AppColors.error,
                        ),
                        onPressed: () {
                          ref
                              .read(addressesProvider.notifier)
                              .deleteAddress(addr.id);
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
