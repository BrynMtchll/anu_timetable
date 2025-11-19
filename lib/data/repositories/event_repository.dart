import 'dart:async';

import 'package:anu_timetable/domain/model/event.dart';
import 'package:anu_timetable/util/result.dart';

abstract class EventRepository {
  Future<Result<List<Event>>> getEventsOnDay(DateTime day);
}