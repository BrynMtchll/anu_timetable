import 'dart:async';

import 'package:anu_timetable/data/repositories/event_repository_firebase.dart';
import 'package:anu_timetable/data/repositories/user_repository_firebase.dart';
import 'package:anu_timetable/domain/model/event.dart';
import 'package:anu_timetable/domain/model/event_rule.dart';
import 'package:anu_timetable/model/timetable.dart';
import 'package:anu_timetable/util/event_expansion.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';

class UserEventsVM extends ChangeNotifier {
  final EventRepositoryFirebase _eventRepository;

  UserEventsVM({required UserRepositoryFirebase userRepository, required EventRepositoryFirebase eventRepository})
    : _eventRepository = eventRepository;
  // final Map<DateTime, List<Event>> _events = {};
  Set<Event> _events = {};

  StreamSubscription<List<EventRule>>? _sub;

  void startWatching(String userId) {
    _sub?.cancel();
    print("watching");
    _sub = _eventRepository.watchEventsForUser(userId).listen(
      (final updated) {
        _events = expandEventOccurrences(updated).toSet();
        print(_events);
        notifyListeners();
      },
      onError: (e) {
        print("error $e");
        // existing error state
      });
  }

  void stopWatching() {
    _sub?.cancel();
    _sub = null;
    _events = {};
    print("stopped watching");
  }

  Event getEvent(String eventId) {
    Event? event = _events.firstWhereOrNull((event) => event.id == eventId);
    if (event == null) (throw Exception("event not found! eventId: $eventId"));
    return event;
  }

  List<(String, String)> getClasses() {
    if (_events.isEmpty) {
      print("no events found!");
      return [];
    }
    return _events.map((e) => (e.title, e.summary)).toSet().toList();
  }
  List<Event> getEvents() {
    if (_events.isEmpty) {
      print("no events found!");
    }
    return _events.toList();
  }

  /// returns events occuring on a given day including events that cross over
  /// the either the start or end of the day, or both.
  List<Event> getEventsOnDay(DateTime day) {
    DateTime dayWithoutTime = TimetableVM.dateWithoutTime(day);
    return _events.where((event) {
      DateTime startWithoutTime = TimetableVM.dateWithoutTime(event.startDate);
      DateTime endWithoutTime = TimetableVM.dateWithoutTime(event.endDate);
      return ((startWithoutTime == dayWithoutTime || endWithoutTime == dayWithoutTime) 
        || (startWithoutTime.isBefore(dayWithoutTime) && endWithoutTime.isAfter(dayWithoutTime)));
    }).toList()..sort((a, b) {
      final startComp = a.startDate.compareTo(b.startDate);
      return startComp == 0 ? a.endDate.compareTo(b.endDate) : startComp;
    });
  }
  List<Event> getEventsAfterTime(DateTime time) {
    return getEventsOnDay(time).where((event) => event.endDate.isAfter(time)).toList();
  }
}