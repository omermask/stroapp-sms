import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../api_client.dart';

class TierApi {
  final Dio _dio;

  TierApi(this._dio);

  Future<Map<String, dynamic>> getCurrentTier() async {
    final response = await _dio.get('/user/tiers/current');
    return response.data as Map<String, dynamic>;
  }

  Future<List<dynamic>> listTiers() async {
    final response = await _dio.get('/user/tiers');
    return response.data as List<dynamic>;
  }
}

final tierApiProvider = Provider<TierApi>((ref) {
  final dio = ref.read(dioProvider);
  return TierApi(dio);
});
