import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import 'app_icon.dart';

class AppCard extends StatelessWidget {
  final String? balance;
  final String? balanceUsd;
  final String? walletAddress;
  final String? label;
  final Widget? child;
  final double width;
  final double height;
  final VoidCallback? onCopy;

  const AppCard({
    super.key,
    this.balance,
    this.balanceUsd,
    this.walletAddress,
    this.label,
    this.child,
    this.width = 335,
    this.height = 160,
    this.onCopy,
  });

  factory AppCard.wallet({
    required String balance,
    required String balanceUsd,
    required String walletAddress,
    VoidCallback? onCopy,
  }) {
    return AppCard(
      balance: balance,
      balanceUsd: balanceUsd,
      walletAddress: walletAddress,
      onCopy: onCopy,
    );
  }

  factory AppCard.custom({required Widget child, double width = 335, double height = 160}) {
    return AppCard(width: width, height: height, child: child);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.cardLight,
        borderRadius: BorderRadius.circular(12),
      ),
      child: child
          ?? Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(balance ?? '', style: AppTextStyles.numberLarge.copyWith(color: AppColors.ink)),
                const SizedBox(height: 4),
                Text(balanceUsd ?? '', style: AppTextStyles.bodySmall.copyWith(color: AppColors.mutedStrong)),
                const Spacer(),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        walletAddress ?? '',
                        style: AppTextStyles.caption.copyWith(color: AppColors.mutedStrong),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 4),
                    GestureDetector(
                      onTap: onCopy,
                      child: AppIcon(name: AppIcons.copy, size: 20, color: AppColors.mutedStrong),
                    ),
                  ],
                ),
              ],
            ),
          ),
    );
  }
}