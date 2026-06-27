import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../api_client.dart';

class ServicesApi {
  final Dio _dio;

  ServicesApi(this._dio);

  Future<List<dynamic>> getServices(
    String? category,
    int limit,
    int offset,
  ) async {
    final params = <String, dynamic>{'limit': limit, 'offset': offset};
    if (category != null) params['category'] = category;
    final response = await _dio.get('/services', queryParameters: params);
    return response.data as List<dynamic>;
  }

  Future<List<dynamic>> getCategories() async {
    final response = await _dio.get('/services/categories');
    return response.data as List<dynamic>;
  }

  Future<List<dynamic>> getServiceCountries(String serviceName) async {
    final response = await _dio.get('/user/services/$serviceName/countries');
    return response.data as List<dynamic>;
  }

  Future<Map<String, dynamic>> getServicePrice(
    String serviceName,
    String country,
  ) async {
    final response = await _dio.get(
      '/user/services/$serviceName/price',
      queryParameters: {'country': country},
    );
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> purchaseService(
    String service,
    String country,
    String provider,
  ) async {
    final response = await _dio.post(
      '/user/services/purchase',
      data: {'service': service, 'country': country, 'provider': provider},
    );
    return response.data as Map<String, dynamic>;
  }
}

final servicesApiProvider = Provider<ServicesApi>((ref) {
  final dio = ref.read(dioProvider);
  return ServicesApi(dio);
});
