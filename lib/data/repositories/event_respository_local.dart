import 'dart:math';

import 'package:anu_timetable/data/repositories/event_repository.dart';
import 'package:anu_timetable/data/services/local/local_event_service.dart';
import 'package:anu_timetable/domain/model/event.dart';
import 'package:anu_timetable/util/result.dart';

class EventRespositoryLocal implements EventRepository {
  EventRespositoryLocal({required LocalEventService localEventService})
    : _localEventService = localEventService;

  final LocalEventService _localEventService;

  Map<DateTime, List<Event>> _events = {};

  @override
  Future<Result<List<Event>>> getEventsOnDay(DateTime day) async {
      if (!_events.containsKey(day)) {
      _events[day] = await _createEventsForDay(day);
      }
    return Result.ok(_events[day]!);
    
  }
  @override
  Future<Result<List<List<Event>>>> getEventsOnWeek(DateTime week) async {
    List<List<Event>> weekEvents = [];
    for (int wd = 0; wd < 7; wd++) {
      DateTime day = DateTime(week.year, week.month, week.day + wd);
      if (!_events.containsKey(day)) {
      _events[day] = await _createEventsForDay(day);
      }
      weekEvents.add(_events[day]!);
    }
    return Result.ok(weekEvents);
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
      events.add(Event(title: "blah", startTime: st, endTime: et));
    }
    return events;
  }
}