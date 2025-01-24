import 'package:anu_timetable/model/timetable_model.dart';
import 'package:anu_timetable/widgets/controllers.dart';
import 'package:test/test.dart';

void main() {
  late int weekBarInitialPage = TimetableModel.weekBarPage(TimetableModel.weekOfDay(DateTime.now()));
  late WeekBarPageController weekBarPageController = WeekBarPageController(
    initialPage: weekBarInitialPage,
  );

  late int dayViewInitialPage = TimetableModel.dayViewPage(DateTime.now());
  late DayViewPageController dayViewPageController = DayViewPageController(
    initialPage: dayViewInitialPage,
  );
  
  TimetableModel timetableModel = TimetableModel(weekBarPageController: weekBarPageController, dayViewPageController: dayViewPageController);

  test("weekBarInitialPage", () {
    expect(timetableModel.week(weekBarInitialPage.toDouble()).weekday, DateTime.monday);
  });

  test("dayViewInitialPage", () {
    expect(timetableModel.day(dayViewInitialPage.toDouble()).day, DateTime.now().day);
  });

  test("dayViewPage()", () {
    expect(TimetableModel.dayViewPage(DateTime.now()), dayViewInitialPage);
  });

  test("weekOfDay()", () {
    expect(TimetableModel.weekOfDay(DateTime.now()).day, DateTime.now().subtract(Duration(days: DateTime.now().weekday - 1)).day);
  });
}