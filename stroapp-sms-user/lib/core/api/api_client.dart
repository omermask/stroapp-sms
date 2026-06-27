import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'auth_interceptor.dart';
import 'api_exceptions.dart';
import '../utils/constants.dart';
import '../services/device_info_service.dart' as device_info;

final secureStorageProvider = Provider<FlutterSecureStorage>((ref) {
  return const FlutterSecureStorage();
});

class _ResponseInterceptor extends Interceptor {
  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    final data = response.data;
    if (data is Map<String, dynamic>) {
      if (data.containsKey('success') && data.containsKey('data')) {
        if (data['success'] == true) {
          response.data = data['data'];
        }
      }
    }
    handler.next(response);
  }
}

class _ErrorInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    ApiException apiException;

    switch (err.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        apiException = ApiException('TIMEOUT', 'انتهت مهلة الاتصال', 0);
        break;
      case DioExceptionType.connectionError:
        apiException = NetworkException();
        break;
      case DioExceptionType.badResponse:
        final statusCode = err.response?.statusCode ?? 500;
        final raw = err.response?.data;
        String message = 'حدث خطأ في الخادم';
        String code = 'SERVER_ERROR';

        if (raw is Map<String, dynamic>) {
          // Standard API error: {success: false, data: null, error: {code, message}}
          if (raw.containsKey('error') && raw['error'] is Map<String, dynamic>) {
            final errorData = raw['error'] as Map<String, dynamic>;
            message = errorData['message'] as String? ?? message;
            code = errorData['code'] as String? ?? code;
          }
          // FastAPI validation error: {detail: [{type, loc, msg}]}
          else if (raw.containsKey('detail') && raw['detail'] is List) {
            final detail = raw['detail'] as List;
            if (detail.isNotEmpty && detail[0] is Map<String, dynamic>) {
              message = detail[0]['msg'] as String? ?? message;
              code = 'VALIDATION_ERROR';
            }
          } else {
            message = raw['message'] as String? ?? raw['error'] as String? ?? message;
            code = raw['code'] as String? ?? code;
          }
        }

        if (statusCode == 401) {
          apiException = UnauthorizedException();
        } else if (statusCode == 403 && code == 'MFA_REQUIRED') {
          handler.reject(DioException(
            requestOptions: err.requestOptions,
            response: err.response,
            type: err.type,
            error: MfaRequiredException(message),
          ));
          return;
        } else if (statusCode == 403) {
          apiException = ApiException('FORBIDDEN', 'ليس لديك صلاحية', 403);
        } else if (statusCode == 404) {
          apiException = ApiException('NOT_FOUND', 'المورد غير موجود', 404);
        } else if (statusCode == 422) {
          apiException = ApiException('VALIDATION_ERROR', message, 422);
        } else if (statusCode == 429) {
          apiException = ApiException('RATE_LIMIT', 'طلبات كثيرة جداً، حاول لاحقاً', 429);
        } else if (statusCode == 502 && code == 'PROVIDER_ERROR') {
          apiException = ApiException('PROVIDER_ERROR', 'عذراً، المزود غير متاح حالياً، يرجى المحاولة لاحقاً', 502);
        } else if (statusCode >= 500) {
          apiException = ApiException('SERVER_ERROR', message, statusCode);
        } else {
          apiException = ApiException(code, message, statusCode);
        }
        break;
      default:
        apiException = ApiException('UNKNOWN', 'حدث خطأ غير متوقع', 0);
    }

    handler.reject(DioException(
      requestOptions: err.requestOptions,
      response: err.response,
      type: err.type,
      error: apiException,
    ));
  }
}

final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(
    BaseOptions(
      baseUrl: AppConstants.apiBaseUrl,
      connectTimeout: AppConstants.connectTimeout,
      receiveTimeout: AppConstants.receiveTimeout,
      headers: {
        'Accept': 'application/json',
        'User-Agent': device_info.userAgent,
      },
    ),
  );

  dio.interceptors.add(_ResponseInterceptor());
  dio.interceptors.add(_ErrorInterceptor());

  dio.interceptors.add(
    LogInterceptor(
      requestBody: true,
      responseBody: true,
    ),
  );

  final authInterceptor = ref.read(authInterceptorProvider);
  dio.interceptors.add(authInterceptor);
  authInterceptor.setDio(dio);

  return dio;
});
