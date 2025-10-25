import 'package:anu_timetable/model/animation_notifiers.dart';
import 'package:anu_timetable/model/current_datetime_notifiers.dart';
import 'package:anu_timetable/util/month_list_layout.dart';
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
  late int currentPageIndex = 0;

  final DateTime currentDate = DateTime.now();


  late DayViewScrollController dayViewScrollController;
  late WeekViewScrollController weekViewScrollController;
  late ViewTabController viewTabController;

  @override
  void initState() {
    super.initState();
    viewTabController = ViewTabController(length: 2, vsync: this);
    dayViewScrollController = DayViewScrollController(
      onAttach: (_) => dayViewScrollController.matchToOther(weekViewScrollController));
    weekViewScrollController = WeekViewScrollController(
      onAttach: (_) => weekViewScrollController.matchToOther(dayViewScrollController));

    viewTabController.addListener(() {
      viewTabController.matchScrollOffsets(dayViewScrollController, weekViewScrollController);
    });
  }

  @override
  void dispose() {
    super.dispose();
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
        ChangeNotifierProvider.value(value: viewTabController),
        ChangeNotifierProvider.value(value: dayViewScrollController),
        ChangeNotifierProvider.value(value: weekViewScrollController),
        ChangeNotifierProvider<TimetableModel>(create: (context) => TimetableModel())
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
          body: <Widget>[const HomePage(),TimetablePage(),const MessagesPage()]
            [currentPageIndex])));
  }
}