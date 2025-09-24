import 'dart:math';
import 'package:anu_timetable/model/timetable_model.dart';
import 'package:anu_timetable/util/timetable_layout.dart';

class MonthListLayout {
  static const double vertPadding = 8;

  static const double height = 37 + vertPadding;

  static const double monthWidth = 55;

  static const double yearWidth
    = monthWidth * 12 + yearLabelWidth + monthGap * 12 + yearGap;

  static const double monthGap = 10;

  static const double yearGap = 10;

  static const double yearLabelWidth = 40;

  static double leftOffset(DateTime day) {
    double yearOffset = (day.year - TimetableModel.hashDate.year) * (yearWidth);
    double monthOffset = (day.month-1) * monthWidth + yearLabelWidth + monthGap * (day.month-1);
    return yearOffset + monthOffset + yearGap/2;
  }

  static double rightOffset(DateTime day) {
    return  max(0, leftOffset(day) - (TimetableLayout.screenWidth - monthWidth - 2*monthGap) - 1);
  }
}