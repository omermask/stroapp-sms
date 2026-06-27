import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/widgets/widgets.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/api/endpoints/affiliate_api.dart';
import '../../../core/api/api_exceptions.dart';

class PayoutScreen extends ConsumerStatefulWidget {
  const PayoutScreen({super.key});

  @override
  ConsumerState<PayoutScreen> createState() => _PayoutScreenState();
}

class _PayoutScreenState extends ConsumerState<PayoutScreen> {
  List<Map<String, dynamic>> _payouts = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  String? _error;
  int _currentPage = 1;
  bool _hasMore = true;
  static const int _perPage = 20;

  final _amountController = TextEditingController();
  String _paymentMethod = 'bank';
  final _detailsController = TextEditingController(text: '{}');
  bool _isSubmitting = false;

  final _paymentMethods = [
    {'key': 'bank', 'label': 'بنك'},
    {'key': 'paypal', 'label': 'PayPal'},
    {'key': 'crypto', 'label': 'عملة رقمية'},
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _fetchPayouts());
  }

  @override
  void dispose() {
    _amountController.dispose();
    _detailsController.dispose();
    super.dispose();
  }

  Future<void> _fetchPayouts({bool refresh = false}) async {
    if (refresh) {
      setState(() {
        _currentPage = 1;
        _hasMore = true;
      });
    }

    setState(() {
      _isLoading = refresh || _payouts.isEmpty;
      _error = null;
    });

    try {
      final data = await ref.read(affiliateApiProvider).getPayouts(_currentPage, _perPage);
      final list = (data['data'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ?? [];

      if (mounted) {
        setState(() {
          if (refresh || _currentPage == 1) {
            _payouts = list;
          } else {
            _payouts.addAll(list);
          }
          _hasMore = list.length >= _perPage;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = extractErrorMessage(e, fallback: 'حدث خطأ في تحميل طلبات السحب');
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore || !_hasMore) return;
    setState(() {
      _isLoadingMore = true;
      _currentPage++;
    });
    await _fetchPayouts();
    if (mounted) setState(() => _isLoadingMore = false);
  }

  Future<void> _requestPayout() async {
    final amountText = _amountController.text.trim();
    final amount = double.tryParse(amountText);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى إدخال مبلغ صحيح'), backgroundColor: AppColors.error),
      );
      return;
    }

    Map<String, dynamic> details;
    try {
      details = _detailsController.text.trim().isEmpty ? {} : Map<String, dynamic>.from(
        Map.fromEntries(
          _detailsController.text.trim().split(',').map((s) {
            final parts = s.split(':');
            return MapEntry(parts[0].trim(), parts.length > 1 ? parts[1].trim() : '');
          }),
        ),
      );
    } catch (_) {
      details = {};
    }

    setState(() => _isSubmitting = true);
    try {
      await ref.read(affiliateApiProvider).requestPayout(amount, _paymentMethod, details);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم تقديم طلب السحب بنجاح'), backgroundColor: AppColors.success),
        );
        _amountController.clear();
        _detailsController.text = '{}';
        await _fetchPayouts(refresh: true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceSoftLight,
      appBar: AppBar(
        title: const Text('السحب'),
        backgroundColor: AppColors.canvasLight,
        surfaceTintColor: AppColors.canvasLight,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () => _fetchPayouts(refresh: true),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildRequestForm(),
            const SizedBox(height: 24),
            Text('سجل السحب', style: AppTextStyles.titleSmall.copyWith(color: AppColors.ink)),
            const SizedBox(height: 12),
            if (_isLoading && _payouts.isEmpty)
              const Padding(
                padding: EdgeInsets.all(32),
                child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
              )
            else if (_error != null && _payouts.isEmpty)
              CustomErrorWidget(message: _error!, onRetry: () => _fetchPayouts(refresh: true))
            else if (_payouts.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 32),
                decoration: BoxDecoration(
                  color: AppColors.canvasLight,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.hairlineLight),
                ),
                child: Column(
                  children: [
                    Icon(QasehIcons.wallet_curved, size: 40, color: AppColors.mutedStrong),
                    const SizedBox(height: 8),
                    Text('لا توجد طلبات سحب', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.mutedStrong)),
                  ],
                ),
              )
            else
              ...List.generate(_payouts.length, (index) {
                if (index == _payouts.length - 1 && _hasMore) {
                  WidgetsBinding.instance.addPostFrameCallback((_) => _loadMore());
                }
                return _buildPayoutCard(_payouts[index]);
              }),
            if (_isLoadingMore)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
              ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildRequestForm() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.canvasLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.hairlineLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(QasehIcons.wallet_curved, size: 20, color: AppColors.ink),
              const SizedBox(width: 8),
              Text('طلب سحب جديد', style: AppTextStyles.titleSmall.copyWith(color: AppColors.ink)),
            ],
          ),
          const SizedBox(height: 16),
          Text('المبلغ', style: AppTextStyles.labelMedium.copyWith(color: AppColors.ink)),
          const SizedBox(height: 8),
          TextField(
            controller: _amountController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              hintText: 'أدخل المبلغ',
              filled: true,
              fillColor: AppColors.surfaceStrongLight,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppColors.hairlineLight),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppColors.hairlineLight),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.bluePrimary, width: 1.5),
              ),
            ),
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.ink),
          ),
          const SizedBox(height: 16),
          Text('طريقة الدفع', style: AppTextStyles.labelMedium.copyWith(color: AppColors.ink)),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            initialValue: _paymentMethod,
            decoration: InputDecoration(
              filled: true,
              fillColor: AppColors.surfaceStrongLight,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppColors.hairlineLight),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppColors.hairlineLight),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.bluePrimary, width: 1.5),
              ),
            ),
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.ink),
            items: _paymentMethods.map((m) {
              return DropdownMenuItem(value: m['key'], child: Text(m['label'] as String));
            }).toList(),
            onChanged: (v) {
              if (v != null) setState(() => _paymentMethod = v);
            },
          ),
          const SizedBox(height: 16),
          Text('تفاصيل الدفع (JSON)', style: AppTextStyles.labelMedium.copyWith(color: AppColors.ink)),
          const SizedBox(height: 8),
          TextField(
            controller: _detailsController,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'مفتاح: قيمة, مفتاح2: قيمة2',
              filled: true,
              fillColor: AppColors.surfaceStrongLight,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppColors.hairlineLight),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppColors.hairlineLight),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.bluePrimary, width: 1.5),
              ),
            ),
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.ink),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _requestPayout,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.onPrimary,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      width: 30,
                      height: 30,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor: AlwaysStoppedAnimation<Color>(AppColors.onPrimary),
                      ),
                    )
                  : Text('طلب السحب', style: AppTextStyles.button),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPayoutCard(Map<String, dynamic> payout) {
    final amount = payout['amount']?.toString() ?? '0';
    final status = payout['status']?.toString() ?? '—';
    final paymentMethod = payout['payment_method']?.toString() ?? payout['paymentMethod']?.toString() ?? '—';
    final createdAt = payout['created_at']?.toString() ?? payout['createdAt']?.toString() ?? '';

    final statusColor = status == 'paid'
        ? AppColors.success
        : (status == 'approved' ? AppColors.bluePrimary : (status == 'rejected' ? AppColors.error : AppColors.warning));
    final statusText = status == 'paid'
        ? 'مدفوع'
        : (status == 'approved' ? 'مقبول' : (status == 'rejected' ? 'مرفوض' : 'معلق'));

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
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
            child: Icon(QasehIcons.wallet_curved, size: 20, color: AppColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(amount, style: AppTextStyles.numberMedium.copyWith(color: AppColors.ink)),
                const SizedBox(height: 2),
                Text(paymentMethod, style: AppTextStyles.caption.copyWith(color: AppColors.mutedStrong)),
                if (createdAt.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(createdAt, style: AppTextStyles.caption.copyWith(color: AppColors.mutedStrong)),
                  ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              statusText,
              style: AppTextStyles.caption.copyWith(color: statusColor, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
