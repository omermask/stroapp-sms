// ignore_for_file: invalid_annotation_target
import 'package:freezed_annotation/freezed_annotation.dart';
part 'user.freezed.dart';
part 'user.g.dart';

@freezed
class User with _$User {
  const factory User({
    required String id,
    required String email,
    @JsonKey(name: 'display_name') String? displayName,
    @JsonKey(name: 'photo_url') String? photoUrl,
    String? avatar,
    required int coins,
    @JsonKey(name: 'lifetime_coins') int? lifetimeCoins,
    @JsonKey(name: 'temp_emails_used') int? tempEmailsUsed,
    @JsonKey(name: 'is_admin') bool? isAdmin,
    @JsonKey(name: 'created_at') DateTime? createdAt,
  }) = _User;

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);
}
