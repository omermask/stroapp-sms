import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../api_client.dart';

class UserApi {
  final Dio _dio;

  UserApi(this._dio);

  Future<Map<String, dynamic>> getUserProfile() async {
    final response = await _dio.get('/user/profile');
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> updateProfile(
    String displayName,
    String? avatar,
  ) async {
    final response = await _dio.put(
      '/user/profile/update',
      data: {'display_name': displayName, 'avatar': avatar},
    );
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> changePassword(
    String currentPassword,
    String newPassword,
  ) async {
    final response = await _dio.post(
      '/user/change-password',
      data: {'current_password': currentPassword, 'new_password': newPassword},
      options: Options(contentType: 'application/json'),
    );
    return response.data as Map<String, dynamic>;
  }

  Future<void> deleteAccount() async {
    await _dio.delete('/user/account');
  }

  Future<Map<String, dynamic>> getBalance() async {
    final response = await _dio.get('/user/balance');
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getWallet() async {
    final response = await _dio.get('/user/wallet');
    return response.data as Map<String, dynamic>;
  }

  Future<List<dynamic>> getVerifications(int limit) async {
    final response = await _dio.get(
      '/user/verifications',
      queryParameters: {'limit': limit},
    );
    return response.data as List<dynamic>;
  }

  Future<Map<String, dynamic>> getVerificationDetail(String id) async {
    final response = await _dio.get('/user/verifications/$id');
    return response.data as Map<String, dynamic>;
  }

  Future<List<dynamic>> getTransactions(int limit, int offset) async {
    final response = await _dio.get(
      '/user/transactions',
      queryParameters: {'limit': limit, 'offset': offset},
    );
    return response.data as List<dynamic>;
  }

  Future<Map<String, dynamic>> refundCoins(String orderId) async {
    final response = await _dio.post(
      '/user/coins/refund',
      data: {'order_id': orderId},
    );
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> createInvoiceFromTransaction(String transactionId) async {
    final response = await _dio.post('/user/invoices/create-from-transaction/$transactionId');
    return response.data as Map<String, dynamic>;
  }

  Future<List<int>> downloadInvoicePdf(String invoiceId) async {
    final response = await _dio.get(
      '/user/invoices/$invoiceId/pdf',
      options: Options(responseType: ResponseType.bytes),
    );
    return response.data as List<int>;
  }
}

final userApiProvider = Provider<UserApi>((ref) {
  final dio = ref.read(dioProvider);
  return UserApi(dio);
});
