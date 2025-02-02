import 'package:anu_timetable/model/current_datetime_notifiers.dart';
import 'package:flutter/material.dart';
import 'package:anu_timetable/pages/home.dart';
import 'package:anu_timetable/pages/timetable_page.dart';
import 'package:anu_timetable/pages/messages_page.dart';
import 'package:provider/provider.dart';
import 'package:anu_timetable/model/timetable_model.dart';
import 'package:anu_timetable/model/controllers.dart';
import 'package:anu_timetable/widgets/app_bar.dart';
import 'package:linked_scroll_controller/linked_scroll_controller.dart';

class App extends StatefulWidget {
  const App({super.key});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> with SingleTickerProviderStateMixin{
  int currentPageIndex = 0;

  late int dayViewInitialPage = TimetableModel.dayViewPage(DateTime.now());
  late DayViewPageController dayViewPageController;

  late int weekViewInitialPage = TimetableModel.weekViewPage(DateTime.now());
  late WeekViewPageController weekViewPageController;

  late int weekBarInitialPage = TimetableModel.weekBarPage(TimetableModel.weekOfDay(DateTime.now()));
  late WeekBarPageController weekBarPageController;

  late TabController tabController;

  // late LinkedScrollControllerGroup _controllerGroup;

  /// [weekViewPageController] is only assigned to [WeekView]'s [PageView] 
  /// after the week tab has been made active. Consequentially the 
  /// [weekViewPageController.page] is not synced with the active week. 
  /// This listener handles the case where the active week is changed before 
  /// this is done by setting the [weekViewPageController.page] as soon 
  /// as [WeekView] is built.
  void handleDayViewPageControllerAttach(ScrollPosition position) {
    if (
      weekViewPageController.hasClients && 
      weekViewPageController.page != weekBarPageController.page
    ) {
      weekViewPageController.jumpToPage(weekBarPageController.page!.round());
    }
  }

  @override
  void initState() {
    super.initState();
      dayViewPageController = DayViewPageController(
      initialPage: dayViewInitialPage,
    );
    weekViewPageController = WeekViewPageController(
      initialPage: weekViewInitialPage,
      onAttach: handleDayViewPageControllerAttach,
    );
    weekBarPageController = WeekBarPageController(
      initialPage: weekBarInitialPage,
    );
    tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    super.dispose();
    dayViewPageController.dispose();
    weekViewPageController.dispose();
    weekBarPageController.dispose();
    tabController.dispose();
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
        ChangeNotifierProvider.value(value: tabController),
        ChangeNotifierProxyProvider4<DayViewPageController, WeekViewPageController, WeekBarPageController, TabController, TimetableModel>(
          create: (context) => TimetableModel(
            dayViewPageController: dayViewPageController, 
            weekViewPageController: weekViewPageController, 
            weekBarPageController: weekBarPageController,
            tabController: tabController,

          ), 
          update: (_, dayViewPageController, weekViewPageController, weekBarPageController, tabController, timetableModel) {
            if (timetableModel == null) throw ArgumentError.notNull('timetableModel');   
            timetableModel.dayViewPageController = dayViewPageController;
            timetableModel.weekViewPageController = weekViewPageController;
            timetableModel.weekBarPageController = weekBarPageController;
            timetableModel.tabController = tabController;
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
          bottomNavigationBar: NavigationBar(
            elevation: 0,
            backgroundColor: ColorScheme.fromSeed(seedColor: Colors.deepPurple).surface,
            selectedIndex: currentPageIndex,
            indicatorColor: Colors.transparent,
            labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
            onDestinationSelected: (int index) {
              setState(() {
                currentPageIndex = index;
              });
            },
            destinations: const <Widget>[
              NavigationDestination(
                icon: Icon(Icons.home_outlined), 
                selectedIcon: Icon(Icons.home),
                label: 'Home'
              ),
              NavigationDestination(
                icon: Icon(
                  Icons.calendar_view_week_outlined,
                ), 
                selectedIcon: Icon(Icons.calendar_view_week),
                label: 'Timetable'
              ),
              NavigationDestination(
                icon: Icon(Icons.chat_bubble_outline), 
                selectedIcon: Icon(Icons.chat_bubble), 
                label: 'Messages'
              ),
          ]),
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
