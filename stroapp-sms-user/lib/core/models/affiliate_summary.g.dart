// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'affiliate_summary.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$AffiliateSummaryImpl _$$AffiliateSummaryImplFromJson(
  Map<String, dynamic> json,
) => _$AffiliateSummaryImpl(
  totalEarned: (json['totalEarned'] as num).toDouble(),
  pending: (json['pending'] as num).toDouble(),
  paid: (json['paid'] as num).toDouble(),
  currency: json['currency'] as String?,
);

Map<String, dynamic> _$$AffiliateSummaryImplToJson(
  _$AffiliateSummaryImpl instance,
) => <String, dynamic>{
  'totalEarned': instance.totalEarned,
  'pending': instance.pending,
  'paid': instance.paid,
  'currency': instance.currency,
};
