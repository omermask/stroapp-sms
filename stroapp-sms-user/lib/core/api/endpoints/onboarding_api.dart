import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../api_client.dart';

class OnboardingApi {
  final Dio _dio;

  OnboardingApi(this._dio);

  Future<Map<String, dynamic>> getOnboarding() async {
    final response = await _dio.get('/user/onboarding');
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> updateOnboardingStep(int step) async {
    final response = await _dio.post(
      '/user/onboarding/step',
      data: {'step': step},
    );
    return response.data as Map<String, dynamic>;
  }

  Future<void> completeOnboarding() async {
    await _dio.post('/user/onboarding/complete');
  }

  Future<void> skipOnboarding() async {
    await _dio.post('/user/onboarding/skip');
  }
}

final onboardingApiProvider = Provider<OnboardingApi>((ref) {
  final dio = ref.read(dioProvider);
  return OnboardingApi(dio);
});
