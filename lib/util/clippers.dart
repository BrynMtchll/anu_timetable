

import 'package:flutter/material.dart';

class HorizontalClipper extends CustomClipper<Rect> {
@override
  Rect getClip(Size size) {
    return Rect.fromLTWH(0, -400, size.width, size.height + 800);
  }

  @override
  bool shouldReclip(covariant CustomClipper<Rect> oldClipper) {
    return false;
  }
}