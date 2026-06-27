import 'package:freezed_annotation/freezed_annotation.dart';
part 'webhook_model.freezed.dart';
part 'webhook_model.g.dart';

@freezed
class WebhookModel with _$WebhookModel {
  const factory WebhookModel({
    required String id,
    required String url,
    required List<String> events,
    @Default(true) bool isActive,
    String? secret,
    DateTime? lastSuccessAt,
    DateTime? lastFailureAt,
    @Default(0) int consecutiveFailures,
    required DateTime createdAt,
  }) = _WebhookModel;

  factory WebhookModel.fromJson(Map<String, dynamic> json) => _$WebhookModelFromJson(json);
}
