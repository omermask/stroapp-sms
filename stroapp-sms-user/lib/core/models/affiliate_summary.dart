import 'package:freezed_annotation/freezed_annotation.dart';
part 'affiliate_summary.freezed.dart';
part 'affiliate_summary.g.dart';

@freezed
class AffiliateSummary with _$AffiliateSummary {
  const factory AffiliateSummary({
    required double totalEarned,
    required double pending,
    required double paid,
    String? currency,
  }) = _AffiliateSummary;

  factory AffiliateSummary.fromJson(Map<String, dynamic> json) => _$AffiliateSummaryFromJson(json);
}
