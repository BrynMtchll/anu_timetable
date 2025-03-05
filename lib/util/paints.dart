import 'package:flutter/material.dart';

class PaintFactory {
  static const liveLineStrokeWidth = 1.5;

  static Paint linePaint(context) => 
    Paint()
      ..color = Theme.of(context).colorScheme.onSurface
      ..strokeWidth = 0.2;

  static Paint liveLinePaint(context) =>
    Paint()
      ..color = Theme.of(context).colorScheme.primary
      ..strokeWidth = liveLineStrokeWidth;

  static Paint backgroundPaint(context) => 
    Paint()
    ..color = Theme.of(context).colorScheme.surface
    ..style = PaintingStyle.fill;
}