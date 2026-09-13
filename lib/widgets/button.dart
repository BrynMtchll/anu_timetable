
import 'package:flutter/material.dart';

class MyButton extends StatelessWidget {
  const MyButton({
    super.key,
    required this.onPressed,
    required this.text,
    required this.isPrimary});

  final VoidCallback onPressed;
  final String text;
  final bool isPrimary;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final hslcolor = HSLColor.fromColor(colorScheme.primary);
    final colorStart = hslcolor.withSaturation(0.65).withLightness(0.55).toColor();
    final colorEnd = hslcolor.withSaturation(0.68).withLightness(0.52).withHue(hslcolor.hue - 5).toColor();
    final hslgrey = HSLColor.fromColor(colorScheme.surfaceContainerHighest);
    final greyStart = hslgrey.withLightness(0.35).toColor();
    final greyEnd = hslgrey.withLightness(0.3).toColor();
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 0),
      height: 40,
      decoration: BoxDecoration(
        // border: Border.all(color: isPrimary ? colorScheme.primary : const Color.fromARGB(255, 114, 114, 114)),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isPrimary ? [colorStart, colorEnd] : [greyStart, greyEnd]),
        color: isPrimary ? null : colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(30),
      ),
      child: TextButton(
        onPressed: onPressed,
        style: TextButton.styleFrom(
          minimumSize: const Size.fromHeight(0)),
        child: Text(text, style: TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 14,
          color: isPrimary ? colorScheme.onSurface : colorScheme.onSurface))));
  }
}