import 'dart:async';
import 'package:anu_timetable/model/timetable_layout.dart';
import 'package:calendar_view/calendar_view.dart';
import 'package:flutter/material.dart';

class LiveTimeIndicator extends StatefulWidget {

  final Size size;

  final TimetableLayout timetableLayout;


  const LiveTimeIndicator({
    super.key, 
    required this.size,
    required this.timetableLayout,
  });

  @override
  State<LiveTimeIndicator> createState() => _LiveTimeIndicatorState();
}

class _LiveTimeIndicatorState extends State<LiveTimeIndicator> {
  late Timer _timer;
  TimeOfDay _currentTime = TimeOfDay.now();

    @override
  void initState() {
    super.initState();

    _timer = Timer.periodic(Duration(seconds: 1), _onTick);
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: widget.size,
      painter: LiveTimePainter(
        timetableLayout: widget.timetableLayout,
        currentTime: _currentTime,
      ),
    );
  }

  void _onTick(Timer? timer) {
    final time = TimeOfDay.now();
    if (time != _currentTime && mounted) {
      _currentTime = time;
      setState(() {});
    }
  }
}

class LiveTimePainter extends CustomPainter {

  final TimetableLayout timetableLayout;

  final TimeOfDay currentTime;

  const LiveTimePainter({
    required this.timetableLayout,
    required this.currentTime,
  });

  @override
  void paint(Canvas canvas, Size size) {
    double vertOffset = _liveTimeVertOffset(size);

    Paint myPaint = Paint()
      ..color = Colors.lightBlue
      ..strokeWidth = 2.0;

    canvas.drawLine(Offset(timetableLayout.leftMargin - 5, vertOffset), Offset(size.width, vertOffset), myPaint);
    _paintLiveTimeLabel(canvas, vertOffset);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) =>
      oldDelegate is LiveTimePainter;

  /// Returns the vertical position representing of the current time
  /// respective to the [timetableLayout] dimensions.
  double _liveTimeVertOffset(Size size) {
    int minutesPerDay = TimeOfDay.minutesPerHour * TimeOfDay.hoursPerDay;
    double currentTimeAsFractionOfDay = (currentTime.getTotalMinutes / minutesPerDay);
    double dayOffset = currentTimeAsFractionOfDay * timetableLayout.dayHeight;
    return dayOffset + timetableLayout.vertPadding;
  }

  void _paintLiveTimeLabel(Canvas canvas, double vertOffset) {
    double textPaddingRight = 10.0;

    TextPainter textPainter = TextPainter(
      text: _liveTimeLabelText(),
      textAlign: TextAlign.end,
      textDirection: TextDirection.ltr,
    )
      ..layout(
        minWidth: timetableLayout.leftMargin - textPaddingRight,
        maxWidth: timetableLayout.leftMargin - textPaddingRight,
      );

    Paint paint = Paint()
      ..color = Colors.lightBlue;

    RRect rect = RRect.fromLTRBR(
        timetableLayout.leftMargin - textPainter.width - 5, 
        vertOffset - 10, timetableLayout.leftMargin - 5, 
        vertOffset + 10, 
        Radius.circular(5.0)
      );
    canvas.drawRRect(rect, paint);
    textPainter.paint(canvas, Offset(0, vertOffset - (textPainter.height / 2)));
  }

  TextSpan _liveTimeLabelText() {
    return TextSpan(
      text: "${currentTime.hourOfPeriod}:${currentTime.minute.toString().padLeft(2, '0')}",
      style: TextStyle(
        fontWeight: FontWeight.bold,
        /// The default color for TextPainter text is white 
        /// so for a quick fix this is hardcoded to sync with
        /// the default text theme.
        /// TODO: get text colour from theme.
        color: Colors.grey[50],
        fontSize: 11,
      )
    );
  }
}