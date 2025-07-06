import 'package:anu_timetable/model/controllers.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:anu_timetable/model/timetable_model.dart';
import 'package:anu_timetable/util/timetable_layout.dart';

class MonthBar extends StatefulWidget {
  const MonthBar({super.key});
  @override
  State<MonthBar> createState() => _MonthBarState();
}

class _MonthBarState extends State<MonthBar>{
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
    return Consumer<MonthBarPageController>(
      builder: (BuildContext context, MonthBarPageController monthBarPageController, Widget? child) { 
        return Align(
          alignment: Alignment.topRight,
          child: AnimatedContainer(
            duration: Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            height: monthBarPageController.height,
            decoration: BoxDecoration(
              color: colorScheme.surface,
              border: Border(
                bottom: BorderSide(color: colorScheme.onSurface, width: 0.2))),
            child: NotificationListener<UserScrollNotification>(
              onNotification: Provider.of<TimetableModel>(context, listen: false).onMonthBarNotification,
              child: PageView.builder(
                controller: Provider.of<MonthBarPageController>(context, listen: false),
                onPageChanged: (page) {
                  Provider.of<TimetableModel>(context, listen: false)
                    .handleMonthBarPageChanged();
                },
                itemBuilder: (context, page) {
                  return(_Month(month: TimetableModel.month(page.toDouble())));
                }))));
      });
  }
}

class _Month extends StatelessWidget {
  final DateTime month;
  const _Month({required this.month});
  
  @override
  Widget build(BuildContext context) {
    DateTime firstWeekOfMonth = TimetableModel.weekOfDay(month);
    return OverflowBox( 
        maxHeight: double.infinity,
        alignment: Alignment.topCenter,
        minHeight: 0,
        child: Column(
        children: [
          _WeekdayLabels(),
          for (int r = 0; r < TimetableLayout.monthRows(month); r++) _Week(
            month: month,
            week: DateTime(firstWeekOfMonth.year, firstWeekOfMonth.month, firstWeekOfMonth.day + r*7))
        ]));
  }
}

class _WeekdayLabels extends StatelessWidget {
  const _WeekdayLabels();

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    return Align(
      alignment: Alignment.center,
      child: IntrinsicHeight(child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          for (int weekday = 1; weekday <= DateTime.daysPerWeek; weekday++) 
            Container(
              width: 30, // matching weekbar
              padding: EdgeInsets.all(2),
              child: Align(
                alignment: Alignment.center,
                child: Text(
                  style: TextStyle(
                    color: colorScheme.secondary,
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
                  ),
                  TimetableLayout.weekdayCharacters(weekday)))),
        ])));
  }
}

class _Week extends StatelessWidget {
  final DateTime month;
  final DateTime week;
  const _Week({required this.month, required this.week});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.center,
      child: IntrinsicHeight(child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          for (int weekday = 1; weekday <= DateTime.daysPerWeek; weekday++) 
            _Weekday(month: month, day: DateTime(week.year, week.month, week.day + weekday - 1)),
        ])));
  }
}

class _Weekday extends StatelessWidget {
  final DateTime month;
  final DateTime day;
  const _Weekday({required this.month, required this.day});

  Color _weekdayItemColor(BuildContext context, TimetableModel timetableModel) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    // if (Provider.of<ViewTabController>(context).index != 0) return colorScheme.surface;
    // DateTime weekdayDate = TimetableModel.weekdayDate(page.toDouble(), weekday);
    return day == timetableModel.activeDay  && day.month == month.month ? colorScheme.inverseSurface : colorScheme.surface;
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    return Consumer<TimetableModel>(
      builder: (BuildContext context, TimetableModel timetableModel, Widget? child) => 
        GestureDetector(
          onTap: () {
            timetableModel.handleMonthBarDayTap(day);
          },
          child: Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: _weekdayItemColor(context, timetableModel), 
                width: 0.5)),
            child: Align(
              alignment: Alignment.center,
              child:  Text(
                style: TextStyle(
                  fontWeight: FontWeight.w400,
                  color: colorScheme.onSurface,
                  // color: _weekdayItemTextColor(timetableModel, page, weekday),
                  fontSize: 14),
                  day.month == month.month ? day.day.toString() : "")))));
  }
}