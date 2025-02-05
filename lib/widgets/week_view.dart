import 'package:anu_timetable/model/controllers.dart';
import 'package:anu_timetable/util/clippers.dart';
import 'package:anu_timetable/widgets/live_time_indicator.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:anu_timetable/model/timetable_model.dart';
import 'package:anu_timetable/widgets/hour_lines.dart';
import 'package:anu_timetable/widgets/day_lines.dart';
import 'package:anu_timetable/util/timetable_layout.dart';
import 'package:anu_timetable/model/current_datetime_notifiers.dart';

class WeekView extends StatefulWidget {
  const WeekView({super.key});

  @override
  State<WeekView> createState() => _WeekViewState();
}

class _WeekViewState extends State<WeekView>{
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        return Consumer3<TimetableModel, CurrentDay, WeekViewScrollController>(
          builder: (context, timetableModel, currentDay, weekViewScrollController, child) { 
          return SingleChildScrollView(
              controller: weekViewScrollController,
              child:  Row(
                children: [
                  _LeftMargin(size: TimetableLayout.marginSize),
                  _WeekPageView(size: TimetableLayout.innerSize)
                ]
              )
            );
          }
        );
      }
    );
  }
}

class _LeftMargin extends StatelessWidget {
  final Size size;

  const _LeftMargin({required this.size});

  @override
  Widget build(BuildContext context) {
    return Consumer2<TimetableModel, CurrentDay>(
      builder: (context, timetableModel, currentDay, child) { 
        bool pageIsCurrent = timetableModel.activeWeekIsCurrent(currentDay);  
        return Stack(
          children: [
            HourLineLabels(size: size, pageIsCurrent: pageIsCurrent),
            if (pageIsCurrent) LiveTimeIndicatorLabel(size: size)
          ],
        );
      }
    );
  }
}

class _WeekPageView extends StatelessWidget {
  final Size size;

  const _WeekPageView({required this.size});

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      clipper: HorizontalClipper(),
      child: SizedBox(
        width: size.width,
        height: size.height,
        child: PageView.builder(
          clipBehavior: Clip.none,
          controller: Provider.of<WeekViewPageController>(context, listen: false),
          itemBuilder: (context, page) =>
            Consumer2<TimetableModel, CurrentDay>(
              builder: (context, timetableModel, currentDay, child) { 
                bool pageIsCurrent = timetableModel.weekIsCurrent(page, currentDay);
                return Stack(
                  children: [
                    HourLines(size: size, pageIsCurrent: pageIsCurrent),
                    DayLines(size: size),
                    if (pageIsCurrent) LiveTimeIndicator(size: size)
                  ],
                );
              }
            )
        )
      )
    );
  }
}