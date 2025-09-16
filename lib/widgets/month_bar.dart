import 'package:anu_timetable/model/animation_notifiers.dart';
import 'package:anu_timetable/model/controllers.dart';
import 'package:anu_timetable/widgets/bar_day.dart';
import 'package:anu_timetable/widgets/month_list.dart';
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
  Widget build(BuildContext context) {
    ColorScheme colorScheme = Theme.of(context).colorScheme;
    TimetableModel timetableModel = Provider.of<TimetableModel>(context, listen: false);
    ViewTabController viewTabController = Provider.of<ViewTabController>(context, listen: false);
    MonthBarPageController monthBarPageController = Provider.of<MonthBarPageController>(context, listen: false);
    
    return Consumer<MonthBarAnimationNotifier>(
      builder: (BuildContext context, MonthBarAnimationNotifier monthBarAnimationNotifier, Widget? child) { 
        return Align(
          alignment: Alignment.topRight,
          child: AnimatedContainer(
            duration: Duration(milliseconds: MonthBarAnimationNotifier.duration),
            curve: Curves.easeInOut,
            height: monthBarAnimationNotifier.displayHeight,
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerLow,
              border: Border(
                bottom: BorderSide(color: colorScheme.onSurface, width: 0.2))),
            child: OverflowBox(
              maxHeight: double.infinity,
              alignment: Alignment.topCenter,
              minHeight: monthBarAnimationNotifier.height,
                child: Column(
                  children: [
                    AnimatedContainer(
                      duration: Duration(milliseconds: MonthBarAnimationNotifier.duration),
                      height: TimetableLayout.monthBarMonthHeight(monthBarAnimationNotifier.height),
                      child: NotificationListener<UserScrollNotification>(
                        onNotification: timetableModel.onMonthBarNotification,
                        child: PageView.builder(
                          controller: monthBarPageController,
                          onPageChanged: (page) {
                            monthBarAnimationNotifier.height = TimetableLayout.monthBarHeight(
                              TimetableModel.month(page.toDouble()));
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
                                monthBarAnimationNotifier: monthBarAnimationNotifier))))),
                    AnimatedOpacity(
                      opacity: monthBarAnimationNotifier.open ? 1 : 0,
                      duration: Duration(milliseconds: MonthBarAnimationNotifier.duration),
                      child: MonthList(monthBarAnimationNotifier: monthBarAnimationNotifier)),
                  ]))));
      });
  }
}

class _Month extends StatefulWidget {
  final DateTime month;
  final MonthBarAnimationNotifier monthBarAnimationNotifier;

  const _Month({required this.month, required this.monthBarAnimationNotifier});

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
      duration: Duration(milliseconds: MonthBarAnimationNotifier.duration),
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
    int weeks = TimetableLayout.monthWeeks(widget.month);
    int activeWeekIndex = TimetableLayout.monthWeek(timetableModel.activeDay, widget.month);

    widget.monthBarAnimationNotifier.open ? _controller.animateTo(1) :  _controller.animateTo(0);

    Animation<double> vOffset = Tween<double>(
      begin: -(activeWeekIndex - 1) * TimetableLayout.barDayHeight, end: 0)
      .animate(CurvedAnimation(
        parent: _controller, 
        curve: Interval(0.0, 1, curve: Curves.easeInOut)));

    Animation<double> opacity(int weekIndex) => Tween<double> (
      begin: weekIndex != (activeWeekIndex- 1) ? 0 : 1, end: 1)
      .animate(CurvedAnimation(
        parent: _controller, 
        curve: Interval(
          activeWeekIndex == 1 ? 0.5 - ((weekIndex / weeks) /8) : 0.5 - ((weekIndex / weeks) /4),
          1 - ((weekIndex / weeks) /8),
          curve: Curves.easeInOut)));
    
    return OverflowBox(
      maxHeight: double.infinity,
      alignment: Alignment.topCenter,
      minHeight: 0,
      child: Column(
        children: [
          WeekdayLabels(),
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) =>
              ClipRect(
                child: Transform.translate(
                  offset: Offset(0, vOffset.value),
                  child: Column(
                    children: [
                      for (int i = 0; i < weeks; i++) Opacity(
                        opacity: opacity(i).value,
                        child: _Week(
                          month: widget.month,
                          week: DateTime(firstWeekOfMonth.year, firstWeekOfMonth.month, 
                            firstWeekOfMonth.day + i*7)))
                    ]))))
      ]));
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

  @override
  Widget build(BuildContext context) {
    if (day.month != month.month) {
      return SizedBox(
        width: TimetableLayout.barDayHeight,
        height: TimetableLayout.barDayHeight
      );
    }
    final TimetableModel timetableModel = Provider.of<TimetableModel>(context, listen: false);
    return GestureDetector(
      onTap: () {
        timetableModel.handleMonthBarDayTap(day);
      },
      child: BarDayItem(day: day));
  }
}