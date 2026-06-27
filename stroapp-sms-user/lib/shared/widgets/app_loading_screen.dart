import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import 'app_logo.dart';

class AppLoadingScreen extends StatelessWidget {
  final String? title;
  final String? subtitle;

  const AppLoadingScreen({
    super.key,
    this.title,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: AppColors.canvasLight,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const AppLogo(size: 92),
          const SizedBox(height: 48),
          if (title != null) ...[
            Text(
              title!,
              style: AppTextStyles.displayMedium.copyWith(
                color: AppColors.ink,
                fontFamily: 'Poppins',
              ),
              textAlign: TextAlign.center,
            ),
          ],
          if (subtitle != null) ...[
            const SizedBox(height: 8),
            Text(
              subtitle!,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.mutedStrong,
              ),
              textAlign: TextAlign.center,
            ),
          ],
          const SizedBox(height: 32),
          const SizedBox(
            width: 30,
            height: 30,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }
}