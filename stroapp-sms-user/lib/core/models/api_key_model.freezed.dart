// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'api_key_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

ApiKeyModel _$ApiKeyModelFromJson(Map<String, dynamic> json) {
  return _ApiKeyModel.fromJson(json);
}

/// @nodoc
mixin _$ApiKeyModel {
  String get id => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  String? get prefix => throw _privateConstructorUsedError;
  bool get isActive => throw _privateConstructorUsedError;
  DateTime? get lastUsedAt => throw _privateConstructorUsedError;
  DateTime get createdAt => throw _privateConstructorUsedError;

  /// Serializes this ApiKeyModel to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ApiKeyModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ApiKeyModelCopyWith<ApiKeyModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ApiKeyModelCopyWith<$Res> {
  factory $ApiKeyModelCopyWith(
    ApiKeyModel value,
    $Res Function(ApiKeyModel) then,
  ) = _$ApiKeyModelCopyWithImpl<$Res, ApiKeyModel>;
  @useResult
  $Res call({
    String id,
    String name,
    String? prefix,
    bool isActive,
    DateTime? lastUsedAt,
    DateTime createdAt,
  });
}

/// @nodoc
class _$ApiKeyModelCopyWithImpl<$Res, $Val extends ApiKeyModel>
    implements $ApiKeyModelCopyWith<$Res> {
  _$ApiKeyModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ApiKeyModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? prefix = freezed,
    Object? isActive = null,
    Object? lastUsedAt = freezed,
    Object? createdAt = null,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            name: null == name
                ? _value.name
                : name // ignore: cast_nullable_to_non_nullable
                      as String,
            prefix: freezed == prefix
                ? _value.prefix
                : prefix // ignore: cast_nullable_to_non_nullable
                      as String?,
            isActive: null == isActive
                ? _value.isActive
                : isActive // ignore: cast_nullable_to_non_nullable
                      as bool,
            lastUsedAt: freezed == lastUsedAt
                ? _value.lastUsedAt
                : lastUsedAt // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
            createdAt: null == createdAt
                ? _value.createdAt
                : createdAt // ignore: cast_nullable_to_non_nullable
                      as DateTime,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$ApiKeyModelImplCopyWith<$Res>
    implements $ApiKeyModelCopyWith<$Res> {
  factory _$$ApiKeyModelImplCopyWith(
    _$ApiKeyModelImpl value,
    $Res Function(_$ApiKeyModelImpl) then,
  ) = __$$ApiKeyModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String name,
    String? prefix,
    bool isActive,
    DateTime? lastUsedAt,
    DateTime createdAt,
  });
}

/// @nodoc
class __$$ApiKeyModelImplCopyWithImpl<$Res>
    extends _$ApiKeyModelCopyWithImpl<$Res, _$ApiKeyModelImpl>
    implements _$$ApiKeyModelImplCopyWith<$Res> {
  __$$ApiKeyModelImplCopyWithImpl(
    _$ApiKeyModelImpl _value,
    $Res Function(_$ApiKeyModelImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of ApiKeyModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? prefix = freezed,
    Object? isActive = null,
    Object? lastUsedAt = freezed,
    Object? createdAt = null,
  }) {
    return _then(
      _$ApiKeyModelImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        name: null == name
            ? _value.name
            : name // ignore: cast_nullable_to_non_nullable
                  as String,
        prefix: freezed == prefix
            ? _value.prefix
            : prefix // ignore: cast_nullable_to_non_nullable
                  as String?,
        isActive: null == isActive
            ? _value.isActive
            : isActive // ignore: cast_nullable_to_non_nullable
                  as bool,
        lastUsedAt: freezed == lastUsedAt
            ? _value.lastUsedAt
            : lastUsedAt // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        createdAt: null == createdAt
            ? _value.createdAt
            : createdAt // ignore: cast_nullable_to_non_nullable
                  as DateTime,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$ApiKeyModelImpl implements _ApiKeyModel {
  const _$ApiKeyModelImpl({
    required this.id,
    required this.name,
    this.prefix,
    this.isActive = true,
    this.lastUsedAt,
    required this.createdAt,
  });

  factory _$ApiKeyModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$ApiKeyModelImplFromJson(json);

  @override
  final String id;
  @override
  final String name;
  @override
  final String? prefix;
  @override
  @JsonKey()
  final bool isActive;
  @override
  final DateTime? lastUsedAt;
  @override
  final DateTime createdAt;

  @override
  String toString() {
    return 'ApiKeyModel(id: $id, name: $name, prefix: $prefix, isActive: $isActive, lastUsedAt: $lastUsedAt, createdAt: $createdAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ApiKeyModelImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.prefix, prefix) || other.prefix == prefix) &&
            (identical(other.isActive, isActive) ||
                other.isActive == isActive) &&
            (identical(other.lastUsedAt, lastUsedAt) ||
                other.lastUsedAt == lastUsedAt) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    name,
    prefix,
    isActive,
    lastUsedAt,
    createdAt,
  );

  /// Create a copy of ApiKeyModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ApiKeyModelImplCopyWith<_$ApiKeyModelImpl> get copyWith =>
      __$$ApiKeyModelImplCopyWithImpl<_$ApiKeyModelImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ApiKeyModelImplToJson(this);
  }
}

abstract class _ApiKeyModel implements ApiKeyModel {
  const factory _ApiKeyModel({
    required final String id,
    required final String name,
    final String? prefix,
    final bool isActive,
    final DateTime? lastUsedAt,
    required final DateTime createdAt,
  }) = _$ApiKeyModelImpl;

  factory _ApiKeyModel.fromJson(Map<String, dynamic> json) =
      _$ApiKeyModelImpl.fromJson;

  @override
  String get id;
  @override
  String get name;
  @override
  String? get prefix;
  @override
  bool get isActive;
  @override
  DateTime? get lastUsedAt;
  @override
  DateTime get createdAt;

  /// Create a copy of ApiKeyModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ApiKeyModelImplCopyWith<_$ApiKeyModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
