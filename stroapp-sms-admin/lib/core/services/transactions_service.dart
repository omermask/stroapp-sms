import '../constants/api_constants.dart';
import '../models/transaction.dart';
import '../network/api_client.dart';
import '../network/api_response.dart';

class TransactionsService {
  final _client = ApiClient();

  Future<({List<Transaction> transactions, int total})> listTransactions({
    int page = 1,
    int limit = 20,
    String type = '',
    String userId = '',
  }) async {
    final params = <String, dynamic>{'page': page, 'limit': limit};
    if (type.isNotEmpty) params['type'] = type;
    if (userId.isNotEmpty) params['user_id'] = userId;

    final response = await _client.get(
      ApiConstants.transactions,
      queryParameters: params,
    );
    final apiResp = ApiResponse.fromJson(response.data, null);

    if (apiResp.success && apiResp.data != null) {
      final data = apiResp.data as Map<String, dynamic>;
      final list =
          (data['items'] as List<dynamic>?)
              ?.map((e) => Transaction.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [];
      final total = data['total'] as int? ?? list.length;
      return (transactions: list, total: total);
    }
    throw Exception(apiResp.error?.message ?? 'Failed to load transactions');
  }
}
