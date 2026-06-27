// ignore_for_file: invalid_annotation_target
import 'package:freezed_annotation/freezed_annotation.dart';
part 'tier.freezed.dart';
part 'tier.g.dart';

Map<String, dynamic>? _featuresFromJson(dynamic json) {
  if (json is Map<String, dynamic>) return json;
  if (json is List) return {};
  return null;
}

@freezed
class Tier with _$Tier {
  const factory Tier({
    required String tier,
    required String name,
    String? description,
    @JsonKey(name: 'price_monthly') double? priceMonthly,
    @JsonKey(name: 'quota_usd') double? quotaUsd,
    @JsonKey(name: 'daily_verification_limit') int? dailyVerificationLimit,
    @JsonKey(name: 'monthly_verification_limit') int? monthlyVerificationLimit,
    @JsonKey(name: 'has_api_access') @Default(false) bool hasApiAccess,
    @JsonKey(name: 'api_key_limit') int? apiKeyLimit,
    @JsonKey(name: 'support_level') String? supportLevel,
    @JsonKey(fromJson: _featuresFromJson) Map<String, dynamic>? features,
  }) = _Tier;

  factory Tier.fromJson(Map<String, dynamic> json) => _$TierFromJson(json);
}
