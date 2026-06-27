// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'webhook_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

WebhookModel _$WebhookModelFromJson(Map<String, dynamic> json) {
  return _WebhookModel.fromJson(json);
}

/// @nodoc
mixin _$WebhookModel {
  String get id => throw _privateConstructorUsedError;
  String get url => throw _privateConstructorUsedError;
  List<String> get events => throw _privateConstructorUsedError;
  bool get isActive => throw _privateConstructorUsedError;
  String? get secret => throw _privateConstructorUsedError;
  DateTime? get lastSuccessAt => throw _privateConstructorUsedError;
  DateTime? get lastFailureAt => throw _privateConstructorUsedError;
  int get consecutiveFailures => throw _privateConstructorUsedError;
  DateTime get createdAt => throw _privateConstructorUsedError;

  /// Serializes this WebhookModel to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of WebhookModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $WebhookModelCopyWith<WebhookModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $WebhookModelCopyWith<$Res> {
  factory $WebhookModelCopyWith(
    WebhookModel value,
    $Res Function(WebhookModel) then,
  ) = _$WebhookModelCopyWithImpl<$Res, WebhookModel>;
  @useResult
  $Res call({
    String id,
    String url,
    List<String> events,
    bool isActive,
    String? secret,
    DateTime? lastSuccessAt,
    DateTime? lastFailureAt,
    int consecutiveFailures,
    DateTime createdAt,
  });
}

/// @nodoc
class _$WebhookModelCopyWithImpl<$Res, $Val extends WebhookModel>
    implements $WebhookModelCopyWith<$Res> {
  _$WebhookModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of WebhookModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? url = null,
    Object? events = null,
    Object? isActive = null,
    Object? secret = freezed,
    Object? lastSuccessAt = freezed,
    Object? lastFailureAt = freezed,
    Object? consecutiveFailures = null,
    Object? createdAt = null,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            url: null == url
                ? _value.url
                : url // ignore: cast_nullable_to_non_nullable
                      as String,
            events: null == events
                ? _value.events
                : events // ignore: cast_nullable_to_non_nullable
                      as List<String>,
            isActive: null == isActive
                ? _value.isActive
                : isActive // ignore: cast_nullable_to_non_nullable
                      as bool,
            secret: freezed == secret
                ? _value.secret
                : secret // ignore: cast_nullable_to_non_nullable
                      as String?,
            lastSuccessAt: freezed == lastSuccessAt
                ? _value.lastSuccessAt
                : lastSuccessAt // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
            lastFailureAt: freezed == lastFailureAt
                ? _value.lastFailureAt
                : lastFailureAt // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
            consecutiveFailures: null == consecutiveFailures
                ? _value.consecutiveFailures
                : consecutiveFailures // ignore: cast_nullable_to_non_nullable
                      as int,
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
abstract class _$$WebhookModelImplCopyWith<$Res>
    implements $WebhookModelCopyWith<$Res> {
  factory _$$WebhookModelImplCopyWith(
    _$WebhookModelImpl value,
    $Res Function(_$WebhookModelImpl) then,
  ) = __$$WebhookModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String url,
    List<String> events,
    bool isActive,
    String? secret,
    DateTime? lastSuccessAt,
    DateTime? lastFailureAt,
    int consecutiveFailures,
    DateTime createdAt,
  });
}

/// @nodoc
class __$$WebhookModelImplCopyWithImpl<$Res>
    extends _$WebhookModelCopyWithImpl<$Res, _$WebhookModelImpl>
    implements _$$WebhookModelImplCopyWith<$Res> {
  __$$WebhookModelImplCopyWithImpl(
    _$WebhookModelImpl _value,
    $Res Function(_$WebhookModelImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of WebhookModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? url = null,
    Object? events = null,
    Object? isActive = null,
    Object? secret = freezed,
    Object? lastSuccessAt = freezed,
    Object? lastFailureAt = freezed,
    Object? consecutiveFailures = null,
    Object? createdAt = null,
  }) {
    return _then(
      _$WebhookModelImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        url: null == url
            ? _value.url
            : url // ignore: cast_nullable_to_non_nullable
                  as String,
        events: null == events
            ? _value._events
            : events // ignore: cast_nullable_to_non_nullable
                  as List<String>,
        isActive: null == isActive
            ? _value.isActive
            : isActive // ignore: cast_nullable_to_non_nullable
                  as bool,
        secret: freezed == secret
            ? _value.secret
            : secret // ignore: cast_nullable_to_non_nullable
                  as String?,
        lastSuccessAt: freezed == lastSuccessAt
            ? _value.lastSuccessAt
            : lastSuccessAt // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        lastFailureAt: freezed == lastFailureAt
            ? _value.lastFailureAt
            : lastFailureAt // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        consecutiveFailures: null == consecutiveFailures
            ? _value.consecutiveFailures
            : consecutiveFailures // ignore: cast_nullable_to_non_nullable
                  as int,
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
class _$WebhookModelImpl implements _WebhookModel {
  const _$WebhookModelImpl({
    required this.id,
    required this.url,
    required final List<String> events,
    this.isActive = true,
    this.secret,
    this.lastSuccessAt,
    this.lastFailureAt,
    this.consecutiveFailures = 0,
    required this.createdAt,
  }) : _events = events;

  factory _$WebhookModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$WebhookModelImplFromJson(json);

  @override
  final String id;
  @override
  final String url;
  final List<String> _events;
  @override
  List<String> get events {
    if (_events is EqualUnmodifiableListView) return _events;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_events);
  }

  @override
  @JsonKey()
  final bool isActive;
  @override
  final String? secret;
  @override
  final DateTime? lastSuccessAt;
  @override
  final DateTime? lastFailureAt;
  @override
  @JsonKey()
  final int consecutiveFailures;
  @override
  final DateTime createdAt;

  @override
  String toString() {
    return 'WebhookModel(id: $id, url: $url, events: $events, isActive: $isActive, secret: $secret, lastSuccessAt: $lastSuccessAt, lastFailureAt: $lastFailureAt, consecutiveFailures: $consecutiveFailures, createdAt: $createdAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$WebhookModelImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.url, url) || other.url == url) &&
            const DeepCollectionEquality().equals(other._events, _events) &&
            (identical(other.isActive, isActive) ||
                other.isActive == isActive) &&
            (identical(other.secret, secret) || other.secret == secret) &&
            (identical(other.lastSuccessAt, lastSuccessAt) ||
                other.lastSuccessAt == lastSuccessAt) &&
            (identical(other.lastFailureAt, lastFailureAt) ||
                other.lastFailureAt == lastFailureAt) &&
            (identical(other.consecutiveFailures, consecutiveFailures) ||
                other.consecutiveFailures == consecutiveFailures) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    url,
    const DeepCollectionEquality().hash(_events),
    isActive,
    secret,
    lastSuccessAt,
    lastFailureAt,
    consecutiveFailures,
    createdAt,
  );

  /// Create a copy of WebhookModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$WebhookModelImplCopyWith<_$WebhookModelImpl> get copyWith =>
      __$$WebhookModelImplCopyWithImpl<_$WebhookModelImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$WebhookModelImplToJson(this);
  }
}

abstract class _WebhookModel implements WebhookModel {
  const factory _WebhookModel({
    required final String id,
    required final String url,
    required final List<String> events,
    final bool isActive,
    final String? secret,
    final DateTime? lastSuccessAt,
    final DateTime? lastFailureAt,
    final int consecutiveFailures,
    required final DateTime createdAt,
  }) = _$WebhookModelImpl;

  factory _WebhookModel.fromJson(Map<String, dynamic> json) =
      _$WebhookModelImpl.fromJson;

  @override
  String get id;
  @override
  String get url;
  @override
  List<String> get events;
  @override
  bool get isActive;
  @override
  String? get secret;
  @override
  DateTime? get lastSuccessAt;
  @override
  DateTime? get lastFailureAt;
  @override
  int get consecutiveFailures;
  @override
  DateTime get createdAt;

  /// Create a copy of WebhookModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$WebhookModelImplCopyWith<_$WebhookModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
