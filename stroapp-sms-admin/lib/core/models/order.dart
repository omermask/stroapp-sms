class Order {
  final String id;
  final String userId;
  final String service;
  final String country;
  final String provider;
  final String? phoneNumber;
  final String status;
  final int costCoins;
  final String? activationId;
  final String? verificationCode;
  final bool refunded;
  final String createdAt;

  Order({
    required this.id,
    required this.userId,
    required this.service,
    required this.country,
    required this.provider,
    this.phoneNumber,
    required this.status,
    required this.costCoins,
    this.activationId,
    this.verificationCode,
    this.refunded = false,
    required this.createdAt,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id'] as String? ?? '',
      userId: json['user_id'] as String? ?? '',
      service: json['service'] as String? ?? '',
      country: json['country'] as String? ?? '',
      provider: json['provider'] as String? ?? '',
      phoneNumber: json['phone_number'] as String?,
      status: json['status'] as String? ?? 'pending',
      costCoins: json['cost_coins'] as int? ?? 0,
      activationId: json['activation_id'] as String?,
      verificationCode: json['verification_code'] as String?,
      refunded: json['refunded'] as bool? ?? false,
      createdAt: json['created_at'] as String? ?? '',
    );
  }

  String get serviceLabel => service.length >= 2
      ? service.substring(0, 2).toUpperCase()
      : service.toUpperCase();
}
