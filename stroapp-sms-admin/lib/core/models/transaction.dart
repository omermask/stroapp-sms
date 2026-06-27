class Transaction {
  final String id;
  final String userId;
  final int amount;
  final String type;
  final String? description;
  final String? reference;
  final int? coinsBefore;
  final int? coinsAfter;
  final String createdAt;

  Transaction({
    required this.id,
    required this.userId,
    required this.amount,
    required this.type,
    this.description,
    this.reference,
    this.coinsBefore,
    this.coinsAfter,
    required this.createdAt,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['id'] as String? ?? '',
      userId: json['user_id'] as String? ?? '',
      amount: json['amount'] as int? ?? 0,
      type: json['type'] as String? ?? '',
      description: json['description'] as String?,
      reference: json['reference'] as String?,
      coinsBefore: json['coins_before'] as int?,
      coinsAfter: json['coins_after'] as int?,
      createdAt: json['created_at'] as String? ?? '',
    );
  }

  bool get isDeposit => amount >= 0;
}
