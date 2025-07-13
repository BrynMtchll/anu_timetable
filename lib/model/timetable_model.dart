import 'package:anu_timetable/model/animation_notifiers.dart';
import 'package:anu_timetable/model/controllers.dart';
import 'package:anu_timetable/model/current_datetime_notifiers.dart';
import 'package:anu_timetable/widgets/day_view.dart';
import 'package:anu_timetable/widgets/week_bar.dart';
import 'package:anu_timetable/widgets/week_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

class TimetableModel extends ChangeNotifier {
  /// All dates are mapped to pages for the respective [PageView]s
  /// that are implemented in [WeekBar] and [DayView].
  /// [WeekBar] pages are mapped to weeks, with the date 
  /// corresponding to the start of the week.
  /// [DayView] pages are mapped to dates one to one.
  static DateTime hashDate = weekOfDay(DateTime(2025, 0, 0));

  /// [WeekBar], [WeekView] and [DayView]'s [PageView]s all affect one another.
  /// They're controllers are managed here so as to decouple them 
  /// from one another. 
  late DayViewPageController dayViewPageController;
  late WeekViewPageController weekViewPageController;
  late WeekBarPageController weekBarPageController;
  late MonthBarPageController monthBarPageController;

  late ViewTabController viewTabController;

  late DayViewScrollController dayViewScrollController;
  late WeekViewScrollController weekViewScrollController;

  late DateTime _persistedActiveDay = CurrentDay().value;

  TimetableModel({
    required this.dayViewPageController,
    required this.weekViewPageController,
    required this.weekBarPageController,
    required this.monthBarPageController,
    required this.viewTabController,
    required this.dayViewScrollController,
    required this.weekViewScrollController,
  }) {
    addListeners();
  }

  /// Returns the day corrosponding to [dayViewPageController.page].
  /// [WeekBar] requires [activeDay] before [DayViewPageController] is attached
  /// to the [PageView] of [DayView].
  DateTime get activeDay => 
    dayViewPageController.hasClients ? 
      day(dayViewPageController.page!) : _persistedActiveDay;
  
  /// Returns the monday of the week that the active date is in.
  DateTime get weekOfActiveDay {
   return weekOfDay(activeDay);
  }
  
  /// Returns the day corrosponding to the given day view page.
  static DateTime day(double dayPage) {
    return DateTime(hashDate.year, hashDate.month, hashDate.day + dayPage.round());
  }

  /// Returns the monday of the week corrosponding to the given 
  /// week bar page.
  static DateTime week(double? weekBarPage) {
    if (weekBarPage == null) {
      throw ArgumentError("weekBarPage is null!");
    }
    return DateTime(hashDate.year, hashDate.month, hashDate.day + (weekBarPage.round() * 7).round());
  }

  static DateTime month(double monthPage) {
    return DateTime(hashDate.year, hashDate.month + monthPage.round());
  }

  int dayPageToWeekPage(double dayPage) {
    return (dayPage.round() / 7).floor();
  }

  int weekPageToDayPage(double weekPage, int weekday) {
    return weekPage.round() * 7 + weekday;
  }

  int weekPageToMonthPage(double weekPage) {
    return getMonthPage(monthOfDay(week(weekPage)));
  }

  int dayPageToMonthPage(double dayPage) {
    return getMonthPage(monthOfDay(day(dayPage)));
  }

  /// Returns the day of the weekday for the given week.
  static DateTime dayOfWeek(double weekBarPage, int weekday) {
    DateTime week = TimetableModel.week(weekBarPage);
    return DateTime(week.year, week.month, week.day + weekday - 1);
  }

  /// Returns the monday of the week that the given date is in.
  static DateTime weekOfDay(DateTime day) => DateTime(day.year, day.month, day.day - day.weekday + 1);
  
  /// Returns the monday of the week that the given date is in.
  static DateTime monthOfDay(DateTime day) => DateTime(day.year, day.month);

  /// Returns the day view page corrosponding to the given date.
  static int getDayPage(DateTime day) => 
    day.difference(hashDate).inDays;

  /// Returns the week page corrosponding to the given date.
  static int getWeekPage(DateTime week) =>
    (week.difference(hashDate).inDays / 7).toInt();

  static int getMonthPage(DateTime month)
    => (month.year - hashDate.year) * 12 + month.month - hashDate.month;
  
  /// Returns true if the active day is the current day
  static bool dayIsCurrent(int page, CurrentDay currentDay) =>
    day(page.toDouble()) == currentDay.value;

  /// Returns true if the active day is the current day
  static bool weekIsCurrent(int page, CurrentDay currentDay) => 
    week(page.toDouble()) == weekOfDay(currentDay.value);

  /// Returns true if the active week contains the current day
  bool activeWeekIsCurrent(CurrentDay currentDay) => 
    weekOfActiveDay == weekOfDay(currentDay.value); 

  void syncDayViewPage(DateTime newActiveDay) {
    if (!dayViewPageController.hasClients) return;
    int newActiveDayPage = getDayPage(newActiveDay);
    int activeDayPage = dayViewPageController.page!.round();
    if (newActiveDayPage != activeDayPage) {
      _persistedActiveDay = newActiveDay;
      dayViewPageController.animateDirectToPage(newActiveDayPage);
    }
  }

  void syncWeekBarPage(int newWeekPage) async {
    int activeWeekPage = weekBarPageController.page!.round();
    if (newWeekPage != activeWeekPage) {
      await weekBarPageController.animateToPage(
        newWeekPage, 
        duration: Duration(milliseconds: 400), 
        curve: Curves.easeInOut,
      );
    }
  }

  void syncWeekViewPage(int newWeekPage) async {
    if (!weekViewPageController.hasClients) return;
    int activeWeekPage = weekViewPageController.page!.round();
    if (newWeekPage != activeWeekPage) {
      await weekViewPageController.animateToPage(
        newWeekPage,
        duration: Duration(milliseconds: 400), 
        curve: Curves.easeInOut,
      );
    }
  }

  void syncMonthBarPage(int newMonthPage) async {
    if (!monthBarPageController.hasClients) return;
    int activeMonthPage = monthBarPageController.page!.round();
    if (newMonthPage != activeMonthPage) {
      await monthBarPageController.animateToPage(
        newMonthPage, 
        duration: Duration(milliseconds: 400), 
        curve: Curves.easeInOut,
      );
    }
  }

  /// Handler for the onPageChanged event of the [DayView]'s [PageView].
  void handleDayViewPageChanged() {
    if (viewTabController.index == 0 && !weekBarPageController.isScrolling) {
      syncWeekBarPage(dayPageToWeekPage(dayViewPageController.page!));
      syncMonthBarPage(dayPageToMonthPage(dayViewPageController.page!));
      notifyListeners();
    }
  }

  /// Handler for the onPageChanged event of the [WeekBar]'s [PageView].
  /// No handler is needed for when the week view page is changed as 
  /// it's linked to the week bar page.
  void handleWeekBarPageChanged() {
    if (weekBarPageController.isScrolling) {
      DateTime newActiveDay = dayOfWeek(weekBarPageController.page!, activeDay.weekday);
      syncDayViewPage(newActiveDay);
      syncMonthBarPage(getMonthPage(newActiveDay));
    }
    notifyListeners();
  }

  void handleWeekViewPageChanged() {
    if (weekViewPageController.isScrolling) {
      DateTime newActiveDay = dayOfWeek(weekViewPageController.page!, activeDay.weekday);
      syncDayViewPage(newActiveDay);
      syncMonthBarPage(getMonthPage(newActiveDay));
    }
    notifyListeners();
  }

  void handleMonthBarPageChanged() {
    if (monthBarPageController.isScrolling) {
      DateTime newActiveDay = month(monthBarPageController.page!);
      syncDayViewPage(newActiveDay);
      syncWeekBarPage(getWeekPage(newActiveDay));
      syncWeekViewPage(getWeekPage(newActiveDay));
    }
    notifyListeners();
  }

  /// Handler for the onTap event of the [WeekBar]'s weekday items.
  void handleWeekBarDayTap(DateTime day) {
    syncDayViewPage(day);
    syncMonthBarPage(getMonthPage(monthOfDay(day)));
    notifyListeners();
  }

  /// Handler for the onTap event of the [MonthBar]'s weekday items.
  void handleMonthBarDayTap(DateTime day) {
    syncDayViewPage(day);
    syncWeekBarPage(getWeekPage(day));
    syncWeekViewPage(getWeekPage(day));
    notifyListeners();
  }

  void addListeners() {
    weekViewPageController.addListener(() {
      weekBarPageController.matchToOther(weekViewPageController);
    });
    weekBarPageController.addListener(() {
      weekViewPageController.matchToOther(weekBarPageController);
    });
    viewTabController.addListener(() {
      viewTabController.matchScrollOffsets(dayViewScrollController, weekViewScrollController);
      dayViewPageController.syncToOther(weekBarPageController);
    });
  }

  bool onWeekBarNotification(UserScrollNotification notification) {
    if(notification.direction != ScrollDirection.idle) {
      if (weekViewPageController.hasClients) {
        (weekViewPageController.position as ScrollPositionWithSingleContext).goIdle();
      }
    }
    weekBarPageController.isScrolling = notification.direction != ScrollDirection.idle;
    return false;
  }

  bool onWeekViewNotification(UserScrollNotification notification) {
    if(notification.direction != ScrollDirection.idle) {
      (weekBarPageController.position as ScrollPositionWithSingleContext).goIdle();
    }
    weekViewPageController.isScrolling = notification.direction != ScrollDirection.idle;
    return false;
  }

  bool onMonthBarNotification(UserScrollNotification notification) {
    monthBarPageController.isScrolling = notification.direction != ScrollDirection.idle;
    return false;
  }
}