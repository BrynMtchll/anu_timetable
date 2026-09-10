import 'package:anu_timetable/domain/model/user.dart';
import 'package:anu_timetable/util/result.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;

abstract class UserRepository {
  Future<Result> signInWithGoogle();
  Future<Result> signOut();
  Future<Result> deleteAccount(User? user);
  Future<Result> addNewUser(firebase_auth.UserCredential userCredentials);
  Future<Result<User>> getUser(String uid);
  Future<Result<User>> getCurrentUser();
  Future<Result> addUserToGroup(User user, Set<String> keys);
  Future<Result<(Set<String>, Set<String>)>> setUserEventRuleKeys(String userId, Set<String> keys);
  Future<Result> addToGroups(String uid, Set<String> keys);
  Future<Result> removeFromGroups(String uid, Set<String> keys);
  // Future<Result> setUserGroups(User user, Set<String> keysRemoved, Set<String> keysAdded);

}