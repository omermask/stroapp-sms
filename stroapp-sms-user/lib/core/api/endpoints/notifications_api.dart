import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../api_client.dart';

class NotificationsApi {
  final Dio _dio;

  NotificationsApi(this._dio);

  Future<List<dynamic>> getNotifications(int limit, int offset) async {
    final response = await _dio.get(
      '/user/notifications',
      queryParameters: {'limit': limit, 'offset': offset},
    );
    return response.data as List<dynamic>;
  }

  Future<int> getUnreadCount() async {
    final response = await _dio.get('/user/notifications/unread');
    return response.data['count'] as int;
  }

  Future<void> markAllRead() async {
    await _dio.post('/user/notifications/read-all');
  }

  Future<Map<String, dynamic>> getPreferences() async {
    final response = await _dio.get('/user/notifications/preferences');
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> updatePreferences(
    Map<String, dynamic> prefs,
  ) async {
    final response = await _dio.put(
      '/user/notifications/preferences',
      data: prefs,
    );
    return response.data as Map<String, dynamic>;
  }
}

final notificationsApiProvider = Provider<NotificationsApi>((ref) {
  final dio = ref.read(dioProvider);
  return NotificationsApi(dio);
});
