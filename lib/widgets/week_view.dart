import 'package:anu_timetable/model/controllers.dart';
import 'package:anu_timetable/widgets/live_time_indicator.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:anu_timetable/model/timetable_model.dart';
import 'package:anu_timetable/widgets/hour_lines.dart';
import 'package:anu_timetable/widgets/day_lines.dart';
import 'package:anu_timetable/model/timetable_layout.dart';
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
        Size size = Size(constraints.maxWidth, TimetableLayout.height);
        return Consumer2<TimetableModel, CurrentDay>(
          builder: (context, timetableModel, currentDay, child) { 
          bool pageIsCurrent = timetableModel.activeWeek() == TimetableModel.weekOfDay(currentDay.value);
          
          return SingleChildScrollView(
              child:  Row(
              children: [
                HourLineLabels(
                  size: Size(TimetableLayout.leftMargin, TimetableLayout.height), 
                  pageIsCurrent: pageIsCurrent
                ),
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: TimetableLayout.height,
                    maxWidth: constraints.maxWidth - TimetableLayout.leftMargin,
                  ),
                  
              child: PageView.builder(
                controller: Provider.of<WeekViewPageController>(context, listen: false),
                onPageChanged: (page) {
                  Provider.of<TimetableModel>(context, listen: false)
                    .handleWeekViewPageChanged();
                },
                itemBuilder: (context, page) => Stack(
                children: [
                  HourLines(size: size, pageIsCurrent: pageIsCurrent),
                  DayLines(size: size),
                  if (pageIsCurrent)
                    LiveTimeIndicator(
                      size: size,
                    )
                  ],
                )
              )
              ),
              ]
            ),
            
            );
          }
        );
      }
    );
  }
}