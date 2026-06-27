// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'price_info.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$PriceInfoImpl _$$PriceInfoImplFromJson(Map<String, dynamic> json) =>
    _$PriceInfoImpl(
      service: json['service'] as String,
      country: json['country'] as String,
      provider: json['provider'] as String?,
      price: (json['price'] as num?)?.toDouble(),
      priceWithMarkup: (json['priceWithMarkup'] as num?)?.toDouble(),
      costCoins: (json['costCoins'] as num?)?.toInt(),
    );

Map<String, dynamic> _$$PriceInfoImplToJson(_$PriceInfoImpl instance) =>
    <String, dynamic>{
      'service': instance.service,
      'country': instance.country,
      'provider': instance.provider,
      'price': instance.price,
      'priceWithMarkup': instance.priceWithMarkup,
      'costCoins': instance.costCoins,
    };
