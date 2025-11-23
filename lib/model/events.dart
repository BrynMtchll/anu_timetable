import 'package:anu_timetable/data/repositories/event_repository.dart';
import 'package:anu_timetable/domain/model/event.dart';
import 'package:anu_timetable/util/command.dart';
import 'package:anu_timetable/util/result.dart';
import 'package:flutter/material.dart';

class EventsForDayVM extends ChangeNotifier {

  EventsForDayVM({
    required EventRepository eventRepository,
    required DateTime day
  }) : _eventRepository = eventRepository {
    load = Command1(_load)..execute(day);
  }

  final EventRepository _eventRepository;

  late Command1<void, DateTime> load;

  late List<Event> _events = [];

  List<Event> get events => _events;

  Future<Result> _load(DateTime day) async {
    try {
      final resultLoad = await _eventRepository.getEventsOnDay(day);
      switch(resultLoad) {
        case Ok<List<Event>>():
          _events = resultLoad.value;
        case Error<List<Event>>():
          print("fail");
      }
      return resultLoad;
    } finally {
      notifyListeners();
    }
  }
}

class EventsVM extends ChangeNotifier {
  EventsVM({
    required EventRepository eventRepository,
  }) : _eventRepository = eventRepository {
    loadEventsForDay = Command1(_loadEventsForDay);
  }

  final EventRepository _eventRepository;

  late Command1<void, DateTime> loadEventsForDay;

  final Map<DateTime, List<Event>> _events = {};

  List<Event> getEventsOnDay(DateTime day) {
    if (_events.containsKey(day)) {
      return _events[day]!;
    }
    return [];
  }

  Future<Result> _loadEventsForDay(DateTime day) async {
    try {
      final resultLoadEventsForDay = await _eventRepository.getEventsOnDay(day);
      switch(resultLoadEventsForDay) {
        case Ok<List<Event>>():
          _events[day] = resultLoadEventsForDay.value;
        case Error<List<Event>>():
      }
      return resultLoadEventsForDay;
    } finally {
      notifyListeners();
    }
  }
}