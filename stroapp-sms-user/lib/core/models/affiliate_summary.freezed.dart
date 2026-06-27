// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'affiliate_summary.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

AffiliateSummary _$AffiliateSummaryFromJson(Map<String, dynamic> json) {
  return _AffiliateSummary.fromJson(json);
}

/// @nodoc
mixin _$AffiliateSummary {
  double get totalEarned => throw _privateConstructorUsedError;
  double get pending => throw _privateConstructorUsedError;
  double get paid => throw _privateConstructorUsedError;
  String? get currency => throw _privateConstructorUsedError;

  /// Serializes this AffiliateSummary to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of AffiliateSummary
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $AffiliateSummaryCopyWith<AffiliateSummary> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $AffiliateSummaryCopyWith<$Res> {
  factory $AffiliateSummaryCopyWith(
    AffiliateSummary value,
    $Res Function(AffiliateSummary) then,
  ) = _$AffiliateSummaryCopyWithImpl<$Res, AffiliateSummary>;
  @useResult
  $Res call({
    double totalEarned,
    double pending,
    double paid,
    String? currency,
  });
}

/// @nodoc
class _$AffiliateSummaryCopyWithImpl<$Res, $Val extends AffiliateSummary>
    implements $AffiliateSummaryCopyWith<$Res> {
  _$AffiliateSummaryCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of AffiliateSummary
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? totalEarned = null,
    Object? pending = null,
    Object? paid = null,
    Object? currency = freezed,
  }) {
    return _then(
      _value.copyWith(
            totalEarned: null == totalEarned
                ? _value.totalEarned
                : totalEarned // ignore: cast_nullable_to_non_nullable
                      as double,
            pending: null == pending
                ? _value.pending
                : pending // ignore: cast_nullable_to_non_nullable
                      as double,
            paid: null == paid
                ? _value.paid
                : paid // ignore: cast_nullable_to_non_nullable
                      as double,
            currency: freezed == currency
                ? _value.currency
                : currency // ignore: cast_nullable_to_non_nullable
                      as String?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$AffiliateSummaryImplCopyWith<$Res>
    implements $AffiliateSummaryCopyWith<$Res> {
  factory _$$AffiliateSummaryImplCopyWith(
    _$AffiliateSummaryImpl value,
    $Res Function(_$AffiliateSummaryImpl) then,
  ) = __$$AffiliateSummaryImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    double totalEarned,
    double pending,
    double paid,
    String? currency,
  });
}

/// @nodoc
class __$$AffiliateSummaryImplCopyWithImpl<$Res>
    extends _$AffiliateSummaryCopyWithImpl<$Res, _$AffiliateSummaryImpl>
    implements _$$AffiliateSummaryImplCopyWith<$Res> {
  __$$AffiliateSummaryImplCopyWithImpl(
    _$AffiliateSummaryImpl _value,
    $Res Function(_$AffiliateSummaryImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of AffiliateSummary
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? totalEarned = null,
    Object? pending = null,
    Object? paid = null,
    Object? currency = freezed,
  }) {
    return _then(
      _$AffiliateSummaryImpl(
        totalEarned: null == totalEarned
            ? _value.totalEarned
            : totalEarned // ignore: cast_nullable_to_non_nullable
                  as double,
        pending: null == pending
            ? _value.pending
            : pending // ignore: cast_nullable_to_non_nullable
                  as double,
        paid: null == paid
            ? _value.paid
            : paid // ignore: cast_nullable_to_non_nullable
                  as double,
        currency: freezed == currency
            ? _value.currency
            : currency // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$AffiliateSummaryImpl implements _AffiliateSummary {
  const _$AffiliateSummaryImpl({
    required this.totalEarned,
    required this.pending,
    required this.paid,
    this.currency,
  });

  factory _$AffiliateSummaryImpl.fromJson(Map<String, dynamic> json) =>
      _$$AffiliateSummaryImplFromJson(json);

  @override
  final double totalEarned;
  @override
  final double pending;
  @override
  final double paid;
  @override
  final String? currency;

  @override
  String toString() {
    return 'AffiliateSummary(totalEarned: $totalEarned, pending: $pending, paid: $paid, currency: $currency)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$AffiliateSummaryImpl &&
            (identical(other.totalEarned, totalEarned) ||
                other.totalEarned == totalEarned) &&
            (identical(other.pending, pending) || other.pending == pending) &&
            (identical(other.paid, paid) || other.paid == paid) &&
            (identical(other.currency, currency) ||
                other.currency == currency));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, totalEarned, pending, paid, currency);

  /// Create a copy of AffiliateSummary
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$AffiliateSummaryImplCopyWith<_$AffiliateSummaryImpl> get copyWith =>
      __$$AffiliateSummaryImplCopyWithImpl<_$AffiliateSummaryImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$AffiliateSummaryImplToJson(this);
  }
}

abstract class _AffiliateSummary implements AffiliateSummary {
  const factory _AffiliateSummary({
    required final double totalEarned,
    required final double pending,
    required final double paid,
    final String? currency,
  }) = _$AffiliateSummaryImpl;

  factory _AffiliateSummary.fromJson(Map<String, dynamic> json) =
      _$AffiliateSummaryImpl.fromJson;

  @override
  double get totalEarned;
  @override
  double get pending;
  @override
  double get paid;
  @override
  String? get currency;

  /// Create a copy of AffiliateSummary
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$AffiliateSummaryImplCopyWith<_$AffiliateSummaryImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
