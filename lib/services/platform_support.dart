import 'package:flutter/foundation.dart';

/// Capability flags so one codebase runs on Android/iOS, web/PWA and desktop.
class PlatformSupport {
  PlatformSupport._();

  static bool get isMobile =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  static bool get isAndroid =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  /// AdMob, RevenueCat and sqflite plugins only exist on mobile.
  static bool get supportsAds => isMobile;
  static bool get supportsBilling => isMobile;
  static bool get supportsSqlite => isMobile;
}
