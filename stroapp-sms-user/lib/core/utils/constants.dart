import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConstants {
  static const String appName = 'StroApp';
  static String get apiBaseUrl =>
      dotenv.get('API_BASE_URL', fallback: 'http://10.92.177.145:9527/stroapp/v1');
  static Duration get connectTimeout =>
      Duration(milliseconds: int.tryParse(dotenv.get('CONNECT_TIMEOUT', fallback: '10000')) ?? 10000);
  static Duration get receiveTimeout =>
      Duration(milliseconds: int.tryParse(dotenv.get('RECEIVE_TIMEOUT', fallback: '15000')) ?? 15000);
  static const String secureStorageKey = 'stroapp_secure';
}
