

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:enough_icalendar/enough_icalendar.dart';
import 'package:uuid/uuid.dart';

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

  @override
  String toString() {
    switch (this) {
      case Freq.daily: return 'daily';
      case Freq.weekly: return 'weekly';
      case Freq.monthly: return 'monthly';
        case Freq.yearly: return 'yearly';
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
  // TODO: will need to assert valid input for byWeekday and byMonth
  /// tuple (instance, weekday) where weekday is 1 through 7, and instance is the nth occurrence
  /// in either the the month or year, depending on [Freq]. If instance is null, then it applies to all occurrences.
  /// Instance should be null when using with [Freq.weekly]. be mindful of 1 indexing for weekday here.
  List<({int? instance, int weekday})>? byWeekday = [];
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
    this.byWeekday,
    this.byMonthDay,
    this.byYearDay,
    this.bySetPos,
    this.byWeek,
    this.byMonth,
  });

  // factory RecurrencePattern.fromIcs(String icsStr) {

  // }

  factory RecurrencePattern.fromFirestore(Map<String, dynamic> recurrence) {
    return RecurrencePattern(freq: Freq.fromString(recurrence['freq']), interval: recurrence['interval'] ?? 1, 
      count: recurrence['count'], until: recurrence['until'].toDate(), byWeekday: recurrence['byWeekday'], byMonthDay: recurrence['byMonthDay'], 
      byYearDay: recurrence['byYearDay'], bySetPos: recurrence['bySetPos'], byWeek: recurrence['byWeek'], 
      byMonth: recurrence['byMonth']);
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'freq': freq.toString(),
      'interval': interval,
      'count': count,
      'until': until,
      'byWeekday': byWeekday,
      'byMonthDay': byMonthDay,
      'byYearDay': byYearDay,
      'bySetPos': bySetPos,
      'byWeek': byWeek,
      'byMonth': byMonth,
    };
  }

  bool get isByWeekday => byWeekday != null && byWeekday!.isNotEmpty;
  bool get isByMonthDay => (freq == Freq.yearly || freq == Freq.monthly) && byMonthDay != null && byMonthDay!.isNotEmpty;
  bool get isByYearDay => freq == Freq.yearly && byYearDay != null && byYearDay!.isNotEmpty;
  bool get isByWeek => freq == Freq.yearly && byWeek != null && byWeek!.isNotEmpty;
  bool get isByMonth => freq == Freq.yearly && byMonth != null && byMonth!.isNotEmpty;

  bool get isFirstDayPeriodic => !isByWeekday && !isByMonthDay && !isByYearDay;

  bool isPeriodStart(DateTime day, DateTime firstDay) {
    switch (freq) {
      case Freq.daily: return true;
      case Freq.weekly: return day.weekday == firstDay.weekday;
      case Freq.monthly: return day.day == 1;
      case Freq.yearly: return day.day == 1 && day.month == 1;
    }
  }

  DateTime periodStart(DateTime day) {
    switch (freq) {
      case Freq.daily: return(DateTime.utc(day.year, day.month, day.day));
      case Freq.weekly: return(DateTime.utc(day.year, day.month, day.day));
      case Freq.monthly: return(DateTime.utc(day.year, day.month));
      case Freq.yearly: return(DateTime.utc(day.year));
    }
  }

  DateTime nextPeriod(DateTime day) {
    switch (freq) {
      case Freq.daily: return(DateTime.utc(day.year, day.month, day.day + 1));
      case Freq.weekly: return(DateTime.utc(day.year, day.month, day.day + 7));
      case Freq.monthly: return(DateTime.utc(day.year, day.month + 1));
      case Freq.yearly: return(DateTime.utc(day.year + 1));
    }
  }
}

class EventRule {
  final String id;
  /// For eventRules that belong to the same rule.
  /// They should be the same rule but rule inference is too much effort
  /// right now when converting from the ics file that MyTimetable provides.
  /// the description is used as the key.
  /// Using a key means group membership doesn't need to be duplicated for
  /// every event instance.
  final String? key;
  final String title;
  final String summary;
  final String description;
  final DateTime startDate;
  /// referring to when an event instance finishes, not the last event occurence, 
  /// which is rather referred to by [RecurrencePattern.until]
  final DateTime endDate;
  final bool isAllDay;
  final int duration;
  final bool isRecurring;
  final RecurrencePattern? recurrencePattern;
  final String location;

  EventRule({
    required this.id,
    required this.key,
    required this.title,
    required this.summary,
    required this.description,
    required this.startDate,
    required this.endDate,
    required this.isAllDay,
    required this.duration,
    required this.isRecurring,
    required this.recurrencePattern,
    required this.location,
  });

  /// a list of events of the same class (since ANU provides them as individual events
  /// rather than as a rule). The rule must be inferred.
  /// Most typically will be weekly, but can also be multi weekly or fortnightly.
  /// TODO: kicking rule inference down the road, events will be individual for now
  /// TODO: duration is a dummy property too.
  factory EventRule.fromIcs(VEvent icsEvent) {
    return EventRule(
      id: Uuid().v4(),
      key: icsEvent.description!,
      title: icsEvent.description!.substring(0, 8),
      summary: icsEvent.summary!,
      description: icsEvent.description!,
      startDate: icsEvent.start!.toUtc(),
      endDate: icsEvent.end!.toUtc(),
      isAllDay: icsEvent.isAllDayEvent ?? false,
      duration: 0,
      isRecurring: false,
      recurrencePattern: null,
      location: icsEvent.location!,
    );
  }

  factory EventRule.fromFirestore(DocumentSnapshot<Map<String, dynamic>> snapshot, SnapshotOptions? options) {
    final data = snapshot.data()!;

    return EventRule(
      id: data['id'], 
      key: data['key'],
      title: data['title'], 
      summary: data['summary'], 
      description: data['description'], 
      startDate: data['startDate'].toDate(), 
      endDate: data['endDate'].toDate(), 
      isAllDay: data['isAllDay'], 
      duration: data['duration'], 
      isRecurring: data['isRecurring'],
      recurrencePattern: data['recurrencePattern'] == null ? null : RecurrencePattern.fromFirestore(data['recurrencePattern']), 
      location: data['location']);
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'key': key,
      'title': title,
      'summary': summary,
      'description': description,
      'startDate': startDate,
      'endDate': endDate, 
      'isAllDay': isAllDay,
      'duration': duration,
      'isRecurring': isRecurring,
      'recurrencePattern': recurrencePattern?.toMap(),
      'location': location,
    };
  }
}