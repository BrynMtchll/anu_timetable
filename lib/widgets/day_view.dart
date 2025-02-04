import 'package:anu_timetable/model/controllers.dart';
import 'package:anu_timetable/util/clippers.dart';
import 'package:anu_timetable/widgets/live_time_indicator.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:anu_timetable/model/timetable_model.dart';
import 'package:anu_timetable/widgets/hour_lines.dart';
import 'package:anu_timetable/util/timetable_layout.dart';
import 'package:linked_scroll_controller/linked_scroll_controller.dart';
import 'package:anu_timetable/model/current_datetime_notifiers.dart';

class DayView extends StatefulWidget {
  const DayView({super.key});

  @override
  State<DayView> createState() => _DayViewState();
}

class _DayViewState extends State<DayView> with AutomaticKeepAliveClientMixin<DayView> {
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
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        TimetableLayout timetableLayout = TimetableLayout(constraints: constraints);

        return SingleChildScrollView(
          child: ClipRect(
            clipper: HorizontalClipper(),
            child: SizedBox(
              height: TimetableLayout.height,
              child: _DayPageView(timetableLayout: timetableLayout)
            )
          )
        );
      }
    );
  }
}

class _DayPageView extends StatelessWidget {
  final TimetableLayout timetableLayout;

  const _DayPageView({super.key, required this.timetableLayout});

  @override
  Widget build(BuildContext context) {
    return PageView.builder(
      clipBehavior: Clip.none,
      controller: Provider.of<DayViewPageController>(context, listen: false),
      onPageChanged: (page) {
        Provider.of<TimetableModel>(context, listen: false).handleDayViewPageChanged();
      },
      itemBuilder: (context, page) => _DayItem(page: page, timetableLayout: timetableLayout)
    );
  }
}

class _DayItem extends StatelessWidget {
  final int page;
  final TimetableLayout timetableLayout;

  const _DayItem({super.key, required this.page, required this.timetableLayout});

  @override
  Widget build(BuildContext context) {
    return Consumer<CurrentDay>(
      builder: (context, currentDay, child) { 
      bool pageIsCurrent = _getPageIsCurrent(context, currentDay, page);
      return Stack(
        children: [
          HourLineLabels(size: timetableLayout.hourLineLabelsSize, pageIsCurrent: pageIsCurrent),
          Positioned(left: TimetableLayout.leftMargin,
            child: HourLines(size: timetableLayout.hourLinesSize, pageIsCurrent: pageIsCurrent),
          ),
          if (pageIsCurrent) Positioned(
            left: TimetableLayout.leftMargin, 
            child: LiveTimeIndicator(size: timetableLayout.liveTimeIndicatorSize),
          ),
          if (pageIsCurrent) LiveTimeIndicatorLabel(size: timetableLayout.liveTimeIndicatorLabelSize)
          ],
        );
      }
    );
  }

  bool _getPageIsCurrent(context, currentDay, page) {
    TimetableModel timetableModel = Provider.of<TimetableModel>(context, listen: false);
    return timetableModel.dayIsCurrent(page, currentDay);
  }
}