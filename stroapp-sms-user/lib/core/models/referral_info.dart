// ignore_for_file: invalid_annotation_target
import 'package:freezed_annotation/freezed_annotation.dart';
part 'referral_info.freezed.dart';
part 'referral_info.g.dart';

@freezed
class ReferralInfo with _$ReferralInfo {
  const factory ReferralInfo({
    required String code,
    @JsonKey(name: 'referral_url') String? referralUrl,
    @JsonKey(name: 'deep_link_url') String? deepLinkUrl,
    @JsonKey(name: 'total_referrals') int? totalReferrals,
    @JsonKey(name: 'total_reward_coins') int? totalRewardCoins,
    List<dynamic>? referrals,
  }) = _ReferralInfo;

  factory ReferralInfo.fromJson(Map<String, dynamic> json) => _$ReferralInfoFromJson(json);
}
