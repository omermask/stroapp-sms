// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'balance.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$BalanceImpl _$$BalanceImplFromJson(Map<String, dynamic> json) =>
    _$BalanceImpl(
      coins: (json['coins'] as num).toInt(),
      lifetimeCoins: (json['lifetime_coins'] as num?)?.toInt(),
      coinsInUsd: (json['coins_in_usd'] as num?)?.toDouble(),
    );

Map<String, dynamic> _$$BalanceImplToJson(_$BalanceImpl instance) =>
    <String, dynamic>{
      'coins': instance.coins,
      'lifetime_coins': instance.lifetimeCoins,
      'coins_in_usd': instance.coinsInUsd,
    };
