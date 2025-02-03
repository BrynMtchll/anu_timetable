import 'package:anu_timetable/model/controllers.dart';
import 'package:anu_timetable/util/clippers.dart';
import 'package:anu_timetable/widgets/live_time_indicator.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:anu_timetable/model/timetable_model.dart';
import 'package:anu_timetable/widgets/hour_lines.dart';
import 'package:anu_timetable/widgets/day_lines.dart';
import 'package:anu_timetable/util/timetable_layout.dart';
import 'package:linked_scroll_controller/linked_scroll_controller.dart';
import 'package:anu_timetable/model/current_datetime_notifiers.dart';

class WeekView extends StatefulWidget {
  const WeekView({super.key});

  @override
  State<WeekView> createState() => _WeekViewState();
}

class _WeekViewState extends State<WeekView> with AutomaticKeepAliveClientMixin<WeekView>{
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
        Size pageSize = Size(constraints.maxWidth - TimetableLayout.leftMargin, TimetableLayout.height);
        Size marginSize = Size(TimetableLayout.leftMargin, TimetableLayout.height);
        return Consumer2<TimetableModel, CurrentDay>(
          builder: (context, timetableModel, currentDay, child) { 
          bool pageIsCurrent = timetableModel.activeWeekIsCurrent(currentDay);
          
          return SingleChildScrollView(
              child:  Row(
                children: [
                  Stack(
                    children: [
                      HourLineLabels(size: marginSize, pageIsCurrent: pageIsCurrent),
                      if (pageIsCurrent) LiveTimeIndicatorLabel(size: marginSize)
                    ],
                  ),
                  _WeekPageView(
                    size: pageSize, 
                    timetableModel: timetableModel, 
                    currentDay: currentDay,
                  )
                ]
              )
            );
          }
        );
      }
    );
  }
}

class _WeekPageView extends StatelessWidget {
  final Size size;

  final TimetableModel timetableModel;
  final CurrentDay currentDay;


  const _WeekPageView({
    super.key, 
    required this.size, 
    required this.timetableModel, 
    required this.currentDay
  });

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      clipper: HorizontalClipper(),
      child: SizedBox(
        width: size.width,
        height: size.height,
        child:  PageView.builder(
          clipBehavior: Clip.none,
          controller: Provider.of<WeekViewPageController>(context, listen: false),
          onPageChanged: (page) {
            Provider.of<TimetableModel>(context, listen: false)
              .handleWeekViewPageChanged();
          },
          itemBuilder: (context, page) {
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
    );
  }
}