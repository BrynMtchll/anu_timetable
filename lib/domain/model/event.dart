import 'package:cloud_firestore/cloud_firestore.dart';

class Event {
  late String ruleId;
  final String title;
  final DateTime startDate;
  final DateTime endDate;
  final bool isAllDay;
  final int duration;
  final String? location;

  Event({
    required this.ruleId,
    required this.title,
    required this.startDate,
    required this.endDate,
    required this.isAllDay,
    required this.duration,
    this.location
  });

//  factory Event.fromFirestore(DocumentSnapshot<Map<String, dynamic>> snapshot, SnapshotOptions? options) {
//     final data = snapshot.data()!;

//     return Event(id: data['id'], title: data['title'], startDate: data['startTime'], endTime: data['endTime'], 
//       location: data['location']);
//   }

//   Map<String, dynamic> toMap() {
//     return <String, dynamic>{
//       'id': id,
//       'title': title,
//       'startTime': startDate,
//       'endTime': endTime,
//       'location': location
//     };
//   }

  bool overlapping(Event other) =>
    startDate.compareTo(other.endDate) < 0 && other.startDate.compareTo(endDate) < 0;
}