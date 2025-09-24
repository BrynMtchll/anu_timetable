import 'package:anu_timetable/model/timetable_model.dart';
import 'package:anu_timetable/model/controllers.dart';
import 'package:anu_timetable/util/timetable_layout.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:checks/checks.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  late int dayInitialPage = TimetableModel.getDayPage(DateTime.now());
  late int weekInitialPage = TimetableModel.getWeekPage(TimetableModel.weekOfDay(DateTime.now()));
  late int monthInitialPage = TimetableModel.getMonthPage(TimetableModel.monthOfDay(DateTime.now()));
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

  TimetableModel timetableModel = TimetableModel(
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