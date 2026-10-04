import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/app_providers.dart';

// ─── Admin section indices ────────────────────────────────────────────────────
const kAdminSections = [
  '/admin',
  '/admin/customers',
  '/admin/merchants',
  '/admin/products',
  '/admin/categories',
  '/admin/orders',
  '/admin/advertisements',
  '/admin/sales',
  '/admin/statistics',
  '/admin/settings',
];

const _kSectionLabels = [
  'الرئيسية',
  'العملاء',
  'التجار',
  'المنتجات',
  'التصنيفات',
  'الطلبات',
  'الإعلانات',
  'المبيعات',
  'الإحصائيات',
  'الإعدادات',
];

const _kSectionIcons = [
  Icons.dashboard_rounded,
  Icons.people_rounded,
  Icons.storefront_rounded,
  Icons.inventory_2_rounded,
  Icons.category_rounded,
  Icons.receipt_long_rounded,
  Icons.campaign_rounded,
  Icons.bar_chart_rounded,
  Icons.analytics_rounded,
  Icons.settings_rounded,
];

/// Admin shell — wraps all /admin/* pages with a persistent Sidebar
class AdminShell extends ConsumerWidget {
  final Widget child;
  final String currentPath;

  const AdminShell({super.key, required this.child, required this.currentPath});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final profile = ref.watch(profileProvider).value;

    // Security guard
    if (profile == null || !profile.isAdmin) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.lock_rounded, size: 64, color: AppColors.error),
              const SizedBox(height: AppSpacing.lg),
              Text('غير مصرح بالدخول',
                  style: AppTextStyles.h3.copyWith(color: AppColors.error)),
              const SizedBox(height: AppSpacing.lg),
              ElevatedButton(
                onPressed: () => context.go('/login'),
                child: const Text('تسجيل الدخول'),
              ),
            ],
          ),
        ),
      );
    }

    final isWide = MediaQuery.of(context).size.width >= 900;

    if (isWide) {
      return Scaffold(
        body: Row(
          children: [
            _AdminSidebar(
              currentPath: currentPath,
              profile: profile,
              isDark: isDark,
              ref: ref,
            ),
            const VerticalDivider(width: 1),
            Expanded(child: child),
          ],
        ),
      );
    }

    // Mobile: drawer
    return Scaffold(
      drawer: Drawer(
        child: _AdminSidebar(
          currentPath: currentPath,
          profile: profile,
          isDark: isDark,
          ref: ref,
          isDrawer: true,
        ),
      ),
      body: child,
    );
  }
}

// ─── Sidebar ──────────────────────────────────────────────────────────────────
class _AdminSidebar extends ConsumerWidget {
  final String currentPath;
  final profile;
  final bool isDark;
  final WidgetRef ref;
  final bool isDrawer;

  const _AdminSidebar({
    required this.currentPath,
    required this.profile,
    required this.isDark,
    required this.ref,
    this.isDrawer = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bgColor = isDark ? AppColors.darkSurface : AppColors.white;

    return Container(
      width: 240,
      color: bgColor,
      child: SafeArea(
        child: Column(
          children: [
            // ── Header ──────────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppColors.primaryDark, AppColors.primary],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppColors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                        ),
                        child: const Icon(
                          Icons.admin_panel_settings_rounded,
                          color: AppColors.white,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              profile?.fullName ?? 'مدير النظام',
                              style: AppTextStyles.labelLarge.copyWith(
                                color: AppColors.white,
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              profile?.email ?? '',
                              style: AppTextStyles.labelSmall.copyWith(
                                color: AppColors.white.withValues(alpha: 0.75),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // ── Nav items ───────────────────────────────────
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                children: [
                  for (int i = 0; i < kAdminSections.length; i++)
                    _SidebarItem(
                      icon: _kSectionIcons[i],
                      label: _kSectionLabels[i],
                      path: kAdminSections[i],
                      currentPath: currentPath,
                      isDark: isDark,
                      onTap: () {
                        if (isDrawer) Navigator.of(context).pop();
                        context.go(kAdminSections[i]);
                      },
                    ),
                ],
              ),
            ),

            // ── Footer ──────────────────────────────────────
            const Divider(height: 1),
            _SidebarItem(
              icon: Icons.logout_rounded,
              label: 'تسجيل الخروج',
              path: '',
              currentPath: '',
              isDark: isDark,
              isDestructive: true,
              onTap: () async {
                final auth = ref.read(authServiceProvider);
                await auth.signOut();
                ref.read(profileProvider.notifier).clear();
                if (context.mounted) context.go('/login');
              },
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
        ),
      ),
    );
  }
}

// ─── Sidebar Item ─────────────────────────────────────────────────────────────
class _SidebarItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String path;
  final String currentPath;
  final bool isDark;
  final bool isDestructive;
  final VoidCallback onTap;

  const _SidebarItem({
    required this.icon,
    required this.label,
    required this.path,
    required this.currentPath,
    required this.isDark,
    required this.onTap,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = path.isNotEmpty && currentPath == path;
    final color = isDestructive
        ? AppColors.error
        : isSelected
            ? AppColors.primary
            : (isDark ? AppColors.darkTextSecondary : AppColors.grey600);
    final bgColor = isSelected
        ? AppColors.primary.withValues(alpha: 0.1)
        : Colors.transparent;

    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
      child: Material(
        color: bgColor,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          child: Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md, vertical: AppSpacing.md),
            child: Row(
              children: [
                Icon(icon, size: 20, color: color),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    label,
                    style: AppTextStyles.labelMedium.copyWith(
                      color: color,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),
                if (isSelected)
                  Container(
                    width: 4,
                    height: 16,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
