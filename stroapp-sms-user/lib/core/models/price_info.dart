import 'package:freezed_annotation/freezed_annotation.dart';
part 'price_info.freezed.dart';
part 'price_info.g.dart';

@freezed
class PriceInfo with _$PriceInfo {
  const factory PriceInfo({
    required String service,
    required String country,
    String? provider,
    double? price,
    double? priceWithMarkup,
    int? costCoins,
  }) = _PriceInfo;

  factory PriceInfo.fromJson(Map<String, dynamic> json) => _$PriceInfoFromJson(json);
}
