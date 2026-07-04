import 'package:anu_timetable/data/repositories/event_repository.dart';
import 'package:anu_timetable/domain/model/event.dart';
import 'package:anu_timetable/domain/model/event_rule.dart';
import 'package:anu_timetable/util/result.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EventRepositoryFirebase implements EventRepository {
  @override
  Future<Result<List<EventRule>>> getEventRules(List<String> eventRuleIds) async {
    final db = FirebaseFirestore.instance;
    final List<EventRule> eventList = [];
    final snapshot = await db.collection('eventRules').where('id', whereIn: eventRuleIds)
      .withConverter(
        fromFirestore: EventRule.fromFirestore,
        toFirestore: (EventRule eventRule, _) => eventRule.toMap())
      .get();

    for (final doc in snapshot.docs) {
      eventList.add(doc.data());
    }
    return Result.ok(eventList);
  }

  @override
  Future<Result<List<EventRule>>> getAllEventRules() async {
    final db = FirebaseFirestore.instance;
    final snapshot = await db.collection('eventRules')
      .withConverter(
        fromFirestore: EventRule.fromFirestore,
        toFirestore: (EventRule eventRule, _) => eventRule.toMap())
      .get();
    final eventRules = snapshot.docs.map((doc) => doc.data()).toList();
    return eventRules.isEmpty
      ? Result.error(Exception("No event rules found"))
      : Result.ok(eventRules);
  }

  @override
  Future<Result<List<EventRule>>> addEventRules(List<EventRule> eventRules) async {
    final db = FirebaseFirestore.instance;
    Exception? e;
    for (final eventRule in eventRules) {
      await db.collection('eventRules').doc(eventRule.id).set(eventRule.toMap())
      .onError((error, _) {
        e = Exception(error);
      });
    }
    return e != null ? Result.error(e!) : Result.ok(eventRules);
  }
  
  @override
  Future<Result<EventRule>> addEventRule(EventRule eventRule) async {
    print(eventRule.toMap());
    print(eventRule);
    final db = FirebaseFirestore.instance;
    Exception? e;
      await db.collection('eventRules').doc(eventRule.id).set(eventRule.toMap())
      .onError((error, _) {
        e = Exception(error);
      });
    return e != null ? Result.error(e!) : Result.ok(eventRule);
  }

  @override
  Future<Result<List<Event>>> getAllEvents() {
    // TODO: implement getEvent
    throw UnimplementedError();
  }

  @override
  Future<Result<Event>> getEvent(String id) {
    // TODO: implement getEvent
    throw UnimplementedError();
  }

  @override
  Future<Result<List<Event>>> getEventsOnDay(DateTime day) {
    // TODO: implement getEventsOnDay
    throw UnimplementedError();
  }

  @override
  Future<Result<List<List<Event>>>> getEventsOnWeek(DateTime week) {
    // TODO: implement getEventsOnWeek
    throw UnimplementedError();
  }

  @override
  Future<Result<List<List<Event>>>> getEventsOnYear(DateTime year) {
    // TODO: implement getEventsOnYear
    throw UnimplementedError();
  }
}