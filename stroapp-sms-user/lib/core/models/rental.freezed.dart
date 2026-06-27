// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'rental.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

Rental _$RentalFromJson(Map<String, dynamic> json) {
  return _Rental.fromJson(json);
}

/// @nodoc
mixin _$Rental {
  String get id => throw _privateConstructorUsedError;
  String get service => throw _privateConstructorUsedError;
  String get country => throw _privateConstructorUsedError;
  String get provider => throw _privateConstructorUsedError;
  @JsonKey(name: 'phone_number')
  String get phoneNumber => throw _privateConstructorUsedError;
  String get status => throw _privateConstructorUsedError;
  @JsonKey(name: 'duration_hours')
  int get durationHours => throw _privateConstructorUsedError;
  @JsonKey(name: 'cost_coins')
  int get costCoins => throw _privateConstructorUsedError;
  @JsonKey(name: 'auto_extend')
  bool get autoExtend => throw _privateConstructorUsedError;
  @JsonKey(name: 'messages_count')
  int get messagesCount => throw _privateConstructorUsedError;
  @JsonKey(name: 'expires_at')
  DateTime? get expiresAt => throw _privateConstructorUsedError;
  @JsonKey(name: 'created_at')
  DateTime? get createdAt => throw _privateConstructorUsedError;
  @JsonKey(name: 'cancelled_at')
  DateTime? get cancelledAt => throw _privateConstructorUsedError;

  /// Serializes this Rental to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of Rental
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $RentalCopyWith<Rental> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $RentalCopyWith<$Res> {
  factory $RentalCopyWith(Rental value, $Res Function(Rental) then) =
      _$RentalCopyWithImpl<$Res, Rental>;
  @useResult
  $Res call({
    String id,
    String service,
    String country,
    String provider,
    @JsonKey(name: 'phone_number') String phoneNumber,
    String status,
    @JsonKey(name: 'duration_hours') int durationHours,
    @JsonKey(name: 'cost_coins') int costCoins,
    @JsonKey(name: 'auto_extend') bool autoExtend,
    @JsonKey(name: 'messages_count') int messagesCount,
    @JsonKey(name: 'expires_at') DateTime? expiresAt,
    @JsonKey(name: 'created_at') DateTime? createdAt,
    @JsonKey(name: 'cancelled_at') DateTime? cancelledAt,
  });
}

/// @nodoc
class _$RentalCopyWithImpl<$Res, $Val extends Rental>
    implements $RentalCopyWith<$Res> {
  _$RentalCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Rental
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? service = null,
    Object? country = null,
    Object? provider = null,
    Object? phoneNumber = null,
    Object? status = null,
    Object? durationHours = null,
    Object? costCoins = null,
    Object? autoExtend = null,
    Object? messagesCount = null,
    Object? expiresAt = freezed,
    Object? createdAt = freezed,
    Object? cancelledAt = freezed,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            service: null == service
                ? _value.service
                : service // ignore: cast_nullable_to_non_nullable
                      as String,
            country: null == country
                ? _value.country
                : country // ignore: cast_nullable_to_non_nullable
                      as String,
            provider: null == provider
                ? _value.provider
                : provider // ignore: cast_nullable_to_non_nullable
                      as String,
            phoneNumber: null == phoneNumber
                ? _value.phoneNumber
                : phoneNumber // ignore: cast_nullable_to_non_nullable
                      as String,
            status: null == status
                ? _value.status
                : status // ignore: cast_nullable_to_non_nullable
                      as String,
            durationHours: null == durationHours
                ? _value.durationHours
                : durationHours // ignore: cast_nullable_to_non_nullable
                      as int,
            costCoins: null == costCoins
                ? _value.costCoins
                : costCoins // ignore: cast_nullable_to_non_nullable
                      as int,
            autoExtend: null == autoExtend
                ? _value.autoExtend
                : autoExtend // ignore: cast_nullable_to_non_nullable
                      as bool,
            messagesCount: null == messagesCount
                ? _value.messagesCount
                : messagesCount // ignore: cast_nullable_to_non_nullable
                      as int,
            expiresAt: freezed == expiresAt
                ? _value.expiresAt
                : expiresAt // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
            createdAt: freezed == createdAt
                ? _value.createdAt
                : createdAt // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
            cancelledAt: freezed == cancelledAt
                ? _value.cancelledAt
                : cancelledAt // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$RentalImplCopyWith<$Res> implements $RentalCopyWith<$Res> {
  factory _$$RentalImplCopyWith(
    _$RentalImpl value,
    $Res Function(_$RentalImpl) then,
  ) = __$$RentalImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String service,
    String country,
    String provider,
    @JsonKey(name: 'phone_number') String phoneNumber,
    String status,
    @JsonKey(name: 'duration_hours') int durationHours,
    @JsonKey(name: 'cost_coins') int costCoins,
    @JsonKey(name: 'auto_extend') bool autoExtend,
    @JsonKey(name: 'messages_count') int messagesCount,
    @JsonKey(name: 'expires_at') DateTime? expiresAt,
    @JsonKey(name: 'created_at') DateTime? createdAt,
    @JsonKey(name: 'cancelled_at') DateTime? cancelledAt,
  });
}

/// @nodoc
class __$$RentalImplCopyWithImpl<$Res>
    extends _$RentalCopyWithImpl<$Res, _$RentalImpl>
    implements _$$RentalImplCopyWith<$Res> {
  __$$RentalImplCopyWithImpl(
    _$RentalImpl _value,
    $Res Function(_$RentalImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of Rental
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? service = null,
    Object? country = null,
    Object? provider = null,
    Object? phoneNumber = null,
    Object? status = null,
    Object? durationHours = null,
    Object? costCoins = null,
    Object? autoExtend = null,
    Object? messagesCount = null,
    Object? expiresAt = freezed,
    Object? createdAt = freezed,
    Object? cancelledAt = freezed,
  }) {
    return _then(
      _$RentalImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        service: null == service
            ? _value.service
            : service // ignore: cast_nullable_to_non_nullable
                  as String,
        country: null == country
            ? _value.country
            : country // ignore: cast_nullable_to_non_nullable
                  as String,
        provider: null == provider
            ? _value.provider
            : provider // ignore: cast_nullable_to_non_nullable
                  as String,
        phoneNumber: null == phoneNumber
            ? _value.phoneNumber
            : phoneNumber // ignore: cast_nullable_to_non_nullable
                  as String,
        status: null == status
            ? _value.status
            : status // ignore: cast_nullable_to_non_nullable
                  as String,
        durationHours: null == durationHours
            ? _value.durationHours
            : durationHours // ignore: cast_nullable_to_non_nullable
                  as int,
        costCoins: null == costCoins
            ? _value.costCoins
            : costCoins // ignore: cast_nullable_to_non_nullable
                  as int,
        autoExtend: null == autoExtend
            ? _value.autoExtend
            : autoExtend // ignore: cast_nullable_to_non_nullable
                  as bool,
        messagesCount: null == messagesCount
            ? _value.messagesCount
            : messagesCount // ignore: cast_nullable_to_non_nullable
                  as int,
        expiresAt: freezed == expiresAt
            ? _value.expiresAt
            : expiresAt // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        createdAt: freezed == createdAt
            ? _value.createdAt
            : createdAt // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        cancelledAt: freezed == cancelledAt
            ? _value.cancelledAt
            : cancelledAt // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$RentalImpl implements _Rental {
  const _$RentalImpl({
    required this.id,
    required this.service,
    required this.country,
    required this.provider,
    @JsonKey(name: 'phone_number') required this.phoneNumber,
    required this.status,
    @JsonKey(name: 'duration_hours') required this.durationHours,
    @JsonKey(name: 'cost_coins') required this.costCoins,
    @JsonKey(name: 'auto_extend') this.autoExtend = false,
    @JsonKey(name: 'messages_count') this.messagesCount = 0,
    @JsonKey(name: 'expires_at') this.expiresAt,
    @JsonKey(name: 'created_at') this.createdAt,
    @JsonKey(name: 'cancelled_at') this.cancelledAt,
  });

  factory _$RentalImpl.fromJson(Map<String, dynamic> json) =>
      _$$RentalImplFromJson(json);

  @override
  final String id;
  @override
  final String service;
  @override
  final String country;
  @override
  final String provider;
  @override
  @JsonKey(name: 'phone_number')
  final String phoneNumber;
  @override
  final String status;
  @override
  @JsonKey(name: 'duration_hours')
  final int durationHours;
  @override
  @JsonKey(name: 'cost_coins')
  final int costCoins;
  @override
  @JsonKey(name: 'auto_extend')
  final bool autoExtend;
  @override
  @JsonKey(name: 'messages_count')
  final int messagesCount;
  @override
  @JsonKey(name: 'expires_at')
  final DateTime? expiresAt;
  @override
  @JsonKey(name: 'created_at')
  final DateTime? createdAt;
  @override
  @JsonKey(name: 'cancelled_at')
  final DateTime? cancelledAt;

  @override
  String toString() {
    return 'Rental(id: $id, service: $service, country: $country, provider: $provider, phoneNumber: $phoneNumber, status: $status, durationHours: $durationHours, costCoins: $costCoins, autoExtend: $autoExtend, messagesCount: $messagesCount, expiresAt: $expiresAt, createdAt: $createdAt, cancelledAt: $cancelledAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$RentalImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.service, service) || other.service == service) &&
            (identical(other.country, country) || other.country == country) &&
            (identical(other.provider, provider) ||
                other.provider == provider) &&
            (identical(other.phoneNumber, phoneNumber) ||
                other.phoneNumber == phoneNumber) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.durationHours, durationHours) ||
                other.durationHours == durationHours) &&
            (identical(other.costCoins, costCoins) ||
                other.costCoins == costCoins) &&
            (identical(other.autoExtend, autoExtend) ||
                other.autoExtend == autoExtend) &&
            (identical(other.messagesCount, messagesCount) ||
                other.messagesCount == messagesCount) &&
            (identical(other.expiresAt, expiresAt) ||
                other.expiresAt == expiresAt) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.cancelledAt, cancelledAt) ||
                other.cancelledAt == cancelledAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    service,
    country,
    provider,
    phoneNumber,
    status,
    durationHours,
    costCoins,
    autoExtend,
    messagesCount,
    expiresAt,
    createdAt,
    cancelledAt,
  );

  /// Create a copy of Rental
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$RentalImplCopyWith<_$RentalImpl> get copyWith =>
      __$$RentalImplCopyWithImpl<_$RentalImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$RentalImplToJson(this);
  }
}

abstract class _Rental implements Rental {
  const factory _Rental({
    required final String id,
    required final String service,
    required final String country,
    required final String provider,
    @JsonKey(name: 'phone_number') required final String phoneNumber,
    required final String status,
    @JsonKey(name: 'duration_hours') required final int durationHours,
    @JsonKey(name: 'cost_coins') required final int costCoins,
    @JsonKey(name: 'auto_extend') final bool autoExtend,
    @JsonKey(name: 'messages_count') final int messagesCount,
    @JsonKey(name: 'expires_at') final DateTime? expiresAt,
    @JsonKey(name: 'created_at') final DateTime? createdAt,
    @JsonKey(name: 'cancelled_at') final DateTime? cancelledAt,
  }) = _$RentalImpl;

  factory _Rental.fromJson(Map<String, dynamic> json) = _$RentalImpl.fromJson;

  @override
  String get id;
  @override
  String get service;
  @override
  String get country;
  @override
  String get provider;
  @override
  @JsonKey(name: 'phone_number')
  String get phoneNumber;
  @override
  String get status;
  @override
  @JsonKey(name: 'duration_hours')
  int get durationHours;
  @override
  @JsonKey(name: 'cost_coins')
  int get costCoins;
  @override
  @JsonKey(name: 'auto_extend')
  bool get autoExtend;
  @override
  @JsonKey(name: 'messages_count')
  int get messagesCount;
  @override
  @JsonKey(name: 'expires_at')
  DateTime? get expiresAt;
  @override
  @JsonKey(name: 'created_at')
  DateTime? get createdAt;
  @override
  @JsonKey(name: 'cancelled_at')
  DateTime? get cancelledAt;

  /// Create a copy of Rental
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$RentalImplCopyWith<_$RentalImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
