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
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => TimetableModel(),
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
            bottom:  (currentPageIndex == 1) ? WeekBar() : null,
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
            const TimetablePage(),
            const MessagesPage()
          ][currentPageIndex]
        )
      ) 
    );
  }
}
