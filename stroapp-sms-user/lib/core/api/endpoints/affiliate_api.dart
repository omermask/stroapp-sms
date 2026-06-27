import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../api_client.dart';

class AffiliateApi {
  final Dio _dio;

  AffiliateApi(this._dio);

  Future<Map<String, dynamic>> apply(
    String programType,
    String? message,
  ) async {
    final response = await _dio.post(
      '/affiliate/apply',
      data: {'program_type': programType, 'message': message},
    );
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getApplication() async {
    final response = await _dio.get('/affiliate/application');
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getCommissions(
    String? status,
    int page,
    int perPage,
  ) async {
    final params = <String, dynamic>{'page': page, 'per_page': perPage};
    if (status != null) params['status'] = status;
    final response = await _dio.get(
      '/affiliate/commissions',
      queryParameters: params,
    );
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getSummary() async {
    final response = await _dio.get('/affiliate/summary');
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> requestPayout(
    double amount,
    String paymentMethod,
    Map<String, dynamic> paymentDetails,
  ) async {
    final response = await _dio.post(
      '/affiliate/payouts',
      data: {
        'amount': amount,
        'payment_method': paymentMethod,
        'payment_details': paymentDetails,
      },
    );
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getPayouts(int page, int perPage) async {
    final response = await _dio.get(
      '/affiliate/payouts',
      queryParameters: {'page': page, 'per_page': perPage},
    );
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getRevenueShare(int page, int perPage) async {
    final response = await _dio.get(
      '/affiliate/revenue-share',
      queryParameters: {'page': page, 'per_page': perPage},
    );
    return response.data as Map<String, dynamic>;
  }

  Future<List<dynamic>> getTiers() async {
    final response = await _dio.get('/affiliate/tiers');
    return response.data as List<dynamic>;
  }
}

final affiliateApiProvider = Provider<AffiliateApi>((ref) {
  final dio = ref.read(dioProvider);
  return AffiliateApi(dio);
});
