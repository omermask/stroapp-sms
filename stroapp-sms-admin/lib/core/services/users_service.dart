import '../constants/api_constants.dart';
import '../models/user.dart';
import '../network/api_client.dart';
import '../network/api_response.dart';

class UsersService {
  final _client = ApiClient();

  Future<({List<User> users, int total})> listUsers({
    int page = 1,
    int perPage = 20,
    String search = '',
    String? tier,
    bool? isBanned,
  }) async {
    final params = <String, dynamic>{'page': page, 'per_page': perPage};
    if (search.isNotEmpty) params['search'] = search;
    if (tier != null && tier.isNotEmpty) params['tier'] = tier;
    if (isBanned != null) params['is_banned'] = isBanned;

    final response = await _client.get(
      ApiConstants.users,
      queryParameters: params,
    );
    final apiResp = ApiResponse.fromJson(response.data, null);

    if (apiResp.success && apiResp.data != null) {
      final data = apiResp.data as Map<String, dynamic>;
      final list =
          (data['users'] as List<dynamic>?)
              ?.map((e) => User.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [];
      final total = data['total'] as int? ?? list.length;
      return (users: list, total: total);
    }
    throw Exception(apiResp.error?.message ?? 'Failed to load users');
  }

  Future<User> getUserDetail(String userId) async {
    final response = await _client.get(ApiConstants.userDetail(userId));
    final apiResp = ApiResponse.fromJson(response.data, null);
    if (apiResp.success && apiResp.data != null) {
      return User.fromJson(apiResp.data as Map<String, dynamic>);
    }
    throw Exception(apiResp.error?.message ?? 'User not found');
  }

  Future<void> toggleBan(String userId) async {
    final response = await _client.post(ApiConstants.banUser(userId), data: {});
    final apiResp = ApiResponse.fromJson(response.data, null);
    if (!apiResp.success) {
      throw Exception(apiResp.error?.message ?? 'Failed to toggle ban');
    }
  }

  Future<void> adjustCoins(String userId, int amount, String reason) async {
    final response = await _client.post(
      ApiConstants.adjustCoins(userId),
      data: {'coins': amount, 'reason': reason},
    );
    final apiResp = ApiResponse.fromJson(response.data, null);
    if (!apiResp.success) {
      throw Exception(apiResp.error?.message ?? 'Failed to adjust coins');
    }
  }

  Future<void> changeTier(String userId, String tier) async {
    final response = await _client.post(
      ApiConstants.setTier(userId),
      data: {'tier': tier},
    );
    final apiResp = ApiResponse.fromJson(response.data, null);
    if (!apiResp.success) {
      throw Exception(apiResp.error?.message ?? 'Failed to change tier');
    }
  }

  Future<void> deleteUser(String userId) async {
    final response = await _client.delete(ApiConstants.deleteUser(userId));
    final apiResp = ApiResponse.fromJson(response.data, null);
    if (!apiResp.success) {
      throw Exception(apiResp.error?.message ?? 'Failed to delete user');
    }
  }

  Future<void> invalidateSessions(String userId) async {
    final response = await _client.post(
      ApiConstants.invalidateSessions(userId),
      data: {},
    );
    final apiResp = ApiResponse.fromJson(response.data, null);
    if (!apiResp.success) {
      throw Exception(
        apiResp.error?.message ?? 'Failed to invalidate sessions',
      );
    }
  }
}
