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
    return Container(
      alignment: Alignment.topRight,
      color: colorScheme.surfaceContainerLow,
      child: Container(
        height: TimetableLayout.weekBarHeight,
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: colorScheme.onSurface, width: 0.2))),
        child: NotificationListener<UserScrollNotification>(
          onNotification: Provider.of<TimetableModel>(context, listen: false).onWeekBarNotification,
          child: PageView.builder(
            controller: Provider.of<WeekBarPageController>(context, listen: false),
            onPageChanged: (page) {
              Provider.of<TimetableModel>(context, listen: false)
                .handleWeekBarPageChanged();
            },
            itemBuilder: (context, page) {
              return AnimatedPadding(
                duration: Duration(milliseconds: 200),
                curve: Curves.easeInOut,
                padding: Provider.of<ViewTabController>(context, listen: false).index == 1 ? 
                  EdgeInsets.only(left: TimetableLayout.leftMargin) : EdgeInsets.all(0),
                child: _Week(week: TimetableModel.week(page.toDouble())));
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

/// Widget for each day of the week bar, i.e. each item of the page.
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
