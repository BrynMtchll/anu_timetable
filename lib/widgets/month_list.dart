import 'package:anu_timetable/model/animation_notifiers.dart';
import 'package:anu_timetable/model/current_datetime_notifiers.dart';
import 'package:anu_timetable/model/timetable_model.dart';
import 'package:anu_timetable/util/month_list_layout.dart';
import 'package:anu_timetable/util/timetable_layout.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class MonthList extends StatefulWidget {
  const MonthList({super.key});

  @override
  State<MonthList> createState() => _MonthListState();
}

class _MonthListState extends State<MonthList> with TickerProviderStateMixin {
  late final AnimationController _controller;
  late Animation<Offset> _offset;
  late Animation<double> _opacity;
  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: MonthBarAnimationNotifier.duration));

    _offset = Tween<Offset>(begin: Offset(0, -3), end: Offset.zero)
      .animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    _opacity = Tween<double> (begin: 0, end: 1)
      .animate(CurvedAnimation(parent: _controller, curve: Interval(0.5, 1)));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    TimetableModel timetableModel = Provider.of<TimetableModel>(context, listen: false);
    timetableModel.createMonthListScrollController();
    return Consumer<MonthBarAnimationNotifier>(
      builder: (context, monthBarAnimationNotifier, child) {
        if (monthBarAnimationNotifier.open && monthBarAnimationNotifier.expanded) {
          _controller.value = 1;
        }
        else if (monthBarAnimationNotifier.open) {
          _controller.animateTo(1);
        }
        else {
          _controller.animateTo(0);
        }

        return AnimatedOpacity(
          opacity: monthBarAnimationNotifier.open ? 1 : 0,
          duration: Duration(milliseconds: MonthBarAnimationNotifier.duration),
          child: child);
      },
      child: SlideTransition(
        position: _offset,
        child: AnimatedBuilder(
          animation: _opacity,
          builder:(context, child) => Opacity(opacity: _opacity.value, child: child),
          child: SizedBox(
            height: MonthListLayout.height,
            child: ListView(
              controller: timetableModel.monthListScrollController,
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
              ])))));
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

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    return Consumer<TimetableModel>(
        builder: (BuildContext context, TimetableModel timetableModel, Widget? child) { 
          bool monthIsActive = timetableModel.activeDay.year == year && timetableModel.activeDay.month == month;
          return GestureDetector(
            onTap: () {
              timetableModel.handleMonthListMonthTap(DateTime(year, month), 
                Provider.of<CurrentDay>(context, listen: false).value);
            },
            child: AnimatedContainer(
              duration: Duration(milliseconds: 200),
              width: MonthListLayout.monthWidth,
              height: MonthListLayout.height,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: monthIsActive ? colorScheme.inverseSurface : null,
                border: Border.all(color: colorScheme.onSurface, width: 0.5),
                borderRadius: BorderRadius.circular(7)),
                child: Text(
                  style: TextStyle(
                    fontWeight: monthIsActive ? FontWeight.w700 : FontWeight.w400,
                    color: monthIsActive ? colorScheme.onInverseSurface : null,
                    fontSize: 12),
                  TimetableLayout.monthStringAbbrev(month))));
        });
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
