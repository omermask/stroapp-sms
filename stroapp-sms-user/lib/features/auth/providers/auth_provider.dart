import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../core/api/api_client.dart';
import '../../../core/api/endpoints/auth_api.dart';
import '../../../core/api/api_exceptions.dart';
import '../../../core/models/user.dart';

class AuthState {
  final bool isAuthenticated;
  final bool isLoading;
  final User? user;
  final String? error;

  const AuthState({
    this.isAuthenticated = false,
    this.isLoading = false,
    this.user,
    this.error,
  });

  AuthState copyWith({
    bool? isAuthenticated,
    bool? isLoading,
    User? user,
    String? error,
  }) {
    return AuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      isLoading: isLoading ?? this.isLoading,
      user: user ?? this.user,
      error: error,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthApi _authApi;
  final FlutterSecureStorage _secureStorage;

  AuthNotifier(this._authApi, this._secureStorage) : super(const AuthState());

  Future<void> login(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _authApi.login(email, password);
      await _secureStorage.write(key: 'access_token', value: response['access_token'] as String);
      if (response.containsKey('refresh_token')) {
        await _secureStorage.write(key: 'refresh_token', value: response['refresh_token'] as String);
      }
      final user = User.fromJson(response['user'] as Map<String, dynamic>);
      state = state.copyWith(isLoading: false, isAuthenticated: true, user: user);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: extractErrorMessage(e, fallback: 'حدث خطأ في تسجيل الدخول'));
    }
  }

  Future<void> register(String email, String password, String displayName, String turnstileToken, {String? ref}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _authApi.register(email, password, displayName, turnstileToken, ref: ref);
      await _secureStorage.write(key: 'access_token', value: response['access_token'] as String);
      if (response.containsKey('refresh_token')) {
        await _secureStorage.write(key: 'refresh_token', value: response['refresh_token'] as String);
      }
      final user = User.fromJson(response['user'] as Map<String, dynamic>);
      state = state.copyWith(isLoading: false, isAuthenticated: true, user: user);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: extractErrorMessage(e, fallback: 'حدث خطأ في التسجيل'));
    }
  }

  Future<void> loginWithGoogle(String idToken, {String? ref}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _authApi.loginWithGoogle(idToken, ref: ref);
      await _secureStorage.write(key: 'access_token', value: response['access_token'] as String);
      if (response.containsKey('refresh_token')) {
        await _secureStorage.write(key: 'refresh_token', value: response['refresh_token'] as String);
      }
      final user = User.fromJson(response['user'] as Map<String, dynamic>);
      state = state.copyWith(isLoading: false, isAuthenticated: true, user: user);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: extractErrorMessage(e, fallback: 'حدث خطأ في تسجيل الدخول'));
    }
  }

  Future<void> loginWithApple(String identityToken, {String? ref}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _authApi.loginWithApple(identityToken, ref: ref);
      await _secureStorage.write(key: 'access_token', value: response['access_token'] as String);
      if (response.containsKey('refresh_token')) {
        await _secureStorage.write(key: 'refresh_token', value: response['refresh_token'] as String);
      }
      final user = User.fromJson(response['user'] as Map<String, dynamic>);
      state = state.copyWith(isLoading: false, isAuthenticated: true, user: user);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: extractErrorMessage(e, fallback: 'حدث خطأ في تسجيل الدخول'));
    }
  }

  Future<void> logout() async {
    state = state.copyWith(isLoading: true);
    final refreshToken = await _secureStorage.read(key: 'refresh_token');
    try {
      await _authApi.logout(refreshToken: refreshToken);
    } catch (_) {}
    await _secureStorage.delete(key: 'access_token');
    await _secureStorage.delete(key: 'refresh_token');
    state = const AuthState();
  }

  Future<void> checkAuth() async {
    final token = await _secureStorage.read(key: 'access_token');
    if (token == null) {
      state = const AuthState();
      return;
    }
    state = state.copyWith(isLoading: true);
    try {
      final response = await _authApi.getMe();
      final user = User.fromJson(response);
      state = state.copyWith(isLoading: false, isAuthenticated: true, user: user);
    } catch (_) {
      await _secureStorage.delete(key: 'access_token');
      await _secureStorage.delete(key: 'refresh_token');
      state = const AuthState();
    }
  }

  Future<void> forgotPassword(String email) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _authApi.forgotPassword(email);
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: extractErrorMessage(e));
    }
  }

  Future<void> resetPassword(String token, String newPassword) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _authApi.resetPassword(token, newPassword);
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: extractErrorMessage(e));
    }
  }

  void clearError() => state = state.copyWith(error: null);
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final authApi = ref.read(authApiProvider);
  final secureStorage = ref.read(secureStorageProvider);
  return AuthNotifier(authApi, secureStorage);
});
