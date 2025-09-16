import 'package:anu_timetable/model/controllers.dart';
import 'package:anu_timetable/util/clippers.dart';
import 'package:anu_timetable/widgets/event_tile_generator.dart';
import 'package:anu_timetable/widgets/live_time_indicator.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:anu_timetable/model/timetable_model.dart';
import 'package:anu_timetable/widgets/hour_lines.dart';
import 'package:anu_timetable/util/timetable_layout.dart';
import 'package:anu_timetable/model/current_datetime_notifiers.dart';

class DayView extends StatefulWidget {
  const DayView({super.key});
  @override
  State<DayView> createState() => _DayViewState();
}

class _DayViewState extends State<DayView> with AutomaticKeepAliveClientMixin<DayView>{
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    super.build(context);
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
            return SingleChildScrollView(
              controller: Provider.of<DayViewScrollController>(context, listen: false),
              child: ClipRect(
                clipper: HorizontalClipper(),
                child: Container(
                  color: colorScheme.surface,
                  height: TimetableLayout.height,
                  child: _DayPageView())));
      });
  }
}

class _DayPageView extends StatelessWidget {
  const _DayPageView();
  @override
  Widget build(BuildContext context) {
    return Consumer<DayViewPageController>(
      builder: (context, dayViewPageController, child) {
        return NotificationListener<UserScrollNotification>(
          onNotification: Provider.of<TimetableModel>(context, listen: false).onDayViewNotification,
          child: PageView.builder(
            clipBehavior: Clip.none,
            controller: dayViewPageController,
            onPageChanged: (page) {
              Provider.of<TimetableModel>(context, listen: false).handleDayViewPageChanged();
            },
            itemBuilder: (context, page) => _DayItem(page: dayViewPageController.overridePage(page))));
      });
  }
}

class _DayItem extends StatelessWidget {
  final int page;
  const _DayItem({required this.page});

  @override
  Widget build(BuildContext context) {
    return Consumer3<CurrentDay, TimetableModel, DayViewPageController>(
      builder: (context, currentDay, timetableModel, dayViewPageController, child) { 
        bool pageIsCurrent = TimetableModel.dayIsCurrent(page.toDouble(), currentDay);
        DateTime day = TimetableModel.day(page.toDouble());
        return Stack(
          children: [
            HourLineLabels(size: TimetableLayout.marginSize, pageIsCurrent: pageIsCurrent),
            if (pageIsCurrent) LiveTimeIndicatorLabel(size: TimetableLayout.marginSize),
            Positioned(
              left: TimetableLayout.leftMargin,
              child: HourLines(size: TimetableLayout.innerSize, pageIsCurrent: pageIsCurrent)),
            Positioned(
              left: TimetableLayout.leftMargin,
              child: EventTileGenerator(size: TimetableLayout.innerSize, day: day)),
            if (pageIsCurrent) Positioned(
              left: TimetableLayout.leftMargin,
              child: LiveTimeIndicator(size: TimetableLayout.innerSize)),
          ]);
      });
  }
}