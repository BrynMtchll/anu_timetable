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

  void _expandEventRules(List<EventRule> eventRules, DateTime from, DateTime to) {
    DateTime fromUtc = from.toUtc();
    DateTime toUtc = to.toUtc();
    for (final EventRule eventRule in eventRules) {
      if (eventRule.endDateUtc.isBefore(fromUtc) || eventRule.startDateUtc.isAfter(toUtc)) continue;
      if (!eventRule.isRecurring) {
        // TODO: check about using local? what if overseas checking timetable, might need to always be anu local.
        Event event = Event(ruleId: eventRule.id, title: eventRule.title, startDate: eventRule.startDateUtc.toLocal(),
          endDate: eventRule.endDateUtc.toLocal(), isAllDay: eventRule.isAllDay, duration: eventRule.duration);
        DateTime dateWithoutTime = TimetableVM.dateWithoutTime(event.startDate);
      }
    }
  }

  // wipe events when expanding rules?
  // store range queryable? complex to maintain... or store sorted 

  Future<Result> _loadEvents(List<String> eventRuleIds, DateTime from, DateTime to) async {
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

        _events = _expandEventRules(result.value, from, to);
        return result;
      case Error<List<EventRule>>():
        throw result.error;
    }
  }

  List<Event> getEvents() {
    if (_events.isEmpty) {
      print("no events found!");
    }
    return _events;
  }

  List<Event> expandDay(int dayIndex) {
    DateTime day = TimetableVM.getDay(dayIndex);
  }

  // List<Event> getEventsOnDay(int dayIndex) {
  //   DateTime day = TimetableVM.getDay(dayIndex);
    
  // }

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