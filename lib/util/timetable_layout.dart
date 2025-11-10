import 'dart:ui';
import 'package:anu_timetable/model/timetable_model.dart';
import 'package:anu_timetable/util/month_list_layout.dart';
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

  static const double monthRowSpacing = 4;

  static double initialScrollOffset = TimetableLayout.vertPadding + (DateTime.now().hour - 4) * TimetableLayout.hourHeight;

  static Size get screenSize {
    FlutterView view = WidgetsBinding.instance.platformDispatcher.views.first;
    return view.physicalSize / view.devicePixelRatio;
  }

  static double get screenWidth {
    return screenSize.width;
  }

  /// The number of weeks that the month spans, 
  /// including weeks partially spanned.
  static int monthWeeks(DateTime month) {
    month = TimetableModel.monthOfDay(month);
    int days = DateUtils.getDaysInMonth(month.year, month.month);
    int weekday = month.weekday;
    return ((days + weekday - 1) / 7).ceil();
  }

  /// Enumeration for the week containing the given day within the month
  /// i.e. the offset from the week containing the first day of the month.
  /// it's 1 indexed; 1 is returned for the week containing the first day of the month.
  static int monthWeek(DateTime day, DateTime month) =>
    ((day.day + month.weekday - 1)/ 7).ceil();

  static double monthBarRowsHeight(DateTime activeMonth) {
    int weeks = monthWeeks(activeMonth);
    return weeks * barDayHeight + (weeks -1) * monthRowSpacing;
  }
  static double monthBarHeight(DateTime activeMonth) 
    => MonthListLayout.height + weekdayLabelSize + monthBarRowsHeight(activeMonth);
    
  static double monthBarMonthHeight(double monthBarHeight) => 
    monthBarHeight - MonthListLayout.height;

  static double vertOffset(int totalMinutes) {
    return minuteHeight * totalMinutes + vertPadding;
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