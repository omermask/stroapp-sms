import 'dart:async';
import 'package:app_links/app_links.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final referralCodeProvider = StateProvider<String?>((ref) => null);

class DeepLinkService {
  final AppLinks _appLinks = AppLinks();
  StreamSubscription<Uri>? _sub;

  void Function(String)? _onRef;

  void setOnRef(void Function(String) onRef) {
    _onRef = onRef;
  }

  Future<void> init() async {
    _sub = _appLinks.uriLinkStream.listen((uri) {
      final ref = uri.queryParameters['ref'];
      if (ref != null && ref.isNotEmpty) {
        _onRef?.call(ref);
      }
    });
    final initialUri = await _appLinks.getInitialLink();
    if (initialUri != null) {
      final ref = initialUri.queryParameters['ref'];
      if (ref != null && ref.isNotEmpty) {
        _onRef?.call(ref);
      }
    }
  }

  void dispose() {
    _sub?.cancel();
  }
}

final deepLinkServiceProvider = Provider<DeepLinkService>((ref) {
  final service = DeepLinkService();
  service.setOnRef((refCode) {
    ref.read(referralCodeProvider.notifier).state = refCode;
  });
  ref.onDispose(() => service.dispose());
  return service;
});
