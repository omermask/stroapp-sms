import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../api_client.dart';

class ReferralApi {
  final Dio _dio;

  ReferralApi(this._dio);

  Future<Map<String, dynamic>> getReferralCode() async {
    final response = await _dio.get('/user/referral/code');
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> claimReferralCode(String code) async {
    final response = await _dio.post(
      '/user/referral/claim',
      data: {'code': code},
    );
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getReferralEarnings() async {
    final response = await _dio.get('/user/referral/earnings');
    return response.data as Map<String, dynamic>;
  }
}

final referralApiProvider = Provider<ReferralApi>((ref) {
  final dio = ref.read(dioProvider);
  return ReferralApi(dio);
});
