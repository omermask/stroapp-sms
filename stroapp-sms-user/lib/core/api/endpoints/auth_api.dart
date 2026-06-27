import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../api_client.dart';

class AuthApi {
  final Dio _dio;

  AuthApi(this._dio);

  Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await _dio.post(
      '/user/auth/login',
      data: {'email': email, 'password': password},
    );
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> register(
    String email,
    String password,
    String displayName,
    String turnstileToken, {
    String? ref,
  }) async {
    final data = <String, dynamic>{
      'email': email,
      'password': password,
      'display_name': displayName,
      'turnstile_token': turnstileToken,
    };
    if (ref != null) data['ref'] = ref;
    final response = await _dio.post(
      '/user/auth/register',
      data: data,
    );
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> loginWithGoogle(String idToken, {String? ref}) async {
    final data = <String, dynamic>{'id_token': idToken};
    if (ref != null) data['ref'] = ref;
    final response = await _dio.post(
      '/user/auth/google',
      data: data,
      options: Options(contentType: 'application/json'),
    );
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> loginWithApple(String identityToken, {String? ref}) async {
    final data = <String, dynamic>{'identity_token': identityToken};
    if (ref != null) data['ref'] = ref;
    final response = await _dio.post(
      '/user/auth/apple',
      data: data,
      options: Options(contentType: 'application/json'),
    );
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> refreshToken(String refreshToken) async {
    final response = await _dio.post(
      '/user/auth/refresh',
      data: {'refresh_token': refreshToken},
      options: Options(contentType: 'application/json'),
    );
    return response.data as Map<String, dynamic>;
  }

  Future<void> logout({String? refreshToken}) async {
    await _dio.post(
      '/user/auth/logout',
      options: Options(
        headers: {
          'x-refresh-token': refreshToken,
        },
      ),
    );
  }

  Future<Map<String, dynamic>> getMe() async {
    final response = await _dio.get('/user/auth/me');
    return response.data as Map<String, dynamic>;
  }

  Future<void> forgotPassword(String email) async {
    await _dio.post(
      '/user/auth/forgot-password',
      data: {'email': email},
    );
  }

  Future<void> resetPassword(String token, String newPassword) async {
    await _dio.post(
      '/user/auth/reset-password',
      data: {'token': token, 'new_password': newPassword},
    );
  }
}

final authApiProvider = Provider<AuthApi>((ref) {
  final dio = ref.read(dioProvider);
  return AuthApi(dio);
});
