import 'package:freezed_annotation/freezed_annotation.dart';
part 'api_key_model.freezed.dart';
part 'api_key_model.g.dart';

@freezed
class ApiKeyModel with _$ApiKeyModel {
  const factory ApiKeyModel({
    required String id,
    required String name,
    String? prefix,
    @Default(true) bool isActive,
    DateTime? lastUsedAt,
    required DateTime createdAt,
  }) = _ApiKeyModel;

  factory ApiKeyModel.fromJson(Map<String, dynamic> json) => _$ApiKeyModelFromJson(json);
}
