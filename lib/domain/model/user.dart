import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class User {
  late String uid;
  late String displayName;
  late String email;
  final List<String> eventRuleKeys = [];
  late String? photoUrl;

  User({required this.uid, required this.displayName, required this.email, 
    this.photoUrl, List<String>? eventRuleKeys}) {
    if (eventRuleKeys != null) {
      this.eventRuleKeys.addAll(eventRuleKeys);
    }
  }

  factory User.fromAuth({required UserCredential userCredential}) {
    return User(uid: userCredential.user!.uid, displayName: userCredential.user!.displayName!, 
      email: userCredential.user!.email!, photoUrl: userCredential.user!.photoURL, eventRuleKeys: []);
  }

  factory User.fromFirestore(DocumentSnapshot<Map<String, dynamic>> snapshot, SnapshotOptions? options) {
    final data = snapshot.data()!;
    return User(uid: data['uid'], displayName: data['displayName'], email: data['email'], 
      photoUrl: data['photoUrl'], eventRuleKeys: List<String>.from(data['eventRuleKeys']));
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'uid': uid,
      'email': email,
      'photoUrl': photoUrl,
      'displayName': displayName,
      'eventRuleKeys': eventRuleKeys
    };
  }
}