import 'package:anu_timetable/model/current_datetime_notifiers.dart';
import 'package:flutter/material.dart';
import 'package:anu_timetable/pages/home.dart';
import 'package:anu_timetable/pages/timetable_page.dart';
import 'package:anu_timetable/pages/messages_page.dart';
// import 'package:calendar_view/calendar_view.dart';
import 'package:anu_timetable/widgets/week_bar.dart';
import 'package:provider/provider.dart';
import 'package:anu_timetable/model/timetable_model.dart';
import 'package:anu_timetable/model/controllers.dart';

class App extends StatefulWidget {
  const App({super.key});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  int currentPageIndex = 0;

  late int weekBarInitialPage = TimetableModel.weekBarPage(TimetableModel.weekOfDay(DateTime.now()));
  late WeekBarPageController weekBarPageController;
  
  late int dayViewInitialPage = TimetableModel.dayViewPage(DateTime.now());
  late DayViewPageController dayViewPageController;

  late CurrentDay currentDay;
  late CurrentMinute currentMinute;
  late CurrentSecond currentSecond;

  @override
  void initState() {
    super.initState();
    dayViewPageController = DayViewPageController(
      initialPage: dayViewInitialPage,
    );
    weekBarPageController = WeekBarPageController(
      initialPage: weekBarInitialPage,
    );
    currentDay = CurrentDay();
    currentMinute = CurrentMinute();
    currentSecond = CurrentSecond();
  }

  @override
  void dispose() {
    super.dispose();
    weekBarPageController.dispose();
    dayViewPageController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: dayViewPageController),
        ChangeNotifierProvider.value(value: weekBarPageController),
        ChangeNotifierProvider.value(value: currentDay),
        ChangeNotifierProvider.value(value: currentMinute),
        ChangeNotifierProvider.value(value: currentSecond),
        ChangeNotifierProxyProvider2<DayViewPageController, WeekBarPageController, TimetableModel>(
          create: (context) => TimetableModel(
            dayViewPageController: dayViewPageController, 
            weekBarPageController: weekBarPageController,
          ), 
          update: (_, dayViewPageController, weekBarPageController, timetableModel) {
            if (timetableModel == null) throw ArgumentError.notNull('timetableModel');   
            timetableModel.dayViewPageController = dayViewPageController;
            timetableModel.weekBarPageController = weekBarPageController;
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
          appBar: AppBar(
            title: Text("Home"),
            elevation: 3.0,
            bottom:  (currentPageIndex == 1) ? 
            WeekBar() : 
            null,
          ),
          bottomNavigationBar: NavigationBar(
            selectedIndex: currentPageIndex,
            onDestinationSelected: (int index) {
              setState(() {
                currentPageIndex = index;
              });
            },
            destinations: const <Widget>[
              NavigationDestination(
                icon: Icon(Icons.home), 
                label: 'Home'
              ),
              NavigationDestination(
                icon: Icon(Icons.calendar_today), 
                label: 'Timetable'
              ),
              NavigationDestination(
                icon: Icon(Icons.message), 
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
