// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tier.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$TierImpl _$$TierImplFromJson(Map<String, dynamic> json) => _$TierImpl(
  tier: json['tier'] as String,
  name: json['name'] as String,
  description: json['description'] as String?,
  priceMonthly: (json['price_monthly'] as num?)?.toDouble(),
  quotaUsd: (json['quota_usd'] as num?)?.toDouble(),
  dailyVerificationLimit: (json['daily_verification_limit'] as num?)?.toInt(),
  monthlyVerificationLimit: (json['monthly_verification_limit'] as num?)
      ?.toInt(),
  hasApiAccess: json['has_api_access'] as bool? ?? false,
  apiKeyLimit: (json['api_key_limit'] as num?)?.toInt(),
  supportLevel: json['support_level'] as String?,
  features: _featuresFromJson(json['features']),
);

Map<String, dynamic> _$$TierImplToJson(_$TierImpl instance) =>
    <String, dynamic>{
      'tier': instance.tier,
      'name': instance.name,
      'description': instance.description,
      'price_monthly': instance.priceMonthly,
      'quota_usd': instance.quotaUsd,
      'daily_verification_limit': instance.dailyVerificationLimit,
      'monthly_verification_limit': instance.monthlyVerificationLimit,
      'has_api_access': instance.hasApiAccess,
      'api_key_limit': instance.apiKeyLimit,
      'support_level': instance.supportLevel,
      'features': instance.features,
    };
