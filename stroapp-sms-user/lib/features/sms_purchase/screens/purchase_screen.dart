import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/widgets/widgets.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/models/price_info.dart';
import '../../../core/models/sms_order.dart';
import '../../../core/api/endpoints/purchase_api.dart';
import '../../../core/api/api_exceptions.dart';

class PurchaseScreen extends ConsumerStatefulWidget {
  final String serviceName;
  final String countryCode;
  final String countryName;
  final String? provider;
  final String? displayName;

  const PurchaseScreen({
    super.key,
    required this.serviceName,
    required this.countryCode,
    required this.countryName,
    this.provider,
    this.displayName,
  });

  @override
  ConsumerState<PurchaseScreen> createState() => _PurchaseScreenState();
}

class _PurchaseScreenState extends ConsumerState<PurchaseScreen> {
  PriceInfo? _price;
  int? _availableCount;
  String? _error;
  bool _isLoadingPrice = true;
  bool _isPurchasing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _fetchPrice());
  }

  Future<void> _fetchPrice() async {
    setState(() {
      _isLoadingPrice = true;
      _error = null;
    });
    try {
      final purchaseApi = ref.read(purchaseApiProvider);
      final response = await purchaseApi.getPrice(widget.serviceName, widget.countryCode);
      final price = PriceInfo(
        service: widget.serviceName,
        country: widget.countryCode,
        provider: response['provider'] as String?,
        price: (response['provider_cost'] as num?)?.toDouble(),
        priceWithMarkup: (response['final_price_usd'] as num?)?.toDouble(),
        costCoins: (response['cost_coins'] as num?)?.toInt(),
      );
      setState(() {
        _price = price;
        _availableCount = (response['available_count'] as num?)?.toInt();
        _isLoadingPrice = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingPrice = false;
        _error = extractErrorMessage(e, fallback: 'حدث خطأ في تحميل السعر');
      });
    }
  }

  Future<void> _purchase() async {
    setState(() {
      _isPurchasing = true;
      _error = null;
    });
    try {
      final purchaseApi = ref.read(purchaseApiProvider);
      final idempotencyKey = DateTime.now().millisecondsSinceEpoch.toString();
      final provider = widget.provider ?? '';
      final response = await purchaseApi.purchase(
        widget.serviceName,
        widget.countryCode,
        provider,
        idempotencyKey,
      );
      final order = SMSOrder.fromJson(response);
      if (mounted) {
        context.go('/sms/waiting/${order.id}');
      }
    } catch (e) {
      setState(() {
        _isPurchasing = false;
        _error = extractErrorMessage(e, fallback: 'حدث خطأ في إتمام الشراء');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceSoftLight,
      appBar: AppBar(
        title: const Text('تأكيد الطلب'),
        backgroundColor: AppColors.canvasLight,
        surfaceTintColor: AppColors.canvasLight,
      ),
      body: _isLoadingPrice
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _error != null && _price == null
              ? CustomErrorWidget(message: _error!, onRetry: _fetchPrice)
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: AppColors.canvasLight,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.hairlineLight),
                        ),
                        child: Column(
                          children: [
                            Container(
                              width: 64,
                              height: 64,
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Icon(QasehIcons.buy_curved, size: 32, color: AppColors.onPrimary),
                            ),
                            const SizedBox(height: 16),
                            Text('تأكيد شراء الخدمة', style: AppTextStyles.titleMedium.copyWith(color: AppColors.ink)),
                            const SizedBox(height: 24),
                            _buildInfoRow('الخدمة', widget.displayName ?? widget.serviceName),
                            const Divider(height: 24),
                            _buildInfoRow('الدولة', widget.countryName),
                            if (widget.provider != null && widget.provider!.isNotEmpty) ...[
                              const Divider(height: 24),
                              _buildInfoRow('المزود', widget.provider!),
                            ],
                            if (_availableCount != null) ...[
                              const Divider(height: 24),
                              _buildInfoRow('الأرقام المتاحة', '${_availableCount}'),
                            ],
                            const Divider(height: 24),
                            _buildInfoRow(
                              'التكلفة',
                              '${_price?.costCoins ?? 0} عملة',
                              valueStyle: AppTextStyles.titleMedium.copyWith(
                                color: AppColors.onPrimary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      if (_error != null)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: AppColors.error.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Icon(QasehIcons.danger_triangle_curved, size: 20, color: AppColors.error),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(_error!, style: AppTextStyles.caption.copyWith(color: AppColors.error)),
                              ),
                            ],
                          ),
                        ),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _isPurchasing ? null : _purchase,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: AppColors.onPrimary,
                            disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.5),
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: _isPurchasing
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    color: AppColors.onPrimary,
                                  ),
                                )
                              : Text('تأكيد الشراء', style: AppTextStyles.button),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildInfoRow(String label, String value, {TextStyle? valueStyle}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: AppTextStyles.bodyMedium.copyWith(color: AppColors.bodyLight)),
        Text(value, style: valueStyle ?? AppTextStyles.labelMedium.copyWith(color: AppColors.ink)),
      ],
    );
  }
}
