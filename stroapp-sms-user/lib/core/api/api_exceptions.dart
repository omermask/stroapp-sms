import 'package:dio/dio.dart';

class ApiException implements Exception {
  final String code;
  final String message;
  final int statusCode;

  ApiException(this.code, this.message, this.statusCode);

  @override
  String toString() => message;
}

class NetworkException extends ApiException {
  NetworkException()
      : super('NETWORK_ERROR', 'لا يوجد اتصال بالإنترنت', 0);
}

class UnauthorizedException extends ApiException {
  UnauthorizedException()
      : super('UNAUTHORIZED', 'انتهت الجلسة، يرجى تسجيل الدخول مرة أخرى', 401);
}

class MfaRequiredException implements Exception {
  final String message;
  MfaRequiredException([this.message = 'مطلوب التحقق بخطوتين']);
  @override
  String toString() => message;
}

String extractErrorMessage(dynamic error, {String fallback = 'حدث خطأ غير متوقع'}) {
  if (error is ApiException) return error.message;
  if (error is DioException) {
    if (error.error is ApiException) return (error.error as ApiException).message;
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'انتهت مهلة الاتصال';
      case DioExceptionType.connectionError:
        return 'لا يوجد اتصال بالإنترنت';
      default:
        return fallback;
    }
  }
  return fallback;
}
