// ignore_for_file: invalid_annotation_target
import 'package:freezed_annotation/freezed_annotation.dart';
part 'transaction.freezed.dart';
part 'transaction.g.dart';

@freezed
class Transaction with _$Transaction {
  const factory Transaction({
    required String id,
    required int amount,
    required String type,
    String? description,
    String? reference,
    @JsonKey(name: 'coins_before') int? coinsBefore,
    @JsonKey(name: 'coins_after') int? coinsAfter,
    @JsonKey(name: 'created_at') required DateTime createdAt,
  }) = _Transaction;

  factory Transaction.fromJson(Map<String, dynamic> json) => _$TransactionFromJson(json);
}
