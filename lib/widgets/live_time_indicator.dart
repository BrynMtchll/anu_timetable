import 'package:anu_timetable/model/timetable_layout.dart';
import 'package:flutter/material.dart';
import 'package:anu_timetable/model/current_datetime_notifiers.dart';
import 'package:provider/provider.dart';
import 'package:anu_timetable/widgets/paints.dart';

class LiveTimeIndicator extends StatelessWidget {
  final Size size;

  const LiveTimeIndicator({
    super.key, 
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<CurrentSecond>(
      builder: (BuildContext context, CurrentSecond currentSecond, Widget? child) {
        return CustomPaint(
          size: size,
          painter: _LiveTimePainter(
            currentSecond: currentSecond,
            context: context,
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

  _LiveTimePainter({
    required this.currentSecond,
    required this.context,
  }) {
    colorScheme = Theme.of(context).colorScheme;
  }

  @override
  void paint(Canvas canvas, Size size) {
    double vertOffset = _liveTimeVertOffset(size);

    Offset p1 = Offset(TimetableLayout.leftMargin - 5, vertOffset);
    Offset p2 = Offset(size.width, vertOffset);
    Paint paint = PaintFactory.liveLinePaint(context);

    canvas.drawLine(p1, p2, paint);
    _paintLiveTimeLabel(canvas, vertOffset);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) =>
    oldDelegate is _LiveTimePainter;

  /// Returns the vertical position representing of the current time
  /// respective to the [TimetableLayout] dimensions.
  double _liveTimeVertOffset(Size size) {
    double dayOffset = currentSecond.getFractionOfDay() * TimetableLayout.dayHeight;
    return dayOffset + TimetableLayout.vertPadding;
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
        maxWidth: TimetableLayout.leftMargin,
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
}