import 'package:anu_timetable/model/controllers.dart';
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

  TimetableModel() {
    final currentDay = DateTime.now();
    _activeDay = DateTime(currentDay.year, currentDay.month, currentDay.day);
    createWeekViewController();
  }

  DateTime get activeDay => _activeDay;

  set activeDay(DateTime day) {
    if (day == activeDay) return;
    _activeDay = day;
    notifyListeners();
  }

  /// Returns the day corrosponding to the given day view page.
  static DateTime getDay(int dayPage)
    => DateTime(hashDate.year, hashDate.month, hashDate.day + dayPage);

  /// Returns the monday of the week corrosponding to the given 
  /// week bar page.
  static DateTime getWeek(int weekPage) {
    int dayOffset = hashDate.day + (weekPage * 7);
    return DateTime(hashDate.year, hashDate.month, dayOffset);
  }

  /// Returns the month corresponding to the given month page.
  static DateTime getMonth(int monthPage)
    => DateTime(hashDate.year, hashDate.month + monthPage);

  /// Returns the day of the given week and weekday index.
  static DateTime dayOfWeekPage(int weekPage, int weekdayInd) {
    DateTime week = TimetableModel.getWeek(weekPage);
    return DateTime(week.year, week.month, week.day + weekdayInd - 1);
  }

  /// Returns the monday of the week of the given date.
  static DateTime weekOfDay(DateTime day) 
    => DateTime(day.year, day.month, day.day - day.weekday + 1);

  /// Returns the monday of the week that the given date is in.
  static DateTime monthOfDay(DateTime day) => DateTime(day.year, day.month);

  /// Returns the day view page corrosponding to the given date.
  static int getDayPage(DateTime day) => day.difference(hashDate).inDays;

  /// Returns the week page corrosponding to the given date.
  static int getWeekPage(DateTime week)
    => (week.difference(hashDate).inDays / 7).toInt();

  static int getMonthPage(DateTime month)
    => (month.year - hashDate.year) * 12 + month.month - hashDate.month;

  static bool dayEquiv(DateTime day1, DateTime day2) => day1 == day2;

  // Checks if two days are of the same month and year
  static bool weekEquiv(DateTime day1, DateTime day2)
    => weekOfDay(day1) == weekOfDay(day2);

  // Checks if two days are of the same month and year
  static bool monthEquiv(DateTime day1, DateTime day2)
    => monthOfDay(day1) == monthOfDay(day2);
  
  void setActiveMonth(DateTime month, DateTime currentDay) {
    if (monthEquiv(month, activeDay)) return;
    monthEquiv(month, currentDay) ? activeDay = currentDay : activeDay = month;
  }

    void createDayViewController() {
      dayViewPageController = DayViewPageController(
      initialPage: getDayPage(activeDay));
  }

  void createWeekViewController() {
    weekViewPageController = WeekViewPageController(
      initialPage: getWeekPage(weekOfDay(activeDay)),
      onAttach: (_) => weekViewPageController.jumpToOther(weekBarPageController));
    weekViewPageController.addListener(() {
      weekBarPageController.matchToOther(weekViewPageController);
    });
  }

  void createWeekBarController() {
    weekBarPageController = WeekBarPageController(
      initialPage: getWeekPage(weekOfDay(activeDay)));
    weekBarPageController.addListener(() {
      weekViewPageController.matchToOther(weekBarPageController);
    });
  }

  void createMonthBarPageController() {
    monthBarPageController = MonthBarPageController(
      initialPage: getMonthPage(monthOfDay(activeDay)));
  }

  void createMonthListScrollController() {
    monthListScrollController = MonthListScrollController(
      initialScrollOffset: MonthListLayout.rightOffset(activeDay));
  }

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
      activeDay = getDay(dayViewPageController.page!.round());
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
    activeDay = dayOfWeekPage(weekBarPageController.page!.round(), activeDay.weekday);
    syncDayView();
    syncMonthBar();
    syncMonthList();
  }

  void handleWeekViewPageChanged() {
    if (!weekViewPageController.isScrolling) return;
    activeDay = dayOfWeekPage(weekViewPageController.page!.round(), activeDay.weekday);
    syncDayView();
    syncMonthBar();
    syncMonthList();
  }

  void handleMonthBarPageChanged(DateTime currentDay) {
    if (!monthBarPageController.isScrolling) return;
    setActiveMonth(getMonth(monthBarPageController.page!.round()), currentDay);
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

  void handleMonthListMonthTap(DateTime month, DateTime currentDay) {
    setActiveMonth(month, currentDay);
    syncDayView();
    syncWeekBar();
    syncWeekView();
    monthBarPageController.jumpToPage(getMonthPage(activeDay));
    syncMonthList();
  }

  void handleTodayTap(DateTime currentDay) {
    activeDay = currentDay;
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
