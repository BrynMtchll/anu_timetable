import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class User {
  final String uid;
  final String displayName;
  final String email;
  late Uri? iCalUrl;
  final Set<String> eventRuleKeys = {};
  final String? photoUrl;

  User({required this.uid, required this.displayName, required this.email, 
    this.iCalUrl, this.photoUrl, Set<String>? eventRuleKeys}) {
    if (eventRuleKeys != null) {
      this.eventRuleKeys.addAll(eventRuleKeys);
    }
  }

  factory User.fromAuth({required UserCredential userCredential}) {
    return User(uid: userCredential.user!.uid, displayName: userCredential.user!.displayName!, 
      email: userCredential.user!.email!, photoUrl: userCredential.user!.photoURL, eventRuleKeys: {});
  }

  factory User.fromFirestore(DocumentSnapshot<Map<String, dynamic>> snapshot, SnapshotOptions? options) {
    final data = snapshot.data()!;
    return User(uid: data['uid'], displayName: data['displayName'], email: data['email'], 
      photoUrl: data['photoUrl'], iCalUrl: data['iCalUrl'] != null ? Uri.parse(data['iCalUrl']) : null,
      eventRuleKeys: Set<String>.from(data['eventRuleKeys']));
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'uid': uid,
      'email': email,
      'photoUrl': photoUrl,
      'iCalUrl': iCalUrl?.toString(),
      'displayName': displayName,
      'eventRuleKeys': eventRuleKeys
    };
  }
}