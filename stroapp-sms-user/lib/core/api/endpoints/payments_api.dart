import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../api_client.dart';

class PaymentsApi {
  final Dio _dio;

  PaymentsApi(this._dio);

  Future<List<dynamic>> getProducts(String provider) async {
    final response = await _dio.get(
      '/user/payments/products',
      queryParameters: {'provider': provider},
    );
    return response.data as List<dynamic>;
  }

  Future<Map<String, dynamic>> googlePay(
    String paymentToken,
    String productId,
    String idempotencyKey,
  ) async {
    final response = await _dio.post(
      '/user/payments/google-pay',
      data: {
        'payment_token': paymentToken,
        'product_id': productId,
        'idempotency_key': idempotencyKey,
      },
    );
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> applePay(
    String paymentToken,
    String productId,
    String idempotencyKey,
  ) async {
    final response = await _dio.post(
      '/user/payments/apple-pay',
      data: {
        'payment_token': paymentToken,
        'product_id': productId,
        'idempotency_key': idempotencyKey,
      },
    );
    return response.data as Map<String, dynamic>;
  }

  Future<List<dynamic>> getPaymentHistory(int limit, int offset) async {
    final response = await _dio.get(
      '/user/payments/history',
      queryParameters: {'limit': limit, 'offset': offset},
    );
    return response.data as List<dynamic>;
  }

  Future<Map<String, dynamic>> requestRefund(String logId) async {
    final response = await _dio.post(
      '/user/payments/refund',
      data: {'log_id': logId},
    );
    return response.data as Map<String, dynamic>;
  }
}

final paymentsApiProvider = Provider<PaymentsApi>((ref) {
  final dio = ref.read(dioProvider);
  return PaymentsApi(dio);
});
