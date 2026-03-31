import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class User {
  late String uid;
  late String displayName;
  late String email;
  final List<String> eventIds = [];
  late String? photoUrl;

  User({required this.uid, required this.displayName, required this.email, 
    this.photoUrl, List<String>? eventIds}) {
    if (eventIds != null) {
      this.eventIds.addAll(eventIds);
    }
  }

  factory User.fromAuth({required UserCredential userCredential}) {
    return User(uid: userCredential.user!.uid, displayName: userCredential.user!.displayName!, 
      email: userCredential.user!.email!, photoUrl: userCredential.user!.photoURL);
  }

  factory User.fromFirestore(DocumentSnapshot<Map<String, dynamic>> snapshot, SnapshotOptions? options) {
    final data = snapshot.data()!;

    return User(uid: data['uid'], displayName: data['displayName'], email: data['email'], 
      photoUrl: data['photoUrl'], eventIds: List<String>.from(data['eventIds']));
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'uid': uid,
      'email': email,
      'photoUrl': photoUrl,
      'displayName': displayName,
      'eventIds': eventIds
    };
  }
}