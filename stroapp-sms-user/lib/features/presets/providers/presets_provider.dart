import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/endpoints/settings_api.dart';
import '../../../core/api/api_exceptions.dart';

class PresetsState {
  final bool isLoading;
  final List<Map<String, dynamic>> presets;
  final String? error;

  const PresetsState({this.isLoading = false, this.presets = const [], this.error});

  PresetsState copyWith({bool? isLoading, List<Map<String, dynamic>>? presets, String? error}) {
    return PresetsState(
      isLoading: isLoading ?? this.isLoading,
      presets: presets ?? this.presets,
      error: error,
    );
  }
}

class PresetsNotifier extends StateNotifier<PresetsState> {
  final SettingsApi _settingsApi;

  PresetsNotifier(this._settingsApi) : super(const PresetsState());

  Future<void> fetchPresets() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final data = await _settingsApi.getPresets();
      state = state.copyWith(isLoading: false, presets: data.cast<Map<String, dynamic>>());
    } catch (e) {
      state = state.copyWith(isLoading: false, error: extractErrorMessage(e, fallback: 'حدث خطأ'));
    }
  }

  Future<void> createPreset(String name, String service, String country) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _settingsApi.createPreset(name, service, country);
      await fetchPresets();
    } catch (e) {
      state = state.copyWith(isLoading: false, error: extractErrorMessage(e, fallback: 'حدث خطأ'));
    }
  }

  Future<void> deletePreset(String presetId) async {
    state = state.copyWith(presets: state.presets.where((p) => p['id'].toString() != presetId).toList());
    try {
      await _settingsApi.deletePreset(presetId);
    } catch (_) {
      await fetchPresets();
    }
  }

  void clearError() => state = state.copyWith(error: null);
}

final presetsProvider = StateNotifierProvider<PresetsNotifier, PresetsState>((ref) {
  final settingsApi = ref.read(settingsApiProvider);
  return PresetsNotifier(settingsApi);
});
