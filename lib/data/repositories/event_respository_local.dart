import 'dart:math';

import 'package:anu_timetable/data/repositories/event_repository.dart';
import 'package:anu_timetable/data/services/local/local_event_service.dart';
import 'package:anu_timetable/domain/model/event.dart';
import 'package:anu_timetable/util/result.dart';
import 'package:calendar_view/calendar_view.dart';
import 'package:uuid/uuid.dart';

class EventRespositoryLocal implements EventRepository {
  EventRespositoryLocal({required LocalEventService localEventService})
    : _localEventService = localEventService;

  final LocalEventService _localEventService;

  final Map<DateTime, List<String>> _eventsOnDay = {};

  final Map<String, Event> _events = {};

  @override
  Future<Result<Event>> getEvent(String id) async {
    if (!_events.containsKey(id)) {
      print("event should already exist if we're going to its page!");
    // _events[id] = await _createEventsForDay(day);
    }
    return Result.ok(_events[id]!);
  }

  @override
  Future<Result<List<Event>>> getEventsOnDay(DateTime day) async {
    List<Event> events = [];
    if (!_eventsOnDay.containsKey(day)) {
      _eventsOnDay[day] = [];
      events = await _createEventsForDay(day);
      for (final e in events) {
        _eventsOnDay[day]!.add(e.id);
        _events[e.id] = e;
      }
    } else {
      for (final id in _eventsOnDay[day]!) {
        events.add(_events[id]!);
      }
    }
    return Result.ok(events);
    
  }
  @override
  Future<Result<List<List<Event>>>> getEventsOnWeek(DateTime week) async {
    List<List<Event>> weekEvents = [];
    for (int wd = 0; wd < 7; wd++) {
      DateTime day = DateTime(week.year, week.month, week.day + wd);
      List<Event> events = [];
      if (!_eventsOnDay.containsKey(day)) {
        _eventsOnDay[day] = [];
        events = await _createEventsForDay(day);
        for (final e in events) {
          _eventsOnDay[day]!.add(e.id);
          _events[e.id] = e;
        }
      } else {
      for (final id in _eventsOnDay[day]!) {
        events.add(_events[id]!);
      }
    }
      weekEvents.add(events);
    }
    return Result.ok(weekEvents);
  }
  @override
  Future<Result<List<List<Event>>>> getEventsOnYear(DateTime year) async {
    List<List<Event>> yearEvents = [];
    for (int wd = 0; wd < year.getDayDifference(DateTime(year.year + 1)); wd++) {
      DateTime day = DateTime(year.year, year.month, year.day + wd);
      List<Event> events = [];
      if (!_eventsOnDay.containsKey(day)) {
        _eventsOnDay[day] = [];
        events = await _createEventsForDay(day);
        for (final e in events) {
          _eventsOnDay[day]!.add(e.id);
          _events[e.id] = e;
        }
      } else {
      for (final id in _eventsOnDay[day]!) {
        events.add(_events[id]!);
      }
    }
      yearEvents.add(events);
    }
    return Result.ok(yearEvents);
  }

  Future<List<Event>> _createEventsForDay(DateTime day) async {
    Random random = Random();
    List<Event> events = [];

    int nEvents = random.nextInt(3) + 1;
    if (day.weekday == DateTime.saturday || day.weekday == DateTime.sunday) {
      nEvents = random.nextInt(6);
    }

    for (int i = 0; i < nEvents; i++) {
      int s = random.nextInt(9) + 8;
      int e = s + 1 + random.nextInt(5);
      DateTime st = day.add(Duration(hours: s));
      DateTime et = day.add(Duration(hours: e));
      events.add(Event(id: Uuid().v4(), title: "blah", startTime: st, endTime: et));
    }
    return events;
  }

  @override
  Future<Result<List<Event>>> getAllEvents() {
    throw UnimplementedError();
  }
}
