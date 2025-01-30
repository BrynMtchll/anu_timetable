import 'package:anu_timetable/model/timetable_layout.dart';
import 'package:flutter/material.dart';
import 'package:anu_timetable/model/current_datetime_notifiers.dart';
import 'package:provider/provider.dart';

class LiveTimeIndicator extends StatelessWidget {

  final Size size;

  final TimetableLayout timetableLayout;


  const LiveTimeIndicator({
    super.key, 
    required this.size,
    required this.timetableLayout,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<CurrentSecond>(
      builder: (BuildContext context, CurrentSecond currentSecond, Widget? child) {
        return CustomPaint(
          size: size,
          painter: LiveTimePainter(
            timetableLayout: timetableLayout,
            currentSecond: currentSecond,
          ),
        );
      }
    );
  }
}

class LiveTimePainter extends CustomPainter {

  final TimetableLayout timetableLayout;

  final CurrentSecond currentSecond;

  const LiveTimePainter({
    required this.timetableLayout,
    required this.currentSecond,
  });

  @override
  void paint(Canvas canvas, Size size) {
    double vertOffset = _liveTimeVertOffset(size);
    Paint paint = Paint()
      ..color = Colors.lightBlue
      ..strokeWidth = 2.0;

    canvas.drawLine(Offset(timetableLayout.leftMargin - 5, vertOffset), Offset(size.width, vertOffset), paint);
    _paintLiveTimeLabel(canvas, vertOffset);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) =>
    oldDelegate is LiveTimePainter;

  /// Returns the vertical position representing of the current time
  /// respective to the [timetableLayout] dimensions.
  double _liveTimeVertOffset(Size size) {
    double dayOffset = currentSecond.getFractionOfDay() * timetableLayout.dayHeight;
    return dayOffset + timetableLayout.vertPadding;
  }

  void _paintLiveTimeLabel(Canvas canvas, double vertOffset) {
    double textPaddingRight = 10.0;

    TextPainter textPainter = TextPainter(
      text: _liveTimeLabelText(),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    )
      ..layout(
        minWidth: 0,
        maxWidth: timetableLayout.leftMargin,
      );

    double horzOffset = timetableLayout.leftMargin - textPainter.width - textPaddingRight;

    Paint paint = Paint()
      ..color = Colors.lightBlue;

    RRect rect = RRect.fromLTRBR(
        horzOffset - (textPaddingRight / 2), 
        vertOffset - 10, 
        horzOffset + textPainter.width + (textPaddingRight / 2), 
        vertOffset + 10, 
        Radius.circular(5.0)
      );
    canvas.drawRRect(rect, paint);
    textPainter.paint(canvas, Offset(horzOffset, vertOffset - (textPainter.height / 2)));
  }

  TextSpan _liveTimeLabelText() {
    return TextSpan(
      text: currentSecond.string,
      style: TextStyle(
        fontWeight: FontWeight.bold,
        /// The default color for TextPainter text is white. 
        /// For a quick fix the color is hardcoded to match
        /// the default text theme.
        /// TODO: get text colour from theme.
        color: Colors.grey[50],
        fontSize: 11,
      )
    );
  }
}