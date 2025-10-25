import 'package:anu_timetable/model/animation_notifiers.dart';
import 'package:anu_timetable/model/controllers.dart';
import 'package:anu_timetable/widgets/bar_day.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:anu_timetable/model/timetable_model.dart';
import 'package:anu_timetable/util/timetable_layout.dart';

class WeekBar extends StatefulWidget implements PreferredSizeWidget {
  const WeekBar({super.key});

  @override
  Size get preferredSize => Size.fromHeight(TimetableLayout.weekBarHeight);

  @override
  State<WeekBar> createState() => _WeekBarState();
}

class _WeekBarState extends State<WeekBar>{
  @override
  Widget build(BuildContext context) {
    ColorScheme colorScheme = Theme.of(context).colorScheme;
    TimetableModel timetableModel = Provider.of<TimetableModel>(context, listen: false);
    timetableModel.createWeekBarController();
    return Container(
      alignment: Alignment.topRight,
      color: colorScheme.surfaceContainerLow,
      child: Container(
        height: TimetableLayout.weekBarHeight,
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: colorScheme.onSurface, width: 0.2))),
        child: NotificationListener<UserScrollNotification>(
          onNotification: timetableModel.onWeekBarNotification,
          child: PageView.builder(
            controller: timetableModel.weekBarPageController,
            onPageChanged: (page) {
              timetableModel.handleWeekBarPageChanged();
            },
            itemBuilder: (context, page) {
              return Consumer<ViewTabController>(
                builder: (context, viewTabController, child) => AnimatedPadding(
                  duration: Duration(milliseconds: 200),
                  curve: Curves.easeInOut,
                  padding: viewTabController.index == 1 ? 
                    EdgeInsets.only(left: TimetableLayout.leftMargin) : EdgeInsets.all(0),
                  child: child),
                child: _Week(week: TimetableModel.getWeek(page.toDouble())));
            }))));
  }
}

class _Week extends StatelessWidget {
  final DateTime week;
  const _Week({required this.week});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: IntrinsicHeight(
        child: Column(
          children: [
            WeekdayLabels(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                for (int weekday = 1; weekday <= DateTime.daysPerWeek; weekday++) 
                  _Weekday(day: DateTime(week.year, week.month, week.day + weekday - 1)),
              ])
        ])));
  }
}

class _Weekday extends StatelessWidget {
  final DateTime day;
  const _Weekday({required this.day});

  @override
  Widget build(BuildContext context) {
    final TimetableModel timetableModel = Provider.of<TimetableModel>(context, listen: false);
      return GestureDetector(
        onTap: () {
          timetableModel.handleWeekBarDayTap(day);
        },
        child: BarDayItem(day: day));
  }
}
