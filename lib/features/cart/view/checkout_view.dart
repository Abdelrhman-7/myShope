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
import '../../cart/models/cart_item_model.dart';
import '../../orders/controller/orders_controller.dart';
import '../../points/controller/points_controller.dart';

class CheckoutView extends ConsumerStatefulWidget {
  final Map<String, dynamic>? extra;

  const CheckoutView({super.key, this.extra});

  @override
  ConsumerState<CheckoutView> createState() => _CheckoutViewState();
}

class _CheckoutViewState extends ConsumerState<CheckoutView> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _notesController = TextEditingController();

  // Visa card controllers
  final _cardNumberController = TextEditingController();
  final _expiryController = TextEditingController();
  final _cvvController = TextEditingController();

  String _selectedPaymentMethod = 'cash_on_delivery'; // 'cash_on_delivery' or 'visa'
  bool _usePoints = false;
  bool _isSubmitting = false;

  CartItemModel? _buyNowItem;

  @override
  void initState() {
    super.initState();
    final profile = ref.read(profileProvider).value;
    if (profile != null) {
      _nameController.text = profile.fullName ?? '';
      _phoneController.text = profile.phone ?? '';
    }

    if (widget.extra != null && widget.extra!['buyNowItem'] != null) {
      _buyNowItem = widget.extra!['buyNowItem'] as CartItemModel;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _notesController.dispose();
    _cardNumberController.dispose();
    _expiryController.dispose();
    _cvvController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final padding = Responsive.getHorizontalPadding(context);

    final List<CartItemModel> items = _buyNowItem != null
        ? [_buyNowItem!]
        : (ref.watch(cartProvider).value ?? []);

    final double subtotal = _buyNowItem != null
        ? _buyNowItem!.lineTotal
        : ref.read(cartProvider.notifier).subtotal;

    final userPoints = ref.watch(userPointsBalanceProvider);
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
                // ─── Products Summary ───────────────────────────
                Text(
                  'ملخص المنتجات',
                  style: AppTextStyles.titleLarge.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),

                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkCard : AppColors.lightCard,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    border: Border.all(
                      color: isDark ? AppColors.darkDivider : AppColors.lightDivider,
                    ),
                  ),
                  child: Column(
                    children: items.map((item) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                        child: Row(
                          children: [
                            Text(
                              '${item.quantity}x',
                              style: AppTextStyles.labelMedium.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: Text(
                                item.product?.nameAr ?? '',
                                style: AppTextStyles.bodyMedium,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Text(
                              '${item.lineTotal.toStringAsFixed(0)} ${loc.translate('common.currency')}',
                              style: AppTextStyles.labelMedium.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),

                // ─── Address & Delivery Info ─────────────────────
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

                // ─── Payment Methods ────────────────────────────
                Text(
                  'طريقة الدفع',
                  style: AppTextStyles.titleLarge.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),

                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    border: Border.all(
                      color: isDark ? AppColors.darkDivider : AppColors.lightDivider,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd - 1),
                    child: Material(
                      color: isDark ? AppColors.darkCard : AppColors.lightCard,
                      child: Column(
                        children: [
                          RadioListTile<String>(
                            value: 'cash_on_delivery',
                            groupValue: _selectedPaymentMethod,
                            activeColor: AppColors.primary,
                            title: const Row(
                              children: [
                                Icon(Icons.payments_outlined, color: AppColors.success),
                                SizedBox(width: AppSpacing.sm),
                                Flexible(
                                  child: Text(
                                    'الدفع عند الاستلام (Cash on Delivery)',
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            onChanged: (v) {
                              if (v != null) setState(() => _selectedPaymentMethod = v);
                            },
                          ),
                          const Divider(height: 1),
                          RadioListTile<String>(
                            value: 'visa',
                            groupValue: _selectedPaymentMethod,
                            activeColor: AppColors.primary,
                            title: const Row(
                              children: [
                                Icon(Icons.credit_card_rounded, color: AppColors.primary),
                                SizedBox(width: AppSpacing.sm),
                                Flexible(
                                  child: Text(
                                    'بطاقة ائتمانية / فيزا (Visa / MasterCard)',
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            onChanged: (v) {
                              if (v != null) setState(() => _selectedPaymentMethod = v);
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),

                // Visa card inputs if Visa selected
                if (_selectedPaymentMethod == 'visa') ...[
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'بيانات الكارت 💳',
                          style: AppTextStyles.labelLarge.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        TextFormField(
                          controller: _cardNumberController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'رقم البطاقة (16 رقم)',
                            prefixIcon: Icon(Icons.credit_card),
                          ),
                          validator: (v) {
                            if (_selectedPaymentMethod == 'visa' && (v == null || v.length < 16)) {
                              return 'يرجى إدخال رقم بطاقة صحيح';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _expiryController,
                                keyboardType: TextInputType.datetime,
                                decoration: const InputDecoration(
                                  labelText: 'MM/YY',
                                  prefixIcon: Icon(Icons.date_range),
                                ),
                                validator: (v) {
                                  if (_selectedPaymentMethod == 'visa' && (v == null || v.isEmpty)) {
                                    return 'مطلوب';
                                  }
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: TextFormField(
                                controller: _cvvController,
                                keyboardType: TextInputType.number,
                                obscureText: true,
                                decoration: const InputDecoration(
                                  labelText: 'CVV',
                                  prefixIcon: Icon(Icons.lock_outline),
                                ),
                                validator: (v) {
                                  if (_selectedPaymentMethod == 'visa' && (v == null || v.length < 3)) {
                                    return 'مطلوب';
                                  }
                                  return null;
                                },
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                ],

                // Points discount toggle
                if (userPoints > 0) ...[
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: AppColors.secondary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                      border: Border.all(
                        color: AppColors.secondary.withValues(alpha: 0.3),
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
                    onPressed: _isSubmitting || items.isEmpty
                        ? null
                        : () async {
                            if (!_formKey.currentState!.validate()) return;
                            setState(() => _isSubmitting = true);

                            final messenger = ScaffoldMessenger.of(context);
                            final nav = GoRouter.of(context);

                            final result = await ref
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
                                  paymentMethod: _selectedPaymentMethod,
                                  overrideItems: _buyNowItem != null ? [_buyNowItem!] : null,
                                );

                            if (!mounted) return;
                            setState(() => _isSubmitting = false);

                            if (result.isSuccess) {
                              messenger.showSnackBar(
                                const SnackBar(
                                  content: Text('تم إرسال الطلب بنجاح 🎉'),
                                  backgroundColor: AppColors.success,
                                ),
                              );
                              nav.go('/orders/${result.orderId}');
                            } else {
                              messenger.showSnackBar(
                                SnackBar(
                                  content: Text(
                                    result.errorMessage ?? 'فشل إنشاء الطلب',
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
                            'تأكيد الطلب',
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
