import 'package:anu_timetable/model/controllers.dart';
import 'package:anu_timetable/util/clippers.dart';
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
    super.build(context);
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        return Consumer<DayViewScrollController>(
          builder: (context, dayViewScrollController, child) => 
            SingleChildScrollView(
              controller: dayViewScrollController,
              child: ClipRect(
                clipper: HorizontalClipper(),
                child: SizedBox(
                  height: TimetableLayout.height,
                  child: _DayPageView()
                )
              )
            )
        );
      }
    );
  }
}

class _DayPageView extends StatelessWidget {
  const _DayPageView();

  @override
  Widget build(BuildContext context) {
    return PageView.builder(
      clipBehavior: Clip.none,
      controller: Provider.of<DayViewPageController>(context, listen: false),
      onPageChanged: (page) {
        Provider.of<TimetableModel>(context, listen: false).handleDayViewPageChanged();
      },
      itemBuilder: (context, page) => _DayItem(page: page)
    );
  }
}

class _DayItem extends StatelessWidget {
  final int page;

  const _DayItem({required this.page});

  @override
  Widget build(BuildContext context) {
    return Consumer2<TimetableModel, CurrentDay>(
      builder: (context, timetableModel, currentDay, child) { 
        bool pageIsCurrent = timetableModel.dayIsCurrent(page, currentDay);
        return Stack(
          children: [
            HourLineLabels(size: TimetableLayout.marginSize, pageIsCurrent: pageIsCurrent),
            if (pageIsCurrent) LiveTimeIndicatorLabel(size: TimetableLayout.marginSize),
            Positioned(
              left: TimetableLayout.leftMargin,
              child: HourLines(size: TimetableLayout.innerSize, pageIsCurrent: pageIsCurrent),
            ),
            if (pageIsCurrent) Positioned(
              left: TimetableLayout.leftMargin, 
              child: LiveTimeIndicator(size: TimetableLayout.innerSize),
            ),
          ],
        );
      }
    );
  }
}