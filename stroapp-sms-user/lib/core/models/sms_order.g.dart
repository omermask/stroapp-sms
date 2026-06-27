// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sms_order.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$SMSOrderImpl _$$SMSOrderImplFromJson(Map<String, dynamic> json) =>
    _$SMSOrderImpl(
      id: json['id'] as String,
      service: json['service'] as String,
      serviceName: json['service_name'] as String?,
      country: json['country'] as String,
      countryName: json['country_name'] as String?,
      provider: json['provider'] as String,
      phoneNumber: json['phone_number'] as String,
      status: json['status'] as String,
      costCoins: (json['cost_coins'] as num).toInt(),
      verificationCode: json['verification_code'] as String?,
      smsText: json['sms_text'] as String?,
      smsReceivedAt: json['sms_received_at'] == null
          ? null
          : DateTime.parse(json['sms_received_at'] as String),
      refunded: json['refunded'] as bool?,
      errorMessage: json['error_message'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] == null
          ? null
          : DateTime.parse(json['updated_at'] as String),
    );

Map<String, dynamic> _$$SMSOrderImplToJson(_$SMSOrderImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'service': instance.service,
      'service_name': instance.serviceName,
      'country': instance.country,
      'country_name': instance.countryName,
      'provider': instance.provider,
      'phone_number': instance.phoneNumber,
      'status': instance.status,
      'cost_coins': instance.costCoins,
      'verification_code': instance.verificationCode,
      'sms_text': instance.smsText,
      'sms_received_at': instance.smsReceivedAt?.toIso8601String(),
      'refunded': instance.refunded,
      'error_message': instance.errorMessage,
      'created_at': instance.createdAt.toIso8601String(),
      'updated_at': instance.updatedAt?.toIso8601String(),
    };
