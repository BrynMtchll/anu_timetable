import 'package:anu_timetable/data/repositories/event_repository.dart';
import 'package:anu_timetable/domain/model/event.dart';
import 'package:anu_timetable/domain/model/event_rule.dart';
import 'package:anu_timetable/util/result.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:collection/collection.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:rxdart/rxdart.dart';

class EventRepositoryFirebase implements EventRepository {
  Future<Result<List<QueryDocumentSnapshot<Map<String, dynamic>>>>> getEventRule(List<String> ids) async {
    // throw UnimplementedError();
    try {
      final collectionRef = FirebaseFirestore.instance.collection('eventRules');
      // if (ids.isEmpty) return Result.ok([]);

      List<List<String>> chunks = [];
      
      // Split the ID list into chunks of 30 items
      for (var i = 0; i < ids.length; i += 30) {
        chunks.add(ids.sublist(i, i + 30 > ids.length ? ids.length : i + 30));
      }

      // Execute all chunk queries concurrently
      final futures = chunks.map((chunk) {
        return collectionRef.where(FieldPath.documentId, whereIn: chunk).get();
      });

      final snapshots = await Future.wait(futures);
      
      // Combine all document snapshots into a single list
      return Result.ok(snapshots.expand((s) => s.docs).toList());

    } catch (e) {
      return Result.error(Exception(e));
    }
  }

  

  List<List<T>> chunkList<T>(List<T> list, int size) {
    return [
      for (var i = 0; i < list.length; i += size)
        list.sublist(i, i + size > list.length ? list.length : i + size)
    ];
  }

  @override
  Stream<List<EventRule>> watchEventsForUser(String uid) {
    final db = FirebaseFirestore.instance;

    return db.collection('users').doc(uid).snapshots().switchMap((userDoc) {
      final eventRuleKeys = List<String>.from(userDoc.data()?['eventRuleKeys'] ?? []);
      print(eventRuleKeys);
        if (eventRuleKeys.isEmpty) return Stream.value(<EventRule>[]);

        final chunks = chunkList(eventRuleKeys, 10);
        final streams = chunks.map((chunk) 
          => db.collection('eventRules').where(FieldPath.documentId, whereIn: chunk).snapshots());
          print(streams.runtimeType);
          print(streams);
        return Rx.combineLatestList(streams).map((snapshots)
          { print(snapshots.expand((s) => s.docs).map(EventRule.fromFirestore).toList());
            return snapshots.expand((s) => s.docs).map(EventRule.fromFirestore).toList();});
    });
  }

  @override
  Future<Result<List<EventRule>>> getAllEventRules() async {
    throw UnimplementedError();
    // final db = FirebaseFirestore.instance;
    // try {
    //   final snapshot = await db.collection('eventRules')
    //     .withConverter(
    //       fromFirestore: EventRule.fromFirestore,
    //       toFirestore: (EventRule eventRule, _) => eventRule.toMap())
    //     .get();
    //   final eventRules = snapshot.docs.map((doc) => doc.data()).toList();
    //   return eventRules.isEmpty
    //     ? Result.error(Exception("No event rules found"))
    //     : Result.ok(eventRules);
    // }
    // catch (e) {
    //   return Result.error(Exception(e));
    // }
  }

  /// Adds [EventRule]s to firebase if [EventRule.key]s are not already present
  @override
  Future<Result<List<EventRule>>> addEventRules(List<EventRule> eventRules) async {
    // final db = FirebaseFirestore.instance;
    // final Map<String, bool> alreadyAdded = {};
    // final List<EventRule> eventRulesAdded = [];
    // try {
    //   for (final eventRule in eventRules) {
    //     if (alreadyAdded.containsKey(eventRule.key!)) continue;
    //     final snapshot = await db.collection('eventRules')
    //       .where('key', isEqualTo: eventRule.key).get();
    //     alreadyAdded[eventRule.key!] = snapshot.docs.isNotEmpty;
    //   }
    //   for (final eventRule in eventRules) {
    //     if (alreadyAdded[eventRule.key!]!) continue;
    //     await db.collection('eventRules').doc(eventRule.id)
    //     .set(eventRule.toMap());
    //     eventRulesAdded.add(eventRule);
    //   }
    //   return Result.ok(eventRulesAdded);
    // }
    // catch (e) {
    //   return Result.error(Exception(e));
    // }
    throw UnimplementedError();
  }

  /// deletes all pre existing [EventRule] instances with an [EventRule.key]
  /// contained in [eventRules] and adds all [eventRules].
  @override
  Future<Result<void>> setEventRules(List<EventRule> eventRules) async {
    // print("hi9");

    final db = FirebaseFirestore.instance;
    final ids = eventRules.map((eventRule) => eventRule.id).toList();
    // print(keys);
    // try {
      // final snapshotsResult = await getEventRule(ids);
      // final refs = [for (final id in ids) db.collection('eventRules').doc(id)];
      final existingResult = await getEventRule(ids);

      switch (existingResult) {
        case Error():
          throw existingResult.error;
        case Ok():
      }

      final existing = existingResult.value;
      final batch = db.batch();

      // final snapshots = snapshotsResult.value;
      // final batch = db.batch();
      // // TODO: will run into issues here if more than 500 results
      // for (final doc in snapshots) {
      //   for (final doc in doc.) {
        
      //   batch.delete(doc.reference);
      //   }
      // }
      // await batch.commit();

      Map<String, EventRule> oldRules = {};

      for (final e in existing) {
        if (!e.exists) continue;
        final er = EventRule.fromFirestore(e);
        oldRules[er.id] = er;
      }
      // eventRules[0].toMap();

      for (int i = 0; i < eventRules.length; i++) {
        final ref = db.collection('eventRules').doc(ids[i]);
        print(eventRules[i].occurrences);
        print(eventRules[i].occurrences.map((occ) => [occ.$1, occ.$2]).toList(),);
        print("ids i ${ids[i]}, $ref");
        if (!oldRules.containsKey(ids[i])) {
          batch.set(ref, eventRules[i].toMap());
        } else {
          if (!DeepCollectionEquality().equals(oldRules[ids[i]]!.toMap(), eventRules[i].toMap())) {
            batch.update(ref, eventRules[i].toMap());
          }
        }
      }
      // print(eventRules);

      await batch.commit();

      // eventRules.forEach((rule, i) => {

      // });

      // for(final key in keys) {
      //   final snapshot = await db.collection('eventRules')
      //     .where('key', isEqualTo: key).get();
      //   if (snapshot.docs.isEmpty) continue;
      //   final batch = db.batch();
      //   for (final doc in snapshot.docs) {
      //     batch.delete(doc.reference);
      //   }
      //   await batch.commit();
      // }
      // for (final eventRule in eventRules) {
      //   await db.collection('eventRules').doc(eventRule.id).set(eventRule.toMap());
      // }
      return Result.ok(null);
    // }
    // catch(e) {
    //   return Result.error(Exception(e));
    // }
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