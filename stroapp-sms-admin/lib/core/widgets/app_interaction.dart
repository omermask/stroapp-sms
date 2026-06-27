import 'package:flutter/material.dart';
import '../utils/qaseh_icons.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import 'app_buttons.dart';
import 'app_misc.dart';

// ──────────────────────────────────────────────
// Segmented Control – Daily / Weekly / Monthly / Year
// Used: Analysis screen top tabs
// ──────────────────────────────────────────────
class AppSegmentedControl extends StatelessWidget {
  final List<String> items;
  final int selectedIndex;
  final ValueChanged<int> onChanged;
  final Color? activeColor;
  final Color? inactiveColor;

  const AppSegmentedControl({
    super.key,
    required this.items,
    required this.selectedIndex,
    required this.onChanged,
    this.activeColor,
    this.inactiveColor,
  });

  factory AppSegmentedControl.analysis({
    required int selectedIndex,
    required ValueChanged<int> onChanged,
  }) {
    return AppSegmentedControl(
      items: const ['Daily', 'Weekly', 'Monthly', 'Year'],
      selectedIndex: selectedIndex,
      onChanged: onChanged,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.lightGreen,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        children: List.generate(items.length, (i) {
          final isSelected = i == selectedIndex;
          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged(i),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected
                      ? (activeColor ?? AppColors.caribbeanGreen)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Text(
                  items[i],
                  textAlign: TextAlign.center,
                  style: AppTypography.categoryFilter.copyWith(
                    color: isSelected
                        ? AppColors.honeydew
                        : AppColors.fenceGreen,
                    fontWeight: isSelected ? FontWeight.w500 : FontWeight.w400,
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

// ──────────────────────────────────────────────
// Settings Toggle Tile – icon + label + switch
// Used: Notification settings
// ──────────────────────────────────────────────
class AppSettingsTile extends StatelessWidget {
  final String label;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool>? onChanged;
  final IconData? icon;
  final Color? iconBackgroundColor;
  final Widget? trailing;

  const AppSettingsTile({
    super.key,
    required this.label,
    this.subtitle,
    required this.value,
    this.onChanged,
    this.icon,
    this.iconBackgroundColor,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          if (icon != null)
            Padding(
              padding: const EdgeInsets.only(right: 13),
              child: AppIconTile(
                icon: icon!,
                backgroundColor: iconBackgroundColor,
              ),
            ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTypography.menuItem.copyWith(
                    color: isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.lightTextPrimary,
                  ),
                ),
                if (subtitle != null)
                  Text(
                    subtitle!,
                    style: AppTypography.bodySmall.copyWith(
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.cyprus,
                    ),
                  ),
              ],
            ),
          ),
          trailing ??
              (onChanged != null
                  ? Switch(
                      value: value,
                      onChanged: onChanged,
                      activeThumbColor: AppColors.caribbeanGreen,
                      inactiveThumbColor: AppColors.lightGreen,
                      inactiveTrackColor: AppColors.lightGreen.withValues(
                        alpha: 0.3,
                      ),
                    )
                  : const SizedBox()),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────
// Notification Item – single notification row
// Used: Notifications screen (5.1)
// ──────────────────────────────────────────────
class AppNotificationItem extends StatelessWidget {
  final String title;
  final String message;
  final String? time;
  final bool isUnread;
  final VoidCallback? onTap;

  const AppNotificationItem({
    super.key,
    required this.title,
    required this.message,
    this.time,
    this.isUnread = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon circle
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: isUnread
                    ? AppColors.caribbeanGreen
                    : AppColors.lightGreen,
                shape: BoxShape.circle,
              ),
              child: Icon(
                isUnread
                    ? QasehIcons.notificationFilled
                    : QasehIcons.notificationCurved,
                size: 20,
                color: isUnread ? AppColors.honeydew : AppColors.cyprus,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: AppTypography.menuItem.copyWith(
                            color: isDark
                                ? AppColors.darkTextPrimary
                                : AppColors.lightTextPrimary,
                            fontWeight: isUnread
                                ? FontWeight.w600
                                : FontWeight.w500,
                          ),
                        ),
                      ),
                      if (time != null)
                        Text(
                          time!,
                          style: AppTypography.bodySmall.copyWith(
                            color: isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.cyprus,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    message,
                    style: AppTypography.bodySmall.copyWith(
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.cyprus,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
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

// ──────────────────────────────────────────────
// Quick Action FAB Row – floating circular buttons
// Used: Home screen bottom area
// ──────────────────────────────────────────────
class AppQuickActionRow extends StatelessWidget {
  final List<QuickAction> actions;

  const AppQuickActionRow({super.key, required this.actions});

  factory AppQuickActionRow.home() {
    return AppQuickActionRow(
      actions: [
        QuickAction(
          icon: QasehIcons.swapCurved,
          label: 'Transfer',
          color: AppColors.lightBlue,
          onTap: null,
        ),
        QuickAction(
          icon: QasehIcons.chartCurved,
          label: 'Analysis',
          color: AppColors.vividBlue,
          onTap: null,
        ),
        QuickAction(
          icon: QasehIcons.plusCurved,
          label: 'Add',
          color: AppColors.oceanBlue,
          onTap: null,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(actions.length, (i) {
        final action = actions[i];
        return Padding(
          padding: EdgeInsets.only(right: i < actions.length - 1 ? 20 : 0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              GestureDetector(
                onTap: action.onTap,
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: action.color,
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: Icon(action.icon, color: AppColors.honeydew, size: 24),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                action.label,
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.cyprus,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}

class QuickAction {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;
  const QuickAction({
    required this.icon,
    required this.label,
    required this.color,
    this.onTap,
  });
}

// ──────────────────────────────────────────────
// Welcome Header – "Hi, Welcome Back" + greeting
// Used: Home screen top
// ──────────────────────────────────────────────
class AppWelcomeHeader extends StatelessWidget {
  final String name;
  final String greeting;
  final VoidCallback? onNotificationTap;

  const AppWelcomeHeader({
    super.key,
    this.name = 'Hi, Welcome Back',
    this.greeting = 'Good Morning',
    this.onNotificationTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      decoration: const BoxDecoration(
        color: AppColors.caribbeanGreen,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(31),
          bottomRight: Radius.circular(31),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: AppTypography.dialogTitle.copyWith(
                      color: AppColors.cyprus,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    greeting,
                    style: AppTypography.accordionTitle.copyWith(
                      color: AppColors.cyprus,
                    ),
                  ),
                ],
              ),
              AppNotificationBell(onTap: onNotificationTap),
            ],
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────
// Income Expense Summary – total income / expense row
// Used: Analysis screens
// ──────────────────────────────────────────────
class AppIncomeExpenseSummary extends StatelessWidget {
  final String income;
  final String expense;
  final String incomeLabel;
  final String expenseLabel;

  const AppIncomeExpenseSummary({
    super.key,
    this.income = r'$11,420.00',
    this.expense = r'$20,000.20',
    this.incomeLabel = 'Income',
    this.expenseLabel = 'Expense',
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                incomeLabel,
                style: AppTypography.cardTitle.copyWith(
                  color: AppColors.cyprus,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                income,
                style: AppTypography.cardAmount.copyWith(
                  color: AppColors.caribbeanGreen,
                ),
              ),
            ],
          ),
        ),
        Container(width: 1, height: 40, color: AppColors.lightGreen),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                expenseLabel,
                style: AppTypography.cardTitle.copyWith(
                  color: AppColors.cyprus,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                expense,
                style: AppTypography.cardAmount.copyWith(
                  color: AppColors.oceanBlue,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ──────────────────────────────────────────────
// Target Card – "My targets" (e.g. Travel 30%, Car 50%)
// Used: Analysis screen
// ──────────────────────────────────────────────
class AppTargetCard extends StatelessWidget {
  final String label;
  final String percentage;
  final Color? color;
  final double progress; // 0.0 – 1.0

  const AppTargetCard({
    super.key,
    required this.label,
    required this.percentage,
    this.color,
    this.progress = 0.3,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = color ?? AppColors.lightBlue;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(25.79),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: AppTypography.menuItem.copyWith(color: AppColors.honeydew),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.honeydew.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              percentage,
              style: AppTypography.chartValue.copyWith(
                color: AppColors.honeydew,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
