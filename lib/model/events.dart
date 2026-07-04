import 'package:anu_timetable/data/repositories/event_repository.dart';
import 'package:anu_timetable/domain/model/event.dart';
import 'package:anu_timetable/domain/model/event_rule.dart';
import 'package:anu_timetable/model/timetable.dart';
import 'package:anu_timetable/util/command.dart';
import 'package:anu_timetable/util/result.dart';
import 'package:calendar_view/calendar_view.dart';
import 'package:flutter/material.dart';

class UserEventsVM extends ChangeNotifier {
  final EventRepository _eventRepository;
  late Command3<void, List<String>, DateTime, DateTime> loadEvents;

  UserEventsVM({required EventRepository eventRepository})
    : _eventRepository = eventRepository {
    loadEvents = Command3(_loadEvents);
  }
  Map<DateTime, List<Event>> _events = {};

  Event _genEventFromRecurrence(EventRule eventRule, int dayOffset) {
    /// could alternatively use duration property?
    DateTime startDate = eventRule.startDate.add(Duration(days: dayOffset));
    DateTime endDate = eventRule.endDate.add(Duration(days: dayOffset));
    return Event(ruleId: eventRule.id, title: eventRule.title, startDate: startDate,
      endDate: endDate, isAllDay: eventRule.isAllDay, duration: eventRule.duration);
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

  /// possibly expensive expanding all events for each query if they fall within the window, rather than memoising.
  /// but otherwise would need logic to resume expansion from previous query in the case of infinitely recurring events
  /// which cannot be fully expanded. Or maybe could mark those specifically as infinite? But also might have events that 
  /// aren't infinite but repeat every day for a hundred years.
  void _expandEventRules(List<EventRule> eventRules, DateTime from, DateTime to) {
    for (final EventRule eventRule in eventRules) {
      if (eventRule.recurrencePattern.until!.isBefore(from) || eventRule.startDate.isAfter(to)) continue;
      if (!eventRule.isRecurring) {
        // TODO: check about using local? what if overseas checking timetable, might need to always be anu local.
        Event event = Event(ruleId: eventRule.id, title: eventRule.title, startDate: eventRule.startDate,
          endDate: eventRule.endDate, isAllDay: eventRule.isAllDay, duration: eventRule.duration);
        _addEvent(event);
      }
      else {
        final count = eventRule.recurrencePattern.count ?? 1e9;
        final interval = eventRule.recurrencePattern.interval;
        switch (eventRule.recurrencePattern.freq) {
          case Freq.daily: {
            for (int i = 0; i < count; i++) {
              final dayOffset = i*interval;
              final event = _genEventFromRecurrence(eventRule, dayOffset);
              if (event.startDate.isBefore(from) || event.endDate.isAfter(to)) continue;
              _addEvent(event);
            }
          }
          case Freq.weekly: {
            /// if byDay is not set, then the event occurs on the same day of the week as the startDate
            if (eventRule.recurrencePattern.byDay == null) {
              for (int i = 0; i < count; i++) {
                final dayOffset = i*7*interval;
                final event = _genEventFromRecurrence(eventRule, dayOffset);
                if (event.startDate.isBefore(from) || event.endDate.isAfter(to)) continue;
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
          case Freq.monthly: {
            int monthOffset = 0;
            int currCount = 0;
            DateTime monthStart = DateTime(eventRule.startDate.year, eventRule.startDate.month);

            while (monthStart.isBefore(eventRule.recurrencePattern.until!) && currCount < count && monthStart.isBefore(to)) {
              List<int> currInstance = List.filled(eventRule.recurrencePattern.byDay?.length ?? 0, 1);

              for (int monthDay = 1; monthDay <= 31; monthDay++) {
                if ((monthOffset == 0 && monthDay < eventRule.startDate.day)
                  || (eventRule.recurrencePattern.byMonthDay != null && !eventRule.recurrencePattern.byMonthDay!.contains(monthDay))
                  || (DateTime(monthStart.year, monthStart.month + 1, 0).isBefore(DateTime(monthStart.year, monthStart.month, monthStart.day + monthDay)))) {
                  continue;
                }

                DateTime day = monthStart.add(Duration(days: monthDay));
                // careful about hours here, should be fine since day should have same time as startDate
                final dayOffset = eventRule.startDate.getDayDifference(day);
                final event = _genEventFromRecurrence(eventRule, dayOffset);
                if (event.startDate.isBefore(from) || event.endDate.isAfter(to)) continue;
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
                  }
                }
                else {
                  _addEvent(event);
                  currCount++;
                }
              }
              monthOffset++;
              monthStart = DateTime(monthStart.year, monthStart.month + 1);
            }
          }
          case Freq.yearly: {
            int yearOffset = 0;
            int currCount = 0;
            DateTime yearStart = DateTime(eventRule.startDate.year);
            while (yearStart.isBefore(eventRule.recurrencePattern.until!) && currCount < count && yearStart.isBefore(to)) {
              List<int> currInstance = List.filled(eventRule.recurrencePattern.byDay?.length ?? 0, 1);

              for (int month = 1; month <= 12; month++) {
                if ((yearOffset == 0 && month < eventRule.startDate.month)
                  || (eventRule.recurrencePattern.byMonth != null && !eventRule.recurrencePattern.byMonth!.contains(month))) {
                  continue;
                }
                DateTime monthStart = DateTime(yearStart.year, month);
                for (int monthDay = 1; monthDay <= 31; monthDay++) {
                  if ((yearOffset == 0 && month == eventRule.startDate.month && monthDay < eventRule.startDate.day)
                    || (eventRule.recurrencePattern.byMonthDay != null && !eventRule.recurrencePattern.byMonthDay!.contains(monthDay))
                    || (eventRule.recurrencePattern.byYearDay != null && !eventRule.recurrencePattern.byYearDay!.contains(yearStart.getDayDifference(monthStart.add(Duration(days: monthDay))) + 1))
                    || (DateTime(monthStart.year, monthStart.month + 1, 0).isBefore(DateTime(monthStart.year, monthStart.month, monthStart.day + monthDay)))) {
                    continue;
                  }
                  DateTime day = monthStart.add(Duration(days: monthDay));
                  final dayOffset = eventRule.startDate.getDayDifference(day);
                  final event = _genEventFromRecurrence(eventRule, dayOffset);
                  if (event.startDate.isBefore(from) || event.endDate.isAfter(to)) continue;
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
                  }
                }
                else {
                  _addEvent(event);
                  currCount++;
                }
                }
              }
            }
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
          // for (final event in result.value) {
          //   int dayIndexStart = TimetableVM.getDayIndex(event.startTime);
          //   int dayIndexEnd = TimetableVM.getDayIndex(event.endTime);
          //   if (_events.dayIndex)

          //   if (dayIndexStart != dayIndexEnd) {
          //     _events
          //   }
          // }

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

  // List<Event> getEventsOnDay(int dayIndex) {
  //   if (_events.containsKey(dayIndex)) {
  //     return _events[dayIndex]!;
  //   }
  //   // TODO: log error
  //   print("no event found!");
  //   DateTime day = TimetableVM.getDay(dayIndex);
  //   loadYear.execute(DateTime(day.year));
  //   return [];
  // }
  // List<List<Event>> getEventsOnWeek(int weekIndex) {
  //   List<List<Event>> weekEvents = [];
  //   DateTime week = TimetableVM.getWeek(weekIndex);
  //   int dayIndex = TimetableVM.getDayIndex(week);
  //   for (int weekdayIndex = dayIndex; weekdayIndex < dayIndex + 7; weekdayIndex++) {
  //     if (_events.containsKey(weekdayIndex)) {
  //       weekEvents.add(_events[weekdayIndex]!);
  //     }
  //     else {
  //       // TODO: log error
  //       weekEvents.add([]);
  //     }
  //   }
  //   return [];
  // }

  // Future<Result> _loadDay(DateTime day) async {
  //   int i = TimetableVM.getDayIndex(day);
  //   try {
  //     final resultLoadDay = await _eventRepository.getEventsOnDay(day);
  //     switch(resultLoadDay) {
  //       case Ok<List<Event>>():
  //         _events[i] = resultLoadDay.value;
  //       case Error<List<Event>>():
  //     }
  //     return resultLoadDay;
  //   } finally {
  //     notifyListeners();
  //   }
  // }

  // Future<Result> _loadWeek(DateTime week) async {
  //   int dayIndex = TimetableVM.getDayIndex(week);
  //   try {
  //     final resultLoadWeek = await _eventRepository.getEventsOnWeek(week);
  //     switch(resultLoadWeek) {
  //       case Ok<List<List<Event>>>():
  //         for (final (i, e) in resultLoadWeek.value.indexed) {
  //           _events[dayIndex + i] = e;
  //         }
  //       case Error<List<List<Event>>>():
  //     }
  //     return resultLoadWeek;
  //   } finally {
  //     notifyListeners();
  //   }
  // }
  // Future<Result> _loadYear(DateTime year) async {
  //   int dayIndex = TimetableVM.getDayIndex(year);
  //   try {
  //     final resultLoadYear = await _eventRepository.getEventsOnYear(year);
  //     switch(resultLoadYear) {
  //       case Ok<List<List<Event>>>():
  //         for (final (i, e) in resultLoadYear.value.indexed) {
  //           _events[dayIndex + i] = e;
  //         }
  //       case Error<List<List<Event>>>():
  //     }
  //     return resultLoadYear;
  //   } finally {
  //     notifyListeners();
  //   }
  // }
}