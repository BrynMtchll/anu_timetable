import 'package:flutter/material.dart';
import 'package:anu_timetable/model/timetable_layout.dart';
import 'package:provider/provider.dart';
import 'package:anu_timetable/model/current_datetime_notifiers.dart';
import 'package:anu_timetable/widgets/paints.dart';

class HourLines extends StatelessWidget {
  final Size size;
  final bool isCurrentDay;

  const HourLines({
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
          painter: _HourLinePainter(
            currentMinute: currentMinute,
            isCurrentDay: isCurrentDay,
            context: context,
          )
        );
      }
    );
  }
}

class _HourLinePainter extends CustomPainter {
  final CurrentMinute currentMinute;
  final bool isCurrentDay;
  final BuildContext context;
  late ColorScheme colorScheme;

  _HourLinePainter({
    required this.currentMinute,
    required this.isCurrentDay,
    required this.context,
  }) {
    colorScheme = Theme.of(context).colorScheme;
  }

  @override
  void paint(Canvas canvas, Size size) {
    _paintLabels(canvas);
    _paintLines(canvas, size);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }

  double _getVertOffset(int hour) =>
    TimetableLayout.vertPadding + hour * TimetableLayout.hourHeight;

  void _paintLines(canvas, size) {
    for (int hour = 0; hour < 25; hour++) {
      final vertOffset = _getVertOffset(hour);
      canvas.drawLine(
        Offset(
          TimetableLayout.leftMargin, 
          vertOffset
        ), 
        Offset(
          size.width, 
          vertOffset
        ), 
        PaintFactory.linePaint(context),
      );
    }
  }

  void _paintLabels(canvas) {
    TextPainter textPainter = TextPainter(
      textAlign: TextAlign.end,
      textDirection: TextDirection.ltr,
    );

    for (int hour = 0; hour < 25; hour++) {
      textPainter.text = _hourLineLabelText(hour);

      double textPaddingRight = 10.0;

      textPainter.layout(
        minWidth: TimetableLayout.leftMargin - textPaddingRight,
        maxWidth: TimetableLayout.leftMargin - textPaddingRight,
      );
      final vertOffset = _getVertOffset(hour) - (textPainter.height / 2);

      if (currentMinute.differenceFromHour(hour) > 15 || !isCurrentDay) {
        textPainter.paint(canvas, Offset(0, vertOffset));
      }
    }
  }

  TextSpan _hourLineLabelText(int hour) {
    String number;
    String unit;

    hour % 12 == 0 ?
      number = 12.toString() :
      number = (hour % 12).toString();
    
    hour >= 12 ?
      unit = "pm":
      unit = "am";

    return TextSpan(
      children: <TextSpan>[
        TextSpan(
          text: number,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
            fontSize: 13,
          )
        ),
        TextSpan(
          style: TextStyle(
            fontSize: 11,
            color: colorScheme.onSurface,
          ),
          text: unit,
        )
      ]
    );
  }
}