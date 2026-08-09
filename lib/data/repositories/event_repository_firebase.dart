import 'package:anu_timetable/data/repositories/event_repository.dart';
import 'package:anu_timetable/domain/model/event.dart';
import 'package:anu_timetable/domain/model/event_rule.dart';
import 'package:anu_timetable/util/result.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class EventRepositoryFirebase implements EventRepository {
  @override
  Future<Result<List<EventRule>>> getEventRules(List<String> eventRuleKeys) async {
    final db = FirebaseFirestore.instance;
    final List<EventRule> eventList = [];
    final snapshot = await db.collection('eventRules').where('key', whereIn: eventRuleKeys)
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
    try {
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
    catch (e) {
      return Result.error(Exception(e));
    }
  }

  /// Adds [EventRule]s to firebase if [EventRule.key]s are not already present
  @override
  Future<Result<List<EventRule>>> addEventRules(List<EventRule> eventRules) async {
    final db = FirebaseFirestore.instance;
    final Map<String, bool> alreadyAdded = {};
    final List<EventRule> eventRulesAdded = [];
    try {
      for (final eventRule in eventRules) {
        if (alreadyAdded.containsKey(eventRule.key!)) continue;
        final snapshot = await db.collection('eventRules')
          .where('key', isEqualTo: eventRule.key).get();
        alreadyAdded[eventRule.key!] = snapshot.docs.isNotEmpty;
      }
      for (final eventRule in eventRules) {
        if (alreadyAdded[eventRule.key!]!) continue;
        await db.collection('eventRules').doc(eventRule.id)
        .set(eventRule.toMap());
        eventRulesAdded.add(eventRule);
      }
      return Result.ok(eventRulesAdded);
    }
    catch (e) {
      return Result.error(Exception(e));
    }
  }

  /// deletes all pre existing [EventRule] instances with an [EventRule.key]
  /// contained in [eventRules] and adds all [eventRules].
  @override
  Future<Result<void>> setEventRules(List<EventRule> eventRules) async {
    print("hi9");

    final db = FirebaseFirestore.instance;
    final keys = eventRules.map((eventRule) => eventRule.key!).toSet();
    // print(keys);
    try {
      final snapshots = await Future.wait([for (final key in keys) 
        db.collection('eventRules') .where('key', isEqualTo: key).get()]);
      final batch = db.batch();
      // TODO: will run into issues here if more than 500 results
      for (final snapshot in snapshots) {
        for (final doc in snapshot.docs) {
        
        batch.delete(doc.reference);
        }
      }
      await batch.commit();
      for(final key in keys) {
        final snapshot = await db.collection('eventRules')
          .where('key', isEqualTo: key).get();
        if (snapshot.docs.isEmpty) continue;
        final batch = db.batch();
        for (final doc in snapshot.docs) {
          batch.delete(doc.reference);
        }
        await batch.commit();
      }
      for (final eventRule in eventRules) {
        await db.collection('eventRules').doc(eventRule.id).set(eventRule.toMap());
      }
      return Result.ok(null);
    }
    catch(e) {
      return Result.error(Exception(e));
    }

  }
  
  @override
  Future<Result<EventRule>> addEventRule(EventRule eventRule) async {
    final db = FirebaseFirestore.instance;
    try {
      await db.collection('eventRules').doc(eventRule.id).set(eventRule.toMap());
      return Result.ok(eventRule);
    }
    catch (e) {
      return Result.error(Exception(e));
    }
  }

  @override
  Future<Result<List<Event>>> getAllEvents() {
    // TODO: implement getEvent
    throw UnimplementedError();
  }

  @override
  Future<Result<Event>> getEvent(String id) async {
    // TODO: implement getEvent
    // throw UnimplementedError();
    return await Result.error(Exception("not implementsed"));
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