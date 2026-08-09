import 'package:flutter/foundation.dart';

String resolveFirebaseEmulatorHost(TargetPlatform platform) {
  switch (platform) {
    case TargetPlatform.android:
      return '10.0.2.2';
    case TargetPlatform.iOS:
    case TargetPlatform.macOS:
    case TargetPlatform.windows:
    case TargetPlatform.linux:
    default:
      return '127.0.0.1';
  }
}
