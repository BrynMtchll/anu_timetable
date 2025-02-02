import 'package:flutter/material.dart';

class PaintFactory {
  static Paint linePaint(context) => 
    Paint()
      ..color = Theme.of(context).colorScheme.onSurface
      ..strokeWidth = 0.2;

  static Paint liveLinePaint(context) =>
    Paint()
      ..color = Theme.of(context).colorScheme.primary
      ..strokeWidth = 2.0;

}