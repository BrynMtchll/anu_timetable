import 'package:anu_timetable/util/timetable_layout.dart';
import 'package:flutter/material.dart';
import 'package:anu_timetable/model/current_datetime_notifiers.dart';
import 'package:provider/provider.dart';
import 'package:anu_timetable/util/paints.dart';

class LiveTimeIndicator extends StatelessWidget {
  final Size size;

  const LiveTimeIndicator({
    super.key, 
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer2<CurrentSecond, TabController>(
      builder: (context, currentSecond, tabController, child) {
        bool weekViewActive = tabController.index == 1;
        return CustomPaint(
          size: size,
          painter: _LiveTimePainter(
            currentSecond: currentSecond,
            context: context,
            weekViewActive: weekViewActive,
          ),
        );
      }
    );
  }
}

class _LiveTimePainter extends CustomPainter {

  final CurrentSecond currentSecond;
  final BuildContext context;
  late ColorScheme colorScheme;
  final bool weekViewActive;

  _LiveTimePainter({
    required this.currentSecond,
    required this.context,
    required this.weekViewActive,
  }) {
    colorScheme = Theme.of(context).colorScheme;
  }

  @override
  void paint(Canvas canvas, Size size) {
    double vertOffset = _liveTimeVertOffset(size, currentSecond);
    Paint paint = PaintFactory.liveLinePaint(context);  

    if (weekViewActive) {
      _paintForWeekView(canvas, size, vertOffset, paint);
    } else {
      _paintForDayView(canvas, size, vertOffset, paint);
    }
  }

  /// paints the 
  void _paintForWeekView(canvas, size, vertOffset, paint) {
    int currentWeekday = currentSecond.value.weekday;

    double dayWidth = size.width / 7;
    
      paint.strokeWidth = PaintFactory.liveLineStrokeWidth/2;
      Offset p1 = Offset(0, vertOffset);
      Offset p2 = Offset(size.width, vertOffset);
      canvas.drawLine(p1, p2, paint);

      paint.strokeWidth = PaintFactory.liveLineStrokeWidth;
      Offset currp1 = Offset((currentWeekday - 1) * dayWidth, vertOffset);
      Offset currp2 = Offset(currentWeekday * dayWidth, vertOffset);
      canvas.drawLine(currp1, currp2, paint);
    
  }

  void _paintForDayView(canvas, size, vertOffset, paint) {
    Offset p1 = Offset(0, vertOffset);
      Offset p2 = Offset(size.width, vertOffset);
      canvas.drawLine(p1, p2, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) =>
    oldDelegate is _LiveTimePainter;
}

class LiveTimeIndicatorLabel extends StatelessWidget {
  final Size size;

  const LiveTimeIndicatorLabel({
    super.key, 
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<CurrentSecond>(
      builder: (BuildContext context, CurrentSecond currentSecond, Widget? child) {

        return CustomPaint(
          size: size,
          painter: _LiveTimeLabelPainter(
            currentSecond: currentSecond,
            context: context,
          ),
        );
      }
    );
  }
}

class _LiveTimeLabelPainter extends CustomPainter {

  final CurrentSecond currentSecond;
  final BuildContext context;
  late ColorScheme colorScheme;

  _LiveTimeLabelPainter({
    required this.currentSecond,
    required this.context,
  }) {
    colorScheme = Theme.of(context).colorScheme;
  }

  @override
  void paint(Canvas canvas, Size size) {
    double vertOffset = _liveTimeVertOffset(size, currentSecond);

    double textPaddingRight = 10.0;
    TextPainter textPainter = TextPainter(
      text: _liveTimeLabelText(),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    )
      ..layout(
        minWidth: 0,
        maxWidth: size.width,
      );

    double horzOffset = TimetableLayout.leftMargin - textPainter.width - textPaddingRight;

    Paint paint = Paint()
      ..color = colorScheme.primary;

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
        color: colorScheme.onInverseSurface,
        fontSize: 11,
      )
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) =>
    oldDelegate is _LiveTimeLabelPainter;
}
  /// Returns the vertical position representing of the current time
  /// respective to the [TimetableLayout] dimensions.

double _liveTimeVertOffset(Size size, CurrentSecond currentSecond) {
  double dayOffset = currentSecond.getFractionOfDay() * TimetableLayout.dayHeight;
  return dayOffset + TimetableLayout.vertPadding;
}