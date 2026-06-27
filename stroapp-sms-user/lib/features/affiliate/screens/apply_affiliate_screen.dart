import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/widgets/widgets.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/api/endpoints/affiliate_api.dart';
import '../../../core/api/api_exceptions.dart';

class ApplyAffiliateScreen extends ConsumerStatefulWidget {
  const ApplyAffiliateScreen({super.key});

  @override
  ConsumerState<ApplyAffiliateScreen> createState() => _ApplyAffiliateScreenState();
}

class _ApplyAffiliateScreenState extends ConsumerState<ApplyAffiliateScreen> {
  bool _isChecking = true;
  Map<String, dynamic>? _application;
  bool _isSubmitting = false;
  String? _error;

  String _selectedType = 'referral';
  final _messageController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkApplication());
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _checkApplication() async {
    setState(() {
      _isChecking = true;
      _error = null;
    });
    try {
      final data = await ref.read(affiliateApiProvider).getApplication();
      if (mounted) setState(() => _application = data);
    } on ApiException catch (e) {
      if (e.statusCode == 404 && mounted) {
        setState(() => _application = null);
      } else if (mounted) {
        setState(() => _error = e.message);
      }
    } catch (e) {
      if (mounted) setState(() => _error = extractErrorMessage(e, fallback: 'حدث خطأ'));
    } finally {
      if (mounted) setState(() => _isChecking = false);
    }
  }

  Future<void> _submit() async {
    if (_selectedType.isEmpty) return;

    setState(() {
      _isSubmitting = true;
      _error = null;
    });
    try {
      await ref.read(affiliateApiProvider).apply(
        _selectedType,
        _messageController.text.trim().isEmpty ? null : _messageController.text.trim(),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم تقديم الطلب بنجاح'), backgroundColor: AppColors.success),
        );
        await _checkApplication();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _error = extractErrorMessage(e, fallback: 'حدث خطأ في تقديم الطلب'));
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
        title: const Text('التسجيل في التسويق'),
        backgroundColor: AppColors.canvasLight,
        surfaceTintColor: AppColors.canvasLight,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isChecking) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    }

    if (_error != null && _application == null) {
      return CustomErrorWidget(message: _error!, onRetry: _checkApplication);
    }

    if (_application != null) {
      return _buildApplicationStatus();
    }

    return _buildApplicationForm();
  }

  Widget _buildApplicationStatus() {
    final status = _application!['status']?.toString() ?? 'pending';
    final type = _application!['program_type']?.toString() ?? _application!['programType']?.toString() ?? '—';
    final message = _application!['message']?.toString() ?? '';
    final createdAt = _application!['created_at']?.toString() ?? _application!['createdAt']?.toString() ?? '';

    final statusColor = status == 'approved' ? AppColors.success : (status == 'rejected' ? AppColors.error : AppColors.warning);
    final statusText = status == 'approved' ? 'تمت الموافقة' : (status == 'rejected' ? 'مرفوض' : 'قيد المراجعة');

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const SizedBox(height: 40),
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              status == 'approved'
                  ? QasehIcons.tick_square_curved
                  : (status == 'rejected' ? QasehIcons.close_square_curved : QasehIcons.time_circle_curved),
              size: 40,
              color: statusColor,
            ),
          ),
          const SizedBox(height: 24),
          Text('حالة الطلب', style: AppTextStyles.titleMedium.copyWith(color: AppColors.ink)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(statusText, style: AppTextStyles.labelLarge.copyWith(color: statusColor)),
          ),
          const SizedBox(height: 24),
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
                _detailRow('نوع البرنامج', type),
                if (message.isNotEmpty) _detailRow('الرسالة', message),
                if (createdAt.isNotEmpty) _detailRow('تاريخ التقديم', createdAt),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildApplicationForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primary, AppColors.primaryDark],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(QasehIcons.ticket_star_curved, size: 28, color: AppColors.onPrimary),
                const SizedBox(height: 12),
                Text(
                  'انضم لبرنامج التسويق',
                  style: AppTextStyles.headlineMedium.copyWith(color: AppColors.onPrimary),
                ),
                const SizedBox(height: 4),
                Text(
                  'اربح عمولات عن طريق دعوة الآخرين',
                  style: AppTextStyles.bodySmall.copyWith(color: AppColors.onPrimary.withValues(alpha: 0.8)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text('نوع البرنامج', style: AppTextStyles.titleSmall.copyWith(color: AppColors.ink)),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            initialValue: _selectedType,
            decoration: InputDecoration(
              filled: true,
              fillColor: AppColors.canvasLight,
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
            items: const [
              DropdownMenuItem(value: 'referral', child: Text('إحالة')),
              DropdownMenuItem(value: 'commission', child: Text('عمولة')),
              DropdownMenuItem(value: 'revenue_share', child: Text('حصة إيرادات')),
            ],
            onChanged: (v) {
              if (v != null) setState(() => _selectedType = v);
            },
          ),
          const SizedBox(height: 20),
          Text('رسالة (اختياري)', style: AppTextStyles.titleSmall.copyWith(color: AppColors.ink)),
          const SizedBox(height: 8),
          TextFormField(
            controller: _messageController,
            maxLines: 4,
            decoration: InputDecoration(
              hintText: 'اكتب رسالتك هنا...',
              filled: true,
              fillColor: AppColors.canvasLight,
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
          if (_error != null) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(_error!, style: AppTextStyles.caption.copyWith(color: AppColors.error)),
            ),
          ],
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _submit,
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
                  : Text('تقديم الطلب', style: AppTextStyles.button),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
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
