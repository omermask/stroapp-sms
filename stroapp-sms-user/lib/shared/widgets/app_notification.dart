import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

class AppNotification extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool isComplete;
  final VoidCallback? onTap;

  const AppNotification({
    super.key,
    required this.title,
    required this.subtitle,
    this.isComplete = false,
    this.onTap,
  });

  factory AppNotification.complete({
    String title = 'Transaction complete!',
    String subtitle = 'Tap to view this transaction',
    VoidCallback? onTap,
  }) {
    return AppNotification(title: title, subtitle: subtitle, isComplete: true, onTap: onTap);
  }

  factory AppNotification.cancelled({
    String title = 'Transaction cancelled!',
    String subtitle = 'Tap to view this transaction',
    VoidCallback? onTap,
  }) {
    return AppNotification(title: title, subtitle: subtitle, isComplete: false, onTap: onTap);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 335,
        height: 68,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: isComplete
              ? AppColors.success.withValues(alpha: 0.1)
              : AppColors.error.withValues(alpha: 0.1),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isComplete ? AppColors.success : AppColors.error,
              ),
              child: Center(
                child: Icon(
                  isComplete ? Icons.check : Icons.close,
                  size: 16,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.titleSmall.copyWith(
                      color: AppColors.ink,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.mutedStrong,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}