import 'package:anu_timetable/model/controllers.dart';
import 'package:anu_timetable/model/current_datetime_notifiers.dart';
import 'package:anu_timetable/util/month_list_layout.dart';
import 'package:anu_timetable/widgets/day_view.dart';
import 'package:anu_timetable/widgets/month_bar.dart';
import 'package:anu_timetable/widgets/month_list.dart';
import 'package:anu_timetable/widgets/week_bar.dart';
import 'package:anu_timetable/widgets/week_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

/// A central control for keeping the various relevant timetable
/// widgets synchronised to the active day (the day in focus).
/// Mapping between pages/offsets and dates is done using a [hashDate].
/// 
/// [DayView] pages map to individual days,
/// [WeekBar] and [WeekView] pages map to the mondays of weeks,
/// [MonthBar] pages and the [MonthList]'s offset map the the first days of months.
class TimetableModel extends ChangeNotifier {

  /// Needs to be the start of the week (monday) so that
  /// the week and day pages align.
  /// It also needs to be within the first month of the year because
  /// the [MonthList] will start from january. 
  static final DateTime hashDate = weekOfDay(DateTime(2024, 1, 7));

  /// Is solely used as the endpoint of the [MonthList]. 
  /// It does not impose a limit on any other element.
  /// TODO: either enforce the end date globally or make [MonthList] infinite.
  static final DateTime endDate = DateTime(2035, 1, 1);

  late DayViewPageController dayViewPageController;
  late WeekViewPageController weekViewPageController;
  late WeekBarPageController weekBarPageController;
  late MonthBarPageController monthBarPageController;
  late MonthListScrollController monthListScrollController;

  /// The sole state managed by [TimetableModel]. It is what all of the 
  /// managed controllers are synchronised to.
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

    weekViewPageController.addListener(() {
      weekBarPageController.matchToOther(weekViewPageController);
    });
    weekBarPageController.addListener(() {
      weekViewPageController.matchToOther(weekBarPageController);
    });
  }

  DateTime get activeDay => _activeDay;

  set activeDay(DateTime day) {
    if (day == activeDay) return;
    _activeDay = day;
    notifyListeners();
  }

  /// Returns the day corrosponding to the given day view page.
  static DateTime day(double dayPage) =>
    DateTime(hashDate.year, hashDate.month, hashDate.day + dayPage.round());

  /// Returns the monday of the week corrosponding to the given 
  /// week bar page.
  static DateTime week(double weekPage) {
    int dayOffset = hashDate.day + (weekPage.round() * 7).round();
    return DateTime(hashDate.year, hashDate.month, dayOffset);
  }

  /// Returns the month corresponding to the given month page.
  static DateTime month(double monthPage) =>
    DateTime(hashDate.year, hashDate.month + monthPage.round());

  /// Returns the day of the weekday for the given week.
  static DateTime dayOfWeek(double weekPage, int weekday) {
    DateTime week = TimetableModel.week(weekPage);
    return DateTime(week.year, week.month, week.day + weekday - 1);
  }

  /// Returns the monday of the week that the given date is in.
  static DateTime weekOfDay(DateTime day) => 
    DateTime(day.year, day.month, day.day - day.weekday + 1);

  /// Returns the monday of the week that the given date is in.
  static DateTime monthOfDay(DateTime day) => DateTime(day.year, day.month);

  /// Returns the day view page corrosponding to the given date.
  static int getDayPage(DateTime day) => day.difference(hashDate).inDays;

  /// Returns the week page corrosponding to the given date.
  static int getWeekPage(DateTime week) => 
    (week.difference(hashDate).inDays / 7).toInt();

  static int getMonthPage(DateTime month) =>
    (month.year - hashDate.year) * 12 + month.month - hashDate.month;

  /// Returns true if the active day is the current day
  static bool dayIsCurrent(double dayPage, CurrentDay currentDay) =>
    day(dayPage) == currentDay.value;

  /// Returns true if the active day is the current day
  static bool weekIsCurrent(double weekPage, CurrentDay currentDay) =>
    week(weekPage) == weekOfDay(currentDay.value);

  /// Returns true if the active week contains the current day
  bool activeWeekIsCurrent(CurrentDay currentDay) =>
    weekOfDay(activeDay) == weekOfDay(currentDay.value);

  /// Animates the [DayView]'s [PageView] directly to the active day,
  /// skipping intermediate pages.
  void syncDayView() {
    if (!dayViewPageController.hasClients) return;
    int newActiveDayPage = getDayPage(activeDay);
    int activeDayPage = dayViewPageController.page!.round();
    if (newActiveDayPage != activeDayPage) {
      dayViewPageController.animateDirectToPage(newActiveDayPage);
    }
  }

  /// Animates the [WeekBar]'s [PageView] to the active page.
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

  /// Animates the [WeekView]'s [PageView] to the active page.
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

  /// Animates the [MonthBar]'s [PageView] to the active page.
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

  /// Animates the [MonthList]'s [ListView] just enough so that 
  /// the active month is entirely visible.
  void syncMonthList() {
    double leftOffset = MonthListLayout.leftOffset(activeDay);
    double rightOffset = MonthListLayout.rightOffset(activeDay);
    Duration duration = Duration(milliseconds: 300);
    Curve curve = Curves.easeInOut;
    
    if (monthListScrollController.offset < rightOffset) {
      monthListScrollController.animateTo(rightOffset, duration: duration, curve: curve);
    } else if (monthListScrollController.offset > leftOffset) {
      monthListScrollController.animateTo(leftOffset, duration: duration, curve: curve);
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
    if (!weekBarPageController.isScrolling) return;
    activeDay = dayOfWeek(weekBarPageController.page!, activeDay.weekday);
    syncDayView();
    syncMonthBar();
    syncMonthList();
  }

  void handleWeekViewPageChanged() {
    if (!weekViewPageController.isScrolling) return;
    activeDay = dayOfWeek(weekViewPageController.page!, activeDay.weekday);
    syncDayView();
    syncMonthBar();
    syncMonthList();
    
  }

  void handleMonthBarPageChanged() {
    if (!monthBarPageController.isScrolling) return;
    activeDay = month(monthBarPageController.page!);
    syncDayView();
    syncWeekBar();
    syncWeekView();
    syncMonthList();
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
