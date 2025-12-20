import 'dart:async';

import 'package:anu_timetable/domain/model/event.dart';
import 'package:anu_timetable/util/result.dart';
import 'package:flutter/material.dart';

abstract class EventRepository {
  Future<Result<Event>> getEvent(String id);
  Future<Result<List<Event>>> getEventsOnDay(DateTime day);
  Future<Result<List<List<Event>>>> getEventsOnWeek(DateTime week);
  Future<Result<List<List<Event>>>> getEventsOnYear(DateTime year);
}