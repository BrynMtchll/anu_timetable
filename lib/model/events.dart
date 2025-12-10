import 'package:anu_timetable/data/repositories/event_repository.dart';
import 'package:anu_timetable/domain/model/event.dart';
import 'package:anu_timetable/model/timetable.dart';
import 'package:anu_timetable/util/command.dart';
import 'package:anu_timetable/util/result.dart';
import 'package:flutter/material.dart';

class EventsVM extends ChangeNotifier {
  EventsVM({
    required EventRepository eventRepository,
  }) : _eventRepository = eventRepository {
    loadDay = Command1(_loadDay);
    loadWeek = Command1(_loadWeek);
  }

  final EventRepository _eventRepository;

  late Command1<void, DateTime> loadDay;
  late Command1<void, DateTime> loadWeek;

  final Map<int, List<Event>> _events = {};

  List<Event> getEventsOnDay(int dayIndex) {
    if (_events.containsKey(dayIndex)) {
      return _events[dayIndex]!;
    }
    // TODO: log error
    return [];
  }
  List<List<Event>> getEventsOnWeek(int weekIndex) {
    List<List<Event>> weekEvents = [];
    DateTime week = TimetableVM.getWeek(weekIndex);
    int dayIndex = TimetableVM.getDayIndex(week);
    for (int weekdayIndex = dayIndex; weekdayIndex < dayIndex + 7; weekdayIndex++) {
      if (_events.containsKey(weekdayIndex)) {
        weekEvents.add(_events[weekdayIndex]!);
      }
      else {
        // TODO: log error
        weekEvents.add([]);
      }
    }
    return [];
  }

  Future<Result> _loadDay(DateTime day) async {
    int i = TimetableVM.getDayIndex(day);
    try {
      final resultLoadDay = await _eventRepository.getEventsOnDay(day);
      switch(resultLoadDay) {
        case Ok<List<Event>>():
          _events[i] = resultLoadDay.value;
        case Error<List<Event>>():
      }
      return resultLoadDay;
    } finally {
      notifyListeners();
    }
  }

  Future<Result> _loadWeek(DateTime week) async {
    int dayIndex = TimetableVM.getDayIndex(week);
    try {
      final resultLoadWeek = await _eventRepository.getEventsOnWeek(week);
      switch(resultLoadWeek) {
        case Ok<List<List<Event>>>():
          for (final (i, e) in resultLoadWeek.value.indexed) {
            _events[dayIndex + i] = e;
          }
        case Error<List<List<Event>>>():
      }
      return resultLoadWeek;
    } finally {
      notifyListeners();
    }
  }
}