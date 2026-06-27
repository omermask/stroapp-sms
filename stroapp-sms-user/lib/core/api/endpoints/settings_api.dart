import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../api_client.dart';

class SettingsApi {
  final Dio _dio;

  SettingsApi(this._dio);

  Future<List<dynamic>> getSessions() async {
    final response = await _dio.get('/user/sessions');
    return response.data as List<dynamic>;
  }

  Future<void> revokeSession(String sessionId) async {
    await _dio.post('/user/sessions/$sessionId/revoke');
  }

  Future<void> revokeAllSessions() async {
    await _dio.post('/user/sessions/revoke-all');
  }

  Future<List<dynamic>> getApiKeys() async {
    final response = await _dio.get('/user/api-keys');
    return response.data as List<dynamic>;
  }

  Future<Map<String, dynamic>> createApiKey(String name) async {
    final response = await _dio.post('/user/api-keys', data: {'name': name});
    return response.data as Map<String, dynamic>;
  }

  Future<void> deleteApiKey(String keyId) async {
    await _dio.delete('/user/api-keys/$keyId');
  }

  Future<Map<String, dynamic>> setupMfa() async {
    final response = await _dio.post('/user/mfa/setup');
    return response.data as Map<String, dynamic>;
  }

  Future<void> verifyMfa(String token) async {
    await _dio.post('/user/mfa/verify', data: {'token': token});
  }

  Future<void> disableMfa(String token) async {
    await _dio.post('/user/mfa/disable', data: {'token': token});
  }

  Future<bool> getMfaStatus() async {
    final response = await _dio.get('/user/mfa/status');
    return response.data['enabled'] as bool;
  }

  Future<List<dynamic>> getWebhookEvents() async {
    final response = await _dio.get('/user/webhooks/events');
    return response.data as List<dynamic>;
  }

  Future<Map<String, dynamic>> createWebhook(
    String url,
    List<String> events,
    String? secret,
  ) async {
    final response = await _dio.post(
      '/user/webhooks',
      data: {'url': url, 'events': events, 'secret': secret},
    );
    return response.data as Map<String, dynamic>;
  }

  Future<List<dynamic>> getWebhooks() async {
    final response = await _dio.get('/user/webhooks');
    return response.data as List<dynamic>;
  }

  Future<Map<String, dynamic>> getWebhookDetail(String webhookId) async {
    final response = await _dio.get('/user/webhooks/$webhookId');
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> updateWebhook(
    String webhookId,
    String? url,
    List<String>? events,
    bool? isActive,
  ) async {
    final response = await _dio.put(
      '/user/webhooks/$webhookId',
      data: {'url': url, 'events': events, 'is_active': isActive},
    );
    return response.data as Map<String, dynamic>;
  }

  Future<void> deleteWebhook(String webhookId) async {
    await _dio.delete('/user/webhooks/$webhookId');
  }

  Future<List<dynamic>> getWebhookEventsList(
    String webhookId,
    int limit,
  ) async {
    final response = await _dio.get(
      '/user/webhooks/$webhookId/events',
      queryParameters: {'limit': limit},
    );
    return response.data as List<dynamic>;
  }

  Future<Map<String, dynamic>> getForwardingConfig() async {
    final response = await _dio.get('/user/forwarding');
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> updateForwardingConfig(
    Map<String, dynamic> config,
  ) async {
    final response = await _dio.put('/user/forwarding', data: config);
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> testForwarding() async {
    final response = await _dio.get('/user/forwarding/test');
    return response.data as Map<String, dynamic>;
  }

  Future<List<dynamic>> getPresets() async {
    final response = await _dio.get('/user/presets');
    return response.data as List<dynamic>;
  }

  Future<Map<String, dynamic>> createPreset(
    String name,
    String service,
    String country,
  ) async {
    final response = await _dio.post(
      '/user/presets',
      data: {'name': name, 'service': service, 'country': country},
    );
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> updatePreset(
    String presetId,
    String? name,
    String? service,
    String? country,
  ) async {
    final response = await _dio.put(
      '/user/presets/$presetId',
      data: {'name': name, 'service': service, 'country': country},
    );
    return response.data as Map<String, dynamic>;
  }

  Future<void> deletePreset(String presetId) async {
    await _dio.delete('/user/presets/$presetId');
  }

  Future<Map<String, dynamic>> getGdprExport() async {
    final response = await _dio.get('/user/gdpr/export');
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getGdprConsent() async {
    final response = await _dio.get('/user/gdpr/consent');
    return response.data as Map<String, dynamic>;
  }

  Future<void> updateGdprConsent(
    bool marketing,
    bool analytics,
    bool dataSharing,
  ) async {
    await _dio.put(
      '/user/gdpr/consent',
      data: {
        'marketing': marketing,
        'analytics': analytics,
        'data_sharing': dataSharing,
      },
    );
  }

  Future<Map<String, dynamic>> getRetentionPolicy() async {
    final response = await _dio.get('/user/gdpr/retention-policy');
    return response.data as Map<String, dynamic>;
  }

  Future<List<dynamic>> getTiers() async {
    final response = await _dio.get('/user/tiers');
    return response.data as List<dynamic>;
  }

  Future<Map<String, dynamic>> getCurrentTier() async {
    final response = await _dio.get('/user/tiers/current');
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> upgradeTier(String tier) async {
    final response = await _dio.post(
      '/user/tiers/upgrade',
      data: {'tier': tier},
    );
    return response.data as Map<String, dynamic>;
  }
}

final settingsApiProvider = Provider<SettingsApi>((ref) {
  final dio = ref.read(dioProvider);
  return SettingsApi(dio);
});
