import 'package:flutter/foundation.dart';
class AppPlatform {
  static bool get isAndroid => !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
  static bool get isIOS => !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;
  static bool get isWindows => !kIsWeb && defaultTargetPlatform == TargetPlatform.windows;
}
