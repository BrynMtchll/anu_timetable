import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

class Event {
  late String id;
  final String title;
  final DateTime startTime;
  final DateTime endTime;
  final String? location;

  Event({
    required this.id,
    required this.title,
    required this.startTime,
    required this.endTime,
    this.location,
  });

 factory Event.fromFirestore(DocumentSnapshot<Map<String, dynamic>> snapshot, SnapshotOptions? options) {
    final data = snapshot.data()!;

    return Event(id: data['id'], title: data['title'], startTime: data['startTime'], endTime: data['endTime'], 
      location: data['location']);
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'title': title,
      'startTime': startTime,
      'endTime': endTime,
      'location': location
    };
  }

  bool overlapping(Event other) =>
    startTime.compareTo(other.endTime) < 0 && other.startTime.compareTo(endTime) < 0;
}