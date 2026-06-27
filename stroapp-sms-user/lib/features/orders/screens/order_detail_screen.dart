import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/widgets/widgets.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/models/sms_order.dart';
import '../../../core/api/endpoints/purchase_api.dart';
import '../../../core/api/api_exceptions.dart';

class OrderDetailScreen extends ConsumerStatefulWidget {
  final String orderId;
  const OrderDetailScreen({super.key, required this.orderId});

  @override
  ConsumerState<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends ConsumerState<OrderDetailScreen> {
  SMSOrder? _order;
  bool _isLoading = true;
  bool _isCancelling = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _fetchDetail());
  }

  Future<void> _fetchDetail() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final purchaseApi = ref.read(purchaseApiProvider);
      final response = await purchaseApi.getOrderDetail(widget.orderId);
      final order = SMSOrder.fromJson(response);
      setState(() {
        _order = order;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = extractErrorMessage(e, fallback: 'حدث خطأ في تحميل التفاصيل');
      });
    }
  }

  Future<void> _cancelOrder() async {
    setState(() => _isCancelling = true);
    try {
      final purchaseApi = ref.read(purchaseApiProvider);
      await purchaseApi.cancelOrder(widget.orderId);
      _fetchDetail();
    } catch (e) {
      setState(() => _isCancelling = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(extractErrorMessage(e, fallback: 'حدث خطأ في الإلغاء'))),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceSoftLight,
      appBar: AppBar(
        title: const Text('تفاصيل الطلب'),
        backgroundColor: AppColors.canvasLight,
        surfaceTintColor: AppColors.canvasLight,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _error != null
              ? CustomErrorWidget(message: _error!, onRetry: _fetchDetail)
              : RefreshIndicator(
                  color: AppColors.primary,
                  onRefresh: _fetchDetail,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    child: _order == null ? const SizedBox.shrink() : _buildContent(),
                  ),
                ),
    );
  }

  Widget _buildContent() {
    final order = _order!;
    final isPending = order.status == 'pending' || order.status == 'waiting';

    return Column(
      children: [
        if (order.verificationCode != null)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.canvasLight,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.primary),
            ),
            child: Column(
              children: [
                Text('رمز التحقق', style: AppTextStyles.caption.copyWith(color: AppColors.mutedStrong)),
                const SizedBox(height: 12),
                Directionality(
                  textDirection: TextDirection.ltr,
                  child: SelectableText(
                    order.verificationCode!,
                    style: AppTextStyles.displayLarge.copyWith(
                      color: AppColors.onPrimary,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 4,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('تم نسخ الرمز')),
                    );
                  },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(QasehIcons.document_curved, size: 16, color: AppColors.bluePrimary),
                      const SizedBox(width: 4),
                      Text('نسخ الرمز', style: AppTextStyles.labelSmall.copyWith(color: AppColors.bluePrimary)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.canvasLight,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.hairlineLight),
          ),
          child: Column(
            children: [
              _buildDetailRow('الخدمة', order.serviceName ?? order.service),
              const Divider(height: 20),
              _buildDetailRow('الدولة', order.countryName ?? order.country),
              const Divider(height: 20),
              _buildDetailRow('المزود', order.provider),
              const Divider(height: 20),
              _buildDetailRow(
                'رقم الهاتف',
                order.phoneNumber,
                textDirection: TextDirection.ltr,
              ),
              const Divider(height: 20),
              _buildDetailRow('التكلفة', '${order.costCoins} عملة'),
              const Divider(height: 20),
              _buildDetailRow('الحالة', _statusText(order)),
              if (order.smsText != null && order.smsText!.isNotEmpty) ...[
                const Divider(height: 20),
                _buildDetailRow('نص الرسالة', order.smsText!),
              ],
              if (order.smsReceivedAt != null) ...[
                const Divider(height: 20),
                _buildDetailRow('وقت الاستلام', _formatDateTime(order.smsReceivedAt!)),
              ],
              const Divider(height: 20),
              _buildDetailRow('تاريخ الطلب', _formatDateTime(order.createdAt)),
            ],
          ),
        ),
        if (isPending) ...[
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: OutlinedButton(
              onPressed: _isCancelling ? null : _cancelOrder,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.error,
                side: const BorderSide(color: AppColors.error),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _isCancelling
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2.5, color: AppColors.error),
                    )
                  : const Text('إلغاء الطلب', style: AppTextStyles.button),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildDetailRow(String label, String value, {TextDirection? textDirection}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(label, style: AppTextStyles.caption.copyWith(color: AppColors.mutedStrong)),
        ),
        Expanded(
          child: Text(
            value,
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.ink),
            textDirection: textDirection,
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }

  String _statusText(SMSOrder order) {
    if (order.status == 'completed' || order.status == 'done') return 'مكتمل';
    if (order.status == 'pending' || order.status == 'waiting') return 'بانتظار الرسالة';
    if (order.status == 'cancelled' || order.status == 'canceled') return 'ملغي';
    if (order.refunded == true) return 'مسترجع';
    return order.status;
  }

  String _formatDateTime(DateTime dt) {
    return '${dt.year}/${dt.month}/${dt.day} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}
