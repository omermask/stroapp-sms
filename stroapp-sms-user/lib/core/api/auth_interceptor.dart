import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'api_client.dart';
import '../services/mfa_service.dart';
import '../services/session_service.dart';

class AuthInterceptor extends Interceptor {
  final FlutterSecureStorage _secureStorage;
  final Ref _ref;
  Dio? _dio;
  bool _isRefreshing = false;

  AuthInterceptor(this._secureStorage, this._ref);

  void setDio(Dio dio) {
    _dio = dio;
  }

  final List<String> _publicPaths = [
    '/user/auth/login',
    '/user/auth/register',
    '/user/auth/forgot-password',
    '/user/auth/reset-password',
    '/user/auth/refresh',
    '/user/auth/google',
    '/user/auth/apple',
  ];

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (_publicPaths.any((path) => options.path.startsWith(path))) {
      return handler.next(options);
    }

    final token = await _secureStorage.read(key: 'access_token');
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    final mfaToken = _ref.read(mfaTokenProvider);
    if (mfaToken != null) {
      options.headers['x-mfa-token'] = mfaToken;
    }
    handler.next(options);
  }

  @override
  void onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (err.response?.statusCode == 403) {
      final data = err.response?.data;
      if (data is Map<String, dynamic>) {
        final errorData = data['error'];
        if (errorData is Map<String, dynamic> && errorData['code'] == 'MFA_REQUIRED') {
          _ref.read(mfaTokenProvider.notifier).state = null;
        }
      }
    }
    if (err.response?.statusCode != 401 || _isRefreshing) {
      return handler.next(err);
    }

    _isRefreshing = true;

    try {
      final refreshToken =
          await _secureStorage.read(key: 'refresh_token');
      if (refreshToken == null) {
        await _clearTokens();
        _isRefreshing = false;
        return handler.next(err);
      }

      if (_dio == null) {
        await _clearTokens();
        _isRefreshing = false;
        return handler.next(err);
      }

      final response = await _dio!.post(
        '/user/auth/refresh',
        data: {'refresh_token': refreshToken},
        options: Options(contentType: 'application/json'),
      );

      if (response.statusCode == 200) {
        final newAccessToken = response.data['access_token'] as String;
        final newRefreshToken = response.data['refresh_token'] as String?;

        await _secureStorage.write(
            key: 'access_token', value: newAccessToken);
        if (newRefreshToken != null) {
          await _secureStorage.write(
              key: 'refresh_token', value: newRefreshToken);
        }

        err.requestOptions.headers['Authorization'] =
            'Bearer $newAccessToken';

        final retryResponse = await _dio!.request(
          err.requestOptions.path,
          data: err.requestOptions.data,
          queryParameters: err.requestOptions.queryParameters,
          options: Options(
            method: err.requestOptions.method,
            headers: err.requestOptions.headers,
            responseType: err.requestOptions.responseType,
            contentType: err.requestOptions.contentType,
            extra: err.requestOptions.extra,
            receiveTimeout: err.requestOptions.receiveTimeout,
            sendTimeout: err.requestOptions.sendTimeout,
            validateStatus: err.requestOptions.validateStatus,
            listFormat: err.requestOptions.listFormat,
            followRedirects: err.requestOptions.followRedirects,
            maxRedirects: err.requestOptions.maxRedirects,
            requestEncoder: err.requestOptions.requestEncoder,
            responseDecoder: err.requestOptions.responseDecoder,
          ),
        );

        _isRefreshing = false;
        return handler.resolve(retryResponse);
      } else {
        await _clearTokens();
        _isRefreshing = false;
        return handler.next(err);
      }
    } catch (e) {
      await _clearTokens();
      _isRefreshing = false;
      return handler.next(err);
    }
  }

  Future<void> _clearTokens() async {
    await _secureStorage.delete(key: 'access_token');
    await _secureStorage.delete(key: 'refresh_token');
    _ref.read(sessionExpiredProvider.notifier).state = true;
  }
}

final authInterceptorProvider = Provider<AuthInterceptor>((ref) {
  final secureStorage = ref.read(secureStorageProvider);
  return AuthInterceptor(secureStorage, ref);
});
