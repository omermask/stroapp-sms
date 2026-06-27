import '../constants/api_constants.dart';
import '../models/audit_log.dart';
import '../network/api_client.dart';
import '../network/api_response.dart';

class LogsService {
  final _client = ApiClient();

  Future<({List<AuditLog> logs, int total})> listLogs({
    int page = 1,
    int limit = 30,
    String action = '',
    String userId = '',
  }) async {
    final params = <String, dynamic>{'page': page, 'limit': limit};
    if (action.isNotEmpty) params['action'] = action;
    if (userId.isNotEmpty) params['user_id'] = userId;

    final response = await _client.get(
      ApiConstants.logs,
      queryParameters: params,
    );
    final apiResp = ApiResponse.fromJson(response.data, null);

    if (apiResp.success && apiResp.data != null) {
      final data = apiResp.data as Map<String, dynamic>;
      final list =
          (data['items'] as List<dynamic>?)
              ?.map((e) => AuditLog.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [];
      final total = data['total'] as int? ?? list.length;
      return (logs: list, total: total);
    }
    throw Exception(apiResp.error?.message ?? 'Failed to load logs');
  }
}
