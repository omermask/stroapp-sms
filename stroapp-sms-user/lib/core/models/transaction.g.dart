// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'transaction.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$TransactionImpl _$$TransactionImplFromJson(Map<String, dynamic> json) =>
    _$TransactionImpl(
      id: json['id'] as String,
      amount: (json['amount'] as num).toInt(),
      type: json['type'] as String,
      description: json['description'] as String?,
      reference: json['reference'] as String?,
      coinsBefore: (json['coins_before'] as num?)?.toInt(),
      coinsAfter: (json['coins_after'] as num?)?.toInt(),
      createdAt: DateTime.parse(json['created_at'] as String),
    );

Map<String, dynamic> _$$TransactionImplToJson(_$TransactionImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'amount': instance.amount,
      'type': instance.type,
      'description': instance.description,
      'reference': instance.reference,
      'coins_before': instance.coinsBefore,
      'coins_after': instance.coinsAfter,
      'created_at': instance.createdAt.toIso8601String(),
    };
