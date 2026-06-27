import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/endpoints/settings_api.dart';
import '../../../core/api/endpoints/user_api.dart';
import '../../../core/models/api_key_model.dart';
import '../../../core/models/webhook_model.dart';
import '../../../core/models/tier.dart';
import '../../../core/api/api_exceptions.dart' show extractErrorMessage, MfaRequiredException;

class SettingsState {
  final bool isLoading;
  final bool isDarkMode;
  final String? locale;
  final List<ApiKeyModel> apiKeys;
  final List<WebhookModel> webhooks;
  final Tier? currentTier;
  final String? error;

  const SettingsState({
    this.isLoading = false,
    this.isDarkMode = false,
    this.locale,
    this.apiKeys = const [],
    this.webhooks = const [],
    this.currentTier,
    this.error,
  });

  SettingsState copyWith({
    bool? isLoading,
    bool? isDarkMode,
    String? locale,
    List<ApiKeyModel>? apiKeys,
    List<WebhookModel>? webhooks,
    Tier? currentTier,
    String? error,
  }) {
    return SettingsState(
      isLoading: isLoading ?? this.isLoading,
      isDarkMode: isDarkMode ?? this.isDarkMode,
      locale: locale ?? this.locale,
      apiKeys: apiKeys ?? this.apiKeys,
      webhooks: webhooks ?? this.webhooks,
      currentTier: currentTier ?? this.currentTier,
      error: error,
    );
  }
}

class SettingsNotifier extends StateNotifier<SettingsState> {
  final SettingsApi _settingsApi;
  final UserApi _userApi;

  SettingsNotifier(this._settingsApi, this._userApi) : super(const SettingsState());

  void toggleDarkMode() => state = state.copyWith(isDarkMode: !state.isDarkMode);
  void setLocale(String locale) => state = state.copyWith(locale: locale);

  Future<void> fetchApiKeys() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final data = await _settingsApi.getApiKeys();
      final apiKeys = data.map((e) => ApiKeyModel.fromJson(e as Map<String, dynamic>)).toList();
      state = state.copyWith(isLoading: false, apiKeys: apiKeys);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: extractErrorMessage(e, fallback: 'حدث خطأ'));
    }
  }

  Future<void> createApiKey(String name) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _settingsApi.createApiKey(name);
      await fetchApiKeys();
    } on MfaRequiredException {
      state = state.copyWith(isLoading: false);
      rethrow;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: extractErrorMessage(e, fallback: 'حدث خطأ'));
    }
  }

  Future<void> deleteApiKey(String keyId) async {
    try {
      await _settingsApi.deleteApiKey(keyId);
      await fetchApiKeys();
    } on MfaRequiredException {
      rethrow;
    } catch (_) {}
  }

  Future<void> changePassword(String current, String newPassword) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _userApi.changePassword(current, newPassword);
      state = state.copyWith(isLoading: false);
    } on MfaRequiredException {
      state = state.copyWith(isLoading: false);
      rethrow;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: extractErrorMessage(e, fallback: 'حدث خطأ'));
    }
  }

  Future<void> deleteAccount() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _userApi.deleteAccount();
      state = state.copyWith(isLoading: false);
    } on MfaRequiredException {
      state = state.copyWith(isLoading: false);
      rethrow;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: extractErrorMessage(e, fallback: 'حدث خطأ'));
    }
  }

  Future<void> fetchCurrentTier() async {
    try {
      final response = await _settingsApi.getCurrentTier();
      final config = response['config'] as Map<String, dynamic>;
      final tier = Tier.fromJson(config);
      state = state.copyWith(currentTier: tier);
    } catch (_) {}
  }

  void clearError() => state = state.copyWith(error: null);
}

final settingsProvider = StateNotifierProvider<SettingsNotifier, SettingsState>((ref) {
  final settingsApi = ref.read(settingsApiProvider);
  final userApi = ref.read(userApiProvider);
  return SettingsNotifier(settingsApi, userApi);
});
