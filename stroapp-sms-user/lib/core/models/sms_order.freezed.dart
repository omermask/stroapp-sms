// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'sms_order.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

SMSOrder _$SMSOrderFromJson(Map<String, dynamic> json) {
  return _SMSOrder.fromJson(json);
}

/// @nodoc
mixin _$SMSOrder {
  String get id => throw _privateConstructorUsedError;
  String get service => throw _privateConstructorUsedError;
  @JsonKey(name: 'service_name')
  String? get serviceName => throw _privateConstructorUsedError;
  String get country => throw _privateConstructorUsedError;
  @JsonKey(name: 'country_name')
  String? get countryName => throw _privateConstructorUsedError;
  String get provider => throw _privateConstructorUsedError;
  @JsonKey(name: 'phone_number')
  String get phoneNumber => throw _privateConstructorUsedError;
  String get status => throw _privateConstructorUsedError;
  @JsonKey(name: 'cost_coins')
  int get costCoins => throw _privateConstructorUsedError;
  @JsonKey(name: 'verification_code')
  String? get verificationCode => throw _privateConstructorUsedError;
  @JsonKey(name: 'sms_text')
  String? get smsText => throw _privateConstructorUsedError;
  @JsonKey(name: 'sms_received_at')
  DateTime? get smsReceivedAt => throw _privateConstructorUsedError;
  bool? get refunded => throw _privateConstructorUsedError;
  @JsonKey(name: 'error_message')
  String? get errorMessage => throw _privateConstructorUsedError;
  @JsonKey(name: 'created_at')
  DateTime get createdAt => throw _privateConstructorUsedError;
  @JsonKey(name: 'updated_at')
  DateTime? get updatedAt => throw _privateConstructorUsedError;

  /// Serializes this SMSOrder to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of SMSOrder
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $SMSOrderCopyWith<SMSOrder> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $SMSOrderCopyWith<$Res> {
  factory $SMSOrderCopyWith(SMSOrder value, $Res Function(SMSOrder) then) =
      _$SMSOrderCopyWithImpl<$Res, SMSOrder>;
  @useResult
  $Res call({
    String id,
    String service,
    @JsonKey(name: 'service_name') String? serviceName,
    String country,
    @JsonKey(name: 'country_name') String? countryName,
    String provider,
    @JsonKey(name: 'phone_number') String phoneNumber,
    String status,
    @JsonKey(name: 'cost_coins') int costCoins,
    @JsonKey(name: 'verification_code') String? verificationCode,
    @JsonKey(name: 'sms_text') String? smsText,
    @JsonKey(name: 'sms_received_at') DateTime? smsReceivedAt,
    bool? refunded,
    @JsonKey(name: 'error_message') String? errorMessage,
    @JsonKey(name: 'created_at') DateTime createdAt,
    @JsonKey(name: 'updated_at') DateTime? updatedAt,
  });
}

/// @nodoc
class _$SMSOrderCopyWithImpl<$Res, $Val extends SMSOrder>
    implements $SMSOrderCopyWith<$Res> {
  _$SMSOrderCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of SMSOrder
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? service = null,
    Object? serviceName = freezed,
    Object? country = null,
    Object? countryName = freezed,
    Object? provider = null,
    Object? phoneNumber = null,
    Object? status = null,
    Object? costCoins = null,
    Object? verificationCode = freezed,
    Object? smsText = freezed,
    Object? smsReceivedAt = freezed,
    Object? refunded = freezed,
    Object? errorMessage = freezed,
    Object? createdAt = null,
    Object? updatedAt = freezed,
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
            serviceName: freezed == serviceName
                ? _value.serviceName
                : serviceName // ignore: cast_nullable_to_non_nullable
                      as String?,
            country: null == country
                ? _value.country
                : country // ignore: cast_nullable_to_non_nullable
                      as String,
            countryName: freezed == countryName
                ? _value.countryName
                : countryName // ignore: cast_nullable_to_non_nullable
                      as String?,
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
            costCoins: null == costCoins
                ? _value.costCoins
                : costCoins // ignore: cast_nullable_to_non_nullable
                      as int,
            verificationCode: freezed == verificationCode
                ? _value.verificationCode
                : verificationCode // ignore: cast_nullable_to_non_nullable
                      as String?,
            smsText: freezed == smsText
                ? _value.smsText
                : smsText // ignore: cast_nullable_to_non_nullable
                      as String?,
            smsReceivedAt: freezed == smsReceivedAt
                ? _value.smsReceivedAt
                : smsReceivedAt // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
            refunded: freezed == refunded
                ? _value.refunded
                : refunded // ignore: cast_nullable_to_non_nullable
                      as bool?,
            errorMessage: freezed == errorMessage
                ? _value.errorMessage
                : errorMessage // ignore: cast_nullable_to_non_nullable
                      as String?,
            createdAt: null == createdAt
                ? _value.createdAt
                : createdAt // ignore: cast_nullable_to_non_nullable
                      as DateTime,
            updatedAt: freezed == updatedAt
                ? _value.updatedAt
                : updatedAt // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$SMSOrderImplCopyWith<$Res>
    implements $SMSOrderCopyWith<$Res> {
  factory _$$SMSOrderImplCopyWith(
    _$SMSOrderImpl value,
    $Res Function(_$SMSOrderImpl) then,
  ) = __$$SMSOrderImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String service,
    @JsonKey(name: 'service_name') String? serviceName,
    String country,
    @JsonKey(name: 'country_name') String? countryName,
    String provider,
    @JsonKey(name: 'phone_number') String phoneNumber,
    String status,
    @JsonKey(name: 'cost_coins') int costCoins,
    @JsonKey(name: 'verification_code') String? verificationCode,
    @JsonKey(name: 'sms_text') String? smsText,
    @JsonKey(name: 'sms_received_at') DateTime? smsReceivedAt,
    bool? refunded,
    @JsonKey(name: 'error_message') String? errorMessage,
    @JsonKey(name: 'created_at') DateTime createdAt,
    @JsonKey(name: 'updated_at') DateTime? updatedAt,
  });
}

/// @nodoc
class __$$SMSOrderImplCopyWithImpl<$Res>
    extends _$SMSOrderCopyWithImpl<$Res, _$SMSOrderImpl>
    implements _$$SMSOrderImplCopyWith<$Res> {
  __$$SMSOrderImplCopyWithImpl(
    _$SMSOrderImpl _value,
    $Res Function(_$SMSOrderImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of SMSOrder
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? service = null,
    Object? serviceName = freezed,
    Object? country = null,
    Object? countryName = freezed,
    Object? provider = null,
    Object? phoneNumber = null,
    Object? status = null,
    Object? costCoins = null,
    Object? verificationCode = freezed,
    Object? smsText = freezed,
    Object? smsReceivedAt = freezed,
    Object? refunded = freezed,
    Object? errorMessage = freezed,
    Object? createdAt = null,
    Object? updatedAt = freezed,
  }) {
    return _then(
      _$SMSOrderImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        service: null == service
            ? _value.service
            : service // ignore: cast_nullable_to_non_nullable
                  as String,
        serviceName: freezed == serviceName
            ? _value.serviceName
            : serviceName // ignore: cast_nullable_to_non_nullable
                  as String?,
        country: null == country
            ? _value.country
            : country // ignore: cast_nullable_to_non_nullable
                  as String,
        countryName: freezed == countryName
            ? _value.countryName
            : countryName // ignore: cast_nullable_to_non_nullable
                  as String?,
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
        costCoins: null == costCoins
            ? _value.costCoins
            : costCoins // ignore: cast_nullable_to_non_nullable
                  as int,
        verificationCode: freezed == verificationCode
            ? _value.verificationCode
            : verificationCode // ignore: cast_nullable_to_non_nullable
                  as String?,
        smsText: freezed == smsText
            ? _value.smsText
            : smsText // ignore: cast_nullable_to_non_nullable
                  as String?,
        smsReceivedAt: freezed == smsReceivedAt
            ? _value.smsReceivedAt
            : smsReceivedAt // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        refunded: freezed == refunded
            ? _value.refunded
            : refunded // ignore: cast_nullable_to_non_nullable
                  as bool?,
        errorMessage: freezed == errorMessage
            ? _value.errorMessage
            : errorMessage // ignore: cast_nullable_to_non_nullable
                  as String?,
        createdAt: null == createdAt
            ? _value.createdAt
            : createdAt // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        updatedAt: freezed == updatedAt
            ? _value.updatedAt
            : updatedAt // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$SMSOrderImpl implements _SMSOrder {
  const _$SMSOrderImpl({
    required this.id,
    required this.service,
    @JsonKey(name: 'service_name') this.serviceName,
    required this.country,
    @JsonKey(name: 'country_name') this.countryName,
    required this.provider,
    @JsonKey(name: 'phone_number') required this.phoneNumber,
    required this.status,
    @JsonKey(name: 'cost_coins') required this.costCoins,
    @JsonKey(name: 'verification_code') this.verificationCode,
    @JsonKey(name: 'sms_text') this.smsText,
    @JsonKey(name: 'sms_received_at') this.smsReceivedAt,
    this.refunded,
    @JsonKey(name: 'error_message') this.errorMessage,
    @JsonKey(name: 'created_at') required this.createdAt,
    @JsonKey(name: 'updated_at') this.updatedAt,
  });

  factory _$SMSOrderImpl.fromJson(Map<String, dynamic> json) =>
      _$$SMSOrderImplFromJson(json);

  @override
  final String id;
  @override
  final String service;
  @override
  @JsonKey(name: 'service_name')
  final String? serviceName;
  @override
  final String country;
  @override
  @JsonKey(name: 'country_name')
  final String? countryName;
  @override
  final String provider;
  @override
  @JsonKey(name: 'phone_number')
  final String phoneNumber;
  @override
  final String status;
  @override
  @JsonKey(name: 'cost_coins')
  final int costCoins;
  @override
  @JsonKey(name: 'verification_code')
  final String? verificationCode;
  @override
  @JsonKey(name: 'sms_text')
  final String? smsText;
  @override
  @JsonKey(name: 'sms_received_at')
  final DateTime? smsReceivedAt;
  @override
  final bool? refunded;
  @override
  @JsonKey(name: 'error_message')
  final String? errorMessage;
  @override
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  @override
  @JsonKey(name: 'updated_at')
  final DateTime? updatedAt;

  @override
  String toString() {
    return 'SMSOrder(id: $id, service: $service, serviceName: $serviceName, country: $country, countryName: $countryName, provider: $provider, phoneNumber: $phoneNumber, status: $status, costCoins: $costCoins, verificationCode: $verificationCode, smsText: $smsText, smsReceivedAt: $smsReceivedAt, refunded: $refunded, errorMessage: $errorMessage, createdAt: $createdAt, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SMSOrderImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.service, service) || other.service == service) &&
            (identical(other.serviceName, serviceName) ||
                other.serviceName == serviceName) &&
            (identical(other.country, country) || other.country == country) &&
            (identical(other.countryName, countryName) ||
                other.countryName == countryName) &&
            (identical(other.provider, provider) ||
                other.provider == provider) &&
            (identical(other.phoneNumber, phoneNumber) ||
                other.phoneNumber == phoneNumber) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.costCoins, costCoins) ||
                other.costCoins == costCoins) &&
            (identical(other.verificationCode, verificationCode) ||
                other.verificationCode == verificationCode) &&
            (identical(other.smsText, smsText) || other.smsText == smsText) &&
            (identical(other.smsReceivedAt, smsReceivedAt) ||
                other.smsReceivedAt == smsReceivedAt) &&
            (identical(other.refunded, refunded) ||
                other.refunded == refunded) &&
            (identical(other.errorMessage, errorMessage) ||
                other.errorMessage == errorMessage) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    service,
    serviceName,
    country,
    countryName,
    provider,
    phoneNumber,
    status,
    costCoins,
    verificationCode,
    smsText,
    smsReceivedAt,
    refunded,
    errorMessage,
    createdAt,
    updatedAt,
  );

  /// Create a copy of SMSOrder
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$SMSOrderImplCopyWith<_$SMSOrderImpl> get copyWith =>
      __$$SMSOrderImplCopyWithImpl<_$SMSOrderImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$SMSOrderImplToJson(this);
  }
}

abstract class _SMSOrder implements SMSOrder {
  const factory _SMSOrder({
    required final String id,
    required final String service,
    @JsonKey(name: 'service_name') final String? serviceName,
    required final String country,
    @JsonKey(name: 'country_name') final String? countryName,
    required final String provider,
    @JsonKey(name: 'phone_number') required final String phoneNumber,
    required final String status,
    @JsonKey(name: 'cost_coins') required final int costCoins,
    @JsonKey(name: 'verification_code') final String? verificationCode,
    @JsonKey(name: 'sms_text') final String? smsText,
    @JsonKey(name: 'sms_received_at') final DateTime? smsReceivedAt,
    final bool? refunded,
    @JsonKey(name: 'error_message') final String? errorMessage,
    @JsonKey(name: 'created_at') required final DateTime createdAt,
    @JsonKey(name: 'updated_at') final DateTime? updatedAt,
  }) = _$SMSOrderImpl;

  factory _SMSOrder.fromJson(Map<String, dynamic> json) =
      _$SMSOrderImpl.fromJson;

  @override
  String get id;
  @override
  String get service;
  @override
  @JsonKey(name: 'service_name')
  String? get serviceName;
  @override
  String get country;
  @override
  @JsonKey(name: 'country_name')
  String? get countryName;
  @override
  String get provider;
  @override
  @JsonKey(name: 'phone_number')
  String get phoneNumber;
  @override
  String get status;
  @override
  @JsonKey(name: 'cost_coins')
  int get costCoins;
  @override
  @JsonKey(name: 'verification_code')
  String? get verificationCode;
  @override
  @JsonKey(name: 'sms_text')
  String? get smsText;
  @override
  @JsonKey(name: 'sms_received_at')
  DateTime? get smsReceivedAt;
  @override
  bool? get refunded;
  @override
  @JsonKey(name: 'error_message')
  String? get errorMessage;
  @override
  @JsonKey(name: 'created_at')
  DateTime get createdAt;
  @override
  @JsonKey(name: 'updated_at')
  DateTime? get updatedAt;

  /// Create a copy of SMSOrder
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$SMSOrderImplCopyWith<_$SMSOrderImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
