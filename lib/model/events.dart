import 'package:anu_timetable/data/repositories/event_repository.dart';
import 'package:anu_timetable/data/repositories/user_repository.dart';
import 'package:anu_timetable/domain/model/event.dart';
import 'package:anu_timetable/domain/model/event_rule.dart';
import 'package:anu_timetable/model/timetable.dart';
import 'package:anu_timetable/util/command.dart';
import 'package:anu_timetable/util/result.dart';
import 'package:calendar_view/calendar_view.dart';
import 'package:flutter/material.dart';

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
    return Event(ruleId: eventRule.id, title: eventRule.title, startDate: startDate,
      endDate: endDate, isAllDay: eventRule.isAllDay, duration: eventRule.duration);
  }

  Future<Result> _addEventRules(List<EventRule> eventRules) async {
    try {
      for (final eventRule in eventRules) {
        final result = await _eventRepository.addEventRule(eventRule);
        switch(result) {
          case Ok<EventRule>():
            for (final userId in eventRule.userIds) {
              final resultAddUser = await _userRepository.addEventRuleToUser(userId, eventRule.id);
              switch(resultAddUser) {
                case Ok<void>():
                  break;
                case Error<void>():
                  throw resultAddUser.error;
              }
            }
          case Error<EventRule>():
            throw result.error;
        }
      }
      return Result.ok(null);
    } finally {
      notifyListeners();
    }
  }

  void _addEvent(Event event) {
    DateTime day = TimetableVM.dateWithoutTime(event.startDate);
    if (!_events.containsKey(day)) {
      _events[day] = [event];
    }
    else if (!_events[day]!.contains(event)) {
      _events[day]!.add(event);
    }
  }

  void _expandDailyEvent(num count, int interval, EventRule eventRule, DateTime from, DateTime to) {
    for (int i = 0; i < count; i++) {
      final dayOffset = i*interval;
      final event = _genEventFromRecurrence(eventRule, dayOffset);
      _addEvent(event);
    }
  }

  void _expandWeeklyEvent(num count, int interval, EventRule eventRule, DateTime from, DateTime to) {
    /// if byDay is not set, then the event occurs on the same day of the week as the startDate
    if (eventRule.recurrencePattern.byDay == null) {
      for (int i = 0; i < count; i++) {
        final dayOffset = i*7*interval;
        final event = _genEventFromRecurrence(eventRule, dayOffset);
        if (event.startDate.isBefore(from)) continue;
        if (event.endDate.isAfter(to)) break;
        _addEvent(event);
      }
    }
    /// otherwise event occurs on each weekday specified in byDay between startDate and endDate.
    else {
      int weekOffset = 0;
      int currCount = 0;
      DateTime weekStart = eventRule.endDate.firstDayOfWeek().add(Duration(days: weekOffset*7));
      while (currCount < count && !weekStart.isAfter(eventRule.recurrencePattern.until!) && !weekStart.isAfter(to)) {
        for (final byDay in eventRule.recurrencePattern.byDay!) {
          if (currCount == count) break;
          /// TODO: raise warning if byDay.instance is not null.
          final dayOffset = weekOffset*7 + byDay.weekday - eventRule.startDate.weekday;
          final event = _genEventFromRecurrence(eventRule, dayOffset);
          if (event.startDate.isBefore(from) || event.endDate.isAfter(to)) continue;
          _addEvent(event);
          currCount++;
        }
        weekOffset += 1*interval;
      }
    }
  }

  bool _common(DateTime day, EventRule eventRule, DateTime from, DateTime to, List<int> currInstance, int currCount) {
    final dayOffset = eventRule.startDate.getDayDifference(day);
    final event = _genEventFromRecurrence(eventRule, dayOffset);
    if (event.startDate.isBefore(from)) return false;
    if (event.endDate.isAfter(to)) return true;
    if (eventRule.recurrencePattern.byDay != null) {
      for (int i = 0; i < eventRule.recurrencePattern.byDay!.length; i++) {
        final byDay = eventRule.recurrencePattern.byDay![i];
        if (byDay.weekday == day.weekday) {
          if (currInstance[i] == byDay.instance) {
            _addEvent(event);
            currCount++;
          } 
          currInstance[i]++;
        }
        if (currCount == eventRule.recurrencePattern.count) return false;
      }
    }
    else {
      _addEvent(event);
      currCount++;
    }
    return false;
  }

  void _expandMonthlyEvent(num count, int interval, EventRule eventRule, DateTime from, DateTime to) {
    int currCount = 0;
    RecurrencePattern recurrence = eventRule.recurrencePattern;
    DateTime day = eventRule.startDate.withoutTime;
    List<int> currInstance = List.filled(recurrence.byDay?.length ?? 0, 1);

    while(currCount < count && day.isBefore(recurrence.until!) && day.isBefore(to)) {
      if (day.day == 1) {
        currInstance = List.filled(recurrence.byDay?.length ?? 0, 1);
      }

      if ((eventRule.isByMonthDay && !recurrence.byMonthDay!.contains(day.day))) {
        day = day.add(Duration(days: 1));
        continue;
      }
      _common(day, eventRule, from, to, currInstance, currCount);
    }
  }

  void _expandYearlyEvent(num count, int interval, EventRule eventRule, DateTime from, DateTime to) {
    int currCount = 0;
    RecurrencePattern recurrence = eventRule.recurrencePattern;
    DateTime day = eventRule.startDate.withoutTime;
    List<int> currInstance = List.filled(recurrence.byDay?.length ?? 0, 1);

    while(currCount < count && day.isBefore(recurrence.until!) && day.isBefore(to)) {
      if (day.month == 1 && day.day == 1) {
        currInstance = List.filled(recurrence.byDay?.length ?? 0, 1);
      }
      if (eventRule.isByMonth && !recurrence.byMonth!.contains(day.month)) {
        day = DateTime(day.year, day.month + 1, 1);
        continue;
      }
      int yearDay = day.getDayDifference(DateTime.utc(day.year)) + 1;

      if ((eventRule.isByMonthDay && !recurrence.byMonthDay!.contains(day.day))
        || (eventRule.isByYearDay && !recurrence.byYearDay!.contains(yearDay))) {
        day = day.add(Duration(days: 1));
        continue;
      }
      _common(day, eventRule, from, to, currInstance, currCount);
    }
  }

  /// possibly expensive expanding all events for each query if they fall within the window, rather than memoising.
  /// but otherwise would need logic to resume expansion from previous query in the case of infinitely recurring events
  /// which cannot be fully expanded. Or maybe could mark those specifically as infinite? But also might have events that 
  /// aren't infinite but repeat every day for a hundred years.
  /// TODO: something about duration, 
  void _expandEventRules(List<EventRule> eventRules, DateTime from, DateTime to) {
    print("expanding event rules from $from to $to");
    for (final EventRule eventRule in eventRules) {
      if (eventRule.recurrencePattern.until!.isBefore(from) || eventRule.startDate.isAfter(to)) continue;
      if (!eventRule.isRecurring) {
        final event = _genEventFromRecurrence(eventRule, 0);
        _addEvent(event);
      }
      else {
        final count = eventRule.recurrencePattern.count ?? 1e9;
        final interval = eventRule.recurrencePattern.interval;
        switch (eventRule.recurrencePattern.freq) {
          case Freq.daily: _expandDailyEvent(count, interval, eventRule, from, to);
          case Freq.weekly: {
              _expandWeeklyEvent(count, interval, eventRule, from, to);
          }
          case Freq.monthly: {
            _expandMonthlyEvent(count, interval, eventRule, from, to);
          }
          case Freq.yearly: {
            _expandYearlyEvent(count, interval, eventRule, from, to);
          }
        }
      }
    }
  }

  // wipe events when expanding rules?
  // store range queryable? complex to maintain... or store sorted

  Future<Result> _loadEvents(List<String> eventRuleIds, DateTime from, DateTime to) async {
    try {
      final result = await _eventRepository.getEventRules(eventRuleIds);
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