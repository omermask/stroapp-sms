import 'package:freezed_annotation/freezed_annotation.dart';
part 'country.freezed.dart';
part 'country.g.dart';

@freezed
class Country with _$Country {
  const factory Country({
    required String code,
    required String name,
    String? serviceId,
    String? provider,
    double? providerCost,
    double? platformPrice,
    String? currency,
  }) = _Country;

  factory Country.fromJson(Map<String, dynamic> json) => _$CountryFromJson(json);
}
