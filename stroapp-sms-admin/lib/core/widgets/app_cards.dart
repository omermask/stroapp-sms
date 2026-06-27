import 'package:flutter/material.dart';
import '../utils/qaseh_icons.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../constants/app_constants.dart';

// ──────────────────────────────────────────────
// Stat Card – Income / Expense
// Used on Home screen
// ──────────────────────────────────────────────
class AppStatCard extends StatelessWidget {
  final String title;
  final String amount;
  final IconData icon;
  final Color? backgroundColor;
  final Color? textColor;
  final Color? amountColor;
  final Color? iconBorderColor;

  const AppStatCard({
    super.key,
    required this.title,
    required this.amount,
    required this.icon,
    this.backgroundColor,
    this.textColor,
    this.amountColor,
    this.iconBorderColor,
  });

  factory AppStatCard.income({
    String title = 'Income',
    String amount = r'$4,120.00',
  }) {
    return AppStatCard(
      title: title,
      amount: amount,
      icon: QasehIcons.arrowDownCurved,
      backgroundColor: AppColors.lightGreen,
      textColor: AppColors.cyprus,
      amountColor: AppColors.cyprus,
      iconBorderColor: AppColors.caribbeanGreen,
    );
  }

  factory AppStatCard.expense({
    String title = 'Expense',
    String amount = r'$1,187.40',
  }) {
    return AppStatCard(
      title: title,
      amount: amount,
      icon: QasehIcons.arrowUpCurved,
      backgroundColor: AppColors.oceanBlue,
      textColor: AppColors.honeydew,
      amountColor: AppColors.honeydew,
      iconBorderColor: AppColors.honeydew,
    );
  }

  @override
  Widget build(BuildContext context) {
    final bg = backgroundColor ?? AppColors.lightGreen;
    final txtColor = textColor ?? AppColors.cyprus;
    final amtColor = amountColor ?? AppColors.cyprus;
    final borderCol = iconBorderColor ?? AppColors.caribbeanGreen;

    return Container(
      width: 171,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppConstants.radiusCardSmall),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 25,
                height: 25,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: borderCol, width: 1.5),
                ),
                child: Icon(icon, size: 14, color: borderCol),
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: AppTypography.cardTitle.copyWith(color: txtColor),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            amount,
            style: AppTypography.cardAmount.copyWith(color: amtColor),
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────
// Dialog Container – white card with radius 20
// Used for: logout confirmation, new category, delete
// ──────────────────────────────────────────────
class AppDialogContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;

  const AppDialogContainer({super.key, required this.child, this.padding});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: 339,
      padding: padding ?? const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.white,
        borderRadius: BorderRadius.circular(AppConstants.radiusDialog),
      ),
      child: child,
    );
  }
}

// ──────────────────────────────────────────────
// Balance Card – Total Balance header
// Used on Home screen header area
// ──────────────────────────────────────────────
class AppBalanceCard extends StatelessWidget {
  final String totalBalance;
  final String totalExpense;
  final VoidCallback? onNotificationTap;

  const AppBalanceCard({
    super.key,
    this.totalBalance = r'$20,000.00',
    this.totalExpense = r'-$1,187.40',
    this.onNotificationTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: const BoxDecoration(
        color: AppColors.caribbeanGreen,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(0),
          bottomRight: Radius.circular(0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total Balance',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.cyprus,
                ),
              ),
              GestureDetector(
                onTap: onNotificationTap,
                child: Container(
                  width: AppConstants.notificationIconSize,
                  height: AppConstants.notificationIconSize,
                  decoration: BoxDecoration(
                    color: AppColors.lightGreen,
                    borderRadius: BorderRadius.circular(
                      AppConstants.notificationIconSize / 2,
                    ),
                  ),
                  child: const Icon(
                    QasehIcons.notificationCurved,
                    size: 16,
                    color: AppColors.cyprus,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            totalBalance,
            style: AppTypography.nameBold.copyWith(
              color: AppColors.honeydew,
              fontSize: 24,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            totalExpense,
            style: AppTypography.cardAmount.copyWith(
              color: AppColors.oceanBlue,
              fontSize: 24,
            ),
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────
// Category Card – for category grid items
// Used in Categories screen
// ──────────────────────────────────────────────
class AppCategoryCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color? backgroundColor;
  final Color? iconColor;
  final VoidCallback? onTap;

  const AppCategoryCard({
    super.key,
    required this.label,
    required this.icon,
    this.backgroundColor,
    this.iconColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bg = backgroundColor ?? AppColors.lightGreen;
    final iColor = iconColor ?? AppColors.cyprus;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(AppConstants.radiusInput),
        ),
        child: Row(
          children: [
            Icon(icon, size: 22, color: iColor),
            const SizedBox(width: 12),
            Text(label, style: AppTypography.menuItem.copyWith(color: iColor)),
          ],
        ),
      ),
    );
  }
}
