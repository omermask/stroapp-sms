import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../api_client.dart';

class PricingApi {
  final Dio _dio;

  PricingApi(this._dio);

  Future<Map<String, dynamic>> getMyPricing() async {
    final response = await _dio.get('/pricing/my');
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> validatePromo(String code) async {
    final response = await _dio.post(
      '/pricing/validate-promo',
      data: {'code': code},
    );
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> applyPromo(String code, String orderId) async {
    final response = await _dio.post(
      '/pricing/apply-promo',
      data: {'code': code, 'order_id': orderId},
    );
    return response.data as Map<String, dynamic>;
  }
}

final pricingApiProvider = Provider<PricingApi>((ref) {
  final dio = ref.read(dioProvider);
  return PricingApi(dio);
});
