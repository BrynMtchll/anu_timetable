import 'package:anu_timetable/model/animation_notifiers.dart';
import 'package:anu_timetable/model/controllers.dart';
import 'package:anu_timetable/model/timetable_model.dart';
import 'package:anu_timetable/util/month_list_layout.dart';
import 'package:anu_timetable/util/timetable_layout.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class MonthList extends StatefulWidget {
  final MonthBarAnimationNotifier monthBarAnimationNotifier;

  const MonthList({super.key, required this.monthBarAnimationNotifier});

  @override
  State<MonthList> createState() => _MonthListState();
}

class _MonthListState extends State<MonthList> with TickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: MonthBarAnimationNotifier.duration));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    widget.monthBarAnimationNotifier.open ? _controller.animateTo(1) :  _controller.animateTo(0);

    Animation<double> opacity = Tween<double> (begin: 0, end: 1)
      .animate(CurvedAnimation(
        parent: _controller,
        curve: Interval(0.65, 0.9, curve: Curves.easeInOut)));

    Animation<double> vOffset = Tween<double>(begin: -60, end: 0)
      .animate(CurvedAnimation(
        parent: _controller,
        curve: Interval(0.4, 1, curve: Curves.easeInOut)));

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) => Transform.translate( 
        offset: Offset(0, vOffset.value),
        child: Opacity(
        opacity: opacity.value,
        child: SizedBox(
          height: MonthListLayout.height,
          child: Consumer<MonthListScrollController>(
            builder: (BuildContext context, MonthListScrollController monthListScrollController, Widget? child) => 
              ListView(
                controller: monthListScrollController,
                scrollDirection: Axis.horizontal,
                children: [
                  for (int year = TimetableModel.hashDate.year; year < TimetableModel.endDate.year; year++)
                    Container(
                      width: MonthListLayout.yearWidth,
                      height: MonthListLayout.height,
                      padding: EdgeInsets.symmetric(vertical: MonthListLayout.vertPadding, horizontal: MonthListLayout.yearGap/2),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _YearLabel(year: year),
                          for (int month = 1; month <= 12; month++)
                            _MonthButton(year: year, month: month, colorScheme: colorScheme)
                        ]))
                ]))))));
  }
}

class _MonthButton extends StatelessWidget {
  final int year;
  final int month;
  final ColorScheme colorScheme;

  const _MonthButton({
    required this.year,
    required this.month,
    required this.colorScheme,
  });

  bool monthIsActive(DateTime activeDay) => activeDay.year == year && activeDay.month == month;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    return Consumer<TimetableModel>(
        builder: (BuildContext context, TimetableModel timetableModel, Widget? child) => 
         GestureDetector(
          onTap: () {
            timetableModel.handleMonthListMonthTap(year, month);
          },
          child: AnimatedContainer(
            duration: Duration(milliseconds: 200),
            width: MonthListLayout.monthWidth,
            height: MonthListLayout.height,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: monthIsActive(timetableModel.activeDay) ? colorScheme.inverseSurface : null,
              border: Border.all(color: colorScheme.onSurface, width: 0.5),
              borderRadius: BorderRadius.circular(7)),
            child: Text(
              style: TextStyle(
                fontWeight: monthIsActive(timetableModel.activeDay) ? FontWeight.w600 : FontWeight.w400,
                color: monthIsActive(timetableModel.activeDay) ? colorScheme.onInverseSurface : null,
                fontSize: 12),
              TimetableLayout.monthStringAbbrev(month)))));
  }
}

class _YearLabel extends StatelessWidget {
  final int year;

  const _YearLabel({
    required this.year,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: MonthListLayout.yearLabelWidth,
      alignment: Alignment.center,
      height: MonthListLayout.height,
      child: Text(
        style: TextStyle(
          fontWeight: FontWeight.w400,
          fontSize: 12),
        year.toString()));
  }
}
