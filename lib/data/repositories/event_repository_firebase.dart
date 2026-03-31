import 'package:anu_timetable/data/repositories/event_repository.dart';
import 'package:anu_timetable/domain/model/event.dart';
import 'package:anu_timetable/domain/model/user.dart';
import 'package:anu_timetable/util/result.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EventRepositoryFirebase implements EventRepository {
  @override
  Future<Result<List<Event>>> getEvents(List<String> eventIds) async {
    final db = FirebaseFirestore.instance;
    final List<Event> eventList = [];
    final snapshot = await db.collection('events').where('id', whereIn: eventIds)
      .withConverter(
        fromFirestore: Event.fromFirestore,
        toFirestore: (Event event, _) => event.toMap())
      .get();

    for (final doc in snapshot.docs) {
      eventList.add(doc.data());
    }
    return Result.ok(eventList);
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