import 'package:anu_timetable/domain/model/user.dart';
import 'package:anu_timetable/util/result.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;

abstract class UserRepository {
  Future<Result> signInWithGoogle();
  Future<Result> addNewUser(firebase_auth.UserCredential userCredentials);
  Future<Result<User>> getUser(String uid);
  Future<Result<User>> getCurrentUser();
}