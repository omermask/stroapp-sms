import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class AppStatusBar extends StatelessWidget {
  final String time;
  final double width;

  const AppStatusBar({
    super.key,
    this.time = '9:41',
    this.width = 331,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: 16,
      child: Row(
        children: [
          Icon(Icons.wifi, size: 14, color: AppColors.ink),
          const Spacer(),
          Text(
            time,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.ink,
              height: 1.0,
            ),
          ),
          const Spacer(),
          Row(
            children: [
              Container(
                width: 13,
                height: 11,
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.ink, width: 1),
                  borderRadius: BorderRadius.circular(2),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(1),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(width: 2, height: 3, color: AppColors.ink),
                      const SizedBox(width: 1),
                      Container(width: 2, height: 5, color: AppColors.ink),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Container(
                width: 20,
                height: 10,
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.ink, width: 1),
                  borderRadius: BorderRadius.circular(2),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(1),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(width: 3, height: 3, color: AppColors.ink),
                      const SizedBox(width: 1),
                      Container(width: 3, height: 5, color: AppColors.ink),
                      const SizedBox(width: 1),
                      Container(width: 3, height: 7, color: AppColors.ink),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}