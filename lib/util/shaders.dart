import 'package:flutter/material.dart';

Shader eventTileShader(Rect bounds, Color shade) {
  // HSVColor hsvColor = HSVColor.fromColor(backgroundColor);
  // Color color = HSVColor.fromAHSV(1, hsvColor.hue, 0.275, 1).toColor();
  return LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [const Color.fromARGB(255, 255, 255, 255), shade])
      .createShader(bounds);
}