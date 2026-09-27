import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/responsive.dart';
import '../controller/admin_controller.dart';

class AdminCustomersView extends ConsumerWidget {
  const AdminCustomersView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final customersAsync = ref.watch(adminCustomersProvider);
    final padding = Responsive.getHorizontalPadding(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.translate('admin.customers')),
        centerTitle: true,
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(adminCustomersProvider);
          },
          child: customersAsync.when(
            loading: () => const Center(
              child: CircularProgressIndicator.adaptive(),
            ),
            error: (_, __) => Center(
              child: Text(loc.translate('common.error')),
            ),
            data: (customers) {
              if (customers.isEmpty) {
                return Center(child: Text(loc.translate('common.no_data')));
              }

              return ListView.separated(
                padding: EdgeInsets.all(padding),
                itemCount: customers.length,
                separatorBuilder: (_, __) =>
                    const SizedBox(height: AppSpacing.sm),
                itemBuilder: (context, idx) {
                  final c = customers[idx];
                  return Container(
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkCard : AppColors.lightCard,
                      borderRadius:
                          BorderRadius.circular(AppSpacing.radiusMd),
                      border: Border.all(
                        color: isDark
                            ? AppColors.darkDivider
                            : AppColors.lightDivider,
                      ),
                    ),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: AppColors.primary.withOpacity(0.12),
                        child: Text(
                          (c.fullName != null && c.fullName!.isNotEmpty)
                              ? c.fullName![0].toUpperCase()
                              : 'U',
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      title: Row(
                        children: [
                          Text(
                            c.fullName ?? loc.translate('common.no_data'),
                            style: AppTextStyles.titleSmall.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (c.isAdmin) ...[
                            const SizedBox(width: AppSpacing.sm),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.xs,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.secondary.withOpacity(0.2),
                                borderRadius:
                                    BorderRadius.circular(AppSpacing.radiusSm),
                              ),
                              child: const Text(
                                'ADMIN',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.secondaryDark,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      subtitle: Text(
                        [
                          if (c.email != null) c.email,
                          if (c.phone != null) c.phone,
                        ].join(' • '),
                        style: AppTextStyles.bodySmall,
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
