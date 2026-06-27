import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import 'app_icon.dart';

enum AppButtonVariant {
  large,
  largeSecondary,
  medium,
  smallWithIcon,
  textButton,
  textWithIcon,
  linear,
  tag,
  copy,
}

class AppButton extends StatelessWidget {
  final AppButtonVariant variant;
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isDisabled;
  final IconData? icon;
  final double? width;

  const AppButton({
    super.key,
    required this.variant,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.isDisabled = false,
    this.icon,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    final pressed = !isLoading && !isDisabled && onPressed != null;
    final effectiveOnPressed = pressed ? onPressed : null;

    switch (variant) {
      case AppButtonVariant.large:
        return _buildLargeButton(effectiveOnPressed);
      case AppButtonVariant.largeSecondary:
        return _buildLargeSecondaryButton(effectiveOnPressed);
      case AppButtonVariant.medium:
        return _buildMediumButton(effectiveOnPressed);
      case AppButtonVariant.smallWithIcon:
        return _buildSmallWithIconButton(effectiveOnPressed);
      case AppButtonVariant.textButton:
        return _buildTextButton(effectiveOnPressed);
      case AppButtonVariant.textWithIcon:
        return _buildTextWithIcon(effectiveOnPressed);
      case AppButtonVariant.linear:
        return _buildLinearButton(effectiveOnPressed);
      case AppButtonVariant.tag:
        return _buildTag(effectiveOnPressed);
      case AppButtonVariant.copy:
        return _buildCopyButton(effectiveOnPressed);
    }
  }

  Widget _buildLargeButton(VoidCallback? onPressed) {
    return SizedBox(
      width: width ?? 335,
      height: 50,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: isDisabled ? AppColors.primary.withValues(alpha: 0.5) : AppColors.primary,
          foregroundColor: AppColors.onPrimary,
          disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.5),
          disabledForegroundColor: AppColors.onPrimary,
          elevation: 0,
          shadowColor: Colors.transparent,
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: isLoading
            ? const SizedBox(
                width: 30,
                height: 30,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.onPrimary),
                ),
              )
            : Text(label, style: AppTextStyles.button),
      ),
    );
  }

  Widget _buildLargeSecondaryButton(VoidCallback? onPressed) {
    return SizedBox(
      width: width ?? 335,
      height: 50,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.hairlineLight,
          foregroundColor: AppColors.onPrimary,
          disabledBackgroundColor: AppColors.hairlineLight,
          disabledForegroundColor: AppColors.onPrimary,
          elevation: 0,
          shadowColor: Colors.transparent,
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: isLoading
            ? const SizedBox(
                width: 30,
                height: 30,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.ink),
                ),
              )
            : Text(label, style: AppTextStyles.button.copyWith(color: AppColors.ink)),
      ),
    );
  }

  Widget _buildMediumButton(VoidCallback? onPressed) {
    return SizedBox(
      width: width ?? 162,
      height: 50,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.onPrimary,
          elevation: 0,
          shadowColor: Colors.transparent,
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: isLoading
            ? const SizedBox(
                width: 30,
                height: 30,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.onPrimary),
                ),
              )
            : Text(label, style: AppTextStyles.button),
      ),
    );
  }

  Widget _buildSmallWithIconButton(VoidCallback? onPressed) {
    return SizedBox(
      width: width ?? 105,
      height: 40,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.onPrimary,
          elevation: 0,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 16),
              const SizedBox(width: 4),
            ],
            Text(label, style: AppTextStyles.button.copyWith(fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _buildTextButton(VoidCallback? onPressed) {
    return SizedBox(
      width: width ?? 162,
      height: 50,
      child: TextButton(
        onPressed: onPressed,
        style: TextButton.styleFrom(
          foregroundColor: isDisabled ? AppColors.mutedStrong : AppColors.ink,
          disabledForegroundColor: AppColors.mutedStrong,
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(label, style: AppTextStyles.button),
      ),
    );
  }

  Widget _buildTextWithIcon(VoidCallback? onPressed) {
    final effectiveColor = isDisabled ? AppColors.mutedStrong : AppColors.bluePrimary;
    return GestureDetector(
      onTap: onPressed,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 10, color: effectiveColor),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: AppTextStyles.button.copyWith(color: effectiveColor, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildLinearButton(VoidCallback? onPressed) {
    return SizedBox(
      width: width ?? 84,
      height: 42,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.white,
          side: const BorderSide(color: Colors.white),
          backgroundColor: Colors.transparent,
          disabledBackgroundColor: Colors.white.withValues(alpha: 0.17),
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
        ),
        child: Text(
          label,
          style: AppTextStyles.button.copyWith(
            color: Colors.white,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildTag(VoidCallback? onPressed) {
    return Container(
      width: width ?? 79,
      height: 30,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderStrong.withValues(alpha: 0.5)),
        color: Colors.transparent,
      ),
      alignment: Alignment.center,
      child: Text(
        label,
        style: AppTextStyles.labelSmall.copyWith(
          color: AppColors.ink,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildCopyButton(VoidCallback? onPressed) {
    return GestureDetector(
      onTap: onPressed,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const AppIcon(name: AppIcons.copy, size: 20, color: AppColors.bluePrimary),
          const SizedBox(width: 4),
          Text(
            label,
            style: AppTextStyles.button.copyWith(color: AppColors.bluePrimary, fontSize: 12),
          ),
        ],
      ),
    );
  }
}