import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../constants/app_constants.dart';

// ──────────────────────────────────────────────
// Primary Button – Caribbean Green, radius 30
// Used: Log In, Sign Up, Save, Yes/Confirm
// ──────────────────────────────────────────────
class AppPrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final double? width;
  final double height;
  final TextStyle? textStyle;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final Widget? icon;

  const AppPrimaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.width,
    this.height = 45,
    this.textStyle,
    this.backgroundColor,
    this.foregroundColor,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width ?? double.infinity,
      height: height,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor ?? AppColors.caribbeanGreen,
          foregroundColor: foregroundColor ?? AppColors.cyprus,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 32),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.radiusButton),
          ),
        ),
        child: icon != null
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  icon!,
                  const SizedBox(width: 8),
                  Text(label, style: textStyle ?? AppTypography.buttonLarge),
                ],
              )
            : Text(label, style: textStyle ?? AppTypography.buttonLarge),
      ),
    );
  }
}

// ──────────────────────────────────────────────
// Secondary Button – Light Green, radius 30
// Used: Cancel, Skip, Back options
// ──────────────────────────────────────────────
class AppSecondaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final double? width;
  final double height;

  const AppSecondaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.width,
    this.height = 45,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width ?? double.infinity,
      height: height,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.lightGreen,
          foregroundColor: AppColors.cyprus,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 32),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.radiusButton),
          ),
        ),
        child: Text(label, style: AppTypography.buttonLarge),
      ),
    );
  }
}

// ──────────────────────────────────────────────
// Small Button – radius 30, Medium 15px
// Used: dialog actions (yes/no), filter chips
// ──────────────────────────────────────────────
class AppSmallButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final double? width;
  final double height;

  const AppSmallButton({
    super.key,
    required this.label,
    this.onPressed,
    this.backgroundColor,
    this.foregroundColor,
    this.width,
    this.height = 45,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor ?? AppColors.caribbeanGreen,
          foregroundColor: foregroundColor ?? AppColors.cyprus,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.radiusButton),
          ),
        ),
        child: Text(label, style: AppTypography.buttonMedium),
      ),
    );
  }
}

// ──────────────────────────────────────────────
// Outlined Button – stroke Caribbean Green
// ──────────────────────────────────────────────
class AppOutlinedButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final double? width;
  final double height;

  const AppOutlinedButton({
    super.key,
    required this.label,
    this.onPressed,
    this.width,
    this.height = 45,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width ?? double.infinity,
      height: height,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.cyprus,
          side: const BorderSide(color: AppColors.caribbeanGreen),
          padding: const EdgeInsets.symmetric(horizontal: 32),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.radiusButton),
          ),
        ),
        child: Text(label, style: AppTypography.buttonMedium),
      ),
    );
  }
}

// ──────────────────────────────────────────────
// Icon Tile – rounded square icon container
// Size: 57×53, cornerRadius: 22
// Used in Profile menu items, category icons
// ──────────────────────────────────────────────
class AppIconTile extends StatelessWidget {
  final IconData icon;
  final Color? backgroundColor;
  final double size;
  final double iconSize;
  final Color iconColor;

  const AppIconTile({
    super.key,
    required this.icon,
    this.backgroundColor,
    this.size = AppConstants.iconContainerSize,
    this.iconSize = 22,
    this.iconColor = AppColors.honeydew,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size - 4, // 57×53 from Figma
      decoration: BoxDecoration(
        color: backgroundColor ?? AppColors.lightBlue,
        borderRadius: BorderRadius.circular(AppConstants.radiusIconContainer),
      ),
      child: Icon(icon, size: iconSize, color: iconColor),
    );
  }
}

// ──────────────────────────────────────────────
// Menu Tile – icon + text row
// Used: Edit Profile, Security, Setting, Help, Logout
// ──────────────────────────────────────────────
class AppMenuTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? iconBackgroundColor;
  final VoidCallback? onTap;
  final Widget? trailing;

  const AppMenuTile({
    super.key,
    required this.icon,
    required this.label,
    this.iconBackgroundColor,
    this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            AppIconTile(icon: icon, backgroundColor: iconBackgroundColor),
            const SizedBox(width: AppConstants.spacingSmall),
            Expanded(
              child: Text(
                label,
                style: AppTypography.menuItem.copyWith(
                  color: isDark
                      ? AppColors.darkTextPrimary
                      : AppColors.lightTextPrimary,
                ),
              ),
            ),
            ?trailing,
          ],
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────
// Dialog Action Row – primary + secondary buttons
// Used: "yes, end session" / "cancel"
// ──────────────────────────────────────────────
class AppDialogActions extends StatelessWidget {
  final String confirmLabel;
  final String cancelLabel;
  final VoidCallback? onConfirm;
  final VoidCallback? onCancel;
  final Color? confirmColor;

  const AppDialogActions({
    super.key,
    this.confirmLabel = 'yes, end session',
    this.cancelLabel = 'cancel',
    this.onConfirm,
    this.onCancel,
    this.confirmColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: AppSmallButton(
            label: confirmLabel,
            onPressed: onConfirm,
            backgroundColor: confirmColor ?? AppColors.caribbeanGreen,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: AppSmallButton(
            label: cancelLabel,
            onPressed: onCancel,
            backgroundColor: AppColors.lightGreen,
            foregroundColor: AppColors.cyprus,
          ),
        ),
      ],
    );
  }
}
