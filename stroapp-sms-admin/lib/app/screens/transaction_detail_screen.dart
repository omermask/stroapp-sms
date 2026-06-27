import 'package:flutter/material.dart';
import '../../core/utils/qaseh_icons.dart';
import '../../core/models/transaction.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/theme/app_colors.dart';

class TransactionDetailScreen extends StatelessWidget {
  final Transaction transaction;

  const TransactionDetailScreen({super.key, required this.transaction});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!.t;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark
        ? AppColors.darkTextPrimary
        : AppColors.lightTextPrimary;
    final secondaryColor = isDark
        ? AppColors.darkTextSecondary
        : AppColors.lightTextSecondary;

    final isPositive = transaction.isDeposit;
    final amountColor = isPositive ? AppColors.statusGreen : AppColors.statusRed;
    final amountPrefix = isPositive ? '+' : '';

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
              '${t('transactions')} #${transaction.id.length >= 8 ? transaction.id.substring(0, 8) : transaction.id}')),
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
                      Icon(
                        isPositive
                            ? QasehIcons.arrowDownCurved
                            : QasehIcons.arrowUpCurved,
                        color: amountColor,
                        size: 24,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '$amountPrefix${transaction.amount} coins',
                        style: TextStyle(
                            color: amountColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 20),
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  row('ID', transaction.id),
                  row('User ID', transaction.userId),
                  row('Type', transaction.type),
                  row('Description', transaction.description ?? '-'),
                  row('Reference', transaction.reference ?? '-'),
                  row('Coins Before', transaction.coinsBefore?.toString() ?? '-'),
                  row('Coins After', transaction.coinsAfter?.toString() ?? '-'),
                  row('Created', transaction.createdAt.length >= 10
                      ? transaction.createdAt.substring(0, 10)
                      : transaction.createdAt),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
