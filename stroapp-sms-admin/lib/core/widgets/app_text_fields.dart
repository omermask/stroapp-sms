import 'package:flutter/material.dart';
import '../utils/qaseh_icons.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../constants/app_constants.dart';

// ──────────────────────────────────────────────
// Standard Text Field
// Label + input with Light Green background, radius 18
// Used: Full name, Email, Mobile, DOB, etc.
// ──────────────────────────────────────────────
class AppTextField extends StatelessWidget {
  final String label;
  final String? hintText;
  final TextEditingController? controller;
  final TextInputType? keyboardType;
  final bool obscureText;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onChanged;

  const AppTextField({
    super.key,
    required this.label,
    this.hintText,
    this.controller,
    this.keyboardType,
    this.obscureText = false,
    this.prefixIcon,
    this.suffixIcon,
    this.validator,
    this.onChanged,
  });

  factory AppTextField.email({
    String label = 'Email',
    String hintText = 'example@example.com',
    TextEditingController? controller,
  }) {
    return AppTextField(
      label: label,
      hintText: hintText,
      controller: controller,
      keyboardType: TextInputType.emailAddress,
    );
  }

  factory AppTextField.password({
    String label = 'Password',
    TextEditingController? controller,
    bool obscure = true,
    VoidCallback? onToggleVisibility,
    bool isVisible = false,
  }) {
    return AppTextField(
      label: label,
      hintText: '●●●●●●●●',
      controller: controller,
      obscureText: obscure,
      suffixIcon: onToggleVisibility != null
          ? IconButton(
              onPressed: onToggleVisibility,
              icon: Icon(
                isVisible ? QasehIcons.hideCurved : QasehIcons.showCurved,
                color: AppColors.cyprus,
                size: 20,
              ),
            )
          : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: AppTypography.inputLabel.copyWith(
            color: isDark ? AppColors.darkTextBody : AppColors.textDarkBrown,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          obscureText: obscureText,
          validator: validator,
          onChanged: onChanged,
          style: AppTypography.inputText.copyWith(
            color: isDark ? AppColors.darkTextPrimary : AppColors.cyprus,
          ),
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: AppTypography.inputText.copyWith(
              color: isDark ? AppColors.darkTextSecondary : AppColors.cyprus,
            ),
            filled: true,
            fillColor: isDark
                ? AppColors.darkTextFieldBg
                : AppColors.lightTextFieldBg,
            prefixIcon: prefixIcon,
            suffixIcon: suffixIcon,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 16,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppConstants.radiusInput),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppConstants.radiusInput),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppConstants.radiusInput),
              borderSide: const BorderSide(
                color: AppColors.caribbeanGreen,
                width: 1.5,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ──────────────────────────────────────────────
// Password Field – with visibility toggle
// ──────────────────────────────────────────────
class AppPasswordField extends StatefulWidget {
  final String label;
  final TextEditingController? controller;
  final String? Function(String?)? validator;

  const AppPasswordField({
    super.key,
    this.label = 'Password',
    this.controller,
    this.validator,
  });

  @override
  State<AppPasswordField> createState() => _AppPasswordFieldState();
}

class _AppPasswordFieldState extends State<AppPasswordField> {
  bool _obscure = true;

  @override
  Widget build(BuildContext context) {
    return AppTextField(
      label: widget.label,
      hintText: '●●●●●●●●',
      controller: widget.controller,
      obscureText: _obscure,
      validator: widget.validator,
      suffixIcon: IconButton(
        onPressed: () => setState(() => _obscure = !_obscure),
        icon: Icon(
          _obscure ? QasehIcons.hideCurved : QasehIcons.showCurved,
          color: AppColors.cyprus,
          size: 20,
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────
// Search Field
// Used: Search bar in analysis/search screens
// ──────────────────────────────────────────────
class AppSearchField extends StatelessWidget {
  final String hintText;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;

  const AppSearchField({
    super.key,
    this.hintText = 'Search',
    this.controller,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return TextField(
      controller: controller,
      onChanged: onChanged,
      style: AppTypography.searchText.copyWith(
        color: isDark ? AppColors.darkTextPrimary : AppColors.cyprus,
      ),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: AppTypography.searchText.copyWith(
          color: isDark ? AppColors.darkTextSecondary : AppColors.cyprus,
        ),
        prefixIcon: Icon(
          QasehIcons.searchCurved,
          color: isDark ? AppColors.darkTextSecondary : AppColors.cyprus,
          size: 20,
        ),
        filled: true,
        fillColor: isDark
            ? AppColors.darkTextFieldBg
            : AppColors.lightTextFieldBg,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusInput),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusInput),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusInput),
          borderSide: const BorderSide(
            color: AppColors.caribbeanGreen,
            width: 1.5,
          ),
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────
// Chat Input Field – for support chat
// ──────────────────────────────────────────────
class AppChatField extends StatelessWidget {
  final TextEditingController? controller;
  final VoidCallback? onSend;
  final String hintText;

  const AppChatField({
    super.key,
    this.controller,
    this.onSend,
    this.hintText = 'Write Here...',
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(25),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              style: AppTypography.chatHint.copyWith(
                color: AppColors.textDarkBrown,
              ),
              decoration: InputDecoration(
                hintText: hintText,
                hintStyle: AppTypography.chatHint.copyWith(
                  color: AppColors.textDarkBrown,
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          GestureDetector(
            onTap: onSend,
            child: Container(
              width: 36,
              height: 36,
              decoration: const BoxDecoration(
                color: AppColors.caribbeanGreen,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                QasehIcons.sendCurved,
                size: 16,
                color: AppColors.honeydew,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
