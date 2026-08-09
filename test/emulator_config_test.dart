import 'package:anu_timetable/util/firebase_emulator.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('uses Android emulator host alias for Firebase emulators', () {
    expect(resolveFirebaseEmulatorHost(TargetPlatform.android), '10.0.2.2');
  });

  test('uses localhost for desktop platforms', () {
    expect(resolveFirebaseEmulatorHost(TargetPlatform.macOS), '127.0.0.1');
  });
}
