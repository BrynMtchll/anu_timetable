import 'package:anu_timetable/model/controller.dart';
import 'package:anu_timetable/model/events.dart';
import 'package:anu_timetable/util/clippers.dart';
import 'package:anu_timetable/widgets/event_tiles.dart';
import 'package:anu_timetable/widgets/live_time_indicator.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:anu_timetable/model/timetable.dart';
import 'package:anu_timetable/widgets/hour_lines.dart';
import 'package:anu_timetable/util/timetable_layout.dart';
import 'package:anu_timetable/model/current.dart';

class DayView extends StatefulWidget {
  const DayView({super.key});
  @override
  State<DayView> createState() => _DayViewState();
}

class _DayViewState extends State<DayView> with AutomaticKeepAliveClientMixin<DayView>{
  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    Provider.of<TimetableVM>(context, listen: false).createDayViewController();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    super.build(context);
    return SingleChildScrollView(
      controller: Provider.of<DayViewScrollController>(context, listen: false),
      child: ClipRect(
        clipper: HorizontalClipper(),
        child: Container(
          color: colorScheme.surface,
          height: TimetableLayout.height,
          child: _DayPageView())));
  }
}

class _DayPageView extends StatelessWidget {
  const _DayPageView();
  @override
  Widget build(BuildContext context) {
    TimetableVM timetableModel = Provider.of<TimetableVM>(context, listen: false);
    timetableModel.loadActiveDayEvents(context);
    return NotificationListener<UserScrollNotification>(
      onNotification: timetableModel.onDayViewNotification,
        child: PageView.builder(
        clipBehavior: Clip.none,
        controller: timetableModel.dayViewPageController,
        onPageChanged: (page) {
          timetableModel.handleDayViewPageChanged(context);
        },
        itemBuilder: (context, page) => Consumer<TimetableVM>(
          builder: (context, timetableModel, child) {
            int pageOverride = timetableModel.dayViewPageController.overridePage(page);
            return _DayItem(page: pageOverride);
          })));
  }
}

class _DayItem extends StatelessWidget {
  final int page;
  const _DayItem({required this.page});

  @override
  Widget build(BuildContext context) {
    final EventsVM eventsVM = Provider.of<EventsVM>(context, listen: false);
    final DateTime day = TimetableVM.getDay(page);
    return Consumer<CurrentDay>(
      builder: (context, currentDay, child) { 
        bool pageIsCurrent = TimetableVM.dayEquiv(day, currentDay.value);
        return Stack(
          children: [
            HourLineLabels(size: TimetableLayout.marginSize, pageIsCurrent: pageIsCurrent),
            if (pageIsCurrent) LiveTimeIndicatorLabel(size: TimetableLayout.marginSize),
            Positioned(
              left: TimetableLayout.leftMargin,
              child: HourLines(size: TimetableLayout.innerSize, pageIsCurrent: pageIsCurrent)),
            Positioned(
              left: TimetableLayout.leftMargin,
              child: ListenableBuilder(
                listenable: eventsVM.loadEventsForDay,
                builder: (context, child) {
                  return EventTiles(events: eventsVM.getEventsOnDay(day), size: TimetableLayout.innerSize, day: day);
                })),
            if (pageIsCurrent) Positioned(
              left: TimetableLayout.leftMargin,
              child: LiveTimeIndicator(size: TimetableLayout.innerSize)),
          ]);
      });
  }
}