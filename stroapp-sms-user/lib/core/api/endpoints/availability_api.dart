import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../api_client.dart';

class AvailabilityApi {
  final Dio _dio;

  AvailabilityApi(this._dio);

  Future<Map<String, dynamic>> getServiceAvailability(
    String service,
    String country,
  ) async {
    final response = await _dio.get(
      '/user/availability/service',
      queryParameters: {'service': service, 'country': country},
    );
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getCountryAvailability(String country) async {
    final response = await _dio.get(
      '/user/availability/country',
      queryParameters: {'country': country},
    );
    return response.data as Map<String, dynamic>;
  }

  Future<List<dynamic>> getTopServices(int limit) async {
    final response = await _dio.get(
      '/user/availability/top-services',
      queryParameters: {'limit': limit},
    );
    return response.data as List<dynamic>;
  }

  Future<Map<String, dynamic>> getAvailabilitySummary() async {
    final response = await _dio.get('/user/availability/summary');
    return response.data as Map<String, dynamic>;
  }
}

final availabilityApiProvider = Provider<AvailabilityApi>((ref) {
  final dio = ref.read(dioProvider);
  return AvailabilityApi(dio);
});
