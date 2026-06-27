import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import 'app_icon.dart';

enum AppInputVariant { default_, focused, disable, search, error, complex }

class AppInputField extends StatefulWidget {
  final AppInputVariant variant;
  final String? hintText;
  final String? label;
  final String? initialValue;
  final bool obscureText;
  final bool showPasteButton;
  final bool showSearchIcon;
  final bool showSuffixIcon;
  final IconData? suffixIcon;
  final ValueChanged<String>? onChanged;
  final TextEditingController? controller;
  final double width;
  final double height;

  const AppInputField({
    super.key,
    this.variant = AppInputVariant.default_,
    this.hintText,
    this.label,
    this.initialValue,
    this.obscureText = false,
    this.showPasteButton = false,
    this.showSearchIcon = false,
    this.showSuffixIcon = false,
    this.suffixIcon,
    this.onChanged,
    this.controller,
    this.width = 335,
    this.height = 56,
  });

  @override
  State<AppInputField> createState() => _AppInputFieldState();
}

class _AppInputFieldState extends State<AppInputField> {
  late bool _obscureText;
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _obscureText = widget.obscureText;
    _controller = widget.controller ?? TextEditingController(text: widget.initialValue);
  }

  @override
  void dispose() {
    if (widget.controller == null) _controller.dispose();
    super.dispose();
  }

  Color get _borderColor {
    switch (widget.variant) {
      case AppInputVariant.error:
        return AppColors.error;
      case AppInputVariant.complex:
        return AppColors.mutedStrong;
      case AppInputVariant.focused:
        return AppColors.bluePrimary;
      default:
        return AppColors.borderStrong.withValues(alpha: 0.5);
    }
  }

  Color get _fillColor {
    if (widget.variant == AppInputVariant.disable) {
      return AppColors.surfaceStrongLight;
    }
    return AppColors.surfaceStrongLight;
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: TextField(
        controller: _controller,
        onChanged: widget.onChanged,
        obscureText: _obscureText,
        enabled: widget.variant != AppInputVariant.disable,
        style: AppTextStyles.bodyMedium.copyWith(color: AppColors.ink),
        decoration: InputDecoration(
          filled: true,
          fillColor: _fillColor,
          hintText: widget.hintText,
          hintStyle: AppTextStyles.bodyMedium.copyWith(color: AppColors.mutedStrong),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
          isDense: true,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: _borderColor, width: 1),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: _borderColor, width: 1),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: _borderColor == AppColors.error ? AppColors.error : AppColors.bluePrimary,
              width: 1.5,
            ),
          ),
          disabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: _borderColor, width: 1),
          ),
          prefixIcon: widget.showSearchIcon
              ? Padding(
                  padding: const EdgeInsets.only(left: 12, right: 8),
                  child: AppIcon(name: AppIcons.search, size: 20, color: AppColors.mutedStrong),
                )
              : null,
          suffixIconConstraints: const BoxConstraints(minWidth: 48, minHeight: 24),
          suffixIcon: _buildSuffix(),
        ),
      ),
    );
  }

  Widget? _buildSuffix() {
    if (widget.showPasteButton) {
      return Padding(
        padding: const EdgeInsets.only(right: 12),
        child: GestureDetector(
          onTap: () {},
          child: Text('Paste', style: AppTextStyles.labelMedium.copyWith(color: AppColors.bluePrimary)),
        ),
      );
    }
    if (widget.obscureText) {
      return Padding(
        padding: const EdgeInsets.only(right: 12),
        child: GestureDetector(
          onTap: () => setState(() => _obscureText = !_obscureText),
          child: AppIcon(
            name: _obscureText ? AppIcons.eyeOff : AppIcons.eye,
            size: 24,
            color: AppColors.bodyLight,
          ),
        ),
      );
    }
    if (widget.showSuffixIcon && widget.suffixIcon != null) {
      return Padding(
        padding: const EdgeInsets.only(right: 12),
        child: Icon(widget.suffixIcon, size: 20, color: AppColors.mutedStrong),
      );
    }
    return null;
  }
}