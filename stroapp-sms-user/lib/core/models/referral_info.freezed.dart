// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'referral_info.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

ReferralInfo _$ReferralInfoFromJson(Map<String, dynamic> json) {
  return _ReferralInfo.fromJson(json);
}

/// @nodoc
mixin _$ReferralInfo {
  String get code => throw _privateConstructorUsedError;
  @JsonKey(name: 'referral_url')
  String? get referralUrl => throw _privateConstructorUsedError;
  @JsonKey(name: 'deep_link_url')
  String? get deepLinkUrl => throw _privateConstructorUsedError;
  @JsonKey(name: 'total_referrals')
  int? get totalReferrals => throw _privateConstructorUsedError;
  @JsonKey(name: 'total_reward_coins')
  int? get totalRewardCoins => throw _privateConstructorUsedError;
  List<dynamic>? get referrals => throw _privateConstructorUsedError;

  /// Serializes this ReferralInfo to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ReferralInfo
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ReferralInfoCopyWith<ReferralInfo> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ReferralInfoCopyWith<$Res> {
  factory $ReferralInfoCopyWith(
    ReferralInfo value,
    $Res Function(ReferralInfo) then,
  ) = _$ReferralInfoCopyWithImpl<$Res, ReferralInfo>;
  @useResult
  $Res call({
    String code,
    @JsonKey(name: 'referral_url') String? referralUrl,
    @JsonKey(name: 'deep_link_url') String? deepLinkUrl,
    @JsonKey(name: 'total_referrals') int? totalReferrals,
    @JsonKey(name: 'total_reward_coins') int? totalRewardCoins,
    List<dynamic>? referrals,
  });
}

/// @nodoc
class _$ReferralInfoCopyWithImpl<$Res, $Val extends ReferralInfo>
    implements $ReferralInfoCopyWith<$Res> {
  _$ReferralInfoCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ReferralInfo
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? code = null,
    Object? referralUrl = freezed,
    Object? deepLinkUrl = freezed,
    Object? totalReferrals = freezed,
    Object? totalRewardCoins = freezed,
    Object? referrals = freezed,
  }) {
    return _then(
      _value.copyWith(
            code: null == code
                ? _value.code
                : code // ignore: cast_nullable_to_non_nullable
                      as String,
            referralUrl: freezed == referralUrl
                ? _value.referralUrl
                : referralUrl // ignore: cast_nullable_to_non_nullable
                      as String?,
            deepLinkUrl: freezed == deepLinkUrl
                ? _value.deepLinkUrl
                : deepLinkUrl // ignore: cast_nullable_to_non_nullable
                      as String?,
            totalReferrals: freezed == totalReferrals
                ? _value.totalReferrals
                : totalReferrals // ignore: cast_nullable_to_non_nullable
                      as int?,
            totalRewardCoins: freezed == totalRewardCoins
                ? _value.totalRewardCoins
                : totalRewardCoins // ignore: cast_nullable_to_non_nullable
                      as int?,
            referrals: freezed == referrals
                ? _value.referrals
                : referrals // ignore: cast_nullable_to_non_nullable
                      as List<dynamic>?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$ReferralInfoImplCopyWith<$Res>
    implements $ReferralInfoCopyWith<$Res> {
  factory _$$ReferralInfoImplCopyWith(
    _$ReferralInfoImpl value,
    $Res Function(_$ReferralInfoImpl) then,
  ) = __$$ReferralInfoImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String code,
    @JsonKey(name: 'referral_url') String? referralUrl,
    @JsonKey(name: 'deep_link_url') String? deepLinkUrl,
    @JsonKey(name: 'total_referrals') int? totalReferrals,
    @JsonKey(name: 'total_reward_coins') int? totalRewardCoins,
    List<dynamic>? referrals,
  });
}

/// @nodoc
class __$$ReferralInfoImplCopyWithImpl<$Res>
    extends _$ReferralInfoCopyWithImpl<$Res, _$ReferralInfoImpl>
    implements _$$ReferralInfoImplCopyWith<$Res> {
  __$$ReferralInfoImplCopyWithImpl(
    _$ReferralInfoImpl _value,
    $Res Function(_$ReferralInfoImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of ReferralInfo
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? code = null,
    Object? referralUrl = freezed,
    Object? deepLinkUrl = freezed,
    Object? totalReferrals = freezed,
    Object? totalRewardCoins = freezed,
    Object? referrals = freezed,
  }) {
    return _then(
      _$ReferralInfoImpl(
        code: null == code
            ? _value.code
            : code // ignore: cast_nullable_to_non_nullable
                  as String,
        referralUrl: freezed == referralUrl
            ? _value.referralUrl
            : referralUrl // ignore: cast_nullable_to_non_nullable
                  as String?,
        deepLinkUrl: freezed == deepLinkUrl
            ? _value.deepLinkUrl
            : deepLinkUrl // ignore: cast_nullable_to_non_nullable
                  as String?,
        totalReferrals: freezed == totalReferrals
            ? _value.totalReferrals
            : totalReferrals // ignore: cast_nullable_to_non_nullable
                  as int?,
        totalRewardCoins: freezed == totalRewardCoins
            ? _value.totalRewardCoins
            : totalRewardCoins // ignore: cast_nullable_to_non_nullable
                  as int?,
        referrals: freezed == referrals
            ? _value._referrals
            : referrals // ignore: cast_nullable_to_non_nullable
                  as List<dynamic>?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$ReferralInfoImpl implements _ReferralInfo {
  const _$ReferralInfoImpl({
    required this.code,
    @JsonKey(name: 'referral_url') this.referralUrl,
    @JsonKey(name: 'deep_link_url') this.deepLinkUrl,
    @JsonKey(name: 'total_referrals') this.totalReferrals,
    @JsonKey(name: 'total_reward_coins') this.totalRewardCoins,
    final List<dynamic>? referrals,
  }) : _referrals = referrals;

  factory _$ReferralInfoImpl.fromJson(Map<String, dynamic> json) =>
      _$$ReferralInfoImplFromJson(json);

  @override
  final String code;
  @override
  @JsonKey(name: 'referral_url')
  final String? referralUrl;
  @override
  @JsonKey(name: 'deep_link_url')
  final String? deepLinkUrl;
  @override
  @JsonKey(name: 'total_referrals')
  final int? totalReferrals;
  @override
  @JsonKey(name: 'total_reward_coins')
  final int? totalRewardCoins;
  final List<dynamic>? _referrals;
  @override
  List<dynamic>? get referrals {
    final value = _referrals;
    if (value == null) return null;
    if (_referrals is EqualUnmodifiableListView) return _referrals;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  @override
  String toString() {
    return 'ReferralInfo(code: $code, referralUrl: $referralUrl, deepLinkUrl: $deepLinkUrl, totalReferrals: $totalReferrals, totalRewardCoins: $totalRewardCoins, referrals: $referrals)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ReferralInfoImpl &&
            (identical(other.code, code) || other.code == code) &&
            (identical(other.referralUrl, referralUrl) ||
                other.referralUrl == referralUrl) &&
            (identical(other.deepLinkUrl, deepLinkUrl) ||
                other.deepLinkUrl == deepLinkUrl) &&
            (identical(other.totalReferrals, totalReferrals) ||
                other.totalReferrals == totalReferrals) &&
            (identical(other.totalRewardCoins, totalRewardCoins) ||
                other.totalRewardCoins == totalRewardCoins) &&
            const DeepCollectionEquality().equals(
              other._referrals,
              _referrals,
            ));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    code,
    referralUrl,
    deepLinkUrl,
    totalReferrals,
    totalRewardCoins,
    const DeepCollectionEquality().hash(_referrals),
  );

  /// Create a copy of ReferralInfo
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ReferralInfoImplCopyWith<_$ReferralInfoImpl> get copyWith =>
      __$$ReferralInfoImplCopyWithImpl<_$ReferralInfoImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ReferralInfoImplToJson(this);
  }
}

abstract class _ReferralInfo implements ReferralInfo {
  const factory _ReferralInfo({
    required final String code,
    @JsonKey(name: 'referral_url') final String? referralUrl,
    @JsonKey(name: 'deep_link_url') final String? deepLinkUrl,
    @JsonKey(name: 'total_referrals') final int? totalReferrals,
    @JsonKey(name: 'total_reward_coins') final int? totalRewardCoins,
    final List<dynamic>? referrals,
  }) = _$ReferralInfoImpl;

  factory _ReferralInfo.fromJson(Map<String, dynamic> json) =
      _$ReferralInfoImpl.fromJson;

  @override
  String get code;
  @override
  @JsonKey(name: 'referral_url')
  String? get referralUrl;
  @override
  @JsonKey(name: 'deep_link_url')
  String? get deepLinkUrl;
  @override
  @JsonKey(name: 'total_referrals')
  int? get totalReferrals;
  @override
  @JsonKey(name: 'total_reward_coins')
  int? get totalRewardCoins;
  @override
  List<dynamic>? get referrals;

  /// Create a copy of ReferralInfo
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ReferralInfoImplCopyWith<_$ReferralInfoImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
