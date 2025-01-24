import 'package:anu_timetable/widgets/controllers.dart';
import 'package:flutter/material.dart';
import 'package:anu_timetable/widgets/day_view.dart';
import 'package:anu_timetable/widgets/week_bar.dart';

class TimetableModel extends ChangeNotifier {

  /// All dates are mapped to pages for the respective [PageView]s
  /// implemented in [WeekBar] and [DayView].
  /// [WeekBar] pages are mapped to weeks, with the date 
  /// corresponding to the start of the week.
  /// [DayView] pages are mapped to dates one to one.
  /// 
  static late DateTime hashDate = weekOfDay(DateTime(2000, 0, 0));

  late DayViewPageController dayViewPageController;

  late WeekBarPageController weekBarPageController;

  /// The desired effect, when changing the [dayViewPageController.page] 
  /// by multiple days, is for the target page to be animated to
  /// as though it were the adjacent page.
  /// The default behaviour, however, is for all intermediate pages 
  /// to be animated between.
  /// 
  /// The hacky solution is to 
  ///   1. temporarily copy the target page to the adjacent page, 
  ///   2. animate to that, and 
  ///   3. jump to the target page. 
  /// 
  /// the date corrosponding to the target page is 
  /// temporarily stored in [dayOverride] under the adjacent page index.
  /// [dayOverride] is then checked when getting the [day]
  /// for a day view page.
  Map<int, dynamic> dayOverride = {};

  TimetableModel({required this.dayViewPageController, required this.weekBarPageController});

  /// Returns the monday of the week corrosponding to the given 
  /// week bar page.
  DateTime week(double? weekBarPage) {
    if (weekBarPage == null) {
      throw ArgumentError("weekBarPage is null!");
    }
    return hashDate.add(Duration(days: (weekBarPage.round() * 7).round()));
  }

  /// Returns the day corrosponding to the given day view page.
  /// 
  /// Before [weekBarPageController] is assigned to the page view
  /// in [WeekBar], [weekBarPageController.page] is null.
  /// 
  /// The [WeekBar] weekday items require the day of the active page on
  /// initialisation, which is the current date.
  DateTime day(double? dayViewPage) {
    if (dayViewPage == null) {
      return day(dayViewPageController.initialPage.toDouble());
    }
    if (dayOverride.containsKey(dayViewPage.round())) {
      return dayOverride[dayViewPage.round()];
    }
    return hashDate.add(Duration(days: dayViewPage.round()));
  }

  /// Returns the day view page corrosponding to the given date.
  static int dayViewPage(DateTime day) => 
    day.difference(hashDate).inDays;
  
  /// Returns the week bar page corrosponding to the given date.
  static int weekBarPage(DateTime week) => 
    (week.difference(hashDate).inDays / 7).toInt();  
  /// Returns the monday of the week that the given date is in.
  static DateTime weekOfDay(DateTime day) => 
    day.subtract(Duration(days:  day.weekday - 1));

  /// Returns the monday of the week that the active date is in.
  DateTime weekOfActiveDay() => weekOfDay(activeDay());
  
  /// Returns the day corrosponding to [dayViewPageController.page].
  DateTime activeDay() => day(dayViewPageController.page);
  
  /// Returns the monday of the week corrosponding to 
  /// [weekBarPageController.page].
  DateTime activeWeek() => week(weekBarPageController.page);
  
  /// Returns the day of the weekday for the given week
  DateTime weekday(double weekBarPage, int weekday) => 
    week(weekBarPage).add(Duration(days: weekday - 1));
  
  void changeDayViewPage(int weekBarPage) { 
    DateTime newActiveDay = weekday(weekBarPage.toDouble(), activeDay().weekday);
    if (activeDay() != newActiveDay) {
      animateDirectToDayViewPage(newActiveDay);
    }
  }
  
  void changeWeekBarPage() {
    int newWeekBarPage = weekBarPage(weekOfActiveDay());
    int activeWeekBarPage = weekBarPageController.page!.round();
    if (newWeekBarPage != activeWeekBarPage) {
      weekBarPageController.animateToPage(
        newWeekBarPage, 
        duration: Duration(milliseconds: 400), 
        curve: Curves.easeInOut,
      );
    }
  }

  animateDirectToDayViewPage(DateTime newActiveDay) async{
    DateTime activeDay = day(dayViewPageController.page);

    if (dayViewPageController.page == null) {
      throw AssertionError("dayViewPageController.page is null!");
    }

    int adjacentDayViewPage = dayViewPageController.page!.round();
    if (newActiveDay.isAfter(activeDay)) {
      adjacentDayViewPage++;
    } else {
      adjacentDayViewPage--;
    }

    dayOverride.addAll({adjacentDayViewPage: newActiveDay});

    await dayViewPageController.animateToPage(
      adjacentDayViewPage,
      curve: Curves.easeInOut,
      duration: Duration(milliseconds: 400),
    );

    dayOverride.remove(adjacentDayViewPage);
    dayViewPageController.jumpToPage(dayViewPage(newActiveDay));
  }

  void handleWeekBarPageChanged(int weekBarPage) {
    changeDayViewPage(weekBarPage);
    notifyListeners();
  }

  void handleDayViewPageChanged(int dayViewPage) {
    changeWeekBarPage();
    notifyListeners();
  }
}