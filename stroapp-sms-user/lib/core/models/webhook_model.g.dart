// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'webhook_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$WebhookModelImpl _$$WebhookModelImplFromJson(Map<String, dynamic> json) =>
    _$WebhookModelImpl(
      id: json['id'] as String,
      url: json['url'] as String,
      events: (json['events'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      isActive: json['isActive'] as bool? ?? true,
      secret: json['secret'] as String?,
      lastSuccessAt: json['lastSuccessAt'] == null
          ? null
          : DateTime.parse(json['lastSuccessAt'] as String),
      lastFailureAt: json['lastFailureAt'] == null
          ? null
          : DateTime.parse(json['lastFailureAt'] as String),
      consecutiveFailures: (json['consecutiveFailures'] as num?)?.toInt() ?? 0,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );

Map<String, dynamic> _$$WebhookModelImplToJson(_$WebhookModelImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'url': instance.url,
      'events': instance.events,
      'isActive': instance.isActive,
      'secret': instance.secret,
      'lastSuccessAt': instance.lastSuccessAt?.toIso8601String(),
      'lastFailureAt': instance.lastFailureAt?.toIso8601String(),
      'consecutiveFailures': instance.consecutiveFailures,
      'createdAt': instance.createdAt.toIso8601String(),
    };
