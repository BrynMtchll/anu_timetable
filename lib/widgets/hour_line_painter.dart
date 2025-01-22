import 'package:flutter/rendering.dart';

class HourLinePainter extends CustomPainter {

  double hourHeight;
  double vertPadding;

  HourLinePainter({
    required this.hourHeight,
    required this.vertPadding,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final myPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5;

    for (int i = 0; i < 25; i++) {
      final vertOffset = vertPadding + i * hourHeight;
      canvas.drawLine(Offset(0, vertOffset), Offset(size.width, vertOffset), Paint());

    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}