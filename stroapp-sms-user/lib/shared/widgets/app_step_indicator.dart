import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class AppStepIndicator extends StatelessWidget {
  final int currentStep;
  final int totalSteps;

  const AppStepIndicator({
    super.key,
    required this.currentStep,
    this.totalSteps = 3,
  });

  @override
  Widget build(BuildContext context) {
    final stripWidth = totalSteps > 1 ? (322 / (totalSteps - 1)) : 0.0;

    return SizedBox(
      height: 20,
      width: 335,
      child: Stack(
        alignment: Alignment.centerLeft,
        children: [
          Positioned(
            left: 0,
            right: 0,
            child: Container(
              height: 2,
              decoration: BoxDecoration(
                color: AppColors.hairlineLight,
                borderRadius: BorderRadius.circular(1),
              ),
            ),
          ),
          if (currentStep > 1)
            Positioned(
              left: 0,
              child: Container(
                height: 2,
                width: stripWidth * (currentStep - 1),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
            ),
          Positioned.fill(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(totalSteps, (i) {
                final stepNum = i + 1;
                final isCompleted = stepNum < currentStep;
                final isCurrent = stepNum == currentStep;

                Color outerColor;
                Color innerColor;
                if (isCompleted) {
                  outerColor = AppColors.primary;
                  innerColor = AppColors.primary;
                } else if (isCurrent) {
                  outerColor = AppColors.hairlineLight;
                  innerColor = AppColors.primary;
                } else {
                  outerColor = AppColors.hairlineLight;
                  innerColor = AppColors.hairlineLight;
                }

                return Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: outerColor,
                  ),
                  child: Center(
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: innerColor,
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}