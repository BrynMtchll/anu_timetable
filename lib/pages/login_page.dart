import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

Future<UserCredential> signInWithGoogle() async {
  // Trigger the authentication flow
  final GoogleSignInAccount? googleUser = await GoogleSignIn.instance.authenticate();

  // Obtain the auth details from the request
  final GoogleSignInAuthentication googleAuth = googleUser!.authentication;

  // Create a new credential
  final credential = GoogleAuthProvider.credential(idToken: googleAuth.idToken);

  // Once signed in, return the UserCredential
  return await FirebaseAuth.instance.signInWithCredential(credential);
}

Future<UserCredential> signInWithMicrosoft() async {
  final microsoftProvider = MicrosoftAuthProvider();
  if (kIsWeb) {
    return await FirebaseAuth.instance.signInWithPopup(microsoftProvider);
  } else {
    return await FirebaseAuth.instance.signInWithProvider(microsoftProvider);
  }
}
class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    ColorScheme colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: SafeArea(
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 50, horizontal: 20),
          child: Center(
            child: Column(
              spacing: 20,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  style: TextStyle(
                    color: colorScheme.onSurface,
                    fontSize: 30,
                    fontWeight: FontWeight.w600,
                  ),
                "Login"),
                ElevatedButton(
                  child: Text("Sign in with Microsoft"),
                  onPressed: () {
                    signInWithGoogle();
                    // signInWithMicrosoft();
                  })
              ])))));
  }
}
