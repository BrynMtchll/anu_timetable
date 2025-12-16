import 'package:anu_timetable/data/repositories/event_repository.dart';
import 'package:anu_timetable/domain/model/event.dart';
import 'package:anu_timetable/util/command.dart';
import 'package:anu_timetable/util/result.dart';
import 'package:flutter/material.dart';

class EventVM extends ChangeNotifier {
  EventVM({
    required EventRepository eventRepository,
  }) : _eventRepository = eventRepository {
    loadEvent = Command1(_loadEvent);
  }

  final EventRepository _eventRepository;

  late Command1<void, String> loadEvent;


  final Map<String, Event> _events = {};

  Event? getEvent(String id) {
    if (_events.containsKey(id)) {
      return _events[id]!;
    }
    // TODO: log error
    return null;
  }

  Future<Result> _loadEvent(String id) async {
    try {
      final resultLoadEvent = await _eventRepository.getEvent(id);
      switch(resultLoadEvent) {
        case Ok<Event>():
          _events[id] = resultLoadEvent.value;
        case Error<Event>():
          print("could not load event");
      }
      return resultLoadEvent;
    } finally {
      notifyListeners();
    }
  }
}