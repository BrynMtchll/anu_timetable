import 'package:anu_timetable/controllers.dart';
import 'package:anu_timetable/widgets/live_time_indicator.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:anu_timetable/model/timetable_model.dart';
import 'package:anu_timetable/widgets/hour_line_painter.dart';
import 'package:anu_timetable/model/timetable_layout.dart';
import 'package:linked_scroll_controller/linked_scroll_controller.dart';

class DayView extends StatefulWidget {
  const DayView({super.key});

  @override
  State<DayView> createState() => _DayViewState();
}

class _DayViewState extends State<DayView> {
  late LinkedScrollControllerGroup _controllers;

  @override
  void initState() {
    super.initState();
    _controllers = LinkedScrollControllerGroup();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PageView.builder(
      controller: Provider.of<DayViewPageController>(context, listen: false),
      onPageChanged: (page) {
        Provider.of<TimetableModel>(context, listen: false)
          .handleDayViewPageChanged();
      },
      itemBuilder: (context, page) => _dayBuilder(context, page),
    );
  }

  LayoutBuilder _dayBuilder(context, int page) {
    TimetableModel timetableModel = Provider.of<TimetableModel>(context, listen: false);
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        TimetableLayout timetableLayout = TimetableLayout();
        Size size = Size(constraints.maxWidth, timetableLayout.height);
        return SingleChildScrollView(
          controller: _controllers.addAndGet(),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: constraints.maxHeight,
            ),
            child: Stack(
              children: [
                Align(
                  alignment: Alignment.centerRight,
                  child: CustomPaint(
                    size: size,
                    painter: HourLinePainter(
                      timetableLayout: timetableLayout,
                    ),
                  ),
                ),
                if (timetableModel.day(page.toDouble()) == timetableModel.currentDay())
                      LiveTimeIndicator(
                        size: size,
                        timetableLayout: timetableLayout,
                      )
              ],
            )
          ),
        );
      }
    );
  }
}