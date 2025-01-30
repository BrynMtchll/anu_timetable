import 'package:flutter/material.dart';
import 'package:anu_timetable/model/timetable_layout.dart';
import 'package:provider/provider.dart';
import 'package:anu_timetable/model/current_datetime_notifiers.dart';

class HourLine extends StatelessWidget {
  final Size size;
  final TimetableLayout timetableLayout;
  final bool isCurrentDay;

  const HourLine({
    super.key, 
    required this.size,
    required this.timetableLayout,
    required this.isCurrentDay,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<CurrentMinute>(
      builder: (BuildContext context, CurrentMinute currentMinute, Widget? child) {
        return CustomPaint(
          size: size,
          painter: HourLinePainter(
            timetableLayout: timetableLayout,
            currentMinute: currentMinute,
            isCurrentDay: isCurrentDay,
          )
        );
      }
    );
  }
}

class HourLinePainter extends CustomPainter {

  final TimetableLayout timetableLayout;
  final CurrentMinute currentMinute;
  final bool isCurrentDay;

  HourLinePainter({
    required this.timetableLayout,
    required this.currentMinute,
    required this.isCurrentDay,
  });

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
    timetableLayout.vertPadding + hour * timetableLayout.hourHeight;

  void _paintLines(canvas, size) {
    for (int hour = 0; hour < 25; hour++) {
      final vertOffset = _getVertOffset(hour);
      canvas.drawLine(Offset(timetableLayout.leftMargin, vertOffset), Offset(size.width, vertOffset), Paint());
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
        minWidth: timetableLayout.leftMargin - textPaddingRight,
        maxWidth: timetableLayout.leftMargin - textPaddingRight,
      );
      final vertOffset = _getVertOffset(hour) - (textPainter.height / 2);

      if (currentMinute.differenceFromHour(hour) > 15) {
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
            /// The default color for TextPainter text is white 
            /// so for a quick fix this is hardcoded to sync with
            /// the default text theme.
            /// TODO: get text colour from theme.
            color: Colors.grey[900],
            fontSize: 13,
          )
        ),
        TextSpan(
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey[900],
          ),
          text: unit,
        )
      ]
    );
  }
}