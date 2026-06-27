import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

final appleAuthServiceProvider = Provider<AppleAuthService>((ref) {
  return AppleAuthService();
});

class AppleAuthService {
  Future<String?> signIn() async {
    try {
      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );
      return credential.identityToken;
    } catch (e) {
      return null;
    }
  }
}
