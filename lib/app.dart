import 'package:flutter/material.dart';
import 'package:anu_timetable/pages/home.dart';

class App extends StatefulWidget {
  const App({super.key});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  int currentPageIndex = 0;
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: Scaffold(
        appBar: AppBar(
          title: Text("Home"),
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
              icon: Icon(Icons.people), 
              label: 'food'
            ),
            NavigationDestination(
              icon: Icon(Icons.person), 
              label: 'Account'
            ),

        ]),
        body: <Widget>[
          const HomePage(),
          Card(),
          Card(),
        ][currentPageIndex]
      )
    );
  }
}
