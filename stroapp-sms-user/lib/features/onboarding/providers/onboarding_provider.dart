import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/endpoints/onboarding_api.dart';
import '../../../core/api/api_exceptions.dart';

class OnboardingState {
  final bool isLoading;
  final bool completed;
  final int? currentStep;
  final String? error;

  const OnboardingState({this.isLoading = false, this.completed = false, this.currentStep, this.error});

  OnboardingState copyWith({bool? isLoading, bool? completed, int? currentStep, String? error}) {
    return OnboardingState(
      isLoading: isLoading ?? this.isLoading,
      completed: completed ?? this.completed,
      currentStep: currentStep ?? this.currentStep,
      error: error,
    );
  }
}

class OnboardingNotifier extends StateNotifier<OnboardingState> {
  final OnboardingApi _onboardingApi;

  OnboardingNotifier(this._onboardingApi) : super(const OnboardingState());

  Future<void> fetchOnboarding() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _onboardingApi.getOnboarding();
      state = state.copyWith(
        isLoading: false,
        completed: response['completed'] as bool? ?? false,
        currentStep: response['current_step'] as int?,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: extractErrorMessage(e, fallback: 'حدث خطأ'));
    }
  }

  Future<void> completeOnboarding() async {
    state = state.copyWith(isLoading: true);
    try {
      await _onboardingApi.completeOnboarding();
      state = state.copyWith(isLoading: false, completed: true);
    } catch (_) {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> skipOnboarding() async {
    try {
      await _onboardingApi.skipOnboarding();
      state = state.copyWith(completed: true);
    } catch (_) {}
  }

  void clearError() => state = state.copyWith(error: null);
}

final onboardingProvider = StateNotifierProvider<OnboardingNotifier, OnboardingState>((ref) {
  final onboardingApi = ref.read(onboardingApiProvider);
  return OnboardingNotifier(onboardingApi);
});
