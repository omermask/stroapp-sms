import 'package:flutter/material.dart';
import '../utils/qaseh_icons.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../constants/app_constants.dart';

// ──────────────────────────────────────────────
// Notification Bell
// Used: top right of screen headers
// ──────────────────────────────────────────────
class AppNotificationBell extends StatelessWidget {
  final VoidCallback? onTap;
  final int? badgeCount;

  const AppNotificationBell({super.key, this.onTap, this.badgeCount});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: AppConstants.notificationIconSize,
        height: AppConstants.notificationIconSize,
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkNotificationBg : AppColors.lightGreen,
          shape: BoxShape.circle,
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            const Center(
              child: Icon(
                QasehIcons.notificationCurved,
                size: 16,
                color: AppColors.cyprus,
              ),
            ),
            if (badgeCount != null && badgeCount! > 0)
              Positioned(
                top: -2,
                right: -2,
                child: Container(
                  width: 16,
                  height: 16,
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '$badgeCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────
// Avatar – circular profile picture
// Used: Profile screen
// ──────────────────────────────────────────────
class AppAvatar extends StatelessWidget {
  final String? imageUrl;
  final String? initials;
  final double size;

  const AppAvatar({
    super.key,
    this.imageUrl,
    this.initials,
    this.size = AppConstants.avatarSize,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.lightGreen,
        image: imageUrl != null
            ? DecorationImage(image: NetworkImage(imageUrl!), fit: BoxFit.cover)
            : null,
      ),
      child: (imageUrl == null && initials != null)
          ? Center(
              child: Text(
                initials!,
                style: AppTypography.nameBold.copyWith(
                  color: AppColors.cyprus,
                  fontSize: size * 0.35,
                ),
              ),
            )
          : null,
    );
  }
}

// ──────────────────────────────────────────────
// Progress Bar – linear progress
// Used: Savings goals, budget progress
// ──────────────────────────────────────────────
class AppProgressBar extends StatelessWidget {
  final double progress; // 0.0 – 1.0
  final String label;
  final String amount;
  final Color? backgroundColor;
  final Color? fillColor;

  const AppProgressBar({
    super.key,
    required this.progress,
    this.label = '30% of your expenses, looks good.',
    this.amount = r'$7,783.00',
    this.backgroundColor,
    this.fillColor,
  });

  @override
  Widget build(BuildContext context) {
    final bg = backgroundColor ?? AppColors.lightGreen;
    final fill = fillColor ?? AppColors.fenceGreen;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label
        Text(
          label,
          style: AppTypography.bodyRegular.copyWith(
            color: AppColors.fenceGreen,
            fontSize: 15,
          ),
        ),
        const SizedBox(height: 8),
        // Amount + percentage
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              amount,
              style: AppTypography.menuItem.copyWith(
                color: AppColors.fenceGreen,
                fontSize: 13,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: fill,
                borderRadius: BorderRadius.circular(13.5),
              ),
              child: Text(
                '${(progress * 100).round()}%',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.honeydew,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        // Bar
        ClipRRect(
          borderRadius: BorderRadius.circular(13.5),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: bg,
            valueColor: AlwaysStoppedAnimation(fill),
            minHeight: 8,
          ),
        ),
      ],
    );
  }
}

// ──────────────────────────────────────────────
// Transaction Item – single row
// Used: Transaction list
// ──────────────────────────────────────────────
class AppTransactionItem extends StatelessWidget {
  final String date;
  final String category;
  final String amount;
  final String title;
  final bool isExpense;
  final VoidCallback? onTap;

  const AppTransactionItem({
    super.key,
    required this.date,
    required this.category,
    required this.amount,
    required this.title,
    this.isExpense = true,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final amountColor = isExpense
        ? AppColors.oceanBlue
        : AppColors.caribbeanGreen;
    final sign = isExpense ? '-' : '+';
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            // Category icon placeholder
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.lightGreen,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                _categoryIcon(category),
                color: AppColors.cyprus,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    category,
                    style: AppTypography.menuItem.copyWith(
                      color: AppColors.cyprus,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$date  ·  $title',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.cyprus,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              '$sign$amount',
              style: AppTypography.menuItem.copyWith(
                color: amountColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _categoryIcon(String cat) {
    switch (cat.toLowerCase()) {
      case 'food':
        return QasehIcons.bagCurved;
      case 'transport':
        return QasehIcons.locationCurved;
      case 'groceries':
        return QasehIcons.bagCurved;
      case 'rent':
        return QasehIcons.homeCurved;
      case 'gifts':
        return QasehIcons.ticketCurved;
      case 'medicine':
        return QasehIcons.callCurved;
      case 'entertainment':
        return QasehIcons.videoCurved;
      case 'saving':
        return QasehIcons.walletCurved;
      default:
        return QasehIcons.documentCurved;
    }
  }
}

// ──────────────────────────────────────────────
// Category Chip – selectable category filter
// Used: Add expense / filter
// ──────────────────────────────────────────────
class AppCategoryChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback? onTap;

  const AppCategoryChip({
    super.key,
    required this.label,
    this.isSelected = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.caribbeanGreen : AppColors.lightGreen,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Text(
          label,
          style: AppTypography.bodyRegular.copyWith(
            color: isSelected ? AppColors.honeydew : AppColors.cyprus,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────
// Category Selector Dropdown
// Used: Add expense screen
// ──────────────────────────────────────────────
class AppCategorySelector extends StatelessWidget {
  final String? selectedCategory;
  final ValueChanged<String?>? onChanged;
  final List<String> categories;

  const AppCategorySelector({
    super.key,
    this.selectedCategory,
    this.onChanged,
    this.categories = const [
      'Food',
      'Transport',
      'Groceries',
      'Rent',
      'Gifts',
      'Medicine',
      'Entertainment',
      'Saving',
    ],
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkTextFieldBg : AppColors.lightTextFieldBg,
        borderRadius: BorderRadius.circular(AppConstants.radiusInput),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selectedCategory,
          isExpanded: true,
          hint: Text(
            'Select the category',
            style: AppTypography.bodyRegular.copyWith(color: AppColors.cyprus),
          ),
          dropdownColor: isDark ? AppColors.darkCard : AppColors.white,
          style: AppTypography.menuItem.copyWith(color: AppColors.fenceGreen),
          icon: const Icon(
            QasehIcons.arrowDownCurved,
            color: AppColors.caribbeanGreen,
          ),
          items: categories.map((cat) {
            return DropdownMenuItem(value: cat, child: Text(cat));
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────
// PIN Dot Input – security PIN code
// Used: Security PIN screen
// ──────────────────────────────────────────────
class AppPinDots extends StatelessWidget {
  final int pinLength;
  final int enteredLength;
  final double dotSize;

  const AppPinDots({
    super.key,
    this.pinLength = 6,
    this.enteredLength = 0,
    this.dotSize = 14,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(pinLength, (i) {
        final filled = i < enteredLength;
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 8),
          width: dotSize,
          height: dotSize,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: filled ? AppColors.caribbeanGreen : Colors.transparent,
            border: Border.all(
              color: filled ? AppColors.caribbeanGreen : AppColors.cyprus,
              width: 2,
            ),
          ),
        );
      }),
    );
  }
}

// ──────────────────────────────────────────────
// Fingerprint Icon – biometric authentication
// Used: Security Fingerprint screen
// ──────────────────────────────────────────────
class AppFingerprintIcon extends StatelessWidget {
  final double size;
  final Color? color;

  const AppFingerprintIcon({super.key, this.size = 80, this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.lightGreen,
        shape: BoxShape.circle,
      ),
      child: Icon(
        QasehIcons.scanCurved,
        size: size * 0.55,
        color: color ?? AppColors.cyprus,
      ),
    );
  }
}

// ──────────────────────────────────────────────
// App Logo – "FinWise" text logo
// Used: Launch / Login screens
// ──────────────────────────────────────────────
class AppLogo extends StatelessWidget {
  final double fontSize;
  final Color? color;

  const AppLogo({super.key, this.fontSize = 52, this.color});

  @override
  Widget build(BuildContext context) {
    return Text(
      'FinWise',
      style: TextStyle(
        fontFamily: 'Poppins',
        fontWeight: FontWeight.w600,
        fontSize: fontSize,
        color: color ?? AppColors.caribbeanGreen,
      ),
    );
  }
}

// ──────────────────────────────────────────────
// Onboarding Dot Indicator
// Used: Onboarding screens
// ──────────────────────────────────────────────
class AppDotIndicator extends StatelessWidget {
  final int itemCount;
  final int currentIndex;
  final Color activeColor;
  final Color inactiveColor;

  const AppDotIndicator({
    super.key,
    required this.itemCount,
    required this.currentIndex,
    this.activeColor = AppColors.caribbeanGreen,
    this.inactiveColor = AppColors.lightGreen,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(itemCount, (i) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: i == currentIndex ? 24 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: i == currentIndex ? activeColor : inactiveColor,
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }
}
