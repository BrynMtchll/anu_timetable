import 'package:anu_timetable/model/controllers.dart';
import 'package:anu_timetable/model/current_datetime_notifiers.dart';
import 'package:anu_timetable/util/timetable_layout.dart';
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
  /// 
  /// [hashDate] needs to be the start of the week (monday) so that
  /// the week and day pages align.
  /// It also needs to be within the first month of the year because
  /// the [monthBarList] will start from january. 
  static final DateTime hashDate = weekOfDay(DateTime(2024, 1, 7));

  static final DateTime endDate = DateTime(2035, 1, 1);

  /// [WeekBar], [WeekView] and [DayView]'s [PageView]s all affect one another.
  /// They're controllers are managed here so as to decouple them 
  /// from one another. 
  late DayViewPageController dayViewPageController;
  late WeekViewPageController weekViewPageController;
  late WeekBarPageController weekBarPageController;
  late MonthBarPageController monthBarPageController;
  late MonthListScrollController monthListScrollController;

  late DateTime _activeDay;

  TimetableModel({
    required this.dayViewPageController,
    required this.weekViewPageController,
    required this.weekBarPageController,
    required this.monthBarPageController,
    required this.monthListScrollController,
  }) {
    final currentDay = DateTime.now();
    _activeDay = DateTime(currentDay.year, currentDay.month, currentDay.day);
    addListeners();
  }

  /// Returns the day corrosponding to [dayViewPageController.page].
  /// [WeekBar] requires [activeDay] before [DayViewPageController] is attached
  /// to the [PageView] of [DayView].
  // DateTime get activeDay => day(dayViewPageController.page!);

  DateTime get activeDay => _activeDay;
  set activeDay(DateTime day) {
    if (day == activeDay) return;
    _activeDay = day;
    notifyListeners();
  }

  
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

  void syncDayView() {
    if (!dayViewPageController.hasClients) return;
    int newActiveDayPage = getDayPage(activeDay);
    int activeDayPage = dayViewPageController.page!.round();
    if (newActiveDayPage != activeDayPage) {
      dayViewPageController.animateDirectToPage(newActiveDayPage);
    }
  }

  void syncWeekBar() async {
    int newWeekPage = getWeekPage(activeDay);
    int activeWeekPage = weekBarPageController.page!.round();
    if (newWeekPage != activeWeekPage) {
      await weekBarPageController.animateToPage(
        newWeekPage,
        duration: Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    }
  }

  void syncWeekView() async {
    if (!weekViewPageController.hasClients) return;
    int newWeekPage = getWeekPage(activeDay);
    int activeWeekPage = weekViewPageController.page!.round();
    if (newWeekPage != activeWeekPage) {
      await weekViewPageController.animateToPage(
        newWeekPage,
        duration: Duration(milliseconds: 400), 
        curve: Curves.easeInOut,
      );
    }
  }

  void syncMonthBar() async {
    if (!monthBarPageController.hasClients) return;
    int newMonthPage = getMonthPage(activeDay);
    int activeMonthPage = monthBarPageController.page!.round();
    if (newMonthPage != activeMonthPage) {
      await monthBarPageController.animateToPage(
        newMonthPage,
        duration: Duration(milliseconds: 400), 
        curve: Curves.easeInOut,
      );
    }
  }

  void syncMonthList() {
    double leftOffset = TimetableLayout.monthListMonthOffset(activeDay);
    double rightOffset = TimetableLayout.monthListMonthRightOffset(activeDay);
    
    if (monthListScrollController.offset < rightOffset) {
      monthListScrollController.animateTo(
        rightOffset, 
        duration: Duration(milliseconds: 300), 
        curve: Curves.easeInOut);
    } else if (monthListScrollController.offset > leftOffset) {
      monthListScrollController.animateTo(
        leftOffset, 
        duration: Duration(milliseconds: 300), 
        curve: Curves.easeInOut);
      print(leftOffset);
    }
  }

  /// Handler for the onPageChanged event of the [DayView]'s [PageView].
  void handleDayViewPageChanged() {
    if (dayViewPageController.isScrolling) {
      activeDay = day(dayViewPageController.page!);
      syncWeekBar();
      syncMonthBar();
      syncMonthList();
    }
  }

  /// Handler for the onPageChanged event of the [WeekBar]'s [PageView].
  /// No handler is needed for when the week view page is changed as 
  /// it's linked to the week bar page.
  void handleWeekBarPageChanged() {
    if (weekBarPageController.isScrolling) {
      activeDay = dayOfWeek(weekBarPageController.page!, activeDay.weekday);
      syncDayView();
      syncMonthBar();
      syncMonthList();
    }
  }

  void handleWeekViewPageChanged() {
    if (weekViewPageController.isScrolling) {
      activeDay = dayOfWeek(weekViewPageController.page!, activeDay.weekday);
      syncDayView();
      syncMonthBar();
      syncMonthList();
    }
  }

  void handleMonthBarPageChanged() {
    if (monthBarPageController.isScrolling) {
      activeDay = month(monthBarPageController.page!);
      syncDayView();
      syncWeekBar();
      syncWeekView();
      syncMonthList();
    }
  }

  /// Handler for the onTap event of the [WeekBar]'s weekday items.
  void handleWeekBarDayTap(DateTime day) {
    activeDay = day;
    syncDayView();
    syncMonthBar();
    syncMonthList();
  }

  /// Handler for the onTap event of the [MonthBar]'s weekday items.
  void handleMonthBarDayTap(DateTime day) {
    activeDay = day;
    syncDayView();
    syncWeekBar();
    syncWeekView();
  }

  void handleMonthListMonthTap(int year, int month) {
    if (year == activeDay.year && month == activeDay.month) return;
    DateTime day = DateTime(year, month, 1);
    activeDay = day;
    syncDayView();
    syncWeekBar();
    syncWeekView();
    monthBarPageController.jumpToPage(getMonthPage(activeDay));
    syncMonthList();
  }

  void addListeners() {
    weekViewPageController.addListener(() {
      weekBarPageController.matchToOther(weekViewPageController);
    });
    weekBarPageController.addListener(() {
      weekViewPageController.matchToOther(weekBarPageController);
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

  bool onDayViewNotification(UserScrollNotification notification) {
    dayViewPageController.isScrolling = notification.direction != ScrollDirection.idle;
    return false;
  }
}
