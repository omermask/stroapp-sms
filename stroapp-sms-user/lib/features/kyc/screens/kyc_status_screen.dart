import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/widgets/widgets.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/api/endpoints/kyc_api.dart';
import '../providers/kyc_provider.dart';

class KycStatusScreen extends ConsumerStatefulWidget {
  const KycStatusScreen({super.key});

  @override
  ConsumerState<KycStatusScreen> createState() => _KycStatusScreenState();
}

class _KycStatusScreenState extends ConsumerState<KycStatusScreen> {
  bool _limitsLoading = false;
  Map<String, dynamic>? _limits;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(kycProvider.notifier).fetchStatus();
      _fetchLimits();
    });
  }

  Future<void> _fetchLimits() async {
    setState(() => _limitsLoading = true);
    try {
      final api = ref.read(kycApiProvider);
      final limits = await api.getKycLimits();
      setState(() => _limits = limits);
    } catch (_) {
    } finally {
      setState(() => _limitsLoading = false);
    }
  }

  Color _statusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'verified':
      case 'موثق':
        return AppColors.success;
      case 'pending':
      case 'قيد المراجعة':
        return AppColors.warning;
      case 'rejected':
      case 'مرفوض':
        return AppColors.error;
      case 'suspended':
      case 'موقوف':
        return AppColors.errorDark;
      case 'not_submitted':
      case 'لم يتم التقديم':
        return AppColors.muted;
      default:
        return AppColors.muted;
    }
  }

  IconData _statusIcon(String? status) {
    switch (status?.toLowerCase()) {
      case 'verified':
        return QasehIcons.shield_done_filled;
      case 'pending':
        return QasehIcons.time_circle_curved;
      case 'rejected':
        return QasehIcons.shield_fail_filled;
      case 'suspended':
        return QasehIcons.danger_triangle_curved;
      default:
        return QasehIcons.shield_done_light;
    }
  }

  String _statusLabel(String? status) {
    switch (status?.toLowerCase()) {
      case 'verified':
        return 'تم التحقق';
      case 'pending':
        return 'قيد المراجعة';
      case 'rejected':
        return 'مرفوض';
      case 'suspended':
        return 'موقوف';
      case 'not_submitted':
        return 'لم يتم التقديم';
      default:
        return 'غير معروف';
    }
  }

  @override
  Widget build(BuildContext context) {
    final kycState = ref.watch(kycProvider);

    return Scaffold(
      backgroundColor: AppColors.surfaceSoftLight,
      appBar: AppBar(
        title: const Text('حالة التحقق'),
        backgroundColor: AppColors.canvasLight,
        surfaceTintColor: AppColors.canvasLight,
      ),
      body: kycState.isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : kycState.error != null
              ? CustomErrorWidget(
                  message: kycState.error!,
                  onRetry: () {
                    ref.read(kycProvider.notifier).fetchStatus();
                    _fetchLimits();
                  },
                )
              : kycState.status == null || kycState.status == 'not_submitted'
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(QasehIcons.shield_done_light, size: 80, color: AppColors.mutedStrong),
                            const SizedBox(height: 24),
                            Text(
                              'لم تقم بتقديم طلب التحقق بعد',
                              style: AppTextStyles.titleMedium.copyWith(color: AppColors.ink),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'يرجى إكمال نموذج التحقق للاستفادة من جميع الخدمات',
                              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.mutedStrong),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 24),
                            SizedBox(
                              width: 200,
                              height: 50,
                              child: ElevatedButton(
                                onPressed: () => context.push('/kyc/form'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: AppColors.onPrimary,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                child: Text('تقديم الطلب', style: AppTextStyles.button),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : RefreshIndicator(
                      color: AppColors.primary,
                      onRefresh: () async {
                        await ref.read(kycProvider.notifier).fetchStatus();
                        await _fetchLimits();
                      },
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: AppColors.canvasLight,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: AppColors.hairlineLight),
                              ),
                              child: Column(
                                children: [
                                  Icon(
                                    _statusIcon(kycState.status),
                                    size: 64,
                                    color: _statusColor(kycState.status),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    _statusLabel(kycState.status),
                                    style: AppTextStyles.titleLarge.copyWith(
                                      color: _statusColor(kycState.status),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: _statusColor(kycState.status).withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      'مستوى التحقق: ${kycState.profile?.verificationLevel ?? 'غير محدد'}',
                                      style: AppTextStyles.labelSmall.copyWith(
                                        color: _statusColor(kycState.status),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            if (_limitsLoading)
                              const Padding(
                                padding: EdgeInsets.all(24),
                                child: CircularProgressIndicator(color: AppColors.primary),
                              )
                            else if (_limits != null)
                              Container(
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
                                        Icon(QasehIcons.graph_curved, size: 20, color: AppColors.ink),
                                        const SizedBox(width: 8),
                                        Text('الحدود والصلاحيات', style: AppTextStyles.titleSmall.copyWith(color: AppColors.ink)),
                                      ],
                                    ),
                                    const SizedBox(height: 16),
                                    if (_limits!['daily_limit'] != null)
                                      _buildLimitRow(
                                        'الحد اليومي',
                                        _limits!['daily_limit'].toString(),
                                      ),
                                    if (_limits!['monthly_limit'] != null)
                                      _buildLimitRow(
                                        'الحد الشهري',
                                        _limits!['monthly_limit'].toString(),
                                      ),
                                    if (_limits!['max_balance'] != null)
                                      _buildLimitRow(
                                        'الحد الأقصى للرصيد',
                                        _limits!['max_balance'].toString(),
                                      ),
                                    if (_limits!['sms_limit'] != null)
                                      _buildLimitRow(
                                        'حد الرسائل',
                                        _limits!['sms_limit'].toString(),
                                      ),
                                  ],
                                ),
                              ),
                            const SizedBox(height: 16),
                            if (kycState.status?.toLowerCase() == 'rejected')
                              SizedBox(
                                width: double.infinity,
                                height: 50,
                                child: ElevatedButton(
                                  onPressed: () => context.push('/kyc/form'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primary,
                                    foregroundColor: AppColors.onPrimary,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                  child: Text('إعادة تقديم الطلب', style: AppTextStyles.button),
                                ),
                              ),
                            if (kycState.profile != null)
                              SizedBox(
                                width: double.infinity,
                                height: 50,
                                child: OutlinedButton(
                                  onPressed: () => context.push('/kyc/form'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: AppColors.ink,
                                    side: BorderSide(color: AppColors.hairlineLight),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                  child: Text('تعديل البيانات', style: AppTextStyles.button),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
    );
  }

  Widget _buildLimitRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Text(label, style: AppTextStyles.bodyMedium.copyWith(color: AppColors.mutedStrong)),
          const Spacer(),
          Text(value, style: AppTextStyles.labelMedium.copyWith(color: AppColors.ink)),
        ],
      ),
    );
  }
}
