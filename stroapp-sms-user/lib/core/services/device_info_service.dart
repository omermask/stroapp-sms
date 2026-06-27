import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';

String _userAgent = 'StroApp/1.0';
String get userAgent => _userAgent;

Future<void> initDeviceInfo() async {
  try {
    final platform = Platform.operatingSystem;
    final parts = ['StroApp/1.0', platform];
    final versionStr = Platform.operatingSystemVersion;
    final firstToken = versionStr.split(' ').first;
    // Only add OS version if it starts with a digit (e.g. "14", "12.4")
    if (firstToken.isNotEmpty && RegExp(r'^\d').hasMatch(firstToken)) {
      parts.add(firstToken);
    }
    _userAgent = parts.join(' ');
    debugPrint('DeviceInfo: $_userAgent (raw: $versionStr)');
  } catch (e) {
    debugPrint('DeviceInfo error: $e');
  }
}
