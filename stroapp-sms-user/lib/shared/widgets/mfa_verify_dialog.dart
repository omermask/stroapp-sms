import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

class MfaVerifyDialog extends StatefulWidget {
  final String? title;
  const MfaVerifyDialog({super.key, this.title});

  @override
  State<MfaVerifyDialog> createState() => _MfaVerifyDialogState();
}

class _MfaVerifyDialogState extends State<MfaVerifyDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: AlertDialog(
        backgroundColor: AppColors.canvasLight,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          widget.title ?? 'مطلوب التحقق بخطوتين',
          style: AppTextStyles.titleMedium.copyWith(color: AppColors.ink),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'أدخل رمز التحقق من تطبيق المصادقة',
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.bodyLight),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _controller,
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.ink),
              textAlign: TextAlign.center,
              decoration: InputDecoration(
                hintText: '000000',
                hintStyle: AppTextStyles.bodyMedium.copyWith(color: AppColors.mutedStrong),
                filled: true,
                fillColor: AppColors.surfaceSoftLight,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: AppColors.hairlineLight),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              ),
              keyboardType: TextInputType.number,
              maxLength: 6,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('إلغاء', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.mutedStrong)),
          ),
          FilledButton(
            onPressed: () {
              if (_controller.text.trim().length == 6) {
                Navigator.of(context).pop(_controller.text.trim());
              }
            },
            style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
            child: Text('تحقق', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.ink)),
          ),
        ],
      ),
    );
  }
}
