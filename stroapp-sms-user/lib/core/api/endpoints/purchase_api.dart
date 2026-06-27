import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../api_client.dart';

class PurchaseApi {
  final Dio _dio;

  PurchaseApi(this._dio);

  Future<Map<String, dynamic>> getPrice(String service, String country) async {
    final response = await _dio.get(
      '/sms/price',
      queryParameters: {'service': service, 'country': country},
    );
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getBulkPrices(
    String service,
    List<String> countries,
  ) async {
    final response = await _dio.post(
      '/sms/prices/bulk',
      data: {'service': service, 'countries': countries},
    );
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> purchase(
    String service,
    String country,
    String provider,
    String idempotencyKey,
  ) async {
    final response = await _dio.post(
      '/sms/purchase',
      data: {
        'service': service,
        'country': country,
        'provider': provider,
        'idempotency_key': idempotencyKey,
      },
    );
    return response.data as Map<String, dynamic>;
  }

  Future<List<dynamic>> getOrders(String? status, int limit) async {
    final params = <String, dynamic>{'limit': limit};
    if (status != null) params['status'] = status;
    final response = await _dio.get('/sms/orders', queryParameters: params);
    return response.data as List<dynamic>;
  }

  Future<Map<String, dynamic>> getOrderDetail(String orderId) async {
    final response = await _dio.get('/sms/orders/$orderId');
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> checkOrder(String orderId) async {
    final response = await _dio.post('/sms/orders/$orderId/check');
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> cancelOrder(String orderId) async {
    final response = await _dio.post('/sms/orders/$orderId/cancel');
    return response.data as Map<String, dynamic>;
  }
}

final purchaseApiProvider = Provider<PurchaseApi>((ref) {
  final dio = ref.read(dioProvider);
  return PurchaseApi(dio);
});
