import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../api_client.dart';

class PushApi {
  final Dio _dio;

  PushApi(this._dio);

  Future<Map<String, dynamic>> registerDevice(
    String token,
    String platform,
    String deviceType,
    String? deviceName,
  ) async {
    final response = await _dio.post(
      '/user/push/register',
      data: {
        'token': token,
        'platform': platform,
        'device_type': deviceType,
        'device_name': deviceName,
      },
    );
    return response.data as Map<String, dynamic>;
  }

  Future<void> unregisterDevice(String token) async {
    await _dio.post('/user/push/unregister', data: {'token': token});
  }

  Future<List<dynamic>> getDevices() async {
    final response = await _dio.get('/user/push/devices');
    return response.data as List<dynamic>;
  }

  Future<void> removeDevice(String deviceId) async {
    await _dio.delete('/user/push/devices/$deviceId');
  }

  Future<Map<String, dynamic>> sendTestPush() async {
    final response = await _dio.post('/user/push/test');
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getPushConfig() async {
    final response = await _dio.get('/user/push/config');
    return response.data as Map<String, dynamic>;
  }
}

final pushApiProvider = Provider<PushApi>((ref) {
  final dio = ref.read(dioProvider);
  return PushApi(dio);
});
