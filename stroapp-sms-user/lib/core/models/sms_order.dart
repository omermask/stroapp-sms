// ignore_for_file: invalid_annotation_target
import 'package:freezed_annotation/freezed_annotation.dart';
part 'sms_order.freezed.dart';
part 'sms_order.g.dart';

@freezed
class SMSOrder with _$SMSOrder {
  const factory SMSOrder({
    required String id,
    required String service,
    @JsonKey(name: 'service_name') String? serviceName,
    required String country,
    @JsonKey(name: 'country_name') String? countryName,
    required String provider,
    @JsonKey(name: 'phone_number') required String phoneNumber,
    required String status,
    @JsonKey(name: 'cost_coins') required int costCoins,
    @JsonKey(name: 'verification_code') String? verificationCode,
    @JsonKey(name: 'sms_text') String? smsText,
    @JsonKey(name: 'sms_received_at') DateTime? smsReceivedAt,
    bool? refunded,
    @JsonKey(name: 'error_message') String? errorMessage,
    @JsonKey(name: 'created_at') required DateTime createdAt,
    @JsonKey(name: 'updated_at') DateTime? updatedAt,
  }) = _SMSOrder;

  factory SMSOrder.fromJson(Map<String, dynamic> json) => _$SMSOrderFromJson(json);
}
