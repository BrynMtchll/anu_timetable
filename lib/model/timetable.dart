import 'package:anu_timetable/model/controller.dart';
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
class TimetableVM extends ChangeNotifier {

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
  late TListViewItemScrollController tListViewItemScrollController;

  /// The sole state managed by [TimetableVM]. It is what all of the 
  /// managed controllers are synchronised to.
  late DateTime _activeDay;

  TimetableVM() {
    final currentDay = DateTime.now();
    _activeDay = DateTime(currentDay.year, currentDay.month, currentDay.day);
    createWeekViewController();
    createDayViewController();
    tListViewItemScrollController = TListViewItemScrollController();
  }

  DateTime get activeDay => _activeDay;

  set activeDay(DateTime day) {
    if (day == activeDay) return;
    _activeDay = day;
    notifyListeners();
  }

  /// Returns the day corrosponding to the given day view page.
  static DateTime getDay(int dayIndex)
    => DateTime(hashDate.year, hashDate.month, hashDate.day + dayIndex);

  /// Returns the monday of the week corrosponding to the given 
  /// week bar page.
  static DateTime getWeek(int weekIndex) {
    int dayOffset = hashDate.day + (weekIndex * 7);
    return DateTime(hashDate.year, hashDate.month, dayOffset);
  }

  /// Returns the month corresponding to the given month page.
  static DateTime getMonth(int monthIndex)
    => DateTime(hashDate.year, hashDate.month + monthIndex);

  /// Returns the day of the given week and weekday index.
  static DateTime dayOfWeek(int weekIndex, int weekdayIndex) {
    DateTime week = TimetableVM.getWeek(weekIndex);
    return DateTime(week.year, week.month, week.day + weekdayIndex - 1);
  }

  /// Returns the monday of the week of the given date.
  static DateTime weekOfDay(DateTime day) 
    => DateTime(day.year, day.month, day.day - day.weekday + 1);

  /// Returns the monday of the week that the given date is in.
  static DateTime monthOfDay(DateTime day) => DateTime(day.year, day.month);

  /// Returns the day view index corrosponding to the given date.
  static int getDayIndex(DateTime day) => day.difference(hashDate).inDays;

  /// Returns the week index corrosponding to the given date.
  static int getWeekIndex(DateTime week)
    => (week.difference(hashDate).inDays / 7).toInt();

  static int getMonthIndex(DateTime month)
    => (month.year - hashDate.year) * 12 + month.month - hashDate.month;

  static bool dayEquiv(DateTime day1, DateTime day2) => day1 == day2;

  // Checks if two days are of the same month and year
  static bool weekEquiv(DateTime day1, DateTime day2)
    => weekOfDay(day1) == weekOfDay(day2);

  // Checks if two days are of the same month and year
  static bool monthEquiv(DateTime day1, DateTime day2)
    => monthOfDay(day1) == monthOfDay(day2);
  
  DateTime getNewActiveDayForMonth(DateTime month, DateTime currentDay) {
    if (monthEquiv(month, activeDay)) return activeDay;
    return monthEquiv(month, currentDay) ? currentDay : month;
  }

  void createDayViewController() {
    dayViewPageController = DayViewPageController(
    initialPage: getDayIndex(activeDay));
  }

  void createWeekViewController() {
    weekViewPageController = WeekViewPageController(
      initialPage: getWeekIndex(weekOfDay(activeDay)),
      onAttach: (_) => weekViewPageController.jumpToOther(weekBarPageController));
    weekViewPageController.addListener(() {
      weekBarPageController.matchToOther(weekViewPageController);
    });
  }

  void createWeekBarController() {
    weekBarPageController = WeekBarPageController(
      initialPage: getWeekIndex(weekOfDay(activeDay)));
    weekBarPageController.addListener(() {
      weekViewPageController.matchToOther(weekBarPageController);
    });
  }

  void createMonthBarPageController() {
    monthBarPageController = MonthBarPageController(
      initialPage: getMonthIndex(monthOfDay(activeDay)));
  }

  void createMonthListScrollController() {
    monthListScrollController = MonthListScrollController(
      initialScrollOffset: MonthListLayout.rightOffset(activeDay));
  }

  /// Animates the [DayView]'s [PageView] directly to the active day,
  /// skipping intermediate pages.
  void syncDayView() {
    if (!dayViewPageController.hasClients) return;
    int newActiveDayIndex = getDayIndex(activeDay);
    int activeDayIndex = dayViewPageController.page!.round();
    if (newActiveDayIndex == activeDayIndex) return;
    dayViewPageController.animateDirectToPage(newActiveDayIndex);
  }

  /// Animates the [WeekBar]'s [PageView] to the active page.
  void syncWeekBar({bool jump = false}) async {
    int newWeekIndex = getWeekIndex(activeDay);
    int activeWeekIndex = weekBarPageController.page!.round();
    if (newWeekIndex == activeWeekIndex) return;
    jump ? weekBarPageController.jumpToPage(newWeekIndex)
      : await weekBarPageController.animateToPage(
        newWeekIndex,
        duration: Duration(milliseconds: 400),
        curve: Curves.easeInOut);
  }

  /// Animates the [WeekView]'s [PageView] to the active page.
  void syncWeekView() async {
    if (!weekViewPageController.hasClients) return;
    int newWeekIndex = getWeekIndex(activeDay);
    int activeWeekIndex = weekViewPageController.page!.round();
    if (newWeekIndex == activeWeekIndex) return;
    await weekViewPageController.animateToPage(
      newWeekIndex,
      duration: Duration(milliseconds: 400), 
      curve: Curves.easeInOut);
  }

  /// Animates the [MonthBar]'s [PageView] to the active page.
  void syncMonthBar({bool jump = false}) async {
    if (!monthBarPageController.hasClients) return;
    int newMonthIndex = getMonthIndex(activeDay);
    int activeMonthIndex = monthBarPageController.page!.round();
    if (newMonthIndex == activeMonthIndex) return;
    jump ? monthBarPageController.jumpToPage(newMonthIndex)
      : await monthBarPageController.animateToPage(
        newMonthIndex,
        duration: Duration(milliseconds: 400), 
        curve: Curves.easeInOut);
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

  void syncTListView({bool jump = false}) {
    if (!tListViewItemScrollController.isAttached) return;
    int newActiveDayIndex = getDayIndex(activeDay);
    jump ? tListViewItemScrollController.jumpTo(index: newActiveDayIndex) :
      tListViewItemScrollController.scrollTo(index: newActiveDayIndex, duration: Duration(milliseconds: 200));
  }

  void synchronise({bool jumpWeekBar = false, bool jumpMonthBar = false, bool jumpTListView = false}) {
    syncDayView();
    syncWeekBar(jump: jumpWeekBar);
    syncWeekView();
    syncMonthBar(jump: jumpMonthBar);
    syncMonthList();
    syncTListView(jump: jumpTListView);
  }

  /// Handler for the onPageChanged event of the [DayView]'s [PageView].
  void handleDayViewPageChanged() {
    if (!dayViewPageController.isScrolling) return;
    activeDay = getDay(dayViewPageController.page!.round());
    synchronise();
  }

  /// Handler for the onPageChanged event of the [WeekBar]'s [PageView].
  /// No handler is needed for when the week view page is changed as 
  /// it's linked to the week bar page.
  void handleWeekBarPageChanged() {
    if (!weekBarPageController.isScrolling) return;
    activeDay = dayOfWeek(weekBarPageController.page!.round(), activeDay.weekday);
    synchronise();
  }

  void handleWeekViewPageChanged() {
    if (!weekViewPageController.isScrolling) return;
    activeDay = dayOfWeek(weekViewPageController.page!.round(), activeDay.weekday);
    synchronise();
  }

  int dayDiff(DateTime day1, DateTime day2) {
    return (getDayIndex(day1) - getDayIndex(day2)).abs();
  }

  void handleMonthBarPageChanged(DateTime currentDay) {
    if (!monthBarPageController.isScrolling) return;
    DateTime newActiveDay = getNewActiveDayForMonth(getMonth(monthBarPageController.page!.round()), currentDay);
    int diff = dayDiff(activeDay, newActiveDay);
    activeDay = newActiveDay;
    synchronise(jumpTListView: diff >= 7);
  }

  void handleTListViewDayChanged(DateTime day) {
    if (!tListViewItemScrollController.isScrolling) return;
    activeDay = day;
    synchronise(jumpWeekBar: true, jumpMonthBar: true);
  }

  /// Handler for the onTap event of the [WeekBar]'s weekday items.
  void handleWeekBarDayTap(DateTime day) {
    activeDay = day;
    synchronise();
  }

  /// Handler for the onTap event of the [MonthBar]'s weekday items.
  void handleMonthBarDayTap(DateTime day) {
    int diff = dayDiff(day, activeDay);
    activeDay = day;
    synchronise(jumpTListView: diff >= 7);
  }

  void handleMonthListMonthTap(DateTime month, DateTime currentDay) {
    DateTime newActiveDay = getNewActiveDayForMonth(month, currentDay);
    int diff = dayDiff(newActiveDay, activeDay);
    activeDay = newActiveDay;
    synchronise(jumpWeekBar: true, jumpMonthBar: true, jumpTListView: diff >= 7);
  }

  void handleTodayTap(DateTime currentDay) {
    activeDay = currentDay;
    synchronise();
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

  bool onTListNotification(UserScrollNotification notification) {
    tListViewItemScrollController.isScrolling = notification.direction != ScrollDirection.idle;
    return false;
  }
}
