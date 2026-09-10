import 'package:anu_timetable/model/events.dart';
import 'package:anu_timetable/router.dart';
import 'package:anu_timetable/util/firebase_emulator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:anu_timetable/app.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  final emulatorHost = resolveFirebaseEmulatorHost(defaultTargetPlatform);

  FirebaseFirestore.setLoggingEnabled(true);
  FirebaseFirestore.instance.useFirestoreEmulator(emulatorHost, 8080);
  await FirebaseAuth.instance.useAuthEmulator(emulatorHost, 9099);

  final router = MyRouter().router;
  FirebaseAuth.instance.authStateChanges().listen((User? user) {
    router.refresh();
  });
  runApp(App(router: router));
}
