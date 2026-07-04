

import 'package:cloud_firestore/cloud_firestore.dart';

enum Freq {
  daily, weekly, monthly, yearly;
  // TODO: handle bad input better
  static Freq fromString(String freqStr) {
    switch (freqStr) {
      case 'daily': return Freq.daily;
      case 'weekly': return Freq.weekly;
      case 'monthly': return Freq.monthly;
      case 'yearly': return Freq.yearly;
      default: throw Error;
    }
  }
}

class RecurrencePattern {
  final Freq freq;
  int interval;
  // if endDateUtc is required then this option should be obsolete
  int? count;
  /// must be careful that one of until and count are set
  DateTime? until;
  // TODO: will need to assert valid input for byDay and byMonth
  /// tuple (instance, weekday) where weekday is 1 through 7, and instance is the nth occurrence
  /// in either the the month or year, depending on [Freq].
  /// If instance is null, then it applies to all occurrences.
  /// Instance should be null when using with [Freq.weekly].
  /// be mindful of 1 indexing for weekday here.
  List<({int? instance, int weekday})>? byDay = [];
  List<int>? byMonthDay = [];
  List<int>? byYearDay = [];
  List<int>? bySetPos = [];
  /// week index of year, only compatable with [Freq.yearly]
  List<int>? byWeek = [];
  List<int>? byMonth = [];

  RecurrencePattern({
    required this.freq,
    required this.interval,
    this.count,
    this.until,
    this.byDay,
    this.byMonthDay,
    this.byYearDay,
    this.bySetPos,
    this.byWeek,
    this.byMonth,
  });

  factory RecurrencePattern.fromFirestore(Map<String, dynamic> recurrence) {
    return RecurrencePattern(freq: Freq.fromString(recurrence['freq']), interval: recurrence['interval'] ?? 1, 
      count: recurrence['count'], until: recurrence['until'], byDay: recurrence['byDay'], byMonthDay: recurrence['byMonthDay'], 
      byYearDay: recurrence['byYearDay'], bySetPos: recurrence['bySetPos'], byWeek: recurrence['byWeek'], 
      byMonth: recurrence['byMonth']);
  }
}

class EventRule {
  final String id;
  final String title;
  final DateTime startDate;
  /// referring to when an event instance finishes, not the last event occurence, 
  /// which is rather referred to by [RecurrencePattern.until]
  final DateTime endDate;
  final bool isAllDay;
  final int duration;
  final bool isRecurring;
  final RecurrencePattern recurrencePattern;
  final String location;

  EventRule({
    required this.id,
    required this.title,
    required this.startDate,
    required this.endDate,
    required this.isAllDay,
    required this.duration,
    required this.isRecurring,
    required this.recurrencePattern,
    required this.location,
  });

  factory EventRule.fromFirestore(DocumentSnapshot<Map<String, dynamic>> snapshot, SnapshotOptions? options) {
    final data = snapshot.data()!;

    return EventRule(id: data['id'], title: data['title'], startDate: data['startDate'], endDate: data['endDate'], 
      isAllDay: data['isAllDay'], duration: data['duration'], isRecurring: data['isRecurring'],
      recurrencePattern: RecurrencePattern.fromFirestore(data['recurrence']), location: data['location']);
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'title': title,
      'startDate': startDate,
      'endDate': endDate, 
      'isAllDay': isAllDay,
      'duration': duration,
      'isRecurring': isRecurring,
      'recurrencePattern': recurrencePattern,
      'location': location
    };
  }
}