import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/widgets/widgets.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../providers/payments_provider.dart';
import '../../../core/api/endpoints/payments_api.dart';

class GooglePayScreen extends ConsumerStatefulWidget {
  const GooglePayScreen({super.key});

  @override
  ConsumerState<GooglePayScreen> createState() => _GooglePayScreenState();
}

class _GooglePayScreenState extends ConsumerState<GooglePayScreen> {
  final _mockToken = 'mock-google-pay-token-${DateTime.now().millisecondsSinceEpoch}';
  String? _selectedProductId;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(paymentsProvider.notifier).fetchProducts('google');
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(paymentsProvider);

    return Scaffold(
      backgroundColor: AppColors.surfaceSoftLight,
      appBar: AppBar(
        title: const Text('Google Pay'),
        backgroundColor: AppColors.canvasLight,
        surfaceTintColor: AppColors.canvasLight,
      ),
      body: _buildBody(state),
    );
  }

  Widget _buildBody(PaymentsState state) {
    if (state.isLoading && state.products.isEmpty) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    }

    if (state.error != null && state.products.isEmpty) {
      return CustomErrorWidget(
        message: state.error!,
        onRetry: () => ref.read(paymentsProvider.notifier).fetchProducts('google'),
      );
    }

    if (state.products.isEmpty) {
      return const EmptyState(
        icon: QasehIcons.wallet_curved,
        message: 'لا توجد منتجات متاحة',
      );
    }

    return Column(
      children: [
        Expanded(
          child: RadioGroup<String>(
            groupValue: _selectedProductId,
            onChanged: (v) => setState(() => _selectedProductId = v),
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: state.products.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final product = state.products[index];
                final productId = product['id']?.toString() ?? '';
                final name = product['name']?.toString() ?? 'منتج';
                final price = product['price']?.toString() ?? '0';
                final currency = product['currency']?.toString() ?? 'USD';
                final isSelected = _selectedProductId == productId;

                return GestureDetector(
                  onTap: () => setState(() => _selectedProductId = productId),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.canvasLight,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? AppColors.primary : AppColors.hairlineLight,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: AppColors.canvasLight,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.hairlineLight),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              'https://developers.google.com/static/pay/api/images/brand-guidelines/google-pay-mark.png',
                              width: 32,
                              height: 32,
                              fit: BoxFit.contain,
                              errorBuilder: (_, __, ___) => const Icon(QasehIcons.wallet_filled, size: 24, color: AppColors.primary),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(name, style: AppTextStyles.titleSmall.copyWith(color: AppColors.ink)),
                              const SizedBox(height: 4),
                              Text(
                                '$price $currency',
                                style: AppTextStyles.numberMedium.copyWith(color: AppColors.bluePrimary),
                              ),
                            ],
                          ),
                        ),
                        Radio<String>(
                          value: productId,
                          activeColor: AppColors.primary,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.canvasLight,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: SafeArea(
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _selectedProductId != null && !_isProcessing ? _handlePayment : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _selectedProductId != null ? AppColors.primary : AppColors.primary.withValues(alpha: 0.5),
                  foregroundColor: AppColors.onPrimary,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isProcessing
                    ? const SizedBox(
                        width: 30,
                        height: 30,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor: AlwaysStoppedAnimation<Color>(AppColors.onPrimary),
                        ),
                      )
                    : Text('تأكيد الدفع', style: AppTextStyles.button),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _handlePayment() async {
    if (_selectedProductId == null) return;
    setState(() => _isProcessing = true);
    try {
      final idempotencyKey = 'gp-${DateTime.now().millisecondsSinceEpoch}';
      await ref.read(paymentsApiProvider).googlePay(_mockToken, _selectedProductId!, idempotencyKey);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تمت عملية الدفع بنجاح'), backgroundColor: AppColors.success),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }
}
