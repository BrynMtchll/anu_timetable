import 'package:anu_timetable/data/repositories/event_repository.dart';
import 'package:anu_timetable/data/repositories/user_repository.dart';
import 'package:anu_timetable/domain/model/event.dart';
import 'package:anu_timetable/domain/model/event_rule.dart';
import 'package:anu_timetable/model/timetable.dart';
import 'package:anu_timetable/util/command.dart';
import 'package:anu_timetable/util/result.dart';
import 'package:calendar_view/calendar_view.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

class UserEventsVM extends ChangeNotifier {
  final EventRepository _eventRepository;
  final UserRepository _userRepository;
  late Command3<void, List<String>, DateTime, DateTime> loadEvents;
  late Command1<void, List<EventRule>> addEventRules;

  UserEventsVM({required UserRepository userRepository, required EventRepository eventRepository})
    : _eventRepository = eventRepository, _userRepository = userRepository {
    loadEvents = Command3(_loadEvents);
    addEventRules = Command1(_addEventRules);
  }
  final Map<DateTime, List<Event>> _events = {};

  Event _genEventFromRecurrence(EventRule eventRule, int dayOffset) {
    /// could alternatively use duration property?
    DateTime startDate = eventRule.startDate.add(Duration(days: dayOffset));
    DateTime endDate = eventRule.endDate.add(Duration(days: dayOffset));
    return Event(
      id: Uuid().v4(),
      key: eventRule.key,
      title: eventRule.title,
      summary: eventRule.summary,
      description: eventRule.description,
      startDate: startDate,
      endDate: endDate,
      isAllDay: eventRule.isAllDay,
      duration: eventRule.duration);
  }

  Future<Result> _addEventRules(List<EventRule> eventRules) async {
    throw UnimplementedError();
    // try {
    //   for (final eventRule in eventRules) {
    //     final result = await _eventRepository.addEventRule(eventRule);
    //     switch(result) {
    //       case Ok<EventRule>():
    //         for (final userId in eventRule.userIds) {
    //           final resultAddUser = await _userRepository.addEventRulesToUser(userId, eventRule.key!);
    //           switch(resultAddUser) {
    //             case Ok<void>():
    //               break;
    //             case Error<void>():
    //               throw resultAddUser.error;
    //           }
    //         }
    //       case Error<EventRule>():
    //         throw result.error;
    //     }
    //   }
    //   return Result.ok(null);
    // } finally {
    //   notifyListeners();
    // }
  }

  void _addEvent(Event event) {
    DateTime day = TimetableVM.dateWithoutTime(event.startDate);
    if (!_events.containsKey(day)) {
      _events[day] = [event];
    }
    else if (_events[day]!.firstWhereOrNull((e) 
      => e.startDate == event.startDate && e.description == event.description) == null) {
      _events[day]!.add(event);
    }
  }
  
  // TODO: should live somewhere else?
  int _weekOfYear(DateTime day) {
    final dayDiff = day.getDayDifference(DateTime.utc(day.year).firstDayOfWeek());
    return(dayDiff / 7).toInt() + 1;
  }

  /// Checks if given weekday is in the recurrence rule, 
  /// of the right instance count if specified.
  /// Whether byWeekday is null should be checked in advance.
  bool _doesWeekdayFail(RecurrencePattern rec, DateTime day, List<int> currInstance) {
    if (!rec.isByWeekday) return false;
    final weekdayInd = rec.byWeekday!.indexWhere((byDay) => byDay.weekday == day.weekday);
    if (weekdayInd != -1) currInstance[weekdayInd]++;
    return weekdayInd == -1 || (currInstance[weekdayInd] != rec.byWeekday![weekdayInd].instance 
      && rec.byWeekday![weekdayInd].instance != null);
  }

  bool _doesPeriodFail(RecurrencePattern rec, DateTime day, DateTime firstDay) {
    return ((rec.freq == Freq.weekly && day.weekday != firstDay.weekday)
      || (rec.freq == Freq.yearly && rec.isByMonth && day.day != firstDay.day)
      || (rec.freq == Freq.yearly && !rec.isByMonth && (day.month != firstDay.month || day.day != firstDay.day)));
  }

  bool _doesDayFail(RecurrencePattern rec, DateTime day, DateTime firstDay, List<int> currInstance) {
    final yearDay = day.getDayDifference(DateTime.utc(day.year)) + 1;
    final byPeriodFail = rec.isFirstDayPeriodic && _doesPeriodFail(rec, day, firstDay);
    final byMonthDayFail = rec.isByMonthDay && !rec.byMonthDay!.contains(day.day);
    final byYearDayFail = rec.isByYearDay && !rec.byYearDay!.contains(yearDay);
    final byWeekdayFail = rec.isByWeekday && _doesWeekdayFail(rec, day, currInstance);
    return byMonthDayFail || byYearDayFail || byWeekdayFail || byPeriodFail;
  }

  /// TODO: negative indexing, bySetPos, exclusions etc.
  /// TODO: closer consideration of defaults, duration??
  /// NOTE: from is treated as start of day and to is treated as end of day
  void _expandRecurring(EventRule eventRule, DateTime from, DateTime to) {
    final rec = eventRule.recurrencePattern!;
    final count = rec.count ?? 1e9;
    final firstDay = eventRule.startDate.withoutTime;
    DateTime day = rec.periodStart(firstDay);
    int freqOffset = -1;
    int currCount = 0;
    List<int> currInstance = List.filled(rec.byWeekday?.length ?? 0, 0);

    while(currCount < count && (rec.until == null || day.isBefore(rec.until!)) && !day.isAfter(to)) {
      if (rec.isPeriodStart(day, firstDay)) {
        currInstance = List.filled(rec.byWeekday?.length ?? 0, 0);
        freqOffset++;
      }
      final intervalFail = freqOffset % rec.interval != 0;
      final byMonthFail = rec.isByMonth && !rec.byMonth!.contains(day.month);
      final byWeekFail = (rec.isByWeek && !rec.byWeek!.contains(_weekOfYear(day)));
      final byDayFail = _doesDayFail(rec, day, firstDay, currInstance);

      if (intervalFail) {
        day = rec.nextPeriod(day);
      }
      else if (byMonthFail) {
        day = DateTime.utc(day.year, day.month + 1);
      }
      else if (byWeekFail) {
        day = DateTime.utc(day.year, day.month, day.day + 1);
      }
      else if (day.isBefore(firstDay) || byDayFail) {
        day = day.add(Duration(days: 1));
      }
      else {
        final dayOffset = eventRule.startDate.getDayDifference(day);
        final event = _genEventFromRecurrence(eventRule, dayOffset);
        _addEvent(event);
        currCount++;
        day = day.add(Duration(days: 1));
      }
    }
  }

  /// possibly expensive expanding all events for each query if they fall within the window, rather than memoising.
  /// but otherwise would need logic to resume expansion from previous query in the case of infinitely recurring events
  /// which cannot be fully expanded. Or maybe could mark those specifically as infinite? But also might have events that 
  /// aren't infinite but repeat every day for a hundred years.
  void _expandEventRules(List<EventRule> eventRules, DateTime from, DateTime to) {
    print(eventRules.length);

    print("expanding event rules from $from to $to");
    for (final EventRule eventRule in eventRules) {
      if (eventRule.isRecurring && eventRule.recurrencePattern!.until != null 
        && eventRule.recurrencePattern!.until!.isBefore(from) || eventRule.startDate.isAfter(to)) continue;
      if (!eventRule.isRecurring) {
        final event = _genEventFromRecurrence(eventRule, 0);
        _addEvent(event);
        continue;
      }
      _expandRecurring(eventRule, from, to);
    }
  }

  // wipe events when expanding rules?
  // store range queryable? complex to maintain... or store sorted
  Future<Result> _loadEvents(List<String> eventRuleKeys, DateTime from, DateTime to) async {

    try {
      final result = await _eventRepository.getEventRules(eventRuleKeys);
      switch(result) {
        case Ok<List<EventRule>>():
          _expandEventRules(result.value, from, to);
          return result;
        case Error<List<EventRule>>():
          throw result.error;
      }
    } finally {
      notifyListeners();
    }
  }

  Event getEvent(DateTime day, String eventId) {
    Event? event;
    if (_events.containsKey(day)) {
      event = _events[day]!.firstWhereOrNull((event) => event.id == eventId);
    }
    return event ?? (throw Exception("event not found! eventId: $eventId"));

  }

  Map<DateTime, List<Event>> getEvents() {
    if (_events.isEmpty) {
      print("no events found!");
    }
    return _events;
  }

  List<Event> getEventsOnDay(DateTime day) {
    // time shouldn't be there anyway but just to be sure.
    DateTime dayWithoutTime = TimetableVM.dateWithoutTime(day);
    return _events.containsKey(dayWithoutTime) ? _events[dayWithoutTime]! : [];
  }
}