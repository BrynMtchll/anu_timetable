import 'package:anu_timetable/data/repositories/user_repository.dart';
import 'package:anu_timetable/domain/model/user.dart';
import 'package:anu_timetable/util/result.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:google_sign_in/google_sign_in.dart';

class UserRepositoryFirebase implements UserRepository {
  @override
  Future<Result<User>> signInWithGoogle() async {
    final GoogleSignInAccount googleUser = await GoogleSignIn.instance.authenticate();
    final GoogleSignInAuthentication googleAuth = googleUser.authentication;
    final credential = firebase_auth.GoogleAuthProvider.credential(idToken: googleAuth.idToken);
    final userCredential = await firebase_auth.FirebaseAuth.instance.signInWithCredential(credential);
    return userCredential.additionalUserInfo!.isNewUser 
      ? await addNewUser(userCredential)
      : await getUser(userCredential.user!.uid);
  }

  @override
  Future<Result<User>> getUser(String uid) async {
    final db = FirebaseFirestore.instance;
    final snapshot = await db.collection('users').doc(uid)
      .withConverter(
        fromFirestore: User.fromFirestore,
        toFirestore: (user, _) => user.toMap())
      .get();
    final user = snapshot.data();
    return user == null 
      ? Result.error(Exception("User not found"))
      : Result.ok(user);
  }

  @override
  Future<Result<User>> addNewUser(firebase_auth.UserCredential userCredential) async {
    final db = FirebaseFirestore.instance;

    User user = User.fromAuth(userCredential: userCredential);
    // TODO: handle error
    Exception? e;
    await db.collection('users').doc(user.uid).set(user.toMap())
    .onError((error, _) {
      e = Exception(error);
    });
    return e != null ? Result.error(e!) : Result.ok(user);
  }
  
  // TODO: consider moving to view model and find a way to do with just one request.
  @override
  Future<Result<User>> getCurrentUser() async {
    final authUser = firebase_auth.FirebaseAuth.instance.currentUser;
    if (authUser == null) {
      return Future.value(Result.error(Exception("No user currently signed in")));
    }
    final uid = firebase_auth.FirebaseAuth.instance.currentUser!.uid;
    return await getUser(uid);
  }
}