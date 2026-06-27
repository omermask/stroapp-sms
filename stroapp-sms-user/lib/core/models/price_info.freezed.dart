// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'price_info.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

PriceInfo _$PriceInfoFromJson(Map<String, dynamic> json) {
  return _PriceInfo.fromJson(json);
}

/// @nodoc
mixin _$PriceInfo {
  String get service => throw _privateConstructorUsedError;
  String get country => throw _privateConstructorUsedError;
  String? get provider => throw _privateConstructorUsedError;
  double? get price => throw _privateConstructorUsedError;
  double? get priceWithMarkup => throw _privateConstructorUsedError;
  int? get costCoins => throw _privateConstructorUsedError;

  /// Serializes this PriceInfo to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of PriceInfo
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $PriceInfoCopyWith<PriceInfo> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PriceInfoCopyWith<$Res> {
  factory $PriceInfoCopyWith(PriceInfo value, $Res Function(PriceInfo) then) =
      _$PriceInfoCopyWithImpl<$Res, PriceInfo>;
  @useResult
  $Res call({
    String service,
    String country,
    String? provider,
    double? price,
    double? priceWithMarkup,
    int? costCoins,
  });
}

/// @nodoc
class _$PriceInfoCopyWithImpl<$Res, $Val extends PriceInfo>
    implements $PriceInfoCopyWith<$Res> {
  _$PriceInfoCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of PriceInfo
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? service = null,
    Object? country = null,
    Object? provider = freezed,
    Object? price = freezed,
    Object? priceWithMarkup = freezed,
    Object? costCoins = freezed,
  }) {
    return _then(
      _value.copyWith(
            service: null == service
                ? _value.service
                : service // ignore: cast_nullable_to_non_nullable
                      as String,
            country: null == country
                ? _value.country
                : country // ignore: cast_nullable_to_non_nullable
                      as String,
            provider: freezed == provider
                ? _value.provider
                : provider // ignore: cast_nullable_to_non_nullable
                      as String?,
            price: freezed == price
                ? _value.price
                : price // ignore: cast_nullable_to_non_nullable
                      as double?,
            priceWithMarkup: freezed == priceWithMarkup
                ? _value.priceWithMarkup
                : priceWithMarkup // ignore: cast_nullable_to_non_nullable
                      as double?,
            costCoins: freezed == costCoins
                ? _value.costCoins
                : costCoins // ignore: cast_nullable_to_non_nullable
                      as int?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$PriceInfoImplCopyWith<$Res>
    implements $PriceInfoCopyWith<$Res> {
  factory _$$PriceInfoImplCopyWith(
    _$PriceInfoImpl value,
    $Res Function(_$PriceInfoImpl) then,
  ) = __$$PriceInfoImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String service,
    String country,
    String? provider,
    double? price,
    double? priceWithMarkup,
    int? costCoins,
  });
}

/// @nodoc
class __$$PriceInfoImplCopyWithImpl<$Res>
    extends _$PriceInfoCopyWithImpl<$Res, _$PriceInfoImpl>
    implements _$$PriceInfoImplCopyWith<$Res> {
  __$$PriceInfoImplCopyWithImpl(
    _$PriceInfoImpl _value,
    $Res Function(_$PriceInfoImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of PriceInfo
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? service = null,
    Object? country = null,
    Object? provider = freezed,
    Object? price = freezed,
    Object? priceWithMarkup = freezed,
    Object? costCoins = freezed,
  }) {
    return _then(
      _$PriceInfoImpl(
        service: null == service
            ? _value.service
            : service // ignore: cast_nullable_to_non_nullable
                  as String,
        country: null == country
            ? _value.country
            : country // ignore: cast_nullable_to_non_nullable
                  as String,
        provider: freezed == provider
            ? _value.provider
            : provider // ignore: cast_nullable_to_non_nullable
                  as String?,
        price: freezed == price
            ? _value.price
            : price // ignore: cast_nullable_to_non_nullable
                  as double?,
        priceWithMarkup: freezed == priceWithMarkup
            ? _value.priceWithMarkup
            : priceWithMarkup // ignore: cast_nullable_to_non_nullable
                  as double?,
        costCoins: freezed == costCoins
            ? _value.costCoins
            : costCoins // ignore: cast_nullable_to_non_nullable
                  as int?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$PriceInfoImpl implements _PriceInfo {
  const _$PriceInfoImpl({
    required this.service,
    required this.country,
    this.provider,
    this.price,
    this.priceWithMarkup,
    this.costCoins,
  });

  factory _$PriceInfoImpl.fromJson(Map<String, dynamic> json) =>
      _$$PriceInfoImplFromJson(json);

  @override
  final String service;
  @override
  final String country;
  @override
  final String? provider;
  @override
  final double? price;
  @override
  final double? priceWithMarkup;
  @override
  final int? costCoins;

  @override
  String toString() {
    return 'PriceInfo(service: $service, country: $country, provider: $provider, price: $price, priceWithMarkup: $priceWithMarkup, costCoins: $costCoins)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PriceInfoImpl &&
            (identical(other.service, service) || other.service == service) &&
            (identical(other.country, country) || other.country == country) &&
            (identical(other.provider, provider) ||
                other.provider == provider) &&
            (identical(other.price, price) || other.price == price) &&
            (identical(other.priceWithMarkup, priceWithMarkup) ||
                other.priceWithMarkup == priceWithMarkup) &&
            (identical(other.costCoins, costCoins) ||
                other.costCoins == costCoins));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    service,
    country,
    provider,
    price,
    priceWithMarkup,
    costCoins,
  );

  /// Create a copy of PriceInfo
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$PriceInfoImplCopyWith<_$PriceInfoImpl> get copyWith =>
      __$$PriceInfoImplCopyWithImpl<_$PriceInfoImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$PriceInfoImplToJson(this);
  }
}

abstract class _PriceInfo implements PriceInfo {
  const factory _PriceInfo({
    required final String service,
    required final String country,
    final String? provider,
    final double? price,
    final double? priceWithMarkup,
    final int? costCoins,
  }) = _$PriceInfoImpl;

  factory _PriceInfo.fromJson(Map<String, dynamic> json) =
      _$PriceInfoImpl.fromJson;

  @override
  String get service;
  @override
  String get country;
  @override
  String? get provider;
  @override
  double? get price;
  @override
  double? get priceWithMarkup;
  @override
  int? get costCoins;

  /// Create a copy of PriceInfo
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PriceInfoImplCopyWith<_$PriceInfoImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
