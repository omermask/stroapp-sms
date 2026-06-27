// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'api_key_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ApiKeyModelImpl _$$ApiKeyModelImplFromJson(Map<String, dynamic> json) =>
    _$ApiKeyModelImpl(
      id: json['id'] as String,
      name: json['name'] as String,
      prefix: json['prefix'] as String?,
      isActive: json['isActive'] as bool? ?? true,
      lastUsedAt: json['lastUsedAt'] == null
          ? null
          : DateTime.parse(json['lastUsedAt'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
    );

Map<String, dynamic> _$$ApiKeyModelImplToJson(_$ApiKeyModelImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'prefix': instance.prefix,
      'isActive': instance.isActive,
      'lastUsedAt': instance.lastUsedAt?.toIso8601String(),
      'createdAt': instance.createdAt.toIso8601String(),
    };
