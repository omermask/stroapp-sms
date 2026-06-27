// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'referral_info.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ReferralInfoImpl _$$ReferralInfoImplFromJson(Map<String, dynamic> json) =>
    _$ReferralInfoImpl(
      code: json['code'] as String,
      referralUrl: json['referral_url'] as String?,
      deepLinkUrl: json['deep_link_url'] as String?,
      totalReferrals: (json['total_referrals'] as num?)?.toInt(),
      totalRewardCoins: (json['total_reward_coins'] as num?)?.toInt(),
      referrals: json['referrals'] as List<dynamic>?,
    );

Map<String, dynamic> _$$ReferralInfoImplToJson(_$ReferralInfoImpl instance) =>
    <String, dynamic>{
      'code': instance.code,
      'referral_url': instance.referralUrl,
      'deep_link_url': instance.deepLinkUrl,
      'total_referrals': instance.totalReferrals,
      'total_reward_coins': instance.totalRewardCoins,
      'referrals': instance.referrals,
    };
