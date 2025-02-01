import 'package:flutter/material.dart';
import 'package:anu_timetable/model/timetable_layout.dart';
import 'package:provider/provider.dart';
import 'package:anu_timetable/model/current_datetime_notifiers.dart';
import 'package:anu_timetable/widgets/paints.dart';

class DayLines extends StatelessWidget {
  final Size size;
  final bool isCurrentDay;

  const DayLines({
    super.key, 
    required this.size,
    required this.isCurrentDay,
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
    double innerWidth = size.width - TimetableLayout.leftMargin;
    double dayWidth = innerWidth / 7;

    for (int i = 0; i < 8; i++) {
      canvas.drawLine(
        Offset(TimetableLayout.leftMargin + i * dayWidth, -400), 
        Offset(TimetableLayout.leftMargin + i * dayWidth, size.height + 400), 
        PaintFactory.linePaint(context),
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}