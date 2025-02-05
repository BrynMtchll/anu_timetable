import 'package:anu_timetable/model/controllers.dart';
import 'package:flutter/material.dart';
import 'package:anu_timetable/widgets/day_view.dart';
import 'package:anu_timetable/widgets/week_bar.dart';
import 'package:anu_timetable/model/current_datetime_notifiers.dart';
import 'package:flutter/rendering.dart';

class TimetableModel extends ChangeNotifier {
  /// All dates are mapped to pages for the respective [PageView]s
  /// implemented in [WeekBar] and [DayView].
  /// [WeekBar] pages are mapped to weeks, with the date 
  /// corresponding to the start of the week.
  /// [DayView] pages are mapped to dates one to one.
  static DateTime hashDate = weekOfDay(DateTime(2000, 0, 0));

  /// [WeekBar], [WeekView] and [DayView]'s [PageView]s all affect one another.
  /// They're controllers are managed here so as to decouple them 
  /// from one another. 
  late DayViewPageController dayViewPageController;

  late WeekViewPageController weekViewPageController;

  late WeekBarPageController weekBarPageController;

  late ViewTabController viewTabController;

  late DayViewScrollController dayViewScrollController;

  late WeekViewScrollController weekViewScrollController;

  late DateTime _persistedActiveDay = CurrentDay().value;

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
    required this.viewTabController,
    required this.dayViewScrollController, 
    required this.weekViewScrollController,
  }) {
    addListeners();
  }

  /// Returns the monday of the week corrosponding to the given 
  /// week bar page.
  static DateTime week(double? weekBarPage) {
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
  DateTime day(double? dayPage) {
    if (dayPage == null) {
      return day(dayViewPageController.initialPage.toDouble());
    }
    if (dayOverride.containsKey(dayPage.round())) {
      return dayOverride[dayPage.round()];
    }
    return pageToDay(dayPage);
  }

  /// Returns the day of the weekday for the given week.
  /// 
  /// 'Date' is suffixed to the function name to avoid ambiguity with the
  /// naming [DateTime.weekday] to represent the weekday index.
  static DateTime weekdayDate(double weekBarPage, int weekday) => 
    week(weekBarPage).add(Duration(days: weekday - 1));
  

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

  static DateTime pageToDay(double dayPage) {
    return hashDate.add(Duration(days: dayPage.round()));
  }

  static int convertToDayPage(double weekPage, double dayPage) {
    int weekday = pageToDay(dayPage).weekday;
    DateTime day = TimetableModel.weekdayDate(weekPage, weekday);
    return getDayPage(day);
  }

  /// Returns the day view page corrosponding to the given date.
  static int getDayPage(DateTime day) => 
    day.difference(hashDate).inDays;

  /// Returns the week page corrosponding to the given date.
  static int getWeekPage(DateTime week) => 
    (week.difference(hashDate).inDays / 7).toInt();  
  
  /// Returns the monday of the week that the given date is in.
  static DateTime weekOfDay(DateTime day) => 
    day.subtract(Duration(days:  day.weekday - 1));

  /// Returns the monday of the week that the active date is in.
  DateTime get weekOfActiveDay {
   return weekOfDay(activeDay);
  } 

  /// Returns true if the active day is the current day
  bool dayIsCurrent(int page, CurrentDay currentDay) => 
    day(page.toDouble()) == currentDay.value;

  /// Returns true if the active day is the current day
  /// could be static
  bool weekIsCurrent(int page, CurrentDay currentDay) => 
    week(page.toDouble()) == TimetableModel.weekOfDay(currentDay.value);


  /// Returns true if the active week contains the current day
  bool activeWeekIsCurrent(CurrentDay currentDay) => 
    activeWeek() == TimetableModel.weekOfDay(currentDay.value); 
  

  /// TODO: fix comment
  /// Updates the [dayViewPageController.page], i.e. the active day,
  /// to the week given, maintaining the same weekday.
  void changeDayViewPage() { 
    // day view page will fall out of sync if it has no clients at time of call
    if (dayViewPageController.hasClients) {
      DateTime newActiveDay = weekdayDate(weekBarPageController.page!, activeDay.weekday);
      if (activeDay != newActiveDay) {
        _persistedActiveDay = newActiveDay;
        animateDirectToDayViewPage(newActiveDay);
      }
    }
  }

  /// TODO: fix comment
  /// Updates the [weekBarPageController.page], i.e. the active week,
  /// to the week containing the [dayViewPageController.page] (the active day).
  void changeWeekBarPage() async {
    int newWeekBarPage = getWeekPage(weekOfActiveDay);
    int activeWeekBarPage = weekBarPageController.page!.round();
    if (newWeekBarPage != activeWeekBarPage) {
      await weekBarPageController.animateToPage(
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
      duration: Duration(milliseconds: 350),
    );

    dayOverride.remove(adjacentDayViewPage);
    dayViewPageController.jumpToPage(getDayPage(newActiveDay));
  }

  /// Handler for the onTap event of the [DayView]'s weekday items.
  void handleWeekBarWeekdayTap(int page, int weekday) async {
    if (viewTabController.index == 0) {
    DateTime newActiveDay = weekdayDate(page.toDouble(), weekday);
    await animateDirectToDayViewPage(newActiveDay);
    notifyListeners();
    }
  }

  void jumpToDay(DateTime day) {
    dayViewPageController.jumpToPage(getDayPage(day));
    if (weekViewPageController.hasClients) {
      weekViewPageController.jumpToPage((getWeekPage(weekOfDay(day))));
    }
    weekBarPageController.jumpToPage((getWeekPage(weekOfDay(day))));
  }

  /// Handler for the onPageChanged event of the [DayView]'s [PageView].
  void handleDayViewPageChanged() {
    if (viewTabController.index == 0 && !weekBarPageController.isScrolling) {
      changeWeekBarPage();
      notifyListeners();
    }
  }

  /// Handler for the onPageChanged event of the [WeekBar]'s [PageView].
  void handleWeekBarPageChanged() {
    if (viewTabController.index == 0 && weekBarPageController.isScrolling) {
      changeDayViewPage();
      notifyListeners();  
    }
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

  bool onNotification(UserScrollNotification notification) {
    if(notification.direction != ScrollDirection.idle) {
      if (weekViewPageController.hasClients) {
        (weekViewPageController.position as ScrollPositionWithSingleContext).goIdle();
      }
      weekViewPageController.isScrolling = false;
      weekBarPageController.isScrolling = true;
    }
    else {
      weekViewPageController.isScrolling = true;
      weekBarPageController.isScrolling = false;
    }
    return false;
  }
}