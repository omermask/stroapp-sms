import 'package:flutter/material.dart';
import '../../core/utils/qaseh_icons.dart';
import '../../core/models/order.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/theme/app_colors.dart';

class OrderDetailScreen extends StatelessWidget {
  final Order order;

  const OrderDetailScreen({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!.t;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final secondaryColor = isDark
        ? AppColors.darkTextSecondary
        : AppColors.lightTextSecondary;

    Color statusColor;
    IconData statusIcon;
    switch (order.status) {
      case 'completed':
        statusColor = AppColors.statusGreen;
        statusIcon = QasehIcons.tickSquareFilled;
      case 'pending':
        statusColor = AppColors.statusOrange;
        statusIcon = QasehIcons.timeCircleCurved;
      default:
        statusColor = AppColors.statusRed;
        statusIcon = QasehIcons.dangerTriangleCurved;
    }

    Widget row(String label, String value, {Color? valueColor}) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 130,
              child: Text(label,
                  style: TextStyle(color: secondaryColor, fontSize: 14)),
            ),
            Expanded(
              child: Text(
                value,
                style: TextStyle(
                  color: valueColor ?? textColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
          title: Text(
              '${t('orders')} #${order.id.length >= 8 ? order.id.substring(0, 8) : order.id}')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(statusIcon, color: statusColor, size: 24),
                      const SizedBox(width: 8),
                      Text(
                        order.status.toUpperCase(),
                        style: TextStyle(
                            color: statusColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 16),
                      ),
                      if (order.refunded) ...[
                        const SizedBox(width: 12),
                        Container(
                          padding:
                              const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.statusRed.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text('REFUNDED',
                              style: TextStyle(
                                  color: AppColors.statusRed,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ],
                  ),
                  const Divider(height: 24),
                  row('ID', order.id),
                  row('User ID', order.userId),
                  row('Service', order.service),
                  row('Country', order.country),
                  row('Provider', order.provider),
                  row('Phone', order.phoneNumber ?? '-'),
                  row('Coins', order.costCoins.toString()),
                  row('Activation ID', order.activationId ?? '-'),
                  row('Verification Code', order.verificationCode ?? '-'),
                  row('Created', order.createdAt.length >= 10
                      ? order.createdAt.substring(0, 10)
                      : order.createdAt),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
