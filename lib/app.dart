import 'package:flutter/material.dart';
import 'package:anu_timetable/pages/home.dart';
import 'package:anu_timetable/pages/timetable_page.dart';
import 'package:anu_timetable/pages/messages_page.dart';
// import 'package:calendar_view/calendar_view.dart';
import 'package:anu_timetable/widgets/week_bar.dart';
import 'package:provider/provider.dart';
import 'package:anu_timetable/model/timetable_model.dart';

class App extends StatefulWidget {
  const App({super.key});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  int currentPageIndex = 0;

  DateTime currentDate = DateTime.now();
  late DateTime currentWeekDate = TimetableModel.weekStart(currentDate);

  static DateTime hashDate = TimetableModel.weekStart(DateTime(2000, 0, 0));
  

  late int weekBarInitialPage = (currentWeekDate.difference(hashDate).inDays / 7).toInt();
  late PageController weekBarPageController = PageController(
      initialPage: weekBarInitialPage,
    );
  
  @override
  void initState() {
    super.initState();

  }

  @override
  void dispose() {
    super.dispose();
    weekBarPageController.dispose();
  }


  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => TimetableModel(
          currentDate: currentDate,
          currentWeekDate: currentWeekDate,
          hashDate: hashDate,
        )),
        ChangeNotifierProvider.value(value: weekBarPageController),
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
