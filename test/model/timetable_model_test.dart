import 'package:anu_timetable/model/timetable.dart';
import 'package:anu_timetable/model/controller.dart';
import 'package:anu_timetable/util/timetable_layout.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:checks/checks.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  late int dayInitialPage = TimetableVM.getDayIndex(DateTime.now());
  late int weekInitialPage = TimetableVM.getWeekIndex(TimetableVM.weekOfDay(DateTime.now()));
  late int monthInitialPage = TimetableVM.getMonthIndex(TimetableVM.monthOfDay(DateTime.now()));
  late double monthInitialListOffset = TimetableLayout.monthListRightOffset(DateTime.now());

  late DayViewPageController dayViewPageController = DayViewPageController(
    initialPage: dayInitialPage);
  late WeekBarPageController weekBarPageController = WeekBarPageController(
    initialPage: weekInitialPage);
  late WeekViewPageController weekViewPageController;
  weekViewPageController = WeekViewPageController(
    initialPage: weekInitialPage,
    onAttach: (_) => weekViewPageController.jumpToOther(weekBarPageController));
  late MonthBarPageController monthBarPageController = MonthBarPageController(
    initialPage: monthInitialPage);
  late MonthListScrollController monthListScrollController = MonthListScrollController(
    initialScrollOffset: monthInitialListOffset);

  TimetableVM timetableModel = TimetableVM(
    dayViewPageController: dayViewPageController,
    weekViewPageController: weekViewPageController,
    weekBarPageController: weekBarPageController,
    monthBarPageController: monthBarPageController,
    monthListScrollController: monthListScrollController);

  group("syncDayView", () {
  });

  // TODO: SYNCHRONIZATION TESTS
  // trigger each swipe/tap and check all are synchronized
}