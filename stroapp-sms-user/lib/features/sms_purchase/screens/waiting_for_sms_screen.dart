import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/widgets/widgets.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/models/sms_order.dart';
import '../../../core/api/endpoints/purchase_api.dart';
import '../../../core/api/api_exceptions.dart';

class WaitingForSmsScreen extends ConsumerStatefulWidget {
  final String orderId;
  const WaitingForSmsScreen({super.key, required this.orderId});

  @override
  ConsumerState<WaitingForSmsScreen> createState() => _WaitingForSmsScreenState();
}

class _WaitingForSmsScreenState extends ConsumerState<WaitingForSmsScreen> {
  SMSOrder? _order;
  bool _isLoading = true;
  bool _isCancelling = false;
  String? _error;
  Timer? _pollTimer;
  int _elapsedSeconds = 0;
  Timer? _elapsedTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchOrder();
      _startPolling();
    });
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _elapsedTimer?.cancel();
    super.dispose();
  }

  Future<void> _fetchOrder() async {
    try {
      final purchaseApi = ref.read(purchaseApiProvider);
      final response = await purchaseApi.getOrderDetail(widget.orderId);
      final order = SMSOrder.fromJson(response);
      setState(() {
        _order = order;
        _isLoading = false;
        _error = null;
      });
      if (order.verificationCode != null || order.status == 'completed' || order.status == 'done') {
        _pollTimer?.cancel();
        _elapsedTimer?.cancel();
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = extractErrorMessage(e, fallback: 'حدث خطأ');
      });
    }
  }

  void _startPolling() {
    _pollTimer = Timer.periodic(const Duration(seconds: 5), (_) => _fetchOrder());
    _elapsedTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _elapsedSeconds++);
    });
  }

  Future<void> _cancelOrder() async {
    setState(() => _isCancelling = true);
    try {
      final purchaseApi = ref.read(purchaseApiProvider);
      await purchaseApi.cancelOrder(widget.orderId);
      if (mounted) context.go('/orders');
    } catch (e) {
      setState(() => _isCancelling = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(extractErrorMessage(e, fallback: 'حدث خطأ في الإلغاء'))),
        );
      }
    }
  }

  bool get _isComplete => _order?.verificationCode != null || _order?.status == 'completed' || _order?.status == 'done';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceSoftLight,
      appBar: AppBar(
        title: const Text('انتظار الرسالة'),
        backgroundColor: AppColors.canvasLight,
        surfaceTintColor: AppColors.canvasLight,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/orders'),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _error != null && _order == null
              ? CustomErrorWidget(message: _error!, onRetry: _fetchOrder)
              : Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (_isComplete)
                          _buildSuccessState()
                        else
                          _buildWaitingState(),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildWaitingState() {
    final minutes = _elapsedSeconds ~/ 60;
    final seconds = _elapsedSeconds % 60;
    final timeStr = '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';

    return Column(
      children: [
        const SizedBox(height: 40),
        SizedBox(
          width: 100,
          height: 100,
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 100,
                height: 100,
                child: CircularProgressIndicator(
                  strokeWidth: 4,
                  color: AppColors.primary,
                  backgroundColor: AppColors.hairlineLight,
                ),
              ),
              Icon(QasehIcons.message_curved, size: 40, color: AppColors.onPrimary),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Text('بانتظار الرسالة النصية', style: AppTextStyles.titleMedium.copyWith(color: AppColors.ink)),
        const SizedBox(height: 8),
        Text(
          'سيتم التحقق من وصول الرسالة تلقائياً',
          style: AppTextStyles.bodyMedium.copyWith(color: AppColors.bodyLight),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),
        if (_order != null)
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
                Text('رقم الهاتف', style: AppTextStyles.caption.copyWith(color: AppColors.mutedStrong)),
                const SizedBox(height: 8),
                Directionality(
                  textDirection: TextDirection.ltr,
                  child: Text(
                    _order!.phoneNumber,
                    style: AppTextStyles.displaySmall.copyWith(color: AppColors.ink, letterSpacing: 2),
                  ),
                ),
                const SizedBox(height: 16),
                Text('الوقت المنقضي', style: AppTextStyles.caption.copyWith(color: AppColors.mutedStrong)),
                const SizedBox(height: 4),
                Text(timeStr, style: AppTextStyles.titleMedium.copyWith(color: AppColors.ink)),
              ],
            ),
          ),
        const SizedBox(height: 32),
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
                : Text('إلغاء الطلب', style: AppTextStyles.button),
          ),
        ),
      ],
    );
  }

  Widget _buildSuccessState() {
    return Column(
      children: [
        const SizedBox(height: 40),
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            color: AppColors.success.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(QasehIcons.tick_square_curved, size: 48, color: AppColors.success),
        ),
        const SizedBox(height: 24),
        Text('تم استلام الرسالة!', style: AppTextStyles.titleMedium.copyWith(color: AppColors.ink)),
        const SizedBox(height: 8),
        Text(
          'رمز التحقق الخاص بك جاهز',
          style: AppTextStyles.bodyMedium.copyWith(color: AppColors.bodyLight),
        ),
        const SizedBox(height: 32),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
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
                  _order!.verificationCode ?? '------',
                  style: AppTextStyles.displayLarge.copyWith(
                    color: AppColors.onPrimary,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 4,
                  ),
                ),
              ),
              if (_order!.smsText != null && _order!.smsText!.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 12),
                Text(
                  'نص الرسالة',
                  style: AppTextStyles.caption.copyWith(color: AppColors.mutedStrong),
                ),
                const SizedBox(height: 8),
                Text(
                  _order!.smsText!,
                  style: AppTextStyles.bodyMedium.copyWith(color: AppColors.ink),
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 32),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: () => context.go('/orders/${widget.orderId}'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.onPrimary,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('عرض تفاصيل الطلب', style: AppTextStyles.button),
          ),
        ),
      ],
    );
  }
}
