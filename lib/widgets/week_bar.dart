import 'package:anu_timetable/model/controllers.dart';
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
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

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
      child: IntrinsicHeight(child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          for (int weekday = 1; weekday <= DateTime.daysPerWeek; weekday++) 
            _Weekday(day: DateTime(week.year, week.month, week.day + weekday - 1)),
        ])));
  }
}

/// Widget for each day of the week bar, i.e. each item of the page.
class _Weekday extends StatelessWidget {
  final DateTime day;
  const _Weekday({required this.day});

  Color _weekdayItemColor(BuildContext context, TimetableModel timetableModel) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    if (Provider.of<ViewTabController>(context).index != 0) return colorScheme.surfaceContainerLow;
    return day == timetableModel.activeDay ? colorScheme.surfaceContainerHighest : colorScheme.surfaceContainerLow;
  }

  Color? _weekdayItemTextColor(BuildContext context, TimetableModel timetableModel) {
    if (Provider.of<ViewTabController>(context).index != 0) return null;
    ColorScheme colorScheme = Theme.of(context).colorScheme;
    return day == timetableModel.activeDay ? colorScheme.onPrimary : colorScheme.onSurface;
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    TimetableModel timetableModel = Provider.of<TimetableModel>(context);
    return GestureDetector(
      onTap: () {
        timetableModel.handleWeekBarDayTap(day);
      },
      child: Column(
        children: [
          SizedBox(
            height: TimetableLayout.weekdayLabelSize,
            width: TimetableLayout.weekdayLabelSize,
            child: Align(
              alignment: Alignment.center,
              child: Text(
                style: TextStyle(
                  color: colorScheme.secondary,
                  fontWeight: FontWeight.w600,
                  fontSize: 11,
                ),
                TimetableLayout.weekdayCharacters(day.weekday)))),
          Consumer<TimetableModel>(
            builder: (BuildContext context, TimetableModel timetableModel, Widget? child) => 
              Container(
                width: TimetableLayout.barDayHeight,
                height: TimetableLayout.barDayHeight,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: _weekdayItemColor(context, timetableModel)),
                child: Align(
                  alignment: Alignment.center,
                  child:  Text(
                    style: TextStyle(
                      fontWeight: FontWeight.w400,
                      color: day == timetableModel.activeDay ? colorScheme.onSurface : colorScheme.onSurface,
                      fontSize: 14),
                    day.day.toString()))))
          ]));
  }
}
