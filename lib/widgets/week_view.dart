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
  void initState() {
    Provider.of<TimetableModel>(context, listen: false).createWeekViewController();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      controller: Provider.of<WeekViewScrollController>(context, listen: false),
      child: Row(
        children: [
          _LeftMargin(size: TimetableLayout.marginSize),
          _WeekPageView(size: TimetableLayout.innerSize)
        ]));
  }
}

class _LeftMargin extends StatelessWidget {
  final Size size;
  const _LeftMargin({required this.size});
  @override
  Widget build(BuildContext context) {
    return Consumer2<TimetableModel, CurrentDay>(
      builder: (context, timetableModel, currentDay, child) { 
        bool pageIsCurrent = TimetableModel.weekEquiv(timetableModel.activeDay, currentDay.value);
        return Stack(
          children: [
            HourLineLabels(size: size, pageIsCurrent: pageIsCurrent),
            if (pageIsCurrent) LiveTimeIndicatorLabel(size: size)
          ]);
      });
  }
}

class _WeekPageView extends StatelessWidget {
  final Size size;
  const _WeekPageView({required this.size});
  @override
  Widget build(BuildContext context) {
    TimetableModel timetableModel = Provider.of<TimetableModel>(context, listen: false);
    return ClipRect(
      clipper: HorizontalClipper(),
      child: SizedBox(
        width: size.width,
        height: size.height,
        child: NotificationListener<UserScrollNotification>(
          onNotification: timetableModel.onWeekViewNotification,
          child: PageView.builder(
            clipBehavior: Clip.none,
            controller: timetableModel.weekViewPageController,
            onPageChanged: (page) {
              timetableModel.handleWeekViewPageChanged();
            },
            itemBuilder: (context, page) =>
              Consumer<CurrentDay>(
                builder: (context, currentDay, child) {
                  bool pageIsCurrent = TimetableModel.weekEquiv(TimetableModel.getWeek(page), currentDay.value);
                  return Stack(
                    children: [
                      HourLines(size: size, pageIsCurrent: pageIsCurrent),
                      DayLines(size: size),
                      if (pageIsCurrent) LiveTimeIndicator(size: size)
                    ]);
                })))));
  }
}
