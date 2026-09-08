import 'package:flutter/material.dart';

Shader eventTileShader(Rect bounds, Color shade) {
  return LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [const Color.fromARGB(255, 255, 255, 255), shade])
      .createShader(bounds);
}