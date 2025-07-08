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
    TimetableModel timetableModel = Provider.of<TimetableModel>(context, listen: false);
    ViewTabController viewTabController = Provider.of<ViewTabController>(context, listen: false);

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
              onNotification: timetableModel.onMonthBarNotification,
              child: PageView.builder(
                controller: monthBarPageController,
                onPageChanged: (page) {
                  timetableModel.handleMonthBarPageChanged();
                },
                itemBuilder: (context, page) =>
                  AnimatedPadding(
                    duration: Duration(milliseconds: 200),
                    curve: Curves.easeInOut,
                    padding: viewTabController.index == 1 ? 
                      EdgeInsets.only(left: TimetableLayout.leftMargin) : EdgeInsets.all(0),
                    child: _Month(
                      month: TimetableModel.month(page.toDouble()), 
                      monthBarPageController: monthBarPageController))))));
      });
  }
}

class _Month extends StatefulWidget {
  final DateTime month;
  final MonthBarPageController monthBarPageController;

  const _Month({required this.month, required this.monthBarPageController});

  @override
  State<_Month> createState() => _MonthState();
}

class _MonthState extends State<_Month> with TickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 200),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    DateTime firstWeekOfMonth = TimetableModel.weekOfDay(widget.month);
    TimetableModel timetableModel = Provider.of<TimetableModel>(context, listen: false);
    int rows = TimetableLayout.monthRows(widget.month);
    int rowOfActiveDay = TimetableLayout.rowOfActiveDay(timetableModel.activeDay, widget.month);

    widget.monthBarPageController.open ? _controller.animateTo(1) :  _controller.animateTo(0);

    Animation<double> vOffset = Tween<double>(
      begin: (TimetableLayout.barDayHeight - rowOfActiveDay * TimetableLayout.barDayHeight),
      end: 0,
    ).animate(CurvedAnimation(
      parent: _controller, 
      curve: Interval(
        0.0,
        1,
        curve: Curves.linear,
    )));

    Animation<double> opacity(int r, int rows) {
      return Tween<double> (
        begin: r != (rowOfActiveDay- 1) ? 0 : 1,
        end: 1,
      ).animate(
        CurvedAnimation(parent: _controller, curve: Interval(
          0.5 - ((r / rows) /2), 
          1- ((r / rows) /2),
          curve: Curves.linear,
        ))
      );
    }

    return OverflowBox(
      maxHeight: double.infinity,
      alignment: Alignment.topCenter,
      minHeight: 0,
      child: Column(
        children: [
          _WeekdayLabels(),
          AnimatedBuilder(
            animation: _controller,
          builder: (context, child) {
            return ClipRect(
              child: Transform.translate(
                offset: Offset(0, vOffset.value),
                child: Column(
                  children: [
                    for (int r = 0; r < rows; r++) Opacity(
                      opacity: opacity(r, rows).value,
                      child: _Week(
                        month: widget.month,
                        week: DateTime(firstWeekOfMonth.year, firstWeekOfMonth.month, firstWeekOfMonth.day + r*7)))
                  ])));
          })
        ]));
  }
}

class _WeekdayLabels extends StatelessWidget {
  const _WeekdayLabels();

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    return Container(
      color: colorScheme.surface,
      alignment: Alignment.center,
      child: IntrinsicHeight(child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          for (int weekday = 1; weekday <= DateTime.daysPerWeek; weekday++) 
            Container(
              width: TimetableLayout.barDayHeight,
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
            width: TimetableLayout.barDayHeight,
            height: TimetableLayout.barDayHeight,
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