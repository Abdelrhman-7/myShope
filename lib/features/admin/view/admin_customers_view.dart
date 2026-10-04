import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/responsive.dart';
import '../../../core/utils/app_providers.dart';
import '../../auth/models/profile_model.dart';
import '../controller/admin_controller.dart';

class AdminCustomersView extends ConsumerStatefulWidget {
  const AdminCustomersView({super.key});

  @override
  ConsumerState<AdminCustomersView> createState() => _AdminCustomersViewState();
}

class _AdminCustomersViewState extends ConsumerState<AdminCustomersView> {
  String _filterRole = 'all'; // all, customer, merchant, admin
  String _searchQuery = '';
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(adminCustomersProvider.notifier).loadCustomers();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Security check
  bool _isAdmin(WidgetRef ref) {
    final profile = ref.read(profileProvider).value;
    return profile?.isAdmin ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final customersState = ref.watch(adminCustomersProvider);
    final padding = Responsive.getHorizontalPadding(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.translate('admin.customers')),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // ── Search + Filter ──────────────────────────────────
            Padding(
              padding: EdgeInsets.fromLTRB(padding, AppSpacing.md, padding, 0),
              child: Column(
                children: [
                  TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'بحث بالاسم أو البريد...',
                      prefixIcon: const Icon(Icons.search_rounded),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();
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
                      enabledBorder: OutlineInputBorder(
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
                  // Role filter chips
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _RoleChip(
                          label: 'الكل',
                          isSelected: _filterRole == 'all',
                          color: AppColors.primary,
                          onTap: () => setState(() => _filterRole = 'all'),
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        _RoleChip(
                          label: '👤 عملاء',
                          isSelected: _filterRole == 'customer',
                          color: AppColors.primary,
                          onTap: () =>
                              setState(() => _filterRole = 'customer'),
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        _RoleChip(
                          label: '🏪 تجار',
                          isSelected: _filterRole == 'merchant',
                          color: AppColors.secondary,
                          onTap: () =>
                              setState(() => _filterRole = 'merchant'),
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        _RoleChip(
                          label: '🛡️ Admins',
                          isSelected: _filterRole == 'admin',
                          color: AppColors.error,
                          onTap: () => setState(() => _filterRole = 'admin'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.sm),

            // ── List ─────────────────────────────────────────────
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  await ref.read(adminCustomersProvider.notifier).loadCustomers();
                },
                child: customersState.when(
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
                        Text(loc.translate('common.error')),
                        const SizedBox(height: AppSpacing.md),
                        ElevatedButton(
                          onPressed: () => ref
                              .read(adminCustomersProvider.notifier)
                              .loadCustomers(),
                          child: Text(loc.translate('common.retry')),
                        ),
                      ],
                    ),
                  ),
                  data: (customers) {
                    // Apply filters
                    var filtered = customers;

                    if (_filterRole != 'all') {
                      filtered = filtered
                          .where((c) => c.role == _filterRole)
                          .toList();
                    }

                    if (_searchQuery.isNotEmpty) {
                      final q = _searchQuery.toLowerCase();
                      filtered = filtered.where((c) {
                        return (c.fullName?.toLowerCase().contains(q) ??
                                false) ||
                            (c.email?.toLowerCase().contains(q) ?? false) ||
                            (c.phone?.contains(q) ?? false);
                      }).toList();
                    }

                    if (filtered.isEmpty) {
                      return Center(
                        child: Text(loc.translate('common.no_data')),
                      );
                    }

                    return ListView.separated(
                      padding: EdgeInsets.all(padding),
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(height: AppSpacing.sm),
                      itemBuilder: (context, idx) {
                        final c = filtered[idx];
                        return _CustomerTile(
                          customer: c,
                          isDark: isDark,
                          isAdmin: _isAdmin(ref),
                          onRoleChange: (newRole) =>
                              _changeRole(context, ref, c, newRole),
                          onToggleActive: () =>
                              _toggleActive(context, ref, c),
                          onDelete: () =>
                              _deleteCustomer(context, ref, c),
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

  Future<void> _changeRole(
    BuildContext context,
    WidgetRef ref,
    ProfileModel customer,
    String newRole,
  ) async {
    if (!_isAdmin(ref)) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تغيير الدور'),
        content: Text(
          'هل تريد تغيير دور "${customer.fullName ?? customer.email}" إلى "$newRole"؟\n\nسيؤثر هذا فورياً على صلاحيات المستخدم.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: AppColors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('تغيير'),
          ),
        ],
      ),
    );

    if (confirm != true || !context.mounted) return;

    final success = await ref
        .read(adminCustomersProvider.notifier)
        .updateUserRole(customer.id, newRole);

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success ? 'تم تغيير الدور بنجاح' : 'فشل تغيير الدور',
          ),
          backgroundColor: success ? AppColors.success : AppColors.error,
        ),
      );
    }
  }

  Future<void> _toggleActive(
    BuildContext context,
    WidgetRef ref,
    ProfileModel customer,
  ) async {
    if (!_isAdmin(ref)) return;

    final newState = !customer.isActive;
    final success = await ref
        .read(adminCustomersProvider.notifier)
        .toggleUserActive(customer.id, newState);

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? newState
                    ? 'تم تفعيل الحساب'
                    : 'تم تعطيل الحساب'
                : 'فشل تحديث الحالة',
          ),
          backgroundColor: success ? AppColors.success : AppColors.error,
        ),
      );
    }
  }

  Future<void> _deleteCustomer(
    BuildContext context,
    WidgetRef ref,
    ProfileModel customer,
  ) async {
    if (!_isAdmin(ref)) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تأكيد حذف الحساب'),
        content: Text(
          'هل أنت متأكد من حذف الحساب "${customer.fullName ?? customer.email}" بشكل نهائي؟\n\n'
          'تنبيه: سيتم حذف البيانات المرتبطة بناءً على قيود قاعدة البيانات الحالية (Foreign Keys).',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: AppColors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('حذف نهائي'),
          ),
        ],
      ),
    );

    if (confirm != true || !context.mounted) return;

    final success = await ref
        .read(adminCustomersProvider.notifier)
        .deleteCustomer(customer.id);

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success ? 'تم حذف الحساب بنجاح' : 'فشل الحذف، راجع القيود المرتبطة بالحساب',
          ),
          backgroundColor: success ? AppColors.success : AppColors.error,
        ),
      );
    }
  }
}

// ─── Customer Tile ────────────────────────────────────────────────────────
class _CustomerTile extends StatelessWidget {
  final ProfileModel customer;
  final bool isDark;
  final bool isAdmin;
  final void Function(String newRole) onRoleChange;
  final VoidCallback onToggleActive;
  final VoidCallback onDelete;

  const _CustomerTile({
    required this.customer,
    required this.isDark,
    required this.isAdmin,
    required this.onRoleChange,
    required this.onToggleActive,
    required this.onDelete,
  });

  Color get _roleColor {
    switch (customer.role) {
      case 'admin':
        return AppColors.error;
      case 'merchant':
        return AppColors.secondary;
      default:
        return AppColors.primary;
    }
  }

  String get _roleLabel {
    switch (customer.role) {
      case 'admin':
        return '🛡️ Admin';
      case 'merchant':
        return '🏪 تاجر';
      default:
        return '👤 عميل';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
          color: isDark ? AppColors.darkDivider : AppColors.lightDivider,
        ),
        // Dimmed if inactive
        boxShadow: !customer.isActive
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.04),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Opacity(
        opacity: customer.isActive ? 1.0 : 0.55,
        child: Column(
          children: [
            ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.xs,
              ),
              leading: CircleAvatar(
                backgroundColor: _roleColor.withValues(alpha: 0.12),
                child: Text(
                  (customer.fullName != null && customer.fullName!.isNotEmpty)
                      ? customer.fullName![0].toUpperCase()
                      : 'U',
                  style: TextStyle(
                    color: _roleColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              title: Row(
                children: [
                  Expanded(
                    child: Text(
                      customer.fullName ?? 'بدون اسم',
                      style: AppTextStyles.titleSmall.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: _roleColor.withValues(alpha: 0.12),
                      borderRadius:
                          BorderRadius.circular(AppSpacing.radiusSm),
                    ),
                    child: Text(
                      _roleLabel,
                      style: AppTextStyles.labelSmall.copyWith(
                        color: _roleColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ],
              ),
              subtitle: Text(
                [
                  if (customer.email != null) customer.email,
                  if (customer.phone != null) customer.phone,
                ].join(' • '),
                style: AppTextStyles.bodySmall,
              ),
            ),

            // ── Admin Actions ──────────────────────────────────
            if (isAdmin) ...[
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.xs,
                ),
                child: Row(
                  children: [
                    // Role change
                    Text(
                      'الدور:',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.grey500,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    DropdownButton<String>(
                      value: ['customer', 'merchant', 'admin']
                              .contains(customer.role)
                          ? customer.role
                          : 'customer',
                      underline: const SizedBox.shrink(),
                      isDense: true,
                      style: AppTextStyles.bodySmall.copyWith(
                        fontWeight: FontWeight.w600,
                        color: _roleColor,
                      ),
                      items: const [
                        DropdownMenuItem(
                            value: 'customer', child: Text('👤 عميل')),
                        DropdownMenuItem(
                            value: 'merchant', child: Text('🏪 تاجر')),
                        DropdownMenuItem(
                            value: 'admin', child: Text('🛡️ Admin')),
                      ],
                      onChanged: (newRole) {
                        if (newRole != null && newRole != customer.role) {
                          onRoleChange(newRole);
                        }
                      },
                    ),
                    const Spacer(),

                    // Delete
                    IconButton(
                      icon: const Icon(Icons.delete_rounded, size: 20, color: AppColors.error),
                      onPressed: onDelete,
                      tooltip: 'حذف',
                    ),
                    const SizedBox(width: AppSpacing.sm),

                    // Active toggle
                    Text(
                      customer.isActive ? 'مفعّل' : 'معطّل',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: customer.isActive
                            ? AppColors.success
                            : AppColors.error,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Switch.adaptive(
                      value: customer.isActive,
                      activeColor: AppColors.success,
                      onChanged: (_) => onToggleActive(),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─── Role Chip ────────────────────────────────────────────────────────────
class _RoleChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final Color color;
  final VoidCallback onTap;

  const _RoleChip({
    required this.label,
    required this.isSelected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? color
              : (isDark ? AppColors.darkCard : AppColors.lightCard),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? color
                : (isDark ? AppColors.darkDivider : AppColors.lightDivider),
          ),
        ),
        child: Text(
          label,
          style: AppTextStyles.labelMedium.copyWith(
            color: isSelected ? AppColors.white : null,
            fontWeight:
                isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

