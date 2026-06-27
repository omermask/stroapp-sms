import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../api_client.dart';

class EmailApi {
  final Dio _dio;

  EmailApi(this._dio);

  Future<Map<String, dynamic>> getTempEmail() async {
    final response = await _dio.get('/user/email/temp');
    return response.data as Map<String, dynamic>;
  }

  Future<List<dynamic>> getTempEmailMessages() async {
    final response = await _dio.get('/user/email/temp/messages');
    return response.data as List<dynamic>;
  }

  Future<void> deleteTempEmail() async {
    await _dio.delete('/user/email/temp');
  }

  Future<Map<String, dynamic>> sendVerification() async {
    final response = await _dio.post('/user/email/send-verification');
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> verifyEmail(String code) async {
    final response = await _dio.post(
      '/user/email/verify',
      data: {'code': code},
    );
    return response.data as Map<String, dynamic>;
  }
}

final emailApiProvider = Provider<EmailApi>((ref) {
  final dio = ref.read(dioProvider);
  return EmailApi(dio);
});
