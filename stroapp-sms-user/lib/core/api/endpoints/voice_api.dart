import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../api_client.dart';

class VoiceApi {
  final Dio _dio;

  VoiceApi(this._dio);

  Future<List<dynamic>> getVoiceServices() async {
    final response = await _dio.get('/user/voice/services');
    return response.data as List<dynamic>;
  }

  Future<Map<String, dynamic>> purchaseVoice(
    String service,
    String country,
  ) async {
    final response = await _dio.post(
      '/user/voice/purchase',
      data: {'service': service, 'country': country},
    );
    return response.data as Map<String, dynamic>;
  }
}

final voiceApiProvider = Provider<VoiceApi>((ref) {
  final dio = ref.read(dioProvider);
  return VoiceApi(dio);
});
