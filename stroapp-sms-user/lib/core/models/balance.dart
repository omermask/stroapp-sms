// ignore_for_file: invalid_annotation_target
import 'package:freezed_annotation/freezed_annotation.dart';
part 'balance.freezed.dart';
part 'balance.g.dart';

@freezed
class Balance with _$Balance {
  const factory Balance({
    required int coins,
    @JsonKey(name: 'lifetime_coins') int? lifetimeCoins,
    @JsonKey(name: 'coins_in_usd') double? coinsInUsd,
  }) = _Balance;

  factory Balance.fromJson(Map<String, dynamic> json) => _$BalanceFromJson(json);
}
