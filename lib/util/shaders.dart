import 'package:flutter/material.dart';

Shader eventTileShader(Rect bounds) {
  return LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [const Color.fromARGB(255, 255, 255, 255), const Color.fromARGB(255, 200, 185, 255)])
      .createShader(bounds);
}