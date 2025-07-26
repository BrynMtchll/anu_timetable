import 'dart:ui';
import 'package:anu_timetable/model/timetable_model.dart';
import 'package:flutter/material.dart';

class TimetableLayout {
  static const double leftMargin = 50;

  static const double height = 1700;

  static const double tabBarHeight = 30;

  static const double weekBarHeight = 60;

  static const double barDayHeight = 30;

  static const double weekdayLabelSize = 20;

  /// An even segment for each of the 24 hours of the day,
  /// plus a half hour top and bottom for padding.
  static const double hourHeight = height / 25;

  static const double vertPadding = hourHeight / 2;

  static const double dayHeight = height - 2 * vertPadding;

  static final Size innerSize = Size(screenWidth - leftMargin, height);

  static const Size marginSize = Size(leftMargin, height);

  static final Size size = Size(screenWidth, height);

  static const double minuteHeight = hourHeight / 60;

  static const double lineStrokeWidth = 0.2;
  static const double liveLineStrokeWidth = 1.5;

  static const double monthListHeight = 35;
  static const double monthListMonthWidth = 70;
  static const double monthListYearWidth 
    = monthListMonthWidth * 12 + monthListYearLabelWidth + monthListMonthGap * 12;
  static const double monthListMonthGap = 5;
  static const double monthListYearLabelWidth = 40;

  static double monthListMonthOffset(DateTime day) {
    double yearOffset = (day.year - TimetableModel.hashDate.year) * monthListYearWidth;
    double monthOffset = (day.month-1) * monthListMonthWidth + monthListYearLabelWidth + monthListMonthGap * (day.month-1);
    return yearOffset + monthOffset;
  }

  static Size get screenSize {
    FlutterView view = WidgetsBinding.instance.platformDispatcher.views.first;
    return view.physicalSize / view.devicePixelRatio;
  }

  static double get screenWidth {
    return screenSize.width;
  }

  /// The number of distinct weeks that the month spans, including partial.
  static int monthRows(DateTime month) {
    month = TimetableModel.monthOfDay(month);
    int days = DateUtils.getDaysInMonth(month.year, month.month);
    int weekday = month.weekday;
    return ((days + weekday - 1) / 7).ceil();
  }

  static int rowOfActiveDay(DateTime activeDay, DateTime month) =>
    ((activeDay.day + month.weekday - 1)/ 7).ceil();

  static double monthBarHeight(DateTime activeMonth) {
    return monthListHeight + weekdayLabelSize + monthRows(activeMonth) * barDayHeight;}
    
  static double monthBarMonthHeight(double monthBarHeight) => 
    monthBarHeight - monthListHeight;

  static double vertOffset(int totalMinutes) {
    return minuteHeight * totalMinutes + vertPadding;
  }

  static Color weekdayBackgroundColor(BuildContext context, ColorScheme colorScheme, TimetableModel timetableModel, DateTime day) {
    // if (Provider.of<ViewTabController>(context).index != 0) return colorScheme.surfaceContainerLow;
    return day == timetableModel.activeDay ? colorScheme.inverseSurface : colorScheme.surfaceContainerLow;
  }
  static Color weekdayTextColor(BuildContext context, ColorScheme colorScheme, TimetableModel timetableModel, DateTime day) {
    // if (Provider.of<ViewTabController>(context).index != 0) return colorScheme.onSurface;
    return day == timetableModel.activeDay ? colorScheme.onInverseSurface : colorScheme.onSurface;
  }

  static String weekdayCharacters(int weekday){
    switch (weekday) {
      case DateTime.monday: return 'M';
      case DateTime.tuesday: return 'Tu';
      case DateTime.wednesday: return 'W';
      case DateTime.thursday: return 'Th';
      case DateTime.friday: return 'F';
      case DateTime.saturday: return 'Sa';
      case DateTime.sunday: return 'Su';
      default: return '';
    }
  }

  static String monthString(int month) {
    switch (month) {
      case DateTime.january: return 'January';
      case DateTime.february: return 'February';
      case DateTime.march: return 'March';
      case DateTime.april: return 'April';
      case DateTime.may: return 'May';
      case DateTime.june: return 'June';
      case DateTime.july: return 'July';
      case DateTime.august: return 'August';
      case DateTime.september: return 'September';
      case DateTime.october: return 'October';
      case DateTime.november: return 'November';
      case DateTime.december: return 'December';
      default: return '';
    }
  }
}