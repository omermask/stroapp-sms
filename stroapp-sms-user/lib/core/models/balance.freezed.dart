// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'balance.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

Balance _$BalanceFromJson(Map<String, dynamic> json) {
  return _Balance.fromJson(json);
}

/// @nodoc
mixin _$Balance {
  int get coins => throw _privateConstructorUsedError;
  @JsonKey(name: 'lifetime_coins')
  int? get lifetimeCoins => throw _privateConstructorUsedError;
  @JsonKey(name: 'coins_in_usd')
  double? get coinsInUsd => throw _privateConstructorUsedError;

  /// Serializes this Balance to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of Balance
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $BalanceCopyWith<Balance> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $BalanceCopyWith<$Res> {
  factory $BalanceCopyWith(Balance value, $Res Function(Balance) then) =
      _$BalanceCopyWithImpl<$Res, Balance>;
  @useResult
  $Res call({
    int coins,
    @JsonKey(name: 'lifetime_coins') int? lifetimeCoins,
    @JsonKey(name: 'coins_in_usd') double? coinsInUsd,
  });
}

/// @nodoc
class _$BalanceCopyWithImpl<$Res, $Val extends Balance>
    implements $BalanceCopyWith<$Res> {
  _$BalanceCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Balance
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? coins = null,
    Object? lifetimeCoins = freezed,
    Object? coinsInUsd = freezed,
  }) {
    return _then(
      _value.copyWith(
            coins: null == coins
                ? _value.coins
                : coins // ignore: cast_nullable_to_non_nullable
                      as int,
            lifetimeCoins: freezed == lifetimeCoins
                ? _value.lifetimeCoins
                : lifetimeCoins // ignore: cast_nullable_to_non_nullable
                      as int?,
            coinsInUsd: freezed == coinsInUsd
                ? _value.coinsInUsd
                : coinsInUsd // ignore: cast_nullable_to_non_nullable
                      as double?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$BalanceImplCopyWith<$Res> implements $BalanceCopyWith<$Res> {
  factory _$$BalanceImplCopyWith(
    _$BalanceImpl value,
    $Res Function(_$BalanceImpl) then,
  ) = __$$BalanceImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    int coins,
    @JsonKey(name: 'lifetime_coins') int? lifetimeCoins,
    @JsonKey(name: 'coins_in_usd') double? coinsInUsd,
  });
}

/// @nodoc
class __$$BalanceImplCopyWithImpl<$Res>
    extends _$BalanceCopyWithImpl<$Res, _$BalanceImpl>
    implements _$$BalanceImplCopyWith<$Res> {
  __$$BalanceImplCopyWithImpl(
    _$BalanceImpl _value,
    $Res Function(_$BalanceImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of Balance
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? coins = null,
    Object? lifetimeCoins = freezed,
    Object? coinsInUsd = freezed,
  }) {
    return _then(
      _$BalanceImpl(
        coins: null == coins
            ? _value.coins
            : coins // ignore: cast_nullable_to_non_nullable
                  as int,
        lifetimeCoins: freezed == lifetimeCoins
            ? _value.lifetimeCoins
            : lifetimeCoins // ignore: cast_nullable_to_non_nullable
                  as int?,
        coinsInUsd: freezed == coinsInUsd
            ? _value.coinsInUsd
            : coinsInUsd // ignore: cast_nullable_to_non_nullable
                  as double?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$BalanceImpl implements _Balance {
  const _$BalanceImpl({
    required this.coins,
    @JsonKey(name: 'lifetime_coins') this.lifetimeCoins,
    @JsonKey(name: 'coins_in_usd') this.coinsInUsd,
  });

  factory _$BalanceImpl.fromJson(Map<String, dynamic> json) =>
      _$$BalanceImplFromJson(json);

  @override
  final int coins;
  @override
  @JsonKey(name: 'lifetime_coins')
  final int? lifetimeCoins;
  @override
  @JsonKey(name: 'coins_in_usd')
  final double? coinsInUsd;

  @override
  String toString() {
    return 'Balance(coins: $coins, lifetimeCoins: $lifetimeCoins, coinsInUsd: $coinsInUsd)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$BalanceImpl &&
            (identical(other.coins, coins) || other.coins == coins) &&
            (identical(other.lifetimeCoins, lifetimeCoins) ||
                other.lifetimeCoins == lifetimeCoins) &&
            (identical(other.coinsInUsd, coinsInUsd) ||
                other.coinsInUsd == coinsInUsd));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, coins, lifetimeCoins, coinsInUsd);

  /// Create a copy of Balance
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$BalanceImplCopyWith<_$BalanceImpl> get copyWith =>
      __$$BalanceImplCopyWithImpl<_$BalanceImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$BalanceImplToJson(this);
  }
}

abstract class _Balance implements Balance {
  const factory _Balance({
    required final int coins,
    @JsonKey(name: 'lifetime_coins') final int? lifetimeCoins,
    @JsonKey(name: 'coins_in_usd') final double? coinsInUsd,
  }) = _$BalanceImpl;

  factory _Balance.fromJson(Map<String, dynamic> json) = _$BalanceImpl.fromJson;

  @override
  int get coins;
  @override
  @JsonKey(name: 'lifetime_coins')
  int? get lifetimeCoins;
  @override
  @JsonKey(name: 'coins_in_usd')
  double? get coinsInUsd;

  /// Create a copy of Balance
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$BalanceImplCopyWith<_$BalanceImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
