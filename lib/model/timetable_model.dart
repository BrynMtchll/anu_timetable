import 'package:anu_timetable/model/controllers.dart';
import 'package:flutter/material.dart';
import 'package:anu_timetable/widgets/day_view.dart';
import 'package:anu_timetable/widgets/week_bar.dart';
import 'package:anu_timetable/model/current_datetime_notifiers.dart';

class TimetableModel extends ChangeNotifier {

  /// All dates are mapped to pages for the respective [PageView]s
  /// implemented in [WeekBar] and [DayView].
  /// [WeekBar] pages are mapped to weeks, with the date 
  /// corresponding to the start of the week.
  /// [DayView] pages are mapped to dates one to one.
  static DateTime hashDate = weekOfDay(DateTime(2000, 0, 0));

  /// [WeekBar], [WeekView] and [DayView]'s [PageView]s are all synced.
  /// They're controllers are managed here so as to decouple them 
  /// from one another. 
  late DayViewPageController dayViewPageController;

  late WeekViewPageController weekViewPageController;

  late WeekBarPageController weekBarPageController;

  late TabController tabController;

  late DateTime _persistedActiveDay;

  /// The desired effect, when changing the [dayViewPageController.page] 
  /// by multiple days, is for the target page to be animated to
  /// as though it were the adjacent page.
  /// The default behaviour, however, is for all intermediate pages 
  /// to be animated between.
  /// 
  /// The hacky solution is implemented in [animateDirectToDayViewPage].
  /// It uses [dayOverride] to map the adjacent page to the date for 
  /// the target page, so that the target page can be temporarily copied 
  /// onto the adjacent page. 
  /// [dayOverride] is first checked when getting the [day].
  Map<int, dynamic> dayOverride = {};

  TimetableModel({
    required this.dayViewPageController, 
    required this.weekViewPageController, 
    required this.weekBarPageController,
    required this.tabController,
  }) {
    _persistedActiveDay = CurrentDay().value;
  }

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

  /// Returns the day view page corrosponding to the given date.
  /// The [WeekView] and [WeekBar] pages are mapped identically.
  static int weekViewPage(DateTime week) => 
    (week.difference(hashDate).inDays / 7).toInt();  
  
  /// Returns the week bar page corrosponding to the given date.
  static int weekBarPage(DateTime week) => 
    (week.difference(hashDate).inDays / 7).toInt();  
  /// Returns the monday of the week that the given date is in.
  static DateTime weekOfDay(DateTime day) => 
    day.subtract(Duration(days:  day.weekday - 1));

  /// Returns the monday of the week that the active date is in.
  DateTime get weekOfActiveDay {
   return weekOfDay(activeDay);
  } 

  /// Returns the day corrosponding to [dayViewPageController.page].
  /// [WeekBar] requires [activeDay] before [DayViewPageController] is attached
  /// to the [PageView] of [DayView].
  DateTime get activeDay {
    if (dayOverride.isNotEmpty) {
      return dayOverride.values.first;
    }
    return dayViewPageController.hasClients ? 
      day(dayViewPageController.page) : _persistedActiveDay;
  }
  
  /// Returns the monday of the week corrosponding to 
  /// [weekBarPageController.page].
  DateTime activeWeek() => week(weekBarPageController.page);
  
  /// Returns the day of the weekday for the given week.
  /// 
  /// 'Date' is suffixed to the function name to avoid ambiguity with the
  /// naming of weekday for the index, which follows [DateTime.weekday]
  DateTime weekdayDate(double weekBarPage, int weekday) => 
    week(weekBarPage).add(Duration(days: weekday - 1));
  
  /// TODO: fix comment
  /// Updates the [dayViewPageController.page], i.e. the active day,
  /// to the week given, maintaining the same weekday.
  void changeDayViewPage() { 
    DateTime newActiveDay = weekdayDate(weekBarPageController.page!, activeDay.weekday);
    if (activeDay != newActiveDay) {
      _persistedActiveDay = newActiveDay;
      animateDirectToDayViewPage(newActiveDay);
    }
  }

  /// Animates the [weekViewPageController.page] to the same page as
  /// [weekBarPageController.page].
  /// If the [weekViewPageController] has not yet been assigned to [WeekView]'s 
  /// [PageView], i.e. the week tab has not yet been made active, nothing is done.
  void changeWeekViewPage() {
    if (weekViewPageController.hasClients) {
      int newWeekViewPage = weekBarPageController.page!.round();
      int activeWeekViewPage = weekViewPageController.page!.round();
      if (newWeekViewPage != activeWeekViewPage) {
        weekViewPageController.animateToPage(
          newWeekViewPage, 
          duration: Duration(milliseconds: 400), 
          curve: Curves.easeInOut,
        );
      }
    }
  }
  
  /// TODO: fix comment
  /// Updates the [weekBarPageController.page], i.e. the active week,
  /// to the week containing the [dayViewPageController.page] (the active day).
  void changeWeekBarPage() {
    int newWeekBarPage;
    if (tabController.index == 0) {
      newWeekBarPage = weekBarPage(weekOfActiveDay);
    } else {
      newWeekBarPage = weekViewPageController.page!.round();
    }
    print(weekBarPageController.page!);
    int activeWeekBarPage = weekBarPageController.page!.round();
    if (newWeekBarPage != activeWeekBarPage) {
      weekBarPageController.animateToPage(
        newWeekBarPage, 
        duration: Duration(milliseconds: 400), 
        curve: Curves.easeInOut,
      );
    }
  }

  /// Functionality for the hacky solution to animate to 
  /// a non adjacent day, skipping intermediate days.
  /// Steps:
  ///   1.  Set the date for the adjacent day view page of the same side
  ///       to that of the target page by adding it to [dayOverride].
  ///   2.  Animate to the adjacent page.
  ///   3.  Jump to the target page and remove the override date from 
  ///       [dayOverride].
  animateDirectToDayViewPage(DateTime newActiveDay) async {

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
    notifyListeners();

    await dayViewPageController.animateToPage(
      adjacentDayViewPage,
      curve: Curves.easeInOut,
      duration: Duration(milliseconds: 400),
    );

    dayOverride.remove(adjacentDayViewPage);
    dayViewPageController.jumpToPage(dayViewPage(newActiveDay));
  }

  /// Handler for the onTap event of the [DayView]'s weekday items.
  void handleWeekBarWeekdayTap(int page, int weekday) async {
    if (tabController.index == 0) {
    DateTime newActiveDay = weekdayDate(page.toDouble(), weekday);
    // _persistedActiveDay = newActiveDay;

    await animateDirectToDayViewPage(newActiveDay);
    notifyListeners();
    }
  }

  /// Handler for the onPageChanged event of the [DayView]'s [PageView].
  void handleDayViewPageChanged() {
    if (tabController.index == 0) {
      changeWeekViewPage();
      changeWeekBarPage();
      notifyListeners();
    }
  }

  /// Handler for the onPageChanged event of the [WeekView]'s [PageView].
  void handleWeekViewPageChanged() {
    if (tabController.index == 1) {
      changeDayViewPage();
      changeWeekBarPage();
      notifyListeners();
    }
  }

  /// Handler for the onPageChanged event of the [WeekBar]'s [PageView].
  void handleWeekBarPageChanged() {
    changeDayViewPage();
    changeWeekViewPage();
    notifyListeners();
  }
}