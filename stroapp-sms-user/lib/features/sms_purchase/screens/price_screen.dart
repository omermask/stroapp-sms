import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/widgets/widgets.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/api/endpoints/pricing_api.dart';
import '../../../core/api/api_exceptions.dart';

class PriceScreen extends ConsumerStatefulWidget {
  const PriceScreen({super.key});

  @override
  ConsumerState<PriceScreen> createState() => _PriceScreenState();
}

class _PriceScreenState extends ConsumerState<PriceScreen> {
  Map<String, dynamic>? _pricing;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _fetchPricing());
  }

  Future<void> _fetchPricing() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final pricingApi = ref.read(pricingApiProvider);
      final data = await pricingApi.getMyPricing();
      setState(() {
        _pricing = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = extractErrorMessage(e, fallback: 'حدث خطأ في تحميل الأسعار');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceSoftLight,
      appBar: AppBar(
        title: const Text('الأسعار'),
        backgroundColor: AppColors.canvasLight,
        surfaceTintColor: AppColors.canvasLight,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _error != null
              ? CustomErrorWidget(message: _error!, onRetry: _fetchPricing)
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('تسعيرتي', style: AppTextStyles.titleMedium.copyWith(color: AppColors.ink)),
                      const SizedBox(height: 16),
                      _buildPricingCard(),
                      const SizedBox(height: 24),
                      Text('الخدمات المتاحة', style: AppTextStyles.titleMedium.copyWith(color: AppColors.ink)),
                      const SizedBox(height: 12),
                      _buildServicesList(),
                    ],
                  ),
                ),
    );
  }

  Widget _buildPricingCard() {
    if (_pricing == null) return const SizedBox.shrink();

    final tier = _pricing!['tier']?.toString() ?? '—';
    final name = _pricing!['name']?.toString() ?? '—';
    final price = _pricing!['price']?.toString() ?? '0';
    final currency = _pricing!['currency']?.toString() ?? 'USD';
    final quota = _pricing!['quota']?.toString() ?? 'غير محدود';
    final dailyLimit = _pricing!['daily_limit']?.toString() ?? '—';
    final monthlyLimit = _pricing!['monthly_limit']?.toString() ?? '—';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primary.withValues(alpha: 0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.onPrimary.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(tier.toUpperCase(), style: AppTextStyles.caption.copyWith(color: AppColors.onPrimary, fontWeight: FontWeight.w600)),
              ),
              const Spacer(),
              Text('\$$price $currency', style: AppTextStyles.titleMedium.copyWith(color: AppColors.onPrimary, fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 12),
          Text(name, style: AppTextStyles.bodyLarge.copyWith(color: AppColors.onPrimary)),
          const SizedBox(height: 20),
          _buildPricingRow('الحصة', quota),
          const SizedBox(height: 8),
          _buildPricingRow('الحد اليومي', dailyLimit),
          const SizedBox(height: 8),
          _buildPricingRow('الحد الشهري', monthlyLimit),
        ],
      ),
    );
  }

  Widget _buildPricingRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: AppTextStyles.bodySmall.copyWith(color: AppColors.onPrimary.withValues(alpha: 0.8))),
        Text(value, style: AppTextStyles.labelSmall.copyWith(color: AppColors.onPrimary, fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _buildServicesList() {
    final services = _pricing?['services'] as List<dynamic>?;
    if (services == null || services.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        alignment: Alignment.center,
        child: Text('لا توجد خدمات متاحة', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.mutedStrong)),
      );
    }

    return Column(
      children: services.map((s) {
        final serviceName = s['name']?.toString() ?? '—';
        final servicePrice = s['price']?.toString() ?? '0';
        final serviceCurrency = s['currency']?.toString() ?? 'USD';

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.canvasLight,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.hairlineLight),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(QasehIcons.message_curved, size: 20, color: AppColors.onPrimary),
              ),
              const SizedBox(width: 12),
              Expanded(child: Text(serviceName, style: AppTextStyles.labelMedium.copyWith(color: AppColors.ink))),
              Text('$servicePrice $serviceCurrency', style: AppTextStyles.numberSmall.copyWith(color: AppColors.bluePrimary, fontWeight: FontWeight.w600)),
            ],
          ),
        );
      }).toList(),
    );
  }
}
