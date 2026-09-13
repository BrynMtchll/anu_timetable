import 'package:flutter/material.dart';

ScaffoldFeatureController<SnackBar, SnackBarClosedReason> showSnackBar(BuildContext context, String text) {
  final colorScheme = Theme.of(context).colorScheme;
  return ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      backgroundColor: colorScheme.surfaceContainer,
      duration: Duration(milliseconds: 3000),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0)),
      content: Center(child: Text(text, style: TextStyle(color: colorScheme.onSurface)))));
}