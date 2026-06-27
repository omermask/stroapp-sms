import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

class AppTabItem {
  final String label;
  final Widget? icon;

  const AppTabItem({required this.label, this.icon});
}

class AppTabs extends StatelessWidget {
  final List<AppTabItem> tabs;
  final int selectedIndex;
  final ValueChanged<int> onTabSelected;
  final double tabWidth;

  const AppTabs({
    super.key,
    required this.tabs,
    required this.selectedIndex,
    required this.onTabSelected,
    this.tabWidth = 80,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 25,
      child: Row(
        children: List.generate(tabs.length, (i) {
          final isSelected = i == selectedIndex;
          return GestureDetector(
            onTap: () => onTabSelected(i),
            child: Container(
              width: tabWidth,
              height: 25,
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: isSelected ? AppColors.ink : Colors.transparent,
                    width: 2,
                  ),
                ),
              ),
              child: Align(
                alignment: Alignment.center,
                child: Text(
                  tabs[i].label,
                  style: AppTextStyles.titleSmall.copyWith(
                    color: isSelected ? AppColors.ink : AppColors.mutedStrong,
                    fontSize: 16,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}