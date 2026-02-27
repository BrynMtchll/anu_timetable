import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

class Event {
  late String id;
  final String title;
  final DateTime startTime;
  final DateTime endTime;
  final String? location;

  Event({
    required this.title,
    required this.startTime,
    required this.endTime,
    this.location,
  }) {
    id = Uuid().v4();
  }

  bool overlapping(Event other) => 
    startTime.compareTo(other.endTime) < 0 && other.startTime.compareTo(endTime) < 0;
}