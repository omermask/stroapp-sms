import 'package:flutter/material.dart';
import '../utils/qaseh_icons.dart';
import '../theme/app_colors.dart';
import '../constants/app_constants.dart';

enum AppTab { home, analysis, transactions, category, profile }

extension AppTabLabel on AppTab {
  String get label {
    switch (this) {
      case AppTab.home:
        return '';
      case AppTab.analysis:
        return '';
      case AppTab.transactions:
        return '';
      case AppTab.category:
        return '';
      case AppTab.profile:
        return '';
    }
  }
}

// ──────────────────────────────────────────────
// Bottom Navigation – exact Figma replica
// 5 tabs, custom Profile active state
// ──────────────────────────────────────────────
class AppBottomNav extends StatelessWidget {
  final AppTab currentTab;
  final ValueChanged<AppTab> onTabChanged;

  const AppBottomNav({
    super.key,
    required this.currentTab,
    required this.onTabChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.darkBottomNav : AppColors.lightBottomNav;

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(AppConstants.radiusBottomNav),
          topRight: Radius.circular(AppConstants.radiusBottomNav),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(
        AppConstants.bottomNavHorizontalPadding,
        AppConstants.bottomNavPaddingTop,
        AppConstants.bottomNavHorizontalPadding,
        AppConstants.bottomNavPaddingBottom,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _NavItem(
            icon: QasehIcons.homeCurved,
            isActive: currentTab == AppTab.home,
            onTap: () => onTabChanged(AppTab.home),
            isDark: isDark,
          ),
          _NavItem(
            icon: QasehIcons.chartCurved,
            isActive: currentTab == AppTab.analysis,
            onTap: () => onTabChanged(AppTab.analysis),
            isDark: isDark,
          ),
          _NavItem(
            icon: QasehIcons.swapCurved,
            isActive: currentTab == AppTab.transactions,
            onTap: () => onTabChanged(AppTab.transactions),
            isDark: isDark,
          ),
          _NavItem(
            icon: QasehIcons.categoryCurved,
            isActive: currentTab == AppTab.category,
            onTap: () => onTabChanged(AppTab.category),
            isDark: isDark,
          ),
          _NavItem(
            icon: QasehIcons.profileCurved,
            isActive: currentTab == AppTab.profile,
            onTap: () => onTabChanged(AppTab.profile),
            isDark: isDark,
            isProfile: true,
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final bool isActive;
  final VoidCallback onTap;
  final bool isDark;
  final bool isProfile;

  const _NavItem({
    required this.icon,
    required this.isActive,
    required this.onTap,
    required this.isDark,
    this.isProfile = false,
  });

  @override
  Widget build(BuildContext context) {
    final iconColor = isDark ? AppColors.darkTextPrimary : AppColors.cyprus;

    if (isProfile && isActive) {
      return GestureDetector(
        onTap: onTap,
        child: Container(
          width: 57,
          height: 53,
          decoration: BoxDecoration(
            color: AppColors.caribbeanGreen,
            borderRadius: BorderRadius.circular(
              AppConstants.radiusIconContainer,
            ),
          ),
          child: Icon(icon, size: 22, color: iconColor),
        ),
      );
    }

    return GestureDetector(
      onTap: onTap,
      child: Icon(icon, size: 25, color: iconColor),
    );
  }
}
