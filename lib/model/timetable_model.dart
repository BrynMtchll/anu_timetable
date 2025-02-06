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

  /// Returns the day corrosponding to [dayViewPageController.page].
  /// [WeekBar] requires [activeDay] before [DayViewPageController] is attached
  /// to the [PageView] of [DayView].
  DateTime get activeDay => 
    dayViewPageController.hasClients ? 
      day(dayViewPageController.page!) : _persistedActiveDay;
  
  /// Returns the monday of the week corrosponding to 
  /// [weekBarPageController.page].
  DateTime get activeWeek => week(weekBarPageController.page);

  /// Returns the monday of the week that the active date is in.
  DateTime get weekOfActiveDay {
   return weekOfDay(activeDay);
  } 

  /// Returns the day corrosponding to the given day view page.
  static DateTime day(double dayPage) {
    return hashDate.add(Duration(days: dayPage.round()));
  }

  /// Returns the monday of the week corrosponding to the given 
  /// week bar page.
  static DateTime week(double? weekBarPage) {
    if (weekBarPage == null) {
      throw ArgumentError("weekBarPage is null!");
    }
    return hashDate.add(Duration(days: (weekBarPage.round() * 7).round()));
  }

  /// Returns the day of the weekday for the given week.
  /// 
  /// 'Date' is suffixed to the function name to avoid ambiguity with the
  /// naming [DateTime.weekday] to represent the weekday index.
  static DateTime weekdayDate(double weekBarPage, int weekday) => 
    week(weekBarPage).add(Duration(days: weekday - 1));
  

  static int convertToDayPage(double weekPage, double dayPage) {
    int weekday = day(dayPage).weekday;
    return getDayPage(TimetableModel.weekdayDate(weekPage, weekday));
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

  /// Returns true if the active day is the current day
  static bool dayIsCurrent(int page, CurrentDay currentDay) => 
    day(page.toDouble()) == currentDay.value;

  /// Returns true if the active day is the current day
  static bool weekIsCurrent(int page, CurrentDay currentDay) => 
    week(page.toDouble()) == weekOfDay(currentDay.value);

  /// Returns true if the active week contains the current day
  bool activeWeekIsCurrent(CurrentDay currentDay) => 
    activeWeek == weekOfDay(currentDay.value); 

  /// TODO: fix comment
  /// Updates the [dayViewPageController.page], i.e. the active day,
  /// to the week given, maintaining the same weekday.
  void changeDayViewPage() { 
    // day view page will fall out of sync if it has no clients at time of call
    if (dayViewPageController.hasClients) {
      DateTime newActiveDay = weekdayDate(weekBarPageController.page!, activeDay.weekday);
      if (activeDay != newActiveDay) {
        _persistedActiveDay = newActiveDay;
        int newPage = getDayPage(newActiveDay);
        dayViewPageController.animateDirectToPage(newPage);
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

  /// Handler for the onTap event of the [DayView]'s weekday items.
  void handleWeekBarWeekdayTap(int page, int weekday) {
    if (viewTabController.index == 0) {
    DateTime newActiveDay = weekdayDate(page.toDouble(), weekday);
    int newPage = getDayPage(newActiveDay);
    dayViewPageController.animateDirectToPage(newPage);
    notifyListeners();
    }
  }

  void jumpToDay(DateTime day) {
    if (dayViewPageController.hasClients) {
      dayViewPageController.jumpToPage(getDayPage(day));
    }
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