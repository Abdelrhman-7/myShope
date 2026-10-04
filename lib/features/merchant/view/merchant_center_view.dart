import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/app_providers.dart';
import '../../../core/config/supabase_config.dart';

// ─── Merchant Stats Model ──────────────────────────────────────────────────
class MerchantStats {
  final double totalSpent;
  final int totalOrders;
  final double totalSaved;
  final int totalPoints;

  const MerchantStats({
    this.totalSpent = 0,
    this.totalOrders = 0,
    this.totalSaved = 0,
    this.totalPoints = 0,
  });
}

// ─── Merchant Stats Provider ───────────────────────────────────────────────
final merchantStatsProvider =
    FutureProvider.autoDispose<MerchantStats>((ref) async {
  final profile = ref.watch(profileProvider).value;
  if (profile == null) return const MerchantStats();

  try {
    final ordersRes = await supabase
        .from('orders')
        .select('total, discount_amount')
        .eq('user_id', profile.id)
        .timeout(const Duration(seconds: 5));

    final orders = ordersRes as List;
    final totalSpent = orders.fold<double>(
      0,
      (sum, o) => sum + ((o['total'] as num?)?.toDouble() ?? 0),
    );
    final totalDiscount = orders.fold<double>(
      0,
      (sum, o) => sum + ((o['discount_amount'] as num?)?.toDouble() ?? 0),
    );

    // Points
    final pointsRes = await supabase
        .from('points_transactions')
        .select('points')
        .eq('user_id', profile.id)
        .timeout(const Duration(seconds: 5));

    final points = (pointsRes as List).fold<int>(
      0,
      (sum, p) => sum + ((p['points'] as num?)?.toInt() ?? 0),
    );

    return MerchantStats(
      totalSpent: totalSpent,
      totalOrders: orders.length,
      totalSaved: totalDiscount,
      totalPoints: points,
    );
  } catch (_) {
    return const MerchantStats();
  }
});

// ─── Merchant Center View ──────────────────────────────────────────────────
class MerchantCenterView extends ConsumerWidget {
  const MerchantCenterView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final profile = ref.watch(profileProvider).value;
    final selectedRole = ref.watch(userRoleProvider);
    final isMerchant =
        selectedRole == 'merchant' || (profile?.isMerchant ?? false);

    // Security: only merchants can see this
    if (!isMerchant) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('مركز التاجر'),
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/home');
              }
            },
          ),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.lock_rounded,
                    size: 64,
                    color: AppColors.error,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  'هذه الصفحة للتجار فقط',
                  style: AppTextStyles.headlineSmall.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'قم بتغيير نوع حسابك إلى "تاجر" من الملف الشخصي للاستفادة من مميزات التجار.',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.xl),
                ElevatedButton.icon(
                  onPressed: () => context.go('/profile'),
                  icon: const Icon(Icons.person_rounded),
                  label: const Text('الملف الشخصي'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final statsAsync = ref.watch(merchantStatsProvider);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // ─── Sliver AppBar ─────────────────────────────────────
          SliverAppBar(
            expandedHeight: 180,
            floating: false,
            pinned: true,
            centerTitle: true,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: AppColors.white),
              onPressed: () {
                if (context.canPop()) {
                  context.pop();
                } else {
                  context.go('/home');
                }
              },
            ),
            title: const Text(
              'مركز التاجر',
              style: TextStyle(
                color: AppColors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.secondary,
                      AppColors.secondaryDark,
                    ],
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg,
                      AppSpacing.xl,
                      AppSpacing.lg,
                      AppSpacing.md,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(AppSpacing.sm),
                              decoration: BoxDecoration(
                                color: AppColors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(
                                    AppSpacing.radiusMd),
                              ),
                              child: const Icon(
                                Icons.storefront_rounded,
                                color: AppColors.white,
                                size: 28,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Text(
                              profile?.fullName ?? 'تاجر',
                              style: AppTextStyles.titleMedium.copyWith(
                                color: AppColors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.xs + 2),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.sm,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.white.withValues(alpha: 0.2),
                            borderRadius:
                                BorderRadius.circular(AppSpacing.radiusSm),
                          ),
                          child: Text(
                            '✅ حساب تاجر مفعّل — مميزات الجملة نشطة',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // ─── Stats Cards ──────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: statsAsync.when(
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.all(AppSpacing.xl),
                    child: CircularProgressIndicator.adaptive(),
                  ),
                ),
                error: (_, __) => const SizedBox.shrink(),
                data: (stats) => Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _StatCard(
                            isDark: isDark,
                            icon: Icons.receipt_long_rounded,
                            label: 'إجمالي طلباتي',
                            value: '${stats.totalOrders}',
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: _StatCard(
                            isDark: isDark,
                            icon: Icons.payments_outlined,
                            label: 'إجمالي إنفاقي',
                            value:
                                '${stats.totalSpent.toStringAsFixed(0)} ج.م',
                            color: AppColors.secondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Row(
                      children: [
                        Expanded(
                          child: _StatCard(
                            isDark: isDark,
                            icon: Icons.savings_rounded,
                            label: 'إجمالي وفرت',
                            value:
                                '${stats.totalSaved.toStringAsFixed(0)} ج.م',
                            color: AppColors.success,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: _StatCard(
                            isDark: isDark,
                            icon: Icons.stars_rounded,
                            label: 'نقاطي',
                            value: '${stats.totalPoints} PTS',
                            color: AppColors.accent,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ─── Section: مميزات التاجر ────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md, vertical: AppSpacing.xs),
              child: Text(
                'مميزاتك كتاجر',
                style: AppTextStyles.titleLarge.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _FeatureTile(
                  isDark: isDark,
                  icon: Icons.inventory_2_rounded,
                  iconColor: AppColors.primary,
                  title: 'أسعار الجملة',
                  subtitle: 'خصم خاص على جميع المنتجات عند الشراء بكميات',
                  trailingLabel: 'خصم 15%',
                  trailingColor: AppColors.success,
                  onTap: () => _showFeatureDialog(
                    context,
                    title: '📦 أسعار الجملة للتجار',
                    body:
                        'بصفتك تاجراً مسجلاً في المتجر، تحصل تلقائياً على:\n\n'
                        '• خصم 15% على جميع طلبيات الجملة\n'
                        '• إمكانية الطلب بكميات مخصصة للورش والمحلات\n'
                        '• أولوية الشحن وخدمة التوصيل السريع\n'
                        '• فاتورة تجارية رسمية مع كل طلب',
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                _FeatureTile(
                  isDark: isDark,
                  icon: Icons.sell_rounded,
                  iconColor: AppColors.secondary,
                  title: 'كتالوج أسعار التجار',
                  subtitle: 'تصفح الأسعار المخصصة للتجار والموزعين',
                  trailingLabel: 'حصري',
                  trailingColor: AppColors.secondary,
                  onTap: () => _showFeatureDialog(
                    context,
                    title: '🏷️ كتالوج أسعار التجار',
                    body:
                        'كتالوج أسعار الجملة والتجار متاح لك دائماً:\n\n'
                        '• أسعار الجملة تظهر مباشرة في صفحة المنتج\n'
                        '• شارة "سعر التاجر" موضحة بجانب كل منتج\n'
                        '• قائمة المنتجات المطلوبة بشكل متكرر للتجار\n'
                        '• عروض حصرية تُرسل لك عبر الإشعارات',
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                _FeatureTile(
                  isDark: isDark,
                  icon: Icons.analytics_rounded,
                  iconColor: AppColors.accent,
                  title: 'إحصائيات المشتريات',
                  subtitle: 'تقارير شهرية مفصلة لمشترياتك وتوفيرك',
                  trailingLabel: 'تقارير',
                  trailingColor: AppColors.accent,
                  onTap: () => _showMerchantAnalyticsDialog(context, ref),
                ),
                const SizedBox(height: AppSpacing.sm),
                _FeatureTile(
                  isDark: isDark,
                  icon: Icons.support_agent_rounded,
                  iconColor: AppColors.success,
                  title: 'دعم التجار المخصص',
                  subtitle: 'مسؤول مبيعات مخصص لك على مدار الساعة',
                  trailingLabel: '24/7',
                  trailingColor: AppColors.success,
                  onTap: () => _showFeatureDialog(
                    context,
                    title: '📞 دعم التجار المباشر',
                    body:
                        'كتاجر مسجل في المتجر تحصل على:\n\n'
                        '• مسؤول مبيعات مخصص لحسابك\n'
                        '• دعم عبر واتساب أو الهاتف مباشرة\n'
                        '• أولوية في الردود والاستفسارات\n'
                        '• نظام شكاوى مخصص للتجار',
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                _FeatureTile(
                  isDark: isDark,
                  icon: Icons.local_shipping_rounded,
                  iconColor: AppColors.primaryDark,
                  title: 'شحن مجاني على الكميات',
                  subtitle: 'شحن مجاني لطلبيات التاجر فوق 500 ج.م',
                  trailingLabel: 'مجاني',
                  trailingColor: AppColors.success,
                  onTap: () => _showFeatureDialog(
                    context,
                    title: '🚚 سياسة الشحن للتجار',
                    body:
                        'سياسة الشحن المميزة للتجار:\n\n'
                        '• شحن مجاني على الطلبيات فوق 500 ج.م\n'
                        '• أولوية التجهيز وضمان التوصيل في أقل وقت\n'
                        '• إمكانية تحديد مواعيد التوصيل المفضلة',
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                _FeatureTile(
                  isDark: isDark,
                  icon: Icons.receipt_rounded,
                  iconColor: AppColors.error,
                  title: 'فواتير تجارية رسمية',
                  subtitle: 'استخراج فاتورة ضريبية لكل طلبية',
                  trailingLabel: 'PDF',
                  trailingColor: AppColors.error,
                  onTap: () => _showFeatureDialog(
                    context,
                    title: '🧾 الفواتير التجارية',
                    body:
                        'خدمة الفواتير التجارية للتجار:\n\n'
                        '• فاتورة ضريبية رسمية لكل طلبية\n'
                        '• إمكانية تنزيل الفاتورة بصيغة PDF\n'
                        '• سجل كامل بجميع فواتيرك من صفحة الطلبات',
                  ),
                ),
                const SizedBox(height: AppSpacing.xxxl),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  void _showFeatureDialog(
    BuildContext context, {
    required String title,
    required String body,
  }) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title, style: AppTextStyles.titleMedium),
        content: Text(body, style: AppTextStyles.bodyMedium),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('حسناً'),
          ),
        ],
      ),
    );
  }

  void _showMerchantAnalyticsDialog(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.read(merchantStatsProvider);
    statsAsync.when(
      data: (stats) => showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('📊 إحصائيات المشتريات'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _AnalyticsRow(
                  label: 'إجمالي الطلبات', value: '${stats.totalOrders}'),
              _AnalyticsRow(
                  label: 'إجمالي الإنفاق',
                  value: '${stats.totalSpent.toStringAsFixed(0)} ج.م'),
              _AnalyticsRow(
                  label: 'إجمالي الوفر',
                  value: '${stats.totalSaved.toStringAsFixed(0)} ج.م'),
              _AnalyticsRow(
                  label: 'رصيد النقاط', value: '${stats.totalPoints} PTS'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('إغلاق'),
            ),
          ],
        ),
      ),
      loading: () {},
      error: (_, __) {},
    );
  }
}

// ─── Stat Card Widget ──────────────────────────────────────────────────────
class _StatCard extends StatelessWidget {
  final bool isDark;
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.isDark,
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
          color: isDark ? AppColors.darkDivider : AppColors.lightDivider,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: AppTextStyles.bodySmall.copyWith(
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.lightTextSecondary,
                ),
              ),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 16),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            value,
            style: AppTextStyles.titleMedium.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Feature Tile Widget ──────────────────────────────────────────────────
class _FeatureTile extends StatelessWidget {
  final bool isDark;
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final String trailingLabel;
  final Color trailingColor;
  final VoidCallback onTap;

  const _FeatureTile({
    required this.isDark,
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.trailingLabel,
    required this.trailingColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : AppColors.lightCard,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(
            color: isDark ? AppColors.darkDivider : AppColors.lightDivider,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              ),
              child: Icon(icon, color: iconColor, size: 24),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.titleSmall.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: trailingColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                  ),
                  child: Text(
                    trailingLabel,
                    style: AppTextStyles.labelSmall.copyWith(
                      color: trailingColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                const Icon(Icons.arrow_forward_ios, size: 12,
                    color: AppColors.grey500),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Analytics Row Widget ─────────────────────────────────────────────────
class _AnalyticsRow extends StatelessWidget {
  final String label;
  final String value;

  const _AnalyticsRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTextStyles.bodyMedium),
          Text(
            value,
            style: AppTextStyles.bodyMedium.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}

