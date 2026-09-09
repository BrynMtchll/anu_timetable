import 'package:anu_timetable/util/timetable_layout.dart';
import 'package:flutter/material.dart';

class PaintFactory {
  static Paint linePaint(BuildContext context) => 
    Paint()
      ..color = Theme.of(context).colorScheme.onSurface
      ..strokeWidth = TimetableLayout.lineStrokeWidth;

  static Paint liveLinePaint(BuildContext context) =>
    Paint()
      ..color = Theme.of(context).colorScheme.primary
      ..strokeWidth = TimetableLayout.liveLineStrokeWidth;

  static Paint backgroundPaint(BuildContext context) => 
    Paint()
    ..color = Theme.of(context).colorScheme.surface
    ..style = PaintingStyle.fill;
}