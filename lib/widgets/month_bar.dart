import 'package:anu_timetable/model/animation_notifiers.dart';
import 'package:anu_timetable/model/controllers.dart';
import 'package:anu_timetable/model/current_datetime_notifiers.dart';
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
    return Consumer<MonthBarAnimationNotifier>(
      builder: (BuildContext context, MonthBarAnimationNotifier monthBarAnimationNotifier, Widget? child) {
        return AnimatedOpacity(
          opacity: monthBarAnimationNotifier.shrunk ? 0 : 1, 
          curve: Curves.linear,
          duration: Duration(milliseconds: 100),
          child: Visibility(
            maintainState: true,
            maintainAnimation: true,
            visible: monthBarAnimationNotifier.visible,
            child: Align(
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
                  child: child)))));
      },
      child: Column(children: [_MonthBarPageView(), MonthList()]));
  }
}

class _MonthBarPageView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {    
    TimetableModel timetableModel = Provider.of<TimetableModel>(context, listen: false);
    timetableModel.createMonthBarPageController();
    return Consumer<MonthBarAnimationNotifier>(
      builder: (context, monthBarAnimationNotifier, child) => AnimatedContainer(
        duration: Duration(milliseconds: MonthBarAnimationNotifier.duration),
        height: TimetableLayout.monthBarMonthHeight(monthBarAnimationNotifier.height),
        child: child),
      child: NotificationListener<UserScrollNotification>(
        onNotification: timetableModel.onMonthBarNotification,
        child: PageView.builder(
          controller: timetableModel.monthBarPageController,
          onPageChanged: (page) {
            Provider.of<MonthBarAnimationNotifier>(context, listen: false).height 
              = TimetableLayout.monthBarHeight(TimetableModel.getMonth(page.toDouble()));
            timetableModel.handleMonthBarPageChanged(
              Provider.of<CurrentDay>(context, listen: false).value);
          },
          itemBuilder: (context, page) => Consumer<ViewTabController>(
            builder: (context, viewTabController, child) => AnimatedPadding(
              duration: Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              padding: viewTabController.index == 1 ? 
                EdgeInsets.only(left: TimetableLayout.leftMargin) : EdgeInsets.all(0),
              child: child),
            child: _Month(month: TimetableModel.getMonth(page.toDouble()))))));
  }
}

class _Month extends StatefulWidget {
  final DateTime month;
  const _Month({required this.month});
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
    return OverflowBox(
      maxHeight: double.infinity,
      alignment: Alignment.topCenter,
      minHeight: 0,
      child: Column(
        children: [
          WeekdayLabels(),
          Consumer<MonthBarAnimationNotifier>(
            builder: (context, monthBarAnimationNotifier, _) => 
              _monthBarRowsBuilder(context, monthBarAnimationNotifier, _controller, widget.month))
      ]));
  }
}

Widget _monthBarRowsBuilder(BuildContext context, MonthBarAnimationNotifier monthBarAnimationNotifier, 
  AnimationController controller, DateTime month) {
  TimetableModel timetableModel = Provider.of<TimetableModel>(context, listen: false);
  int activeWeekIndex = TimetableLayout.monthWeek(timetableModel.activeDay, month);
  DateTime firstWeekOfMonth = TimetableModel.weekOfDay(month);
  int weeks = TimetableLayout.monthWeeks(month);

  double vOffsetFrac() {
    double offset = -(activeWeekIndex - 1) * (TimetableLayout.barDayHeight + TimetableLayout.monthRowSpacing);
    return offset / TimetableLayout.monthBarRowsHeight(month);  
  }

  Animation<Offset> offset = Tween<Offset> (begin: Offset(0, vOffsetFrac()), end: Offset.zero)
    .animate(CurvedAnimation(parent: controller,curve: Curves.easeInOut));

  Animation<double> opacity(int weekIndex) => Tween<double> (
    begin: weekIndex != (activeWeekIndex- 1) ? 0 : 1, end: 1)
    .animate(CurvedAnimation(
      parent: controller, 
      curve: Interval((weekIndex - (activeWeekIndex-1)).abs() / weeks, 1)));

  if (monthBarAnimationNotifier.open && monthBarAnimationNotifier.expanded) {
    controller.value = 1;
  }
  else if (monthBarAnimationNotifier.open) {
    controller.animateTo(1);
  }
  else {
    controller.animateTo(0);
  }

  return ClipRect(
    child: SlideTransition(
      position: offset,
      child:  Column(
        spacing: TimetableLayout.monthRowSpacing,
        children: [
          for (int i = 0; i < weeks; i++) AnimatedBuilder(
            animation: opacity(i),
            builder:(context, child) => Opacity(
              opacity: opacity(i).value, 
              child: child),
            child: _Week(
              month: month,
              week: DateTime(firstWeekOfMonth.year, firstWeekOfMonth.month, 
                firstWeekOfMonth.day + i*7)))
        ])));
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
    return GestureDetector(
      onTap: () {
        Provider.of<TimetableModel>(context, listen: false).handleMonthBarDayTap(day);
      },
      child: BarDayItem(day: day));
  }
}