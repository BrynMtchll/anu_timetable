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

  Future<List<Event>> _createEventsForDay(DateTime day) async {
    Random random = Random();
    List<Event> events = [];
    int nEvents = random.nextInt(20) + 3;

    for (int i = 0; i < nEvents; i++) {
      int s = random.nextInt(8) + 8;
      int e = s + 1 + random.nextInt(4);
      DateTime st = day.add(Duration(hours: s));
      DateTime et = day.add(Duration(hours: e));
      events.add(Event(title: "blah", startTime: st, endTime: et));
    }
    return events;
  }
}