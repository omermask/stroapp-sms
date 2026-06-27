// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$UserImpl _$$UserImplFromJson(Map<String, dynamic> json) => _$UserImpl(
  id: json['id'] as String,
  email: json['email'] as String,
  displayName: json['display_name'] as String?,
  photoUrl: json['photo_url'] as String?,
  avatar: json['avatar'] as String?,
  coins: (json['coins'] as num).toInt(),
  lifetimeCoins: (json['lifetime_coins'] as num?)?.toInt(),
  tempEmailsUsed: (json['temp_emails_used'] as num?)?.toInt(),
  isAdmin: json['is_admin'] as bool?,
  createdAt: json['created_at'] == null
      ? null
      : DateTime.parse(json['created_at'] as String),
);

Map<String, dynamic> _$$UserImplToJson(_$UserImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'email': instance.email,
      'display_name': instance.displayName,
      'photo_url': instance.photoUrl,
      'avatar': instance.avatar,
      'coins': instance.coins,
      'lifetime_coins': instance.lifetimeCoins,
      'temp_emails_used': instance.tempEmailsUsed,
      'is_admin': instance.isAdmin,
      'created_at': instance.createdAt?.toIso8601String(),
    };
