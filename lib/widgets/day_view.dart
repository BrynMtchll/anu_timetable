import 'package:anu_timetable/controllers.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:anu_timetable/model/timetable_model.dart';
import 'package:anu_timetable/widgets/hour_line_painter.dart';

class DayView extends StatelessWidget {
  const DayView({super.key});

  static const double leftMargin = 50;

  static const double height = 1500;

  /// An even segment for each of the 24 hours of the day,
  /// plus a half hour top and bottom for padding.
  static const double hourHeight = height / 25;

  static const double vertPadding = hourHeight / 2;

  LayoutBuilder _dayBuilder(int page) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: constraints.maxHeight,
            ),
            child: Stack(
              children: [
                Align(
                  alignment: Alignment.centerRight,
                  child: CustomPaint(
                    size: Size(constraints.maxWidth - leftMargin, height),
                    painter: HourLinePainter(
                      hourHeight: hourHeight, 
                      vertPadding: vertPadding
                    )
                  ),
                ),
                for (int i = 0; i < 25; i++) _hourLineLabel(i), 
              ],
            )
          ),
        );
      }
    );
  }

  Text _hourLineLabelText(int hour) {
    String number;
    String unit;

    hour % 12 == 0 ?
      number = 12.toString() :
      number = (hour % 12).toString();
    
    hour >= 12 ?
      unit = "pm":
      unit = "am";

    return Text.rich(TextSpan(
      children: <TextSpan>[
        TextSpan(
          text: number,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 13,
          )
        ),
        TextSpan(
          style: TextStyle(
            fontSize: 11,
          ),
          text: unit,
        )
      ]
    ));
  }

  Positioned _hourLineLabel(int hour) {
    final double labelHeight = 30;
    return Positioned(
      top: hourHeight * hour + vertPadding  - (labelHeight / 2),
      left: 0,
      child: Align(
        alignment: Alignment.centerLeft,
        child: SizedBox(
          width: leftMargin,
          height: labelHeight,
          child: Align(
            alignment: Alignment.centerRight,
            child: Padding(
              padding: EdgeInsets.only(right: 5),
              child: _hourLineLabelText(hour),
          )
        )
      )
    ));
  }

  @override
  Widget build(BuildContext context) {
    return PageView.builder(
      controller: Provider.of<DayViewPageController>(context, listen: false),
      onPageChanged: (page) {
        Provider.of<TimetableModel>(context, listen: false)
          .handleDayViewPageChanged();
      },
      itemBuilder: (context, page) => _dayBuilder(page),
    );
  }
}