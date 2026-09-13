import 'package:anu_timetable/domain/model/user.dart';
import 'package:anu_timetable/util/result.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:google_sign_in/google_sign_in.dart';

class UserRepositoryFirebase {
  User? currentUser;
  bool triedInitialSync = false;
  bool loading = false;
  
  Future<Result<User>> signInWithGoogle() async {
    final GoogleSignInAccount googleUser = await GoogleSignIn.instance.authenticate();
    final GoogleSignInAuthentication googleAuth = googleUser.authentication;
    final credential = firebase_auth.GoogleAuthProvider.credential(idToken: googleAuth.idToken);
    final userCredential = await firebase_auth.FirebaseAuth.instance.signInWithCredential(credential);
    final result = userCredential.additionalUserInfo!.isNewUser
      ? await addNewUser(userCredential)
      : await getUser(userCredential.user!.uid);
    if (result is Ok) {
      currentUser = (result as Ok).value;
    } else {
      currentUser = null;
    }
    return result;
  }

  Future<Result> signInWithMicrosoft() async {
    final provider = firebase_auth.OAuthProvider('microsoft.com');

    // Force ANU tenant, or use 'common' if you skip tenant restriction
    provider.setCustomParameters({
      'tenant': 'common',
      'prompt': 'select_account',
    });

    try {
      loading = true;
      final userCredential = await firebase_auth.FirebaseAuth.instance.signInWithProvider(provider);
      final user = userCredential.user;
      if (user == null) {
        throw Exception('Something went wrong');
      }
      if (user.email == null || !user.email!.endsWith('@anu.edu.au')) {
        await firebase_auth.FirebaseAuth.instance.currentUser!.delete();
        throw Exception('Please sign in with your ANU email');
      }

      triedInitialSync = userCredential.additionalUserInfo!.isNewUser;
      final result = userCredential.additionalUserInfo!.isNewUser
        ? await addNewUser(userCredential)
        : await getUser(userCredential.user!.uid);
      if (result is Ok) {
        currentUser = (result as Ok).value;
      } else {
        currentUser = null;
      }
      loading = false;
      return result;
    } on firebase_auth.FirebaseAuthException catch (e) {
      // Common ones: 'account-exists-with-different-credential', 'popup-blocked' (web), 'user-cancelled'
      loading = false;
      print('Auth error: ${e.code} - ${e.message}');
      if (e.code == 'web-context-cancelled') {
        return Result.ok(false);
      }
      return Result.error(e);

    } catch(e) {
      loading = false;
      return Result.error(e as Exception);
    }
  }

  Future<Result> signOut() async {
    try {
      await firebase_auth.FirebaseAuth.instance.signOut();
      return Result.ok(null);
    } catch (e) {
      print("Error signing out: $e");
      return Result.error(e as Exception);
    }
  }

  Future<Result> deleteAccount() async {
    try {
      final authUser = firebase_auth.FirebaseAuth.instance.currentUser;
      if (authUser == null || currentUser == null) {
        throw Exception("No current user found");
      }
      // TODO: handle requires-recent-login error
      await authUser.delete();

      final result = await removeFromGroups(currentUser!.uid, currentUser!.eventRuleKeys);

      switch(result) {
        case Ok():
          break;
        case Error():
          throw result.error;
      }

      final db = FirebaseFirestore.instance;

      await db.collection('users').doc(currentUser!.uid).delete();

      return Result.ok(null);

    } on firebase_auth.FirebaseAuthException catch(e) {

      // TODO: finish
      if (e.code == 'requires-recent-login') {
        final authUser = firebase_auth.FirebaseAuth.instance.currentUser;
        // authUser.reauthenticateWithCredential(credential)
      }
      return Result.error(e);

    } catch (e) {
      print("Error deleteing account: $e");
      return Result.error(Exception(e));
    }
  }

  Future<Result> addICalUrl(Uri url) async {
    final db = FirebaseFirestore.instance;
    if (currentUser == null) {
      return Result.error(Exception("No Current User"));
    }
    try {
      await db.collection('users').doc(currentUser!.uid).update({
        'iCalUrl': url.toString()
      });
      currentUser!.iCalUrl = url;
      return Result.ok(null);
    } catch(e) {
      return Result.error(Exception(e));
    }
  }

  Future<Result<User>> getUser(String uid) async {
    final db = FirebaseFirestore.instance;
    try {
      final snapshot = await db.collection('users').doc(uid)
        .withConverter(
          fromFirestore: User.fromFirestore,
          toFirestore: (user, _) => user.toMap())
        .get();
      final user = snapshot.data();
      print ("user: $user");
      return user == null
        ? Result.error(Exception("User not found"))
        : Result.ok(user);
    } catch (e) {
      return Result.error(Exception(e));
    }
  }

  Future<Result<User>> addNewUser(firebase_auth.UserCredential userCredential) async {
    final db = FirebaseFirestore.instance;
    User user = User.fromAuth(userCredential: userCredential);
    try {
      await db.collection('users').doc(user.uid).set(user.toMap());
      return Result.ok(user);
    } 
    catch(e) {
      return Result.error(Exception(e));
    }
  }
  
  Future<Result<User>> getCurrentUser() async {
    try {
      final authUser = firebase_auth.FirebaseAuth.instance.currentUser;
      if (authUser == null) {
        currentUser = null;
        return Result.error(Exception("No user currently signed in"));
      }
      final uid = firebase_auth.FirebaseAuth.instance.currentUser!.uid;
      final result = await getUser(uid);
      if (result is Ok) {
        print((result as Ok).value);
        currentUser = (result as Ok).value;
      }
      return result;
    } catch (e) {
      currentUser = null;
      return Result.error(Exception(e));
    }
    
  }

  Future<Result<(Set<String>, Set<String>)>> setUserEventRuleKeys(String userId, Set<String> keys) async {
    final db = FirebaseFirestore.instance;
    try {
      Set<String>? keysRemoved;
      Set<String>? keysAdded;
      final userRef = db.collection('users').doc(userId)
        .withConverter(
          fromFirestore: User.fromFirestore,
          toFirestore: (user, _) => user.toMap());
      await db.runTransaction((transaction) async {
        final snapshot = await transaction.get(userRef);
        final user = snapshot.data();
        if (user == null) {
          throw Exception("User not found");
        }
        keysRemoved = user.eventRuleKeys.difference(keys);
        keysAdded = keys.difference(user.eventRuleKeys);
        user.eventRuleKeys.clear();
        user.eventRuleKeys.addAll(keys);
        transaction.update(userRef, user.toMap());
      });
      return Result.ok((keysRemoved!, keysAdded!));
    }
    catch (e) {
      return Result.error(Exception(e));
    }
  }

  Future<Result> removeFromGroups(String uid, Set<String> keys) async {
    final db = FirebaseFirestore.instance;
    
    try {
      // TODO: check for empty groups and remove (including associated eventRules)
      final batch = db.batch();
      for (final key in keys) {
        batch.delete(db.collection('groups').doc(key).collection('members').doc(uid));
        // await db.collection('groups').doc(key).collection('members').doc(user.uid).delete();
      }
      await batch.commit();
      return Result.ok(null);
    }
    catch (e) {
      return Result.error(Exception(e));
    }
  }

  Future<Result> addToGroups(String uid, Set<String> keys) async {
    final db = FirebaseFirestore.instance;
    
    try {
      final batch = db.batch();
      for (final key in keys) {
        batch.set(db.collection('groups').doc(key).collection('members').doc(uid), {"userId": uid});
        // await db.collection('groups').doc(key).collection('members').doc(user.uid).set({"userId": user.uid});
      }
      await batch.commit();
      return Result.ok(null);
    }
    catch (e) {
      return Result.error(Exception(e));
    }
  }
  
  Future<Result> addUserToGroup(User user, Set<String> keys) async {
    final db = FirebaseFirestore.instance;
    try {
      for (final key in keys) {
        await db.collection('groups').doc(key).collection('members').doc(user.uid).set({"userId": user.uid});
      }
      return Result.ok(null);
    }
    catch (e) {
      return Result.error(Exception(e));
    }
  }
}