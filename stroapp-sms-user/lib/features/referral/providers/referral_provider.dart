import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/endpoints/referral_api.dart';
import '../../../core/models/referral_info.dart';
import '../../../core/api/api_exceptions.dart';

class ReferralState {
  final bool isLoading;
  final ReferralInfo? info;
  final String? error;

  const ReferralState({this.isLoading = false, this.info, this.error});

  ReferralState copyWith({bool? isLoading, ReferralInfo? info, String? error}) {
    return ReferralState(
      isLoading: isLoading ?? this.isLoading,
      info: info ?? this.info,
      error: error,
    );
  }
}

class ReferralNotifier extends StateNotifier<ReferralState> {
  final ReferralApi _referralApi;

  ReferralNotifier(this._referralApi) : super(const ReferralState());

  Future<void> fetchReferralCode() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final codeResponse = await _referralApi.getReferralCode();
      Map<String, dynamic> merged = Map<String, dynamic>.from(codeResponse);

      try {
        final earningsResponse = await _referralApi.getReferralEarnings();
        merged.addAll(earningsResponse);
      } catch (_) {}

      final info = ReferralInfo.fromJson(merged);
      state = state.copyWith(isLoading: false, info: info);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: extractErrorMessage(e, fallback: 'حدث خطأ'));
    }
  }

  Future<void> claimCode(String code) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _referralApi.claimReferralCode(code);
      await fetchReferralCode();
    } catch (e) {
      state = state.copyWith(isLoading: false, error: extractErrorMessage(e, fallback: 'حدث خطأ'));
    }
  }

  void clearError() => state = state.copyWith(error: null);
}

final referralProvider = StateNotifierProvider<ReferralNotifier, ReferralState>((ref) {
  final referralApi = ref.read(referralApiProvider);
  return ReferralNotifier(referralApi);
});
