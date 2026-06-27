import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/endpoints/kyc_api.dart';
import '../../../core/models/kyc_profile.dart';
import '../../../core/api/api_exceptions.dart';

class KycState {
  final bool isLoading;
  final KycProfile? profile;
  final String? status;
  final String? error;

  const KycState({this.isLoading = false, this.profile, this.status, this.error});

  KycState copyWith({bool? isLoading, KycProfile? profile, String? status, String? error}) {
    return KycState(
      isLoading: isLoading ?? this.isLoading,
      profile: profile ?? this.profile,
      status: status ?? this.status,
      error: error,
    );
  }
}

class KycNotifier extends StateNotifier<KycState> {
  final KycApi _kycApi;

  KycNotifier(this._kycApi) : super(const KycState());

  Future<void> fetchStatus() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _kycApi.getKycStatus();
      state = state.copyWith(
        isLoading: false,
        status: response['status'] as String?,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: extractErrorMessage(e, fallback: 'حدث خطأ'));
    }
  }

  Future<void> fetchProfile() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _kycApi.getKycProfile();
      final profile = KycProfile.fromJson(response);
      state = state.copyWith(isLoading: false, profile: profile, status: profile.status);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: extractErrorMessage(e, fallback: 'حدث خطأ'));
    }
  }

  Future<void> submitKyc(Map<String, dynamic> data) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _kycApi.createKycProfile(data);
      final profile = KycProfile.fromJson(response);
      state = state.copyWith(isLoading: false, profile: profile, status: profile.status);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: extractErrorMessage(e, fallback: 'حدث خطأ في تقديم الطلب'));
    }
  }

  void clearError() => state = state.copyWith(error: null);
}

final kycProvider = StateNotifierProvider<KycNotifier, KycState>((ref) {
  final kycApi = ref.read(kycApiProvider);
  return KycNotifier(kycApi);
});
