import 'package:flutter/foundation.dart';

class AppLogger {
  static void log(String message, {String tag = 'APP'}) {
    debugPrint('[$tag] $message');
  }

  static void api(String message) {
    debugPrint('[API] $message');
  }

  static void request(String method, String url, {Map<String, dynamic>? body}) {
    debugPrint('[REQ] $method $url');
    if (body != null) {
      debugPrint('[REQ] Body: $body');
    }
  }

  static void response(int statusCode, dynamic data) {
    debugPrint('[RES] Status: $statusCode');
    if (data != null) {
      final str = data.toString();
      debugPrint(
        '[RES] Data: ${str.length > 500 ? '${str.substring(0, 500)}...' : str}',
      );
    }
  }

  static void error(String message, {dynamic error}) {
    debugPrint('[ERR] $message');
    if (error != null) {
      debugPrint('[ERR] Details: $error');
    }
  }
}
