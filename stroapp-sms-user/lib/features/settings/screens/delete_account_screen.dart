import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/widgets/widgets.dart';
import '../../../shared/widgets/mfa_verify_dialog.dart';
import '../../../core/api/api_exceptions.dart';
import '../../../core/services/mfa_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../providers/settings_provider.dart';
import '../../auth/providers/auth_provider.dart';

class DeleteAccountScreen extends ConsumerStatefulWidget {
  const DeleteAccountScreen({super.key});

  @override
  ConsumerState<DeleteAccountScreen> createState() => _DeleteAccountScreenState();
}

class _DeleteAccountScreenState extends ConsumerState<DeleteAccountScreen> {
  final _confirmController = TextEditingController();
  bool _isDeleting = false;
  String? _error;

  static const _confirmText = 'DELETE';

  @override
  void dispose() {
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _deleteAccount() async {
    if (_confirmController.text.trim() != _confirmText) {
      setState(() { _error = 'يرجى كتابة "$_confirmText" للتأكيد'; });
      return;
    }
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.canvasLight,
        title: const Text('تأكيد حذف الحساب', style: AppTextStyles.titleMedium),
        content: const Text('هذا الإجراء نهائي ولا يمكن التراجع عنه. هل أنت متأكد؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('إلغاء', style: TextStyle(color: AppColors.mutedStrong)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('نعم، احذف حسابي', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    setState(() { _isDeleting = true; _error = null; });
    ref.read(settingsProvider.notifier).clearError();

    await _doDeleteAccount();
  }

  Future<void> _doDeleteAccount() async {
    try {
      await ref.read(settingsProvider.notifier).deleteAccount();
      final settingsState = ref.read(settingsProvider);
      if (settingsState.error != null) {
        if (mounted) setState(() { _error = settingsState.error; _isDeleting = false; });
      } else if (mounted) {
        ref.read(authProvider.notifier).logout();
        context.go('/login');
      }
    } on MfaRequiredException {
      if (!mounted) return;
      setState(() => _isDeleting = false);
      final token = await showDialog<String>(
        context: context,
        barrierDismissible: false,
        builder: (_) => const MfaVerifyDialog(),
      );
      if (token != null && mounted) {
        ref.read(mfaTokenProvider.notifier).state = token;
        setState(() => _isDeleting = true);
        await _doDeleteAccount();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final settingsState = ref.watch(settingsProvider);

    return Scaffold(
      backgroundColor: AppColors.surfaceSoftLight,
      appBar: AppBar(
        title: const Text('حذف الحساب'),
        backgroundColor: AppColors.canvasLight,
        surfaceTintColor: AppColors.canvasLight,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(QasehIcons.danger_triangle_curved, size: 32, color: AppColors.error),
            ),
            const SizedBox(height: 20),
            Text(
              'حذف الحساب',
              style: AppTextStyles.titleLarge.copyWith(color: AppColors.ink),
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.canvasLight,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(QasehIcons.info_square_curved, size: 18, color: AppColors.error),
                      const SizedBox(width: 8),
                      Text('تحذير', style: AppTextStyles.labelMedium.copyWith(color: AppColors.error)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'عند حذف حسابك:',
                    style: AppTextStyles.bodyMedium.copyWith(color: AppColors.ink),
                  ),
                  const SizedBox(height: 8),
                  _warningItem('سيتم حذف جميع بياناتك بشكل نهائي'),
                  _warningItem('لن تتمكن من استعادة حسابك'),
                  _warningItem('سيتم إلغاء جميع الاشتراكات النشطة'),
                  _warningItem('لن نتمكن من استرجاع رصيدك'),
                ],
              ),
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'للتأكيد، اكتب "$_confirmText" في الحقل أدناه',
                    style: AppTextStyles.labelMedium.copyWith(color: AppColors.ink),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _confirmController,
                    style: AppTextStyles.bodyMedium.copyWith(color: AppColors.ink),
                    decoration: InputDecoration(
                      hintText: 'اكتب $_confirmText',
                      hintStyle: AppTextStyles.bodyMedium.copyWith(color: AppColors.mutedStrong),
                      filled: true,
                      fillColor: AppColors.surfaceSoftLight,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: AppColors.hairlineLight),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: AppColors.hairlineLight),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: AppColors.error),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                    ),
                  ),
                ],
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Icon(QasehIcons.danger_triangle_curved, size: 18, color: AppColors.error),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(_error!, style: AppTextStyles.caption.copyWith(color: AppColors.error)),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: (settingsState.isLoading || _isDeleting) ? null : _deleteAccount,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.error,
                  foregroundColor: AppColors.onDark,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: (settingsState.isLoading || _isDeleting)
                    ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.onDark))
                    : const Text('حذف الحساب', style: AppTextStyles.button),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _warningItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(QasehIcons.close_square_curved, size: 16, color: AppColors.error),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text, style: AppTextStyles.bodySmall.copyWith(color: AppColors.mutedStrong)),
          ),
        ],
      ),
    );
  }
}
