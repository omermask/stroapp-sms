import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

enum AppCheckboxState { unchecked, checked, inactive }

class AppCheckbox extends StatelessWidget {
  final AppCheckboxState state;
  final String? label;
  final ValueChanged<bool?>? onChanged;

  const AppCheckbox({
    super.key,
    this.state = AppCheckboxState.unchecked,
    this.label,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final Widget checkbox = GestureDetector(
      onTap: () {
        if (onChanged != null && state != AppCheckboxState.inactive) {
          onChanged!(state != AppCheckboxState.checked);
        }
      },
      child: Container(
        width: 20,
        height: 20,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(4),
          color: state == AppCheckboxState.checked
              ? AppColors.primary
              : state == AppCheckboxState.inactive
                  ? AppColors.borderStrong.withValues(alpha: 0.5)
                  : Colors.transparent,
          border: state == AppCheckboxState.unchecked
              ? Border.all(color: AppColors.borderStrong.withValues(alpha: 0.5))
              : null,
        ),
        child: state == AppCheckboxState.checked
            ? const Center(
                child: Icon(Icons.check, size: 14, color: AppColors.ink),
              )
            : state == AppCheckboxState.inactive
                ? Center(
                    child: Container(
                      width: 8,
                      height: 2,
                      decoration: BoxDecoration(
                        color: AppColors.ink,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  )
                : null,
      ),
    );

    if (label != null) {
      return GestureDetector(
        onTap: () {
          if (onChanged != null && state != AppCheckboxState.inactive) {
            onChanged!(state != AppCheckboxState.checked);
          }
        },
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            checkbox,
            const SizedBox(width: 8),
            Text(label!, style: AppTextStyles.bodySmall.copyWith(color: AppColors.ink, fontSize: 14)),
          ],
        ),
      );
    }

    return checkbox;
  }
}

enum AppRadioState { default_, checked, inactive }

class AppRadio extends StatelessWidget {
  final AppRadioState state;
  final ValueChanged<bool?>? onChanged;

  const AppRadio({
    super.key,
    this.state = AppRadioState.default_,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (onChanged != null && state != AppRadioState.inactive) {
          onChanged!(state != AppRadioState.checked);
        }
      },
      child: Container(
        width: 20,
        height: 20,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: state == AppRadioState.default_
              ? AppColors.surfaceStrongLight
              : state == AppRadioState.checked
                  ? AppColors.primary
                  : AppColors.borderStrong.withValues(alpha: 0.5),
        ),
        child: state == AppRadioState.checked
            ? const Center(
                child: Icon(Icons.check, size: 12, color: AppColors.ink),
              )
            : state == AppRadioState.inactive
                ? Center(
                    child: Container(
                      width: 7,
                      height: 2,
                      decoration: BoxDecoration(
                        color: AppColors.ink,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  )
                : null,
      ),
    );
  }
}