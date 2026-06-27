import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../api_client.dart';

class RentalsApi {
  final Dio _dio;

  RentalsApi(this._dio);

  Future<List<dynamic>> getRentals(String? status) async {
    final params = <String, dynamic>{};
    if (status != null) params['status'] = status;
    final response = await _dio.get('/user/rentals', queryParameters: params);
    return response.data as List<dynamic>;
  }

  Future<List<dynamic>> getAvailableCountries() async {
    final response = await _dio.get('/user/rentals/available-countries');
    return response.data as List<dynamic>;
  }

  Future<List<dynamic>> getAvailableServices(String country) async {
    final response = await _dio.get(
      '/user/rentals/available-services',
      queryParameters: {'country': country},
    );
    return response.data as List<dynamic>;
  }

  Future<Map<String, dynamic>> createRental(
    String service,
    String country,
    int hours,
    bool autoExtend,
  ) async {
    final response = await _dio.post(
      '/user/rentals',
      data: {
        'service': service,
        'country': country,
        'hours': hours,
        'auto_extend': autoExtend,
      },
    );
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getRentalDetail(String rentalId) async {
    final response = await _dio.get('/user/rentals/$rentalId');
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> extendRental(String rentalId, int hours) async {
    final response = await _dio.post(
      '/user/rentals/$rentalId/extend',
      data: {'hours': hours},
    );
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> cancelRental(String rentalId) async {
    final response = await _dio.post('/user/rentals/$rentalId/cancel');
    return response.data as Map<String, dynamic>;
  }

  Future<List<dynamic>> getRentalMessages(String rentalId) async {
    final response = await _dio.get('/user/rentals/$rentalId/messages');
    return response.data as List<dynamic>;
  }
}

final rentalsApiProvider = Provider<RentalsApi>((ref) {
  final dio = ref.read(dioProvider);
  return RentalsApi(dio);
});
