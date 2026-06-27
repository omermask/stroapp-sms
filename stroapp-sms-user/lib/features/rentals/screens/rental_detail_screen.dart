import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/widgets/widgets.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/api/endpoints/rentals_api.dart';
import '../../../core/api/api_exceptions.dart';

class RentalDetailScreen extends ConsumerStatefulWidget {
  final String rentalId;

  const RentalDetailScreen({super.key, required this.rentalId});

  @override
  ConsumerState<RentalDetailScreen> createState() => _RentalDetailScreenState();
}

class _RentalDetailScreenState extends ConsumerState<RentalDetailScreen> {
  Map<String, dynamic>? _rental;
  bool _isLoading = true;
  String? _error;
  bool _isExtending = false;
  bool _isCancelling = false;

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
      final data = await ref.read(rentalsApiProvider).getRentalDetail(widget.rentalId);
      if (mounted) setState(() => _rental = data);
    } catch (e) {
      if (mounted) setState(() => _error = extractErrorMessage(e, fallback: 'حدث خطأ في تحميل التفاصيل'));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _extendRental() async {
    final hoursController = TextEditingController();
    final result = await showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تمديد الإيجار'),
        content: TextField(
          controller: hoursController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(hintText: 'عدد الساعات', border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () {
              final hours = int.tryParse(hoursController.text);
              if (hours != null && hours > 0) Navigator.pop(ctx, hours);
            },
            child: const Text('تمديد'),
          ),
        ],
      ),
    );
    if (result == null) return;

    setState(() => _isExtending = true);
    try {
      await ref.read(rentalsApiProvider).extendRental(widget.rentalId, result);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم تمديد الإيجار بنجاح'), backgroundColor: AppColors.success),
        );
        await _fetchDetail();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isExtending = false);
    }
  }

  Future<void> _cancelRental() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('إلغاء الإيجار'),
        content: const Text('هل أنت متأكد من إلغاء هذا الإيجار؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('رجوع')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('تأكيد الإلغاء'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _isCancelling = true);
    try {
      await ref.read(rentalsApiProvider).cancelRental(widget.rentalId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم إلغاء الإيجار'), backgroundColor: AppColors.success),
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
      if (mounted) setState(() => _isCancelling = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceSoftLight,
      appBar: AppBar(
        title: const Text('تفاصيل الإيجار'),
        backgroundColor: AppColors.canvasLight,
        surfaceTintColor: AppColors.canvasLight,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    }

    if (_error != null) {
      return CustomErrorWidget(message: _error!, onRetry: _fetchDetail);
    }

    if (_rental == null) {
      return const EmptyState(icon: QasehIcons.bag_curved, message: 'لم يتم العثور على الإيجار');
    }

    final r = _rental!;
    final service = r['service']?.toString() ?? '—';
    final country = r['country']?.toString() ?? '—';
    final provider = r['provider']?.toString() ?? '—';
    final phone = r['phone_number']?.toString() ?? r['phoneNumber']?.toString() ?? '—';
    final status = r['status']?.toString() ?? '—';
    final cost = r['cost_coins']?.toString() ?? r['costCoins']?.toString() ?? '0';
    final messagesCount = r['messages_count']?.toString() ?? r['messagesCount']?.toString() ?? '0';
    final duration = r['duration_hours']?.toString() ?? r['durationHours']?.toString() ?? '0';
    final autoExtend = r['auto_extend'] == true || r['autoExtend'] == true;
    final expiresAt = r['expires_at'] ?? r['expiresAt'];
    final createdAt = r['created_at'] ?? r['createdAt'];

    final statusColor = _statusColor(status);
    final statusText = _statusText(status);

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: _fetchDetail,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
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
                    child: Icon(QasehIcons.message_curved, size: 32, color: AppColors.primary),
                  ),
                  const SizedBox(height: 16),
                  Text(service, style: AppTextStyles.headlineMedium.copyWith(color: AppColors.ink)),
                  const SizedBox(height: 8),
                  Text(phone, style: AppTextStyles.displaySmall.copyWith(color: AppColors.ink)),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      statusText,
                      style: AppTextStyles.labelMedium.copyWith(color: statusColor, fontWeight: FontWeight.w600),
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
                  _detailRow('الدولة', country),
                  _detailRow('المزود', provider),
                  _detailRow('المدة', '$duration ساعة'),
                  _detailRow('التمديد التلقائي', autoExtend ? 'مفعل' : 'غير مفعل'),
                  _detailRow('التكلفة', '$cost عملة'),
                  _detailRow('عدد الرسائل', messagesCount),
                  if (expiresAt != null) _detailRow('ينتهي في', expiresAt.toString()),
                  if (createdAt != null) _detailRow('تاريخ الإنشاء', createdAt.toString()),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isExtending ? null : _extendRental,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.onPrimary,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: _isExtending
                          ? const SizedBox(
                              width: 30,
                              height: 30,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                valueColor: AlwaysStoppedAnimation<Color>(AppColors.onPrimary),
                              ),
                            )
                          : Text('تمديد', style: AppTextStyles.button),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SizedBox(
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isCancelling ? null : _cancelRental,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.error,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: _isCancelling
                          ? const SizedBox(
                              width: 30,
                              height: 30,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : Text('إلغاء', style: AppTextStyles.button),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () => context.push('/rentals/${widget.rentalId}/messages'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.hairlineLight,
                  foregroundColor: AppColors.ink,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text('عرض الرسائل', style: AppTextStyles.button.copyWith(color: AppColors.ink)),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Text(label, style: AppTextStyles.bodyMedium.copyWith(color: AppColors.mutedStrong)),
          const Spacer(),
          Text(value, style: AppTextStyles.labelMedium.copyWith(color: AppColors.ink)),
        ],
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return AppColors.success;
      case 'expired':
        return AppColors.mutedStrong;
      case 'cancelled':
        return AppColors.error;
      default:
        return AppColors.warning;
    }
  }

  String _statusText(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return 'نشط';
      case 'expired':
        return 'منتهي';
      case 'cancelled':
        return 'ملغي';
      default:
        return status;
    }
  }
}
