import 'package:anu_timetable/model/animation.dart';
import 'package:anu_timetable/model/controller.dart';
import 'package:anu_timetable/model/events.dart';
import 'package:anu_timetable/util/clippers.dart';
import 'package:anu_timetable/widgets/event_tiles.dart';
import 'package:anu_timetable/widgets/live_time_indicator.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:anu_timetable/model/timetable.dart';
import 'package:anu_timetable/widgets/hour_lines.dart';
import 'package:anu_timetable/widgets/day_lines.dart';
import 'package:anu_timetable/util/timetable_layout.dart';
import 'package:anu_timetable/model/current.dart';

class WeekView extends StatefulWidget {
  const WeekView({super.key});
  @override
  State<WeekView> createState() => _WeekViewState();
}

class _WeekViewState extends State<WeekView>{
  @override
  void initState() {
    Provider.of<TimetableVM>(context, listen: false).createWeekViewController();
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
    return Consumer2<TimetableVM, CurrentDay>(
      builder: (context, timetableModel, currentDay, child) { 
        bool pageIsCurrent = TimetableVM.weekEquiv(timetableModel.activeDay, currentDay.value);
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
    TimetableVM timetableModel = Provider.of<TimetableVM>(context, listen: false);
    final EventsVM eventsVM = Provider.of<EventsVM>(context, listen: false);
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
              timetableModel.handleWeekViewPageChanged(context);
            },
            itemBuilder: (context, page) 
              => Consumer<MonthBarAnimationNotifier>(
                builder: (context, monthBarAnimationNotifier, child) => 
                  IgnorePointer(
                    ignoring: monthBarAnimationNotifier.open,
                    child: child),
                 child: Consumer<CurrentDay>(
                    builder: (context, currentDay, child) {
                      bool pageIsCurrent = TimetableVM.weekEquiv(TimetableVM.getWeek(page), currentDay.value);
                      int dayIndex = TimetableVM.getDayIndex(TimetableVM.getWeek(page));
                      return Stack(
                      children: [
                        HourLines(size: size, pageIsCurrent: pageIsCurrent),
                        DayLines(size: size),
                          for (int i = 0; i < 7; i++)
                            Positioned(
                              left: size.width / 7 * i,
                              child: EventTiles(events: eventsVM.getEventsOnDay(dayIndex + i), size: Size(size.width / 7, size.height), 
                                transition: false)),
                        if (pageIsCurrent) IgnorePointer(child: LiveTimeIndicator(size: size))
                      ]);
            }))))));
  }
}
