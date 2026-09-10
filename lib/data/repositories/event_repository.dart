import 'dart:async';
import 'package:anu_timetable/domain/model/event.dart';
import 'package:anu_timetable/domain/model/event_rule.dart';
import 'package:anu_timetable/util/result.dart';

abstract class EventRepository {
  Stream<List<EventRule>> watchEventsForUser(String uid);
  Future<Result<EventRule>> addEventRule(EventRule eventRule);
  Future<Result<List<EventRule>>> addEventRules(List<EventRule> eventRules);
  Future<Result<void>> setEventRules(List<EventRule> eventRules);
  Future<Result<List<EventRule>>> getAllEventRules();
  // Future<Result<List<EventRule>>> getEventRules(List<String> eventRuleKeys);
  Future<Result<Event>> getEvent(String id);
  Future<Result<List<Event>>> getEventsOnDay(DateTime day);
  Future<Result<List<List<Event>>>> getEventsOnWeek(DateTime week);
  Future<Result<List<List<Event>>>> getEventsOnYear(DateTime year);
  Future<Result<List<Event>>> getAllEvents();
}
