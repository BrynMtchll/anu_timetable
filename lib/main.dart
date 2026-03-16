import 'package:anu_timetable/router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:anu_timetable/app.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await FirebaseAuth.instance.useAuthEmulator('localhost', 9099);
  final router = MyRouter().router;
  FirebaseAuth.instance.authStateChanges().listen((User? user) {
    router.refresh();
  });
  runApp(App(router: router));
}
