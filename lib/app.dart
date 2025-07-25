import 'package:anu_timetable/model/animation_notifiers.dart';
import 'package:anu_timetable/model/current_datetime_notifiers.dart';
import 'package:anu_timetable/util/timetable_layout.dart';
import 'package:anu_timetable/widgets/bottom_navigation_bar.dart';
import 'package:anu_timetable/widgets/month_list.dart';
import 'package:flutter/material.dart';
import 'package:anu_timetable/pages/home.dart';
import 'package:anu_timetable/pages/timetable_page.dart';
import 'package:anu_timetable/pages/messages_page.dart';
import 'package:provider/provider.dart';
import 'package:anu_timetable/model/timetable_model.dart';
import 'package:anu_timetable/model/controllers.dart';
import 'package:anu_timetable/widgets/app_bar.dart';

class App extends StatefulWidget {
  const App({super.key});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> with SingleTickerProviderStateMixin{
  late int currentPageIndex = 0;

  final DateTime currentDate = DateTime.now();

  late int dayViewInitialPage = TimetableModel.getDayPage(currentDate);
  late int weekViewInitialPage = TimetableModel.getWeekPage(currentDate);
  late int weekBarInitialPage = TimetableModel.getWeekPage(TimetableModel.weekOfDay(currentDate));
  late int monthBarInitialPage = TimetableModel.getMonthPage(TimetableModel.monthOfDay(currentDate));

  late double monthListInitialOffset = TimetableLayout.monthListMonthOffset(currentDate);

  late DayViewPageController dayViewPageController;
  late WeekViewPageController weekViewPageController;
  late WeekBarPageController weekBarPageController;
  late MonthBarPageController monthBarPageController;
  late DayViewScrollController dayViewScrollController;
  late WeekViewScrollController weekViewScrollController;
  late MonthListScrollController monthListScrollController;
  late ViewTabController viewTabController;

  @override
  void initState() {
    super.initState();

    dayViewPageController = DayViewPageController(initialPage: dayViewInitialPage);
    weekViewPageController = WeekViewPageController(
      initialPage: weekViewInitialPage,
      onAttach: (_) => weekViewPageController.jumpToOther(weekBarPageController));
    weekBarPageController = WeekBarPageController(initialPage: weekBarInitialPage);
    monthBarPageController = MonthBarPageController(initialPage: monthBarInitialPage);
    viewTabController = ViewTabController(length: 2, vsync: this);
    dayViewScrollController = DayViewScrollController(
      onAttach: (_) => dayViewScrollController.matchToOther(weekViewScrollController));
    weekViewScrollController = WeekViewScrollController(
      onAttach: (_) => weekViewScrollController.matchToOther(dayViewScrollController));

    monthListScrollController = MonthListScrollController(initialScrollOffset: monthListInitialOffset);

    viewTabController.addListener(() {
      viewTabController.matchScrollOffsets(dayViewScrollController, weekViewScrollController);
      dayViewPageController.syncToOther(weekBarPageController);
    });
  }

  @override
  void dispose() {
    super.dispose();
    dayViewPageController.dispose();
    weekViewPageController.dispose();
    weekBarPageController.dispose();
    viewTabController.dispose();
    dayViewScrollController.dispose();
    weekViewScrollController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => CurrentDay()),
        ChangeNotifierProvider(create: (context) => CurrentMinute()),
        ChangeNotifierProvider(create: (context) => CurrentSecond()),
        ChangeNotifierProvider(create: (context) => MonthBarAnimationNotifier(DateTime.now())),
        ChangeNotifierProvider(create: (context) => SelectBarWeekdayNotifier()),
        ChangeNotifierProvider.value(value: viewTabController),
        ChangeNotifierProvider.value(value: dayViewScrollController),
        ChangeNotifierProvider.value(value: weekViewScrollController),
        ChangeNotifierProvider.value(value: dayViewPageController),
        ChangeNotifierProvider.value(value: weekViewPageController),
        ChangeNotifierProvider.value(value: weekBarPageController),
        ChangeNotifierProvider.value(value: monthBarPageController),
        ChangeNotifierProvider.value(value: monthListScrollController),
        ChangeNotifierProxyProvider5<
          DayViewPageController,
          WeekViewPageController,
          WeekBarPageController,
          MonthBarPageController,
          MonthListScrollController,
          TimetableModel
        >(
          create: (context) => TimetableModel(
            dayViewPageController: dayViewPageController, 
            weekViewPageController: weekViewPageController, 
            weekBarPageController: weekBarPageController,
            monthBarPageController: monthBarPageController,
            monthListScrollController: monthListScrollController), 
          update: (
            _,
            dayViewPageController,
            weekViewPageController,
            weekBarPageController,
            monthBarPageController,
            monthListScrollController,
            timetableModel) {
            if (timetableModel == null) throw ArgumentError.notNull('timetableModel');
            timetableModel.dayViewPageController = dayViewPageController;
            timetableModel.weekViewPageController = weekViewPageController;
            timetableModel.weekBarPageController = weekBarPageController;
            timetableModel.monthBarPageController = monthBarPageController;
            timetableModel.monthListScrollController = monthListScrollController;
            return timetableModel;
          })
      ],
      child: MaterialApp(
        title: 'Flutter Demo',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color.fromARGB(255, 48, 48, 153),
            brightness: Brightness.dark),
          useMaterial3: true),
        home: Scaffold(
          appBar: MyAppBar(currentPageIndex: currentPageIndex),
          bottomNavigationBar: MyBottomNavigationBar(
            currentPageIndex: currentPageIndex, 
            onPageChanged: (int index) {
              setState(() {
                currentPageIndex = index;
              });
            }),
          body: <Widget>[
            const HomePage(),
            TimetablePage(),
            const MessagesPage()
          ][currentPageIndex])));
  }
}