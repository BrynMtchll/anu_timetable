import 'package:anu_timetable/model/current_datetime_notifiers.dart';
import 'package:anu_timetable/model/timetable_model.dart';
import 'package:anu_timetable/util/timetable_layout.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class WeekdayLabels extends StatelessWidget {
  const WeekdayLabels({super.key});

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    return Container(
      color: colorScheme.surfaceContainerLow,
      alignment: Alignment.center,
      child: IntrinsicHeight(child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          for (int weekday = 1; weekday <= DateTime.daysPerWeek; weekday++)
            SizedBox(
              width: TimetableLayout.weekdayLabelSize,
              height: TimetableLayout.weekdayLabelSize,
              child: Align(
                alignment: Alignment.center,
                child: Text(
                  style: TextStyle(
                    color: colorScheme.secondary,
                    fontWeight: FontWeight.w600,
                    fontSize: 11),
                  TimetableLayout.weekdayCharacters(weekday)))),
        ])));
  }
}

class BarDayItem extends StatelessWidget {
  final DateTime day;
  const BarDayItem({super.key, required this.day});

  Color backgroundColor(ColorScheme colorScheme, bool dayIsActive, dayIsCurrent) {
    if (dayIsActive && dayIsCurrent) {
      return colorScheme.primary;
    }
    else if (dayIsActive) {
      return colorScheme.inverseSurface;
    }
    else {
      return colorScheme.surfaceContainerLow;
    }
  }
  Color textColor(ColorScheme colorScheme, bool dayIsActive, bool dayIsCurrent) {
    if (dayIsActive && dayIsCurrent) {
      return colorScheme.onPrimary;
    }
    else if (dayIsCurrent) {
      return colorScheme.primary;
    }
    else if (dayIsActive) {
       return colorScheme.onInverseSurface;
    }
    else {
      return colorScheme.onSurface;
    }
    // return dayIsActive ? colorScheme.onInverseSurface : colorScheme.onSurface;
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    return Consumer2<TimetableModel, CurrentDay>(
      builder: (BuildContext context, TimetableModel timetableModel, CurrentDay currentDay, Widget? child) {
        bool dayIsCurrent = TimetableModel.dayEquiv(day, currentDay.value);
        bool dayIsActive = TimetableModel.dayEquiv(day, timetableModel.activeDay);
        return AnimatedContainer(
          duration: Duration(milliseconds: 200),
          width: TimetableLayout.barDayHeight,
          height: TimetableLayout.barDayHeight,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: backgroundColor(colorScheme, dayIsActive, dayIsCurrent)),
          child: Align(
            alignment: Alignment.center,
            child:  Text(
              style: TextStyle(
                fontWeight: dayIsActive || dayIsCurrent ? FontWeight.w800 : FontWeight.w400,
                color: textColor(colorScheme, dayIsActive, dayIsCurrent),
                fontSize: 14),
              day.day.toString())));
      });
  }
}