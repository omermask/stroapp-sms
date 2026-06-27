import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/widgets/widgets.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../payments/providers/payments_provider.dart';

class TopUpScreen extends ConsumerStatefulWidget {
  const TopUpScreen({super.key});

  @override
  ConsumerState<TopUpScreen> createState() => _TopUpScreenState();
}

class _TopUpScreenState extends ConsumerState<TopUpScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(paymentsProvider.notifier).fetchProducts('google');
    });
  }

  final List<_CoinPackage> _packages = [
    _CoinPackage('100', 100, 1.99),
    _CoinPackage('500', 500, 4.99),
    _CoinPackage('1000', 1000, 9.99),
    _CoinPackage('2500', 2500, 19.99),
    _CoinPackage('5000', 5000, 39.99),
    _CoinPackage('10000', 10000, 79.99),
  ];

  void _selectPackage(_CoinPackage pkg) {
    final isAndroid = Theme.of(context).platform == TargetPlatform.android;
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.hairlineLight,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.network(
                isAndroid
                    ? 'https://developers.google.com/static/pay/api/images/brand-guidelines/google-pay-mark.png'
                    : 'https://logo.clearbit.com/apple.com',
                width: 72,
                height: 72,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => Icon(
                  isAndroid ? QasehIcons.wallet_filled : QasehIcons.buy_filled,
                  size: 36,
                  color: AppColors.primary,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'شحن ${pkg.coins} عملة',
              style: AppTextStyles.titleMedium.copyWith(color: AppColors.ink),
            ),
            const SizedBox(height: 4),
            Text(
              '\$${pkg.price.toStringAsFixed(2)}',
              style: AppTextStyles.numberLarge.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 24),
            if (isAndroid)
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx);
                    context.push('/payments/google-pay');
                  },
                  icon: Image.network(
                    'https://developers.google.com/static/pay/api/images/brand-guidelines/google-pay-mark.png',
                    width: 20,
                    height: 20,
                    errorBuilder: (_, __, ___) => const Icon(QasehIcons.wallet_filled, size: 20, color: AppColors.onPrimary),
                  ),
                  label: const Text('الدفع عبر Google Pay', style: AppTextStyles.button),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.onPrimary,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              )
            else
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx);
                    context.push('/payments/apple-pay');
                  },
                  icon: Image.network(
                    'https://logo.clearbit.com/apple.com',
                    width: 20,
                    height: 20,
                    errorBuilder: (_, __, ___) => const Icon(QasehIcons.buy_filled, size: 20, color: AppColors.onPrimary),
                  ),
                  label: const Text('Apple Pay', style: AppTextStyles.button),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.onPrimary,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('إلغاء', style: AppTextStyles.labelMedium.copyWith(color: AppColors.mutedStrong)),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceSoftLight,
      appBar: AppBar(
        title: const Text('شحن الرصيد'),
        backgroundColor: AppColors.canvasLight,
        surfaceTintColor: AppColors.canvasLight,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildHeader(),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              child: Column(
                children: [
                  ..._packages.asMap().entries.map((entry) {
                    final i = entry.key;
                    final pkg = entry.value;
                    return Padding(
                      padding: EdgeInsets.only(bottom: i < _packages.length - 1 ? 12 : 0),
                      child: GestureDetector(
                        onTap: () => _selectPackage(pkg),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.canvasLight,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AppColors.hairlineLight),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(QasehIcons.wallet_filled, size: 24, color: AppColors.primary),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${pkg.coins} عملة',
                                      style: AppTextStyles.titleSmall.copyWith(
                                        color: AppColors.ink,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${pkg.label} عملات',
                                      style: AppTextStyles.caption.copyWith(color: AppColors.mutedStrong),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                decoration: BoxDecoration(
                                  color: AppColors.primary,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '\$${pkg.price.toStringAsFixed(2)}',
                                  style: AppTextStyles.labelSmall.copyWith(
                                    color: AppColors.onPrimary,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          const Icon(QasehIcons.wallet_filled, size: 22, color: AppColors.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'اختر باقة الشحن المناسبة لك',
              style: AppTextStyles.labelMedium.copyWith(color: AppColors.ink),
            ),
          ),
        ],
      ),
    );
  }
}

class _CoinPackage {
  final String label;
  final int coins;
  final double price;
  const _CoinPackage(this.label, this.coins, this.price);
}
