// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'tier.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

Tier _$TierFromJson(Map<String, dynamic> json) {
  return _Tier.fromJson(json);
}

/// @nodoc
mixin _$Tier {
  String get tier => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  String? get description => throw _privateConstructorUsedError;
  @JsonKey(name: 'price_monthly')
  double? get priceMonthly => throw _privateConstructorUsedError;
  @JsonKey(name: 'quota_usd')
  double? get quotaUsd => throw _privateConstructorUsedError;
  @JsonKey(name: 'daily_verification_limit')
  int? get dailyVerificationLimit => throw _privateConstructorUsedError;
  @JsonKey(name: 'monthly_verification_limit')
  int? get monthlyVerificationLimit => throw _privateConstructorUsedError;
  @JsonKey(name: 'has_api_access')
  bool get hasApiAccess => throw _privateConstructorUsedError;
  @JsonKey(name: 'api_key_limit')
  int? get apiKeyLimit => throw _privateConstructorUsedError;
  @JsonKey(name: 'support_level')
  String? get supportLevel => throw _privateConstructorUsedError;
  @JsonKey(fromJson: _featuresFromJson)
  Map<String, dynamic>? get features => throw _privateConstructorUsedError;

  /// Serializes this Tier to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of Tier
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $TierCopyWith<Tier> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $TierCopyWith<$Res> {
  factory $TierCopyWith(Tier value, $Res Function(Tier) then) =
      _$TierCopyWithImpl<$Res, Tier>;
  @useResult
  $Res call({
    String tier,
    String name,
    String? description,
    @JsonKey(name: 'price_monthly') double? priceMonthly,
    @JsonKey(name: 'quota_usd') double? quotaUsd,
    @JsonKey(name: 'daily_verification_limit') int? dailyVerificationLimit,
    @JsonKey(name: 'monthly_verification_limit') int? monthlyVerificationLimit,
    @JsonKey(name: 'has_api_access') bool hasApiAccess,
    @JsonKey(name: 'api_key_limit') int? apiKeyLimit,
    @JsonKey(name: 'support_level') String? supportLevel,
    @JsonKey(fromJson: _featuresFromJson) Map<String, dynamic>? features,
  });
}

/// @nodoc
class _$TierCopyWithImpl<$Res, $Val extends Tier>
    implements $TierCopyWith<$Res> {
  _$TierCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Tier
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? tier = null,
    Object? name = null,
    Object? description = freezed,
    Object? priceMonthly = freezed,
    Object? quotaUsd = freezed,
    Object? dailyVerificationLimit = freezed,
    Object? monthlyVerificationLimit = freezed,
    Object? hasApiAccess = null,
    Object? apiKeyLimit = freezed,
    Object? supportLevel = freezed,
    Object? features = freezed,
  }) {
    return _then(
      _value.copyWith(
            tier: null == tier
                ? _value.tier
                : tier // ignore: cast_nullable_to_non_nullable
                      as String,
            name: null == name
                ? _value.name
                : name // ignore: cast_nullable_to_non_nullable
                      as String,
            description: freezed == description
                ? _value.description
                : description // ignore: cast_nullable_to_non_nullable
                      as String?,
            priceMonthly: freezed == priceMonthly
                ? _value.priceMonthly
                : priceMonthly // ignore: cast_nullable_to_non_nullable
                      as double?,
            quotaUsd: freezed == quotaUsd
                ? _value.quotaUsd
                : quotaUsd // ignore: cast_nullable_to_non_nullable
                      as double?,
            dailyVerificationLimit: freezed == dailyVerificationLimit
                ? _value.dailyVerificationLimit
                : dailyVerificationLimit // ignore: cast_nullable_to_non_nullable
                      as int?,
            monthlyVerificationLimit: freezed == monthlyVerificationLimit
                ? _value.monthlyVerificationLimit
                : monthlyVerificationLimit // ignore: cast_nullable_to_non_nullable
                      as int?,
            hasApiAccess: null == hasApiAccess
                ? _value.hasApiAccess
                : hasApiAccess // ignore: cast_nullable_to_non_nullable
                      as bool,
            apiKeyLimit: freezed == apiKeyLimit
                ? _value.apiKeyLimit
                : apiKeyLimit // ignore: cast_nullable_to_non_nullable
                      as int?,
            supportLevel: freezed == supportLevel
                ? _value.supportLevel
                : supportLevel // ignore: cast_nullable_to_non_nullable
                      as String?,
            features: freezed == features
                ? _value.features
                : features // ignore: cast_nullable_to_non_nullable
                      as Map<String, dynamic>?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$TierImplCopyWith<$Res> implements $TierCopyWith<$Res> {
  factory _$$TierImplCopyWith(
    _$TierImpl value,
    $Res Function(_$TierImpl) then,
  ) = __$$TierImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String tier,
    String name,
    String? description,
    @JsonKey(name: 'price_monthly') double? priceMonthly,
    @JsonKey(name: 'quota_usd') double? quotaUsd,
    @JsonKey(name: 'daily_verification_limit') int? dailyVerificationLimit,
    @JsonKey(name: 'monthly_verification_limit') int? monthlyVerificationLimit,
    @JsonKey(name: 'has_api_access') bool hasApiAccess,
    @JsonKey(name: 'api_key_limit') int? apiKeyLimit,
    @JsonKey(name: 'support_level') String? supportLevel,
    @JsonKey(fromJson: _featuresFromJson) Map<String, dynamic>? features,
  });
}

/// @nodoc
class __$$TierImplCopyWithImpl<$Res>
    extends _$TierCopyWithImpl<$Res, _$TierImpl>
    implements _$$TierImplCopyWith<$Res> {
  __$$TierImplCopyWithImpl(_$TierImpl _value, $Res Function(_$TierImpl) _then)
    : super(_value, _then);

  /// Create a copy of Tier
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? tier = null,
    Object? name = null,
    Object? description = freezed,
    Object? priceMonthly = freezed,
    Object? quotaUsd = freezed,
    Object? dailyVerificationLimit = freezed,
    Object? monthlyVerificationLimit = freezed,
    Object? hasApiAccess = null,
    Object? apiKeyLimit = freezed,
    Object? supportLevel = freezed,
    Object? features = freezed,
  }) {
    return _then(
      _$TierImpl(
        tier: null == tier
            ? _value.tier
            : tier // ignore: cast_nullable_to_non_nullable
                  as String,
        name: null == name
            ? _value.name
            : name // ignore: cast_nullable_to_non_nullable
                  as String,
        description: freezed == description
            ? _value.description
            : description // ignore: cast_nullable_to_non_nullable
                  as String?,
        priceMonthly: freezed == priceMonthly
            ? _value.priceMonthly
            : priceMonthly // ignore: cast_nullable_to_non_nullable
                  as double?,
        quotaUsd: freezed == quotaUsd
            ? _value.quotaUsd
            : quotaUsd // ignore: cast_nullable_to_non_nullable
                  as double?,
        dailyVerificationLimit: freezed == dailyVerificationLimit
            ? _value.dailyVerificationLimit
            : dailyVerificationLimit // ignore: cast_nullable_to_non_nullable
                  as int?,
        monthlyVerificationLimit: freezed == monthlyVerificationLimit
            ? _value.monthlyVerificationLimit
            : monthlyVerificationLimit // ignore: cast_nullable_to_non_nullable
                  as int?,
        hasApiAccess: null == hasApiAccess
            ? _value.hasApiAccess
            : hasApiAccess // ignore: cast_nullable_to_non_nullable
                  as bool,
        apiKeyLimit: freezed == apiKeyLimit
            ? _value.apiKeyLimit
            : apiKeyLimit // ignore: cast_nullable_to_non_nullable
                  as int?,
        supportLevel: freezed == supportLevel
            ? _value.supportLevel
            : supportLevel // ignore: cast_nullable_to_non_nullable
                  as String?,
        features: freezed == features
            ? _value._features
            : features // ignore: cast_nullable_to_non_nullable
                  as Map<String, dynamic>?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$TierImpl implements _Tier {
  const _$TierImpl({
    required this.tier,
    required this.name,
    this.description,
    @JsonKey(name: 'price_monthly') this.priceMonthly,
    @JsonKey(name: 'quota_usd') this.quotaUsd,
    @JsonKey(name: 'daily_verification_limit') this.dailyVerificationLimit,
    @JsonKey(name: 'monthly_verification_limit') this.monthlyVerificationLimit,
    @JsonKey(name: 'has_api_access') this.hasApiAccess = false,
    @JsonKey(name: 'api_key_limit') this.apiKeyLimit,
    @JsonKey(name: 'support_level') this.supportLevel,
    @JsonKey(fromJson: _featuresFromJson) final Map<String, dynamic>? features,
  }) : _features = features;

  factory _$TierImpl.fromJson(Map<String, dynamic> json) =>
      _$$TierImplFromJson(json);

  @override
  final String tier;
  @override
  final String name;
  @override
  final String? description;
  @override
  @JsonKey(name: 'price_monthly')
  final double? priceMonthly;
  @override
  @JsonKey(name: 'quota_usd')
  final double? quotaUsd;
  @override
  @JsonKey(name: 'daily_verification_limit')
  final int? dailyVerificationLimit;
  @override
  @JsonKey(name: 'monthly_verification_limit')
  final int? monthlyVerificationLimit;
  @override
  @JsonKey(name: 'has_api_access')
  final bool hasApiAccess;
  @override
  @JsonKey(name: 'api_key_limit')
  final int? apiKeyLimit;
  @override
  @JsonKey(name: 'support_level')
  final String? supportLevel;
  final Map<String, dynamic>? _features;
  @override
  @JsonKey(fromJson: _featuresFromJson)
  Map<String, dynamic>? get features {
    final value = _features;
    if (value == null) return null;
    if (_features is EqualUnmodifiableMapView) return _features;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(value);
  }

  @override
  String toString() {
    return 'Tier(tier: $tier, name: $name, description: $description, priceMonthly: $priceMonthly, quotaUsd: $quotaUsd, dailyVerificationLimit: $dailyVerificationLimit, monthlyVerificationLimit: $monthlyVerificationLimit, hasApiAccess: $hasApiAccess, apiKeyLimit: $apiKeyLimit, supportLevel: $supportLevel, features: $features)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$TierImpl &&
            (identical(other.tier, tier) || other.tier == tier) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.priceMonthly, priceMonthly) ||
                other.priceMonthly == priceMonthly) &&
            (identical(other.quotaUsd, quotaUsd) ||
                other.quotaUsd == quotaUsd) &&
            (identical(other.dailyVerificationLimit, dailyVerificationLimit) ||
                other.dailyVerificationLimit == dailyVerificationLimit) &&
            (identical(
                  other.monthlyVerificationLimit,
                  monthlyVerificationLimit,
                ) ||
                other.monthlyVerificationLimit == monthlyVerificationLimit) &&
            (identical(other.hasApiAccess, hasApiAccess) ||
                other.hasApiAccess == hasApiAccess) &&
            (identical(other.apiKeyLimit, apiKeyLimit) ||
                other.apiKeyLimit == apiKeyLimit) &&
            (identical(other.supportLevel, supportLevel) ||
                other.supportLevel == supportLevel) &&
            const DeepCollectionEquality().equals(other._features, _features));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    tier,
    name,
    description,
    priceMonthly,
    quotaUsd,
    dailyVerificationLimit,
    monthlyVerificationLimit,
    hasApiAccess,
    apiKeyLimit,
    supportLevel,
    const DeepCollectionEquality().hash(_features),
  );

  /// Create a copy of Tier
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$TierImplCopyWith<_$TierImpl> get copyWith =>
      __$$TierImplCopyWithImpl<_$TierImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$TierImplToJson(this);
  }
}

abstract class _Tier implements Tier {
  const factory _Tier({
    required final String tier,
    required final String name,
    final String? description,
    @JsonKey(name: 'price_monthly') final double? priceMonthly,
    @JsonKey(name: 'quota_usd') final double? quotaUsd,
    @JsonKey(name: 'daily_verification_limit')
    final int? dailyVerificationLimit,
    @JsonKey(name: 'monthly_verification_limit')
    final int? monthlyVerificationLimit,
    @JsonKey(name: 'has_api_access') final bool hasApiAccess,
    @JsonKey(name: 'api_key_limit') final int? apiKeyLimit,
    @JsonKey(name: 'support_level') final String? supportLevel,
    @JsonKey(fromJson: _featuresFromJson) final Map<String, dynamic>? features,
  }) = _$TierImpl;

  factory _Tier.fromJson(Map<String, dynamic> json) = _$TierImpl.fromJson;

  @override
  String get tier;
  @override
  String get name;
  @override
  String? get description;
  @override
  @JsonKey(name: 'price_monthly')
  double? get priceMonthly;
  @override
  @JsonKey(name: 'quota_usd')
  double? get quotaUsd;
  @override
  @JsonKey(name: 'daily_verification_limit')
  int? get dailyVerificationLimit;
  @override
  @JsonKey(name: 'monthly_verification_limit')
  int? get monthlyVerificationLimit;
  @override
  @JsonKey(name: 'has_api_access')
  bool get hasApiAccess;
  @override
  @JsonKey(name: 'api_key_limit')
  int? get apiKeyLimit;
  @override
  @JsonKey(name: 'support_level')
  String? get supportLevel;
  @override
  @JsonKey(fromJson: _featuresFromJson)
  Map<String, dynamic>? get features;

  /// Create a copy of Tier
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$TierImplCopyWith<_$TierImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
