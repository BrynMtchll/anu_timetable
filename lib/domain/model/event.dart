import 'package:anu_timetable/domain/model/event_rule.dart';

class Event {
  late String id;
  final String title;
  final String? key;
  final EventType type;
  final String summary;
  final String description;
  final DateTime startDate;
  final DateTime endDate;
  final bool isAllDay;
  final int duration;
  final String room;
  final String location;

  Event({
    required this.id,
    required this.title,
    required this.key,
    required this.type,
    required this.summary,
    required this.description,
    required this.startDate,
    required this.endDate,
    required this.isAllDay,
    required this.duration,
    required this.room,
    required this.location
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