import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import 'app_icon.dart';

class _NavItem {
  final String iconName;
  final String label;

  const _NavItem({required this.iconName, required this.label});
}

const _navItems = [
  _NavItem(iconName: AppIcons.wallet, label: 'Wallet'),
  _NavItem(iconName: AppIcons.settingsAlt, label: 'Settings'),
  _NavItem(iconName: AppIcons.browser, label: 'Browser'),
  _NavItem(iconName: AppIcons.stacking, label: 'Stacking'),
  _NavItem(iconName: AppIcons.exchange, label: 'Exhange'),
];

class AppBottomBar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onItemSelected;

  const AppBottomBar({
    super.key,
    this.selectedIndex = 0,
    required this.onItemSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 355,
      height: 60,
      decoration: BoxDecoration(
        color: AppColors.cardLight,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(_navItems.length, (i) {
          final item = _navItems[i];
          final isSelected = i == selectedIndex;
          return GestureDetector(
            onTap: () => onItemSelected(i),
            behavior: HitTestBehavior.opaque,
            child: Container(
              height: 34,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : Colors.transparent,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AppIcon(
                    name: item.iconName,
                    size: 14,
                    color: isSelected ? AppColors.ink : AppColors.mutedStrong,
                  ),
                  if (isSelected) ...[
                    const SizedBox(width: 6),
                    Text(
                      item.label,
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.ink,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}