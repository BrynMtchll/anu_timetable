import 'package:anu_timetable/model/controllers.dart';
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
        // TODO: move into TimetableLayout and pass reference to users.
        Size hourLineLabelsSize = Size(TimetableLayout.leftMargin, TimetableLayout.height);
        Size hourLinesSize = Size(constraints.maxWidth - TimetableLayout.leftMargin, TimetableLayout.height);
        Size liveTimeIndicatorSize = Size(constraints.maxWidth - TimetableLayout.leftMargin, TimetableLayout.height);
        Size liveTimeIndicatorLabelSize = Size(TimetableLayout.leftMargin, TimetableLayout.height);
        return Consumer<CurrentDay>(
          builder: (context, currentDay, child) { 
          bool pageIsCurrent = timetableModel.dayIsCurrent(page, currentDay);

          return SingleChildScrollView(
            // controller: _controllers.addAndGet(),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: constraints.maxHeight,
              ),
              child: Stack(
                children: [
                  HourLineLabels(size: hourLineLabelsSize, pageIsCurrent: pageIsCurrent),
                  Positioned(left: TimetableLayout.leftMargin,
                    child: HourLines(size: hourLinesSize, pageIsCurrent: pageIsCurrent),
                  ),
                  if (pageIsCurrent) Positioned(
                    left: TimetableLayout.leftMargin, 
                    child: LiveTimeIndicator(size: liveTimeIndicatorSize),
                  ),
                  if (pageIsCurrent) LiveTimeIndicatorLabel(size: liveTimeIndicatorLabelSize)
                  ],
                )
              ),
            );
          }
        );
      }
    );
  }
}