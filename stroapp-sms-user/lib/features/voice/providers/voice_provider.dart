import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/endpoints/voice_api.dart';
import '../../../core/api/api_exceptions.dart';

class VoiceState {
  final bool isLoading;
  final List<Map<String, dynamic>> services;
  final String? error;

  const VoiceState({this.isLoading = false, this.services = const [], this.error});

  VoiceState copyWith({bool? isLoading, List<Map<String, dynamic>>? services, String? error}) {
    return VoiceState(
      isLoading: isLoading ?? this.isLoading,
      services: services ?? this.services,
      error: error,
    );
  }
}

class VoiceNotifier extends StateNotifier<VoiceState> {
  final VoiceApi _voiceApi;

  VoiceNotifier(this._voiceApi) : super(const VoiceState());

  Future<void> fetchServices() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final data = await _voiceApi.getVoiceServices();
      state = state.copyWith(isLoading: false, services: data.cast<Map<String, dynamic>>());
    } catch (e) {
      state = state.copyWith(isLoading: false, error: extractErrorMessage(e, fallback: 'حدث خطأ'));
    }
  }

  Future<void> purchase(String service, String country) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _voiceApi.purchaseVoice(service, country);
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: extractErrorMessage(e, fallback: 'حدث خطأ في الشراء'));
    }
  }

  void clearError() => state = state.copyWith(error: null);
}

final voiceProvider = StateNotifierProvider<VoiceNotifier, VoiceState>((ref) {
  final voiceApi = ref.read(voiceApiProvider);
  return VoiceNotifier(voiceApi);
});
