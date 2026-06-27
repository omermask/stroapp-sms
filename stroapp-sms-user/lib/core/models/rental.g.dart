// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'rental.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$RentalImpl _$$RentalImplFromJson(Map<String, dynamic> json) => _$RentalImpl(
  id: json['id'] as String,
  service: json['service'] as String,
  country: json['country'] as String,
  provider: json['provider'] as String,
  phoneNumber: json['phone_number'] as String,
  status: json['status'] as String,
  durationHours: (json['duration_hours'] as num).toInt(),
  costCoins: (json['cost_coins'] as num).toInt(),
  autoExtend: json['auto_extend'] as bool? ?? false,
  messagesCount: (json['messages_count'] as num?)?.toInt() ?? 0,
  expiresAt: json['expires_at'] == null
      ? null
      : DateTime.parse(json['expires_at'] as String),
  createdAt: json['created_at'] == null
      ? null
      : DateTime.parse(json['created_at'] as String),
  cancelledAt: json['cancelled_at'] == null
      ? null
      : DateTime.parse(json['cancelled_at'] as String),
);

Map<String, dynamic> _$$RentalImplToJson(_$RentalImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'service': instance.service,
      'country': instance.country,
      'provider': instance.provider,
      'phone_number': instance.phoneNumber,
      'status': instance.status,
      'duration_hours': instance.durationHours,
      'cost_coins': instance.costCoins,
      'auto_extend': instance.autoExtend,
      'messages_count': instance.messagesCount,
      'expires_at': instance.expiresAt?.toIso8601String(),
      'created_at': instance.createdAt?.toIso8601String(),
      'cancelled_at': instance.cancelledAt?.toIso8601String(),
    };
