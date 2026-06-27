// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'kyc_profile.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$KycProfileImpl _$$KycProfileImplFromJson(Map<String, dynamic> json) =>
    _$KycProfileImpl(
      id: json['id'] as String,
      status: json['status'] as String,
      verificationLevel: json['verificationLevel'] as String?,
      fullName: json['fullName'] as String?,
      dateOfBirth: json['dateOfBirth'] as String?,
      nationality: json['nationality'] as String?,
      phoneNumber: json['phoneNumber'] as String?,
      addressLine1: json['addressLine1'] as String?,
      addressLine2: json['addressLine2'] as String?,
      city: json['city'] as String?,
      state: json['state'] as String?,
      postalCode: json['postalCode'] as String?,
      country: json['country'] as String?,
    );

Map<String, dynamic> _$$KycProfileImplToJson(_$KycProfileImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'status': instance.status,
      'verificationLevel': instance.verificationLevel,
      'fullName': instance.fullName,
      'dateOfBirth': instance.dateOfBirth,
      'nationality': instance.nationality,
      'phoneNumber': instance.phoneNumber,
      'addressLine1': instance.addressLine1,
      'addressLine2': instance.addressLine2,
      'city': instance.city,
      'state': instance.state,
      'postalCode': instance.postalCode,
      'country': instance.country,
    };
