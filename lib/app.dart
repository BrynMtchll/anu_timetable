import 'package:anu_timetable/model/current_datetime_notifiers.dart';
import 'package:anu_timetable/widgets/bottom_navigation_bar.dart';
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
  int currentPageIndex = 0;

  late int dayViewInitialPage = TimetableModel.getDayPage(DateTime.now());
  late DayViewPageController dayViewPageController;

  late int weekViewInitialPage = TimetableModel.getWeekPage(DateTime.now());
  late WeekViewPageController weekViewPageController;

  late int weekBarInitialPage = TimetableModel.getWeekPage(TimetableModel.weekOfDay(DateTime.now()));
  late WeekBarPageController weekBarPageController;

  late ViewTabController viewTabController;

  late DayViewScrollController dayViewScrollController;

  late WeekViewScrollController weekViewScrollController;

  @override
  void initState() {
    super.initState();
    dayViewPageController = DayViewPageController(
      initialPage: dayViewInitialPage,
    );
    
    weekViewPageController = WeekViewPageController(
      initialPage: weekViewInitialPage,
      onAttach: (_) => weekViewPageController.jumpToOther(weekBarPageController),
    );
    weekBarPageController = WeekBarPageController(
      initialPage: weekBarInitialPage,
    );

    viewTabController = ViewTabController(length: 2, vsync: this);

    dayViewScrollController = DayViewScrollController(
      onAttach: (_) => dayViewScrollController.matchToOther(weekViewScrollController),
    );
    weekViewScrollController = WeekViewScrollController(
      onAttach: (_) => weekViewScrollController.matchToOther(dayViewScrollController),
    );
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
        ChangeNotifierProvider.value(value: dayViewPageController),
        ChangeNotifierProvider.value(value: weekViewPageController),
        ChangeNotifierProvider.value(value: weekBarPageController),
        ChangeNotifierProvider.value(value: viewTabController),
        ChangeNotifierProvider.value(value: dayViewScrollController),
        ChangeNotifierProvider.value(value: weekViewScrollController),
        ChangeNotifierProxyProvider6<
          DayViewPageController, 
          WeekViewPageController, 
          WeekBarPageController, 
          ViewTabController, 
          DayViewScrollController,
          WeekViewScrollController,
          TimetableModel
        >(
          create: (context) => TimetableModel(
            dayViewPageController: dayViewPageController, 
            weekViewPageController: weekViewPageController, 
            weekBarPageController: weekBarPageController,
            viewTabController: viewTabController,
            dayViewScrollController: dayViewScrollController,
            weekViewScrollController: weekViewScrollController,
          ), 
          update: (
            _, 
            dayViewPageController, 
            weekViewPageController, 
            weekBarPageController, 
            viewTabController, 
            dayViewScrollController,
            weekViewScrollController,
            timetableModel
          ) {
            if (timetableModel == null) throw ArgumentError.notNull('timetableModel');   
            timetableModel.dayViewPageController = dayViewPageController;
            timetableModel.weekViewPageController = weekViewPageController;
            timetableModel.weekBarPageController = weekBarPageController;
            timetableModel.viewTabController = viewTabController;
            timetableModel.dayViewScrollController = dayViewScrollController;
            timetableModel.weekViewScrollController = weekViewScrollController;
            return timetableModel;
          }
        )
      ],
      child: MaterialApp(
        title: 'Flutter Demo',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          useMaterial3: true,
        ),
        home: Scaffold(
          appBar: MyAppBar(),
          bottomNavigationBar: MyBottomNavigationBar(
            currentPageIndex: currentPageIndex, 
            onPageChanged: (int index) {
              setState(() {
                currentPageIndex = index;
              });
            }
          ),
          body: <Widget>[
            const HomePage(),
             TimetablePage(),
            const MessagesPage()
          ][currentPageIndex]
        )
      ) 
    );
  }
}