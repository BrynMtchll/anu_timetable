import 'package:flutter/material.dart';

class PaintFactory {
  static Paint linePaint(context) {
    return Paint()
      ..color = Theme.of(context).colorScheme.onSurface
      ..strokeWidth = 0.2;
  }
}