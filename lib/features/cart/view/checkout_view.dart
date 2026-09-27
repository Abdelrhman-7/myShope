import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/app_providers.dart';
import '../../../core/utils/responsive.dart';
import '../../cart/controller/cart_controller.dart';
import '../../orders/controller/orders_controller.dart';
import '../../points/controller/points_controller.dart';

class CheckoutView extends ConsumerStatefulWidget {
  const CheckoutView({super.key});

  @override
  ConsumerState<CheckoutView> createState() => _CheckoutViewState();
}

class _CheckoutViewState extends ConsumerState<CheckoutView> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _notesController = TextEditingController();

  bool _usePoints = false;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    final profile = ref.read(profileProvider).value;
    if (profile != null) {
      _nameController.text = profile.fullName ?? '';
      _phoneController.text = profile.phone ?? '';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final padding = Responsive.getHorizontalPadding(context);

    final cartItems = ref.watch(cartProvider).value ?? [];
    final subtotal = ref.read(cartProvider.notifier).subtotal;
    final userPoints = ref.watch(userPointsBalanceProvider);

    // Points conversion: e.g. 100 points = 10 EGP discount
    final pointsDiscount = _usePoints ? (userPoints * 0.1) : 0.0;
    const deliveryFee = 30.0;
    final total = (subtotal - pointsDiscount + deliveryFee).clamp(0.0, double.infinity);

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.translate('cart.checkout')),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(padding),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  loc.translate('addresses.title'),
                  style: AppTextStyles.titleLarge.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),

                // Name field
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: loc.translate('auth.full_name'),
                    prefixIcon: const Icon(Icons.person_outline),
                  ),
                  validator: (v) =>
                      v == null || v.isEmpty ? loc.translate('common.required_field') : null,
                ),
                const SizedBox(height: AppSpacing.md),

                // Phone field
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    labelText: loc.translate('auth.phone'),
                    prefixIcon: const Icon(Icons.phone_outlined),
                  ),
                  validator: (v) =>
                      v == null || v.isEmpty ? loc.translate('common.required_field') : null,
                ),
                const SizedBox(height: AppSpacing.md),

                // Address field
                TextFormField(
                  controller: _addressController,
                  maxLines: 2,
                  decoration: InputDecoration(
                    labelText: loc.translate('addresses.full_address'),
                    prefixIcon: const Icon(Icons.location_on_outlined),
                  ),
                  validator: (v) =>
                      v == null || v.isEmpty ? loc.translate('common.required_field') : null,
                ),
                const SizedBox(height: AppSpacing.md),

                // Notes field
                TextFormField(
                  controller: _notesController,
                  decoration: InputDecoration(
                    labelText: loc.translate('orders.notes'),
                    prefixIcon: const Icon(Icons.note_alt_outlined),
                  ),
                ),

                const Divider(height: AppSpacing.xxl),

                // Points discount toggle
                if (userPoints > 0) ...[
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: AppColors.secondary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                      border: Border.all(
                        color: AppColors.secondary.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.stars_rounded,
                              color: AppColors.secondary,
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  loc.translate('home.your_points'),
                                  style: AppTextStyles.labelLarge.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  '$userPoints PTS ≈ ${(userPoints * 0.1).toStringAsFixed(1)} ${loc.translate('common.currency')}',
                                  style: AppTextStyles.bodySmall,
                                ),
                              ],
                            ),
                          ],
                        ),
                        Switch.adaptive(
                          value: _usePoints,
                          activeColor: AppColors.secondary,
                          onChanged: (val) {
                            setState(() => _usePoints = val);
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                ],

                // ─── Price Summary ──────────────────────────
                Container(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkCard : AppColors.lightCard,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    border: Border.all(
                      color: isDark
                          ? AppColors.darkDivider
                          : AppColors.lightDivider,
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(loc.translate('orders.subtotal')),
                          Text(
                            '${subtotal.toStringAsFixed(0)} ${loc.translate('common.currency')}',
                          ),
                        ],
                      ),
                      if (_usePoints && pointsDiscount > 0) ...[
                        const SizedBox(height: AppSpacing.xs),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              loc.translate('orders.discount'),
                              style: const TextStyle(color: AppColors.discount),
                            ),
                            Text(
                              '-${pointsDiscount.toStringAsFixed(1)} ${loc.translate('common.currency')}',
                              style: const TextStyle(
                                color: AppColors.discount,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: AppSpacing.xs),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(loc.translate('orders.delivery_fee')),
                          Text(
                            '${deliveryFee.toStringAsFixed(0)} ${loc.translate('common.currency')}',
                          ),
                        ],
                      ),
                      const Divider(height: AppSpacing.lg),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            loc.translate('orders.total'),
                            style: AppTextStyles.titleMedium.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '${total.toStringAsFixed(0)} ${loc.translate('common.currency')}',
                            style: AppTextStyles.titleLarge.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: AppSpacing.xxl),

                // Place Order Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.white,
                      padding: const EdgeInsets.symmetric(
                        vertical: AppSpacing.md,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusMd),
                      ),
                    ),
                    onPressed: _isSubmitting || cartItems.isEmpty
                        ? null
                        : () async {
                            if (!_formKey.currentState!.validate()) return;
                            setState(() => _isSubmitting = true);

                            final messenger = ScaffoldMessenger.of(context);
                            final nav = GoRouter.of(context);

                            final orderId = await ref
                                .read(ordersProvider.notifier)
                                .createOrder(
                                  customerName: _nameController.text.trim(),
                                  customerPhone: _phoneController.text.trim(),
                                  address: _addressController.text.trim(),
                                  notes: _notesController.text.trim().isNotEmpty
                                      ? _notesController.text.trim()
                                      : null,
                                  pointsUsed: _usePoints ? userPoints : 0,
                                  discount: pointsDiscount,
                                );

                            if (!mounted) return;
                            setState(() => _isSubmitting = false);

                            if (orderId != null) {
                              messenger.showSnackBar(
                                SnackBar(
                                  content: Text(
                                    loc.translate('common.success'),
                                  ),
                                  backgroundColor: AppColors.success,
                                ),
                              );
                              nav.go('/orders/$orderId');
                            } else {
                              messenger.showSnackBar(
                                SnackBar(
                                  content: Text(
                                    loc.translate('common.error'),
                                  ),
                                  backgroundColor: AppColors.error,
                                ),
                              );
                            }
                          },
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: AppColors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : Text(
                            loc.translate('cart.checkout'),
                            style: AppTextStyles.labelLarge.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: AppSpacing.xxxl),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
