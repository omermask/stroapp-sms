// ignore_for_file: invalid_annotation_target
import 'package:freezed_annotation/freezed_annotation.dart';
part 'rental.freezed.dart';
part 'rental.g.dart';

@freezed
class Rental with _$Rental {
  const factory Rental({
    required String id,
    required String service,
    required String country,
    required String provider,
    @JsonKey(name: 'phone_number') required String phoneNumber,
    required String status,
    @JsonKey(name: 'duration_hours') required int durationHours,
    @JsonKey(name: 'cost_coins') required int costCoins,
    @JsonKey(name: 'auto_extend') @Default(false) bool autoExtend,
    @JsonKey(name: 'messages_count') @Default(0) int messagesCount,
    @JsonKey(name: 'expires_at') DateTime? expiresAt,
    @JsonKey(name: 'created_at') DateTime? createdAt,
    @JsonKey(name: 'cancelled_at') DateTime? cancelledAt,
  }) = _Rental;

  factory Rental.fromJson(Map<String, dynamic> json) => _$RentalFromJson(json);
}
