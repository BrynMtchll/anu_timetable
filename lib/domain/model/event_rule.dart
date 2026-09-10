

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:enough_icalendar/enough_icalendar.dart';
import 'package:uuid/uuid.dart';

enum EventTypeEnum {
  lec, dro, asm, com, tut, wor, preLec, sem, pra, stu, let, other;
}

class EventType {
  final EventTypeEnum typeEnum;
  final String typeStr;
  final String item;
  final String typeStrFull;

  EventType({required this.typeEnum, required this.typeStr, required this.item, required this.typeStrFull});

  /// Seems to always be a 3 letter abbreviation, followed by single letter item.
  /// will subscribe to the more general rule of the last space being the item, and everything before that being the typeStr.
  /// NOTE: Extending this will implicate [CalendarTheme] in [theme_extension.dart].
  static EventType fromString(String str) {
    final typeStr = str.substring(0, str.length - 1);
    final item = str.substring(str.length - 1);
    switch(typeStr) {
      case 'Lec': return EventType(typeEnum: EventTypeEnum.lec, typeStr: typeStr, item: item, typeStrFull: 'Lecture');
      case 'Tut': return EventType(typeEnum: EventTypeEnum.tut, typeStr: typeStr, item: item, typeStrFull: 'Tutorial');
      case 'Dro': return EventType(typeEnum: EventTypeEnum.dro, typeStr: typeStr, item: item, typeStrFull: 'Drop-In');
      case 'Asm': return EventType(typeEnum: EventTypeEnum.asm, typeStr: typeStr, item: item, typeStrFull: 'Assessment');
      case 'Com': return EventType(typeEnum: EventTypeEnum.com, typeStr: typeStr, item: item, typeStrFull: 'Computer Lab');
      case 'Wor': return EventType(typeEnum: EventTypeEnum.wor, typeStr: typeStr, item: item, typeStrFull: 'Workshop');
      case 'Pre': return EventType(typeEnum: EventTypeEnum.preLec, typeStr: typeStr, item: item, typeStrFull: 'Pre-Lecture');
      case 'Sem': return EventType(typeEnum: EventTypeEnum.sem, typeStr: typeStr, item: item, typeStrFull: 'Seminar');
      case 'Pra': return EventType(typeEnum: EventTypeEnum.pra, typeStr: typeStr, item: item, typeStrFull: 'Practical');
      case 'Stu': return EventType(typeEnum: EventTypeEnum.stu, typeStr: typeStr, item: item, typeStrFull: 'Studio');
      case 'Let': return EventType(typeEnum: EventTypeEnum.let, typeStr: typeStr, item: item, typeStrFull: 'Lectorial');
      case _: return EventType(typeEnum: EventTypeEnum.other, typeStr: typeStr, item: item, typeStrFull: typeStr);
    }
  }

  @override
  String toString() {
    return typeStr + item;
  }
}

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
  final String title;
  final String summary;
  final EventType type;
  final String description;
  final DateTime startDate;
  /// referring to when an event instance finishes, not the last event occurence, 
  /// which is rather referred to by [RecurrencePattern.until]
  final DateTime endDate;
  final bool isAllDay;
  final int duration;
  final bool isRecurring;
  final RecurrencePattern? recurrencePattern;
  final String room;
  final String location;
  /// Abusing the specification here as ANU has - they provide each ics event as its own rule,
  /// so rather than inferring the rule from the set of events given, we will keep track of the
  /// start and end dates for those rules. Reverting this is trivial if there isn't much real data to modify.
  /// [startDate] and [endDate] are kept for compatability, but their values redundant where [occurrences] are being used
  final List<(DateTime, DateTime)> occurrences;

  EventRule({
    required this.id,
    required this.title,
    required this.summary,
    required this.type,
    required this.description,
    required this.startDate,
    required this.endDate,
    required this.isAllDay,
    required this.duration,
    required this.isRecurring,
    required this.recurrencePattern,
    required this.room,
    required this.location,
    required this.occurrences
  });

  static List<EventRule> fromIcsList(List<VEvent> icsEventList) {
    Map<String, EventRule> eventRules = {};

    for (final icsEvent in icsEventList) {
      final id = icsEvent.description!.hashCode.toString();
      if (eventRules.keys.contains(id)) {
        eventRules[id]!.occurrences.add((icsEvent.start!.toUtc(), icsEvent.end!.toUtc()));
      } else {
        eventRules[id] = EventRule.fromIcs(icsEvent);
      }
    }
    return eventRules.values.toList();
  }

  /// a list of events of the same class (since ANU provides them as individual events
  /// rather than as a rule). The rule must be inferred.
  /// Most typically will be weekly, but can also be multi weekly or fortnightly.
  /// TODO: kicking rule inference down the road, events will be individual for now
  /// TODO: duration is a dummy property too.
  factory EventRule.fromIcs(VEvent icsEvent) {
    int locationSplit = icsEvent.location!.indexOf('_');
    String room;
    String location;

    if (locationSplit == -1) {
      room = "";
      location = icsEvent.location!;
    } else {
      room = icsEvent.location!.substring(0, locationSplit);
      location = icsEvent.location!.substring(locationSplit + 1);
    }

    return EventRule(
      id: icsEvent.description!.hashCode.toString(),
      title: icsEvent.description!.substring(0, 8),
      summary: icsEvent.summary!,
      type: EventType.fromString(icsEvent.summary!.substring(icsEvent.summary!.lastIndexOf(' ') + 1)),
      description: icsEvent.description!,
      occurrences: [(icsEvent.start!.toUtc(), icsEvent.end!.toUtc())],
      startDate: icsEvent.start!.toUtc(),
      endDate: icsEvent.end!.toUtc(),
      isAllDay: icsEvent.isAllDayEvent ?? false,
      duration: 0,
      isRecurring: false,
      recurrencePattern: null,
      room: room,
      location: location);
  }

  factory EventRule.fromFirestore(QueryDocumentSnapshot<Map<String, dynamic>> snapshot) {
    final data = snapshot.data();
    // print(EventType.fromString(data['type']));
    print("hi");
    print(data['occurrences'].runtimeType);
    return EventRule(
      id: snapshot.id,
      title: data['title'],
      summary: data['summary'],
      type: EventType.fromString(data['type']),
      description: data['description'],
      startDate: data['startDate'].toDate(),
      endDate: data['endDate'].toDate(),
      occurrences: (data['occurrences'] as List<dynamic>).map((item) {
      final map = item as Map<String, dynamic>;
      return (
        (map['start'] as Timestamp).toDate(),
        (map['end'] as Timestamp).toDate(),
      );
    }).toList(),
      isAllDay: data['isAllDay'],
      duration: data['duration'],
      isRecurring: data['isRecurring'],
      recurrencePattern: data['recurrencePattern'] == null ? null : RecurrencePattern.fromFirestore(data['recurrencePattern']), 
      room: data['room'],
      location: data['location']);
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'title': title,
      'summary': summary,
      'type': type.toString(),
      'description': description,
      'startDate': startDate,
      'endDate': endDate,
      'occurrences': occurrences.map((occ) => {"start": occ.$1, "end": occ.$2}).toList(),
      'isAllDay': isAllDay,
      'duration': duration,
      'isRecurring': isRecurring,
      'recurrencePattern': recurrencePattern?.toMap(),
      'room': room,
      'location': location,
    };
  }
}