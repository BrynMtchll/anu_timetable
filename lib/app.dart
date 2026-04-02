import 'package:anu_timetable/data/repositories/event_repository.dart';
import 'package:anu_timetable/data/repositories/event_respository_local.dart';
import 'package:anu_timetable/data/repositories/user_repository.dart';
import 'package:anu_timetable/data/repositories/user_repository_firebase.dart';
import 'package:anu_timetable/model/animation.dart';
import 'package:anu_timetable/model/current.dart';
import 'package:anu_timetable/model/event.dart';
import 'package:anu_timetable/model/events.dart';
import 'package:anu_timetable/model/user.dart';
import 'package:anu_timetable/util/timetable_layout.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:anu_timetable/model/timetable.dart';
import 'package:anu_timetable/model/controller.dart';
import 'package:go_router/go_router.dart';

class App extends StatefulWidget {
  const App({super.key, required this.router});

  final GoRouter router;

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> with SingleTickerProviderStateMixin {
  late int currentPageIndex = 0;

  final DateTime currentDate = DateTime.now();

  late DayViewScrollController dayViewScrollController;
  late WeekViewScrollController weekViewScrollController;
  late ViewTabController viewTabController;

  @override
  void initState() {
    super.initState();
    viewTabController = ViewTabController(length: 3, vsync: this);
    dayViewScrollController = DayViewScrollController(
      initialScrollOffset:  TimetableLayout.initialScrollOffset,
      onAttach: (_) => dayViewScrollController.matchToOther(weekViewScrollController));
    weekViewScrollController = WeekViewScrollController(
      initialScrollOffset: TimetableLayout.initialScrollOffset,
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
        Provider(create:(context) => EventRespositoryLocal() as EventRepository),
        Provider(create:(context) => UserRepositoryFirebase() as UserRepository),
        ChangeNotifierProvider(create: (context) => CurrentDay()),
        ChangeNotifierProvider(create: (context) => CurrentMinute()),
        ChangeNotifierProvider(create: (context) => CurrentSecond()),
        ChangeNotifierProvider(create: (context) => MonthBarAnimationNotifier(DateTime.now())),
        ChangeNotifierProvider.value(value: viewTabController),
        ChangeNotifierProvider.value(value: dayViewScrollController),
        ChangeNotifierProvider.value(value: weekViewScrollController),
        ChangeNotifierProvider<TimetableVM>(create: (context) => TimetableVM()),
        ChangeNotifierProvider<EventsVM>(create: (context) => EventsVM(eventRepository: context.read())),
        ChangeNotifierProvider<EventVM>(create: (context) => EventVM(eventRepository: context.read())),
        ChangeNotifierProvider<UserVM>(create: (context) => UserVM(userRepository: context.read()))
      ],
      child: MaterialApp.router(
        title: 'Flutter Demo',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            // 255, 190, 135, 43
            seedColor: const Color.fromARGB(255, 58, 43, 190),
            surfaceContainerHighest: const Color.fromARGB(255, 50, 41, 85),
            brightness: Brightness.dark,
            dynamicSchemeVariant: DynamicSchemeVariant.rainbow),
          useMaterial3: true),
        routerConfig: widget.router));
  }
}

class ScaffoldWithNavBar extends StatelessWidget {
  final StatefulNavigationShell navigationShell;
  const ScaffoldWithNavBar({super.key, required this.navigationShell});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: navigationShell.currentIndex,
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'home'),
          BottomNavigationBarItem(icon: Icon(Icons.work), label: 'timetable'),
          BottomNavigationBarItem(icon: Icon(Icons.tab), label: 'messages'),
        ],
        onTap: (int index) => navigationShell.goBranch(index)),
      body: navigationShell);
  }
}
