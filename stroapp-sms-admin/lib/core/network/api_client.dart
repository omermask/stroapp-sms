import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/api_constants.dart';
import '../utils/logger.dart';

class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;

  late final Dio _dio;
  late final Dio _v4Dio;

  ApiClient._internal() {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        headers: {'Content-Type': 'application/json'},
      ),
    );

    _v4Dio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.v4Base,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        headers: {'Content-Type': 'application/json'},
      ),
    );

    void attachInterceptors(Dio dio) {
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) async {
            final prefs = await SharedPreferences.getInstance();
            final token = prefs.getString('access_token');
            if (token != null) {
              options.headers['Authorization'] = 'Bearer $token';
            }
            AppLogger.request(
              options.method,
              '${options.baseUrl}${options.path}',
              body: options.data is Map ? Map<String, dynamic>.from(options.data as Map) : null,
            );
            handler.next(options);
          },
          onResponse: (response, handler) {
            AppLogger.response(response.statusCode ?? 0, response.data);
            handler.next(response);
          },
          onError: (error, handler) {
            AppLogger.error(
              '${error.requestOptions.method} ${error.requestOptions.path}',
              error: '${error.response?.statusCode} ${error.message}',
            );
            if (error.response?.statusCode == 401) {
              _handleUnauthorized();
            }
            handler.next(error);
          },
        ),
      );
    }

    attachInterceptors(_dio);
    attachInterceptors(_v4Dio);
  }

  void _handleUnauthorized() async {
    AppLogger.log('Token expired — clearing session', tag: 'AUTH');
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('access_token');
  }

  Future<Response> get(String path, {Map<String, dynamic>? queryParameters}) {
    return _dio.get(path, queryParameters: queryParameters);
  }

  Future<Response> getV4(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) {
    return _v4Dio.get(path, queryParameters: queryParameters);
  }

  Future<Response> post(String path, {dynamic data}) {
    return _dio.post(path, data: data);
  }

  Future<Response> postV4(String path, {dynamic data}) {
    return _v4Dio.post(path, data: data);
  }

  Future<Response> put(String path, {dynamic data}) {
    return _dio.put(path, data: data);
  }

  Future<Response> putV4(String path, {dynamic data}) {
    return _v4Dio.put(path, data: data);
  }

  Future<Response> delete(String path) {
    return _dio.delete(path);
  }

  static void setBaseUrl(String url) {
    AppLogger.log('Base URL changed: $url', tag: 'CONFIG');
    ApiConstants.baseUrl = url;
    _instance._dio.options.baseUrl = url;
    _instance._v4Dio.options.baseUrl = ApiConstants.v4Base;
  }
}
