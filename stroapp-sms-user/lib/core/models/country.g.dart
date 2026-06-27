// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'country.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$CountryImpl _$$CountryImplFromJson(Map<String, dynamic> json) =>
    _$CountryImpl(
      code: json['code'] as String,
      name: json['name'] as String,
      serviceId: json['serviceId'] as String?,
      provider: json['provider'] as String?,
      providerCost: (json['providerCost'] as num?)?.toDouble(),
      platformPrice: (json['platformPrice'] as num?)?.toDouble(),
      currency: json['currency'] as String?,
    );

Map<String, dynamic> _$$CountryImplToJson(_$CountryImpl instance) =>
    <String, dynamic>{
      'code': instance.code,
      'name': instance.name,
      'serviceId': instance.serviceId,
      'provider': instance.provider,
      'providerCost': instance.providerCost,
      'platformPrice': instance.platformPrice,
      'currency': instance.currency,
    };
