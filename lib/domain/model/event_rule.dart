

import 'package:cloud_firestore/cloud_firestore.dart';

class EventRule {
  final String id;
  final String title;
  final DateTime startDateUtc;
  final DateTime endDateUtc;
  final bool isAllDay;
  final int duration;
  final bool isRecurring;
  final String recurrencePattern;
  final String location;

  EventRule({
    required this.id,
    required this.title,
    required this.startDateUtc,
    required this.endDateUtc,
    required this.isAllDay,
    required this.duration,
    required this.isRecurring,
    required this.recurrencePattern,
    required this.location,
  });

  factory EventRule.fromFirestore(DocumentSnapshot<Map<String, dynamic>> snapshot, SnapshotOptions? options) {
    final data = snapshot.data()!;

    return EventRule(id: data['id'], title: data['title'], startDateUtc: data['startDateUtc'], endDateUtc: data['endDateUtc'], 
      isAllDay: data['isAllDay'], duration: data['duration'], isRecurring: data['isRecurring'],
      recurrencePattern: data['recurrence'], location: data['location']);
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'title': title,
      'startDateUtc': startDateUtc,
      'endDateUtc': endDateUtc, 
      'isAllDay': isAllDay,
      'duration': duration,
      'isRecurring': isRecurring,
      'recurrencePattern': recurrencePattern,
      'location': location
    };
  }
}