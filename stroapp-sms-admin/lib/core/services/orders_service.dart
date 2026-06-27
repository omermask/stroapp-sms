import '../constants/api_constants.dart';
import '../models/order.dart';
import '../network/api_client.dart';
import '../network/api_response.dart';

class OrdersService {
  final _client = ApiClient();

  Future<({List<Order> orders, int total})> listOrders({
    int page = 1,
    int limit = 20,
    String status = '',
  }) async {
    final params = <String, dynamic>{'page': page, 'limit': limit};
    if (status.isNotEmpty) params['status'] = status;

    final response = await _client.get(
      ApiConstants.orders,
      queryParameters: params,
    );
    final apiResp = ApiResponse.fromJson(response.data, null);

    if (apiResp.success && apiResp.data != null) {
      final data = apiResp.data as Map<String, dynamic>;
      final list =
          (data['items'] as List<dynamic>?)
              ?.map((e) => Order.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [];
      final total = data['total'] as int? ?? list.length;
      return (orders: list, total: total);
    }
    throw Exception(apiResp.error?.message ?? 'Failed to load orders');
  }
}
