import 'package:anu_timetable/domain/model/event_rule.dart';
import 'package:anu_timetable/util/result.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:collection/collection.dart';
import 'package:rxdart/rxdart.dart';

class EventRepositoryFirebase {
  Future<Result<List<QueryDocumentSnapshot<Map<String, dynamic>>>>> getEventRule(List<String> ids) async {
    try {
      final collectionRef = FirebaseFirestore.instance.collection('eventRules');

      List<List<String>> chunks = [];
      for (var i = 0; i < ids.length; i += 30) {
        chunks.add(ids.sublist(i, i + 30 > ids.length ? ids.length : i + 30));
      }
      final futures = chunks.map((chunk) {
        return collectionRef.where(FieldPath.documentId, whereIn: chunk).get();
      });

      final snapshots = await Future.wait(futures);
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

  Stream<List<EventRule>> watchEventsForUser(String uid) {
    final db = FirebaseFirestore.instance;

    return db.collection('users').doc(uid).snapshots().switchMap((userDoc) {
      final eventRuleKeys = List<String>.from(userDoc.data()?['eventRuleKeys'] ?? []);
        if (eventRuleKeys.isEmpty) return Stream.value(<EventRule>[]);

        final chunks = chunkList(eventRuleKeys, 10);
        final streams = chunks.map((chunk) 
          => db.collection('eventRules').where(FieldPath.documentId, whereIn: chunk).snapshots());
        return Rx.combineLatestList(streams).map((snapshots)
          => snapshots.expand((s) => s.docs).map(EventRule.fromFirestore).toList());
    });
  }

  /// deletes all pre existing [EventRule] instances with an [EventRule.key]
  /// contained in [eventRules] and adds all [eventRules].
  Future<Result<void>> setEventRules(List<EventRule> eventRules) async {
    final db = FirebaseFirestore.instance;
    try {
      final ids = eventRules.map((eventRule) => eventRule.id).toList();
      final existingResult = await getEventRule(ids);

      switch (existingResult) {
        case Error():
          throw existingResult.error;
        case Ok():
      }

      final existing = existingResult.value;
      final batch = db.batch();

      Map<String, EventRule> oldRules = {};

      for (final e in existing) {
        if (!e.exists) continue;
        final eventRule = EventRule.fromFirestore(e);
        oldRules[eventRule.id] = eventRule;
      }

      for (final eventRule in eventRules) {
        final ref = db.collection('eventRules').doc(eventRule.id);
        if (!oldRules.containsKey(eventRule.id)) {
          batch.set(ref, eventRule.toMap());
        } else {
          if (!DeepCollectionEquality().equals(oldRules[eventRule.id]!.toMap(), eventRule.toMap())) {
            batch.update(ref, eventRule.toMap());
          }
        }
      }
      await batch.commit();
      return Result.ok(null);
    }
    catch(e) {
      return Result.error(Exception(e));
    }
  }
  
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
}
