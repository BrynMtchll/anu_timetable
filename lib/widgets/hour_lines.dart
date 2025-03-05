import 'package:flutter/material.dart';
import 'package:anu_timetable/util/timetable_layout.dart';
import 'package:provider/provider.dart';
import 'package:anu_timetable/model/current_datetime_notifiers.dart';
import 'package:anu_timetable/util/paints.dart';

class HourLines extends StatelessWidget {
  final Size size;
  final bool pageIsCurrent;

  const HourLines({
    super.key, 
    required this.size,
    required this.pageIsCurrent,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<CurrentMinute>(
      builder: (BuildContext context, CurrentMinute currentMinute, Widget? child) {
        return SizedBox(
          width: size.width,
          height: size.height,
          child: CustomPaint(
            size: size,
            painter: _HourLinePainter(
              currentMinute: currentMinute,
              pageIsCurrent: pageIsCurrent,
              context: context)));
      });
  }
}

class _HourLinePainter extends CustomPainter {
  final CurrentMinute currentMinute;
  final bool pageIsCurrent;
  final BuildContext context;
  late ColorScheme colorScheme;

  _HourLinePainter({
    required this.currentMinute,
    required this.pageIsCurrent,
    required this.context,
  }) {
    colorScheme = Theme.of(context).colorScheme;
  }

  @override
  void paint(Canvas canvas, Size size) {
   for (int hour = 0; hour < 25; hour++) {
      final vertOffset = _getVertOffset(hour);
      canvas.drawLine(
        Offset(0, vertOffset), 
        Offset(size.width, vertOffset), 
        PaintFactory.linePaint(context));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}

class HourLineLabels extends StatelessWidget {
  final Size size;
  final bool pageIsCurrent;

  const HourLineLabels({
    super.key, 
    required this.size,
    required this.pageIsCurrent,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<CurrentMinute>(
      builder: (BuildContext context, CurrentMinute currentMinute, Widget? child) {
        return SizedBox(
          width: size.width,
          height: size.height,
          child: CustomPaint(
          size: size,
          painter: _HourLineLabelPainter(
            currentMinute: currentMinute,
            pageIsCurrent: pageIsCurrent,
            context: context)));
      });
  }
}

class _HourLineLabelPainter extends CustomPainter {
  final CurrentMinute currentMinute;
  final bool pageIsCurrent;
  final BuildContext context;
  late ColorScheme colorScheme;

  _HourLineLabelPainter({
    required this.currentMinute,
    required this.pageIsCurrent,
    required this.context,
  }) {
    colorScheme = Theme.of(context).colorScheme;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final TextPainter textPainter = TextPainter(
      textAlign: TextAlign.end,
      textDirection: TextDirection.ltr);
    final RRect backgroundRect = RRect.fromLTRBR(0, 0, size.width, size.height, Radius.zero);
    canvas.drawRRect(backgroundRect, PaintFactory.backgroundPaint(context));

    for (int hour = 0; hour < 25; hour++) {
      // don't draw the hour label if it overlaps with the live time indicator label.
      if (currentMinute.differenceFromHour(hour) <= 15 && pageIsCurrent) continue;
      textPainter.text = _text(hour);
      final double textPaddingRight = 10.0;
      textPainter.layout(
        minWidth: TimetableLayout.leftMargin - textPaddingRight,
        maxWidth: TimetableLayout.leftMargin - textPaddingRight);
      final vertOffset = _getVertOffset(hour) - (textPainter.height / 2);
      textPainter.paint(canvas, Offset(0, vertOffset));
    }
    canvas.drawLine(Offset(size.width, -400), Offset(size.width, size.height + 400), PaintFactory.linePaint(context));
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }

  TextSpan _text(int hour) {
    final String number = hour % 12 == 0 ? 12.toString() : (hour % 12).toString();
    final String unit = hour >= 12 ? "pm" : "am";

    return TextSpan(
      children: <TextSpan>[
        TextSpan(
          text: number,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
            fontSize: 13)),
        TextSpan(
          style: TextStyle(
            fontSize: 11,
            color: colorScheme.onSurface),
          text: unit)
      ]);
  }
}

double _getVertOffset(int hour) =>
  TimetableLayout.vertPadding + hour * TimetableLayout.hourHeight;
