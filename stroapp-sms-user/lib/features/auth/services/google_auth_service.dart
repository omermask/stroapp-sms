import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../../core/api/api_client.dart';

final googleAuthServiceProvider = Provider<GoogleAuthService>((ref) {
  final dio = ref.read(dioProvider);
  return GoogleAuthService(dio);
});

class GoogleAuthService {
  final Dio _dio;
  GoogleSignIn? _googleSignIn;

  GoogleAuthService(this._dio);

  Future<String?> getClientId() async {
    final response = await _dio.get('/user/auth/google/config');
    final data = response.data as Map<String, dynamic>;
    if (data['enabled'] == true && data['client_id'] != null && (data['client_id'] as String).isNotEmpty) {
      return data['client_id'] as String;
    }
    return null;
  }

  Future<String?> signIn() async {
    final clientId = await getClientId();
    if (clientId == null) return null;

    _googleSignIn ??= GoogleSignIn(
      scopes: ['email', 'profile'],
      serverClientId: clientId,
    );

    final account = await _googleSignIn!.signIn();
    if (account == null) {
      _googleSignIn?.signInSilently();
      return null;
    }

    final auth = await account.authentication;
    return auth.idToken;
  }

  Future<void> signOut() async {
    await _googleSignIn?.signOut();
  }
}
