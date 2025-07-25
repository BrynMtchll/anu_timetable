import 'package:anu_timetable/model/animation_notifiers.dart';
import 'package:anu_timetable/model/controllers.dart';
import 'package:anu_timetable/model/timetable_model.dart';
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

    Animation<double> opacity = Tween<double> (
        begin: 0,
        end: 1,
      ).animate(CurvedAnimation(
          parent: _controller,
          curve: Interval(0.65, 0.9, curve: Curves.easeInOut)));

    // _scrollController.animateTo(400, duration: Duration(seconds: 2), curve: Curves.linear);

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) => Opacity(
        opacity: opacity.value,
        child: SizedBox(
          height: TimetableLayout.monthListHeight,
          child: Consumer<MonthListScrollController>(
            builder: (BuildContext context, MonthListScrollController monthListScrollController, Widget? child) => 
              ListView(
                controller: monthListScrollController,
                scrollDirection: Axis.horizontal,
                children: [
                  for (int year = TimetableModel.hashDate.year; year < TimetableModel.endDate.year; year++)
                    Container(
                      width: TimetableLayout.monthListYearWidth,
                      height: TimetableLayout.monthListHeight,
                      padding: EdgeInsets.symmetric(vertical: 5),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
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
          child: Container(
        width: TimetableLayout.monthListMonthWidth,
        height: TimetableLayout.monthListHeight,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: monthIsActive(timetableModel.activeDay) ? colorScheme.inverseSurface : null,
          border: Border.all(color: colorScheme.onSurface, width: 0.5),
          borderRadius: BorderRadius.circular(5),
        ),
        child: Text(
          style: TextStyle(
            fontWeight: monthIsActive(timetableModel.activeDay) ? FontWeight.w600 : FontWeight.w400,
            color: monthIsActive(timetableModel.activeDay) ? colorScheme.onInverseSurface : null,
            fontSize: 11,
          ),
          TimetableLayout.monthString(month),
        ))));
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
      width: TimetableLayout.monthListYearLabelWidth,
      alignment: Alignment.center,
      height: TimetableLayout.monthListHeight,
      child: Text(
        style: TextStyle(
          fontWeight: FontWeight.w400,
          fontSize: 12),
        year.toString()
    ));
  }
}
