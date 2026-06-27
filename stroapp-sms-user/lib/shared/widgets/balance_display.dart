import 'package:flutter/material.dart';

class BalanceDisplay extends StatelessWidget {
  final double amount;

  const BalanceDisplay({super.key, required this.amount});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.monetization_on, color: Colors.amber),
        const SizedBox(width: 8),
        Text(amount.toStringAsFixed(2), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      ],
    );
  }
}
