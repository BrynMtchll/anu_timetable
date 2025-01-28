import 'package:flutter/material.dart';
import 'package:anu_timetable/model/timetable_layout.dart';

class HourLinePainter extends CustomPainter {

  final TimetableLayout timetableLayout;

  HourLinePainter({
    required this.timetableLayout,
  });

  @override
  void paint(Canvas canvas, Size size) {
      TextPainter textPainter = TextPainter(
        textAlign: TextAlign.end,
        textDirection: TextDirection.ltr,
      );

    for (int i = 0; i < 25; i++) {
      final vertOffset = timetableLayout.vertPadding + i * timetableLayout.hourHeight;

      textPainter.text = _hourLineLabelText(i);

      double textPaddingRight = 10.0;

      textPainter.layout(
        minWidth: timetableLayout.leftMargin - textPaddingRight,
        maxWidth: timetableLayout.leftMargin - textPaddingRight,
      );

      textPainter.paint(canvas, Offset(0, vertOffset - (textPainter.height / 2)));

      canvas.drawLine(Offset(timetableLayout.leftMargin, vertOffset), Offset(size.width, vertOffset), Paint());
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
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