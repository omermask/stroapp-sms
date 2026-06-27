// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'kyc_profile.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

KycProfile _$KycProfileFromJson(Map<String, dynamic> json) {
  return _KycProfile.fromJson(json);
}

/// @nodoc
mixin _$KycProfile {
  String get id => throw _privateConstructorUsedError;
  String get status => throw _privateConstructorUsedError;
  String? get verificationLevel => throw _privateConstructorUsedError;
  String? get fullName => throw _privateConstructorUsedError;
  String? get dateOfBirth => throw _privateConstructorUsedError;
  String? get nationality => throw _privateConstructorUsedError;
  String? get phoneNumber => throw _privateConstructorUsedError;
  String? get addressLine1 => throw _privateConstructorUsedError;
  String? get addressLine2 => throw _privateConstructorUsedError;
  String? get city => throw _privateConstructorUsedError;
  String? get state => throw _privateConstructorUsedError;
  String? get postalCode => throw _privateConstructorUsedError;
  String? get country => throw _privateConstructorUsedError;

  /// Serializes this KycProfile to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of KycProfile
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $KycProfileCopyWith<KycProfile> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $KycProfileCopyWith<$Res> {
  factory $KycProfileCopyWith(
    KycProfile value,
    $Res Function(KycProfile) then,
  ) = _$KycProfileCopyWithImpl<$Res, KycProfile>;
  @useResult
  $Res call({
    String id,
    String status,
    String? verificationLevel,
    String? fullName,
    String? dateOfBirth,
    String? nationality,
    String? phoneNumber,
    String? addressLine1,
    String? addressLine2,
    String? city,
    String? state,
    String? postalCode,
    String? country,
  });
}

/// @nodoc
class _$KycProfileCopyWithImpl<$Res, $Val extends KycProfile>
    implements $KycProfileCopyWith<$Res> {
  _$KycProfileCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of KycProfile
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? status = null,
    Object? verificationLevel = freezed,
    Object? fullName = freezed,
    Object? dateOfBirth = freezed,
    Object? nationality = freezed,
    Object? phoneNumber = freezed,
    Object? addressLine1 = freezed,
    Object? addressLine2 = freezed,
    Object? city = freezed,
    Object? state = freezed,
    Object? postalCode = freezed,
    Object? country = freezed,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            status: null == status
                ? _value.status
                : status // ignore: cast_nullable_to_non_nullable
                      as String,
            verificationLevel: freezed == verificationLevel
                ? _value.verificationLevel
                : verificationLevel // ignore: cast_nullable_to_non_nullable
                      as String?,
            fullName: freezed == fullName
                ? _value.fullName
                : fullName // ignore: cast_nullable_to_non_nullable
                      as String?,
            dateOfBirth: freezed == dateOfBirth
                ? _value.dateOfBirth
                : dateOfBirth // ignore: cast_nullable_to_non_nullable
                      as String?,
            nationality: freezed == nationality
                ? _value.nationality
                : nationality // ignore: cast_nullable_to_non_nullable
                      as String?,
            phoneNumber: freezed == phoneNumber
                ? _value.phoneNumber
                : phoneNumber // ignore: cast_nullable_to_non_nullable
                      as String?,
            addressLine1: freezed == addressLine1
                ? _value.addressLine1
                : addressLine1 // ignore: cast_nullable_to_non_nullable
                      as String?,
            addressLine2: freezed == addressLine2
                ? _value.addressLine2
                : addressLine2 // ignore: cast_nullable_to_non_nullable
                      as String?,
            city: freezed == city
                ? _value.city
                : city // ignore: cast_nullable_to_non_nullable
                      as String?,
            state: freezed == state
                ? _value.state
                : state // ignore: cast_nullable_to_non_nullable
                      as String?,
            postalCode: freezed == postalCode
                ? _value.postalCode
                : postalCode // ignore: cast_nullable_to_non_nullable
                      as String?,
            country: freezed == country
                ? _value.country
                : country // ignore: cast_nullable_to_non_nullable
                      as String?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$KycProfileImplCopyWith<$Res>
    implements $KycProfileCopyWith<$Res> {
  factory _$$KycProfileImplCopyWith(
    _$KycProfileImpl value,
    $Res Function(_$KycProfileImpl) then,
  ) = __$$KycProfileImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String status,
    String? verificationLevel,
    String? fullName,
    String? dateOfBirth,
    String? nationality,
    String? phoneNumber,
    String? addressLine1,
    String? addressLine2,
    String? city,
    String? state,
    String? postalCode,
    String? country,
  });
}

/// @nodoc
class __$$KycProfileImplCopyWithImpl<$Res>
    extends _$KycProfileCopyWithImpl<$Res, _$KycProfileImpl>
    implements _$$KycProfileImplCopyWith<$Res> {
  __$$KycProfileImplCopyWithImpl(
    _$KycProfileImpl _value,
    $Res Function(_$KycProfileImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of KycProfile
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? status = null,
    Object? verificationLevel = freezed,
    Object? fullName = freezed,
    Object? dateOfBirth = freezed,
    Object? nationality = freezed,
    Object? phoneNumber = freezed,
    Object? addressLine1 = freezed,
    Object? addressLine2 = freezed,
    Object? city = freezed,
    Object? state = freezed,
    Object? postalCode = freezed,
    Object? country = freezed,
  }) {
    return _then(
      _$KycProfileImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        status: null == status
            ? _value.status
            : status // ignore: cast_nullable_to_non_nullable
                  as String,
        verificationLevel: freezed == verificationLevel
            ? _value.verificationLevel
            : verificationLevel // ignore: cast_nullable_to_non_nullable
                  as String?,
        fullName: freezed == fullName
            ? _value.fullName
            : fullName // ignore: cast_nullable_to_non_nullable
                  as String?,
        dateOfBirth: freezed == dateOfBirth
            ? _value.dateOfBirth
            : dateOfBirth // ignore: cast_nullable_to_non_nullable
                  as String?,
        nationality: freezed == nationality
            ? _value.nationality
            : nationality // ignore: cast_nullable_to_non_nullable
                  as String?,
        phoneNumber: freezed == phoneNumber
            ? _value.phoneNumber
            : phoneNumber // ignore: cast_nullable_to_non_nullable
                  as String?,
        addressLine1: freezed == addressLine1
            ? _value.addressLine1
            : addressLine1 // ignore: cast_nullable_to_non_nullable
                  as String?,
        addressLine2: freezed == addressLine2
            ? _value.addressLine2
            : addressLine2 // ignore: cast_nullable_to_non_nullable
                  as String?,
        city: freezed == city
            ? _value.city
            : city // ignore: cast_nullable_to_non_nullable
                  as String?,
        state: freezed == state
            ? _value.state
            : state // ignore: cast_nullable_to_non_nullable
                  as String?,
        postalCode: freezed == postalCode
            ? _value.postalCode
            : postalCode // ignore: cast_nullable_to_non_nullable
                  as String?,
        country: freezed == country
            ? _value.country
            : country // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$KycProfileImpl implements _KycProfile {
  const _$KycProfileImpl({
    required this.id,
    required this.status,
    this.verificationLevel,
    this.fullName,
    this.dateOfBirth,
    this.nationality,
    this.phoneNumber,
    this.addressLine1,
    this.addressLine2,
    this.city,
    this.state,
    this.postalCode,
    this.country,
  });

  factory _$KycProfileImpl.fromJson(Map<String, dynamic> json) =>
      _$$KycProfileImplFromJson(json);

  @override
  final String id;
  @override
  final String status;
  @override
  final String? verificationLevel;
  @override
  final String? fullName;
  @override
  final String? dateOfBirth;
  @override
  final String? nationality;
  @override
  final String? phoneNumber;
  @override
  final String? addressLine1;
  @override
  final String? addressLine2;
  @override
  final String? city;
  @override
  final String? state;
  @override
  final String? postalCode;
  @override
  final String? country;

  @override
  String toString() {
    return 'KycProfile(id: $id, status: $status, verificationLevel: $verificationLevel, fullName: $fullName, dateOfBirth: $dateOfBirth, nationality: $nationality, phoneNumber: $phoneNumber, addressLine1: $addressLine1, addressLine2: $addressLine2, city: $city, state: $state, postalCode: $postalCode, country: $country)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$KycProfileImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.verificationLevel, verificationLevel) ||
                other.verificationLevel == verificationLevel) &&
            (identical(other.fullName, fullName) ||
                other.fullName == fullName) &&
            (identical(other.dateOfBirth, dateOfBirth) ||
                other.dateOfBirth == dateOfBirth) &&
            (identical(other.nationality, nationality) ||
                other.nationality == nationality) &&
            (identical(other.phoneNumber, phoneNumber) ||
                other.phoneNumber == phoneNumber) &&
            (identical(other.addressLine1, addressLine1) ||
                other.addressLine1 == addressLine1) &&
            (identical(other.addressLine2, addressLine2) ||
                other.addressLine2 == addressLine2) &&
            (identical(other.city, city) || other.city == city) &&
            (identical(other.state, state) || other.state == state) &&
            (identical(other.postalCode, postalCode) ||
                other.postalCode == postalCode) &&
            (identical(other.country, country) || other.country == country));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    status,
    verificationLevel,
    fullName,
    dateOfBirth,
    nationality,
    phoneNumber,
    addressLine1,
    addressLine2,
    city,
    state,
    postalCode,
    country,
  );

  /// Create a copy of KycProfile
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$KycProfileImplCopyWith<_$KycProfileImpl> get copyWith =>
      __$$KycProfileImplCopyWithImpl<_$KycProfileImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$KycProfileImplToJson(this);
  }
}

abstract class _KycProfile implements KycProfile {
  const factory _KycProfile({
    required final String id,
    required final String status,
    final String? verificationLevel,
    final String? fullName,
    final String? dateOfBirth,
    final String? nationality,
    final String? phoneNumber,
    final String? addressLine1,
    final String? addressLine2,
    final String? city,
    final String? state,
    final String? postalCode,
    final String? country,
  }) = _$KycProfileImpl;

  factory _KycProfile.fromJson(Map<String, dynamic> json) =
      _$KycProfileImpl.fromJson;

  @override
  String get id;
  @override
  String get status;
  @override
  String? get verificationLevel;
  @override
  String? get fullName;
  @override
  String? get dateOfBirth;
  @override
  String? get nationality;
  @override
  String? get phoneNumber;
  @override
  String? get addressLine1;
  @override
  String? get addressLine2;
  @override
  String? get city;
  @override
  String? get state;
  @override
  String? get postalCode;
  @override
  String? get country;

  /// Create a copy of KycProfile
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$KycProfileImplCopyWith<_$KycProfileImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
