import 'dart:ui';
import 'package:flutter/material.dart';

class TimetableLayout {
  static final double leftMargin = 50;

  static final double height = 1700;

  static final double tabBarHeight = 45;

  static final double weekBarHeight = 70;

  /// An even segment for each of the 24 hours of the day,
  /// plus a half hour top and bottom for padding.
  static final double hourHeight = height / 25;

  static final double vertPadding = hourHeight / 2;

  static final double dayHeight = height - 2 * vertPadding;

  static final Size innerSize = Size(screenWidth - leftMargin, height);

  static final Size marginSize = Size(leftMargin, height);

  static final Size size = Size(screenWidth, height);

  static final double minuteHeight = hourHeight / 60;

  static Size get screenSize {
    FlutterView view = WidgetsBinding.instance.platformDispatcher.views.first;
    return view.physicalSize / view.devicePixelRatio;
  }

  static double get screenWidth {
    return screenSize.width;
  }

  /// The number of distinct weeks that the month spans, including partial.
  static int monthRows(DateTime month) {
    int days = DateUtils.getDaysInMonth(month.year, month.month);
    int weekday = month.weekday;
    return ((days + weekday - 1) / 7).ceil();
  }

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