import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:anu_timetable/model/current_datetime_notifiers.dart';
import 'package:anu_timetable/util/paints.dart';

class DayLines extends StatelessWidget {
  final Size size;

  const DayLines({
    super.key, 
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<CurrentMinute>(
      builder: (BuildContext context, CurrentMinute currentMinute, Widget? child) {
        return CustomPaint(
          size: size,
          painter: DayLinePainter(
            context: context,
          )
        );
      }
    );
  }
}

class DayLinePainter extends CustomPainter {
  final BuildContext context;
  late ColorScheme colorScheme;

  DayLinePainter({
    required this.context,
  }) {
    colorScheme = Theme.of(context).colorScheme;
  }

  @override
  void paint(Canvas canvas, Size size) {
    double dayWidth = size.width / 7;
    for (int i = 1; i < 8; i++) {
      canvas.drawLine(
        Offset(i * dayWidth, -400), 
        Offset(i * dayWidth, size.height + 400), 
        PaintFactory.linePaint(context),
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}