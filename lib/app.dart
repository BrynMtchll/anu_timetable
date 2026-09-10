import 'dart:async';

import 'package:anu_timetable/data/repositories/event_repository_firebase.dart';
import 'package:anu_timetable/data/repositories/user_repository_firebase.dart';
import 'package:anu_timetable/model/animation.dart';
import 'package:anu_timetable/model/current.dart';
import 'package:anu_timetable/model/events.dart';
import 'package:anu_timetable/model/sync_anu.dart';
import 'package:anu_timetable/model/user.dart';
import 'package:anu_timetable/util/theme_extension.dart';
import 'package:anu_timetable/util/timetable_layout.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
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
        Provider(create:(context) => EventRepositoryFirebase()),
        Provider(create:(context) => UserRepositoryFirebase()),
        ChangeNotifierProvider(create: (context) => CurrentDay()),
        ChangeNotifierProvider(create: (context) => CurrentMinute()),
        ChangeNotifierProvider(create: (context) => CurrentSecond()),
        ChangeNotifierProvider(create: (context) => MonthBarAnimationNotifier(DateTime.now())),
        ChangeNotifierProvider.value(value: viewTabController),
        ChangeNotifierProvider.value(value: dayViewScrollController),
        ChangeNotifierProvider.value(value: weekViewScrollController),
        ChangeNotifierProvider<TimetableVM>(create: (context) => TimetableVM()),
        ChangeNotifierProvider<UserEventsVM>(create: (context) => UserEventsVM(eventRepository: context.read(), userRepository: context.read())),
        ChangeNotifierProvider<UserVM>(create: (context) => UserVM(userRepository: context.read())
          ..loadCurrentUser.execute()),
        ChangeNotifierProvider<SyncAnuVM>(create: (context) => SyncAnuVM(eventRepository: context.read(), userRepository: context.read()))
      ],
      child: AuthGate(
        child: MaterialApp.router(
          title: 'Flutter Demo',
          theme: ThemeData(
            splashFactory: NoSplash.splashFactory,
            // splashColor: Colors.transparent,
            // Removes the highlight background fade on tap
            highlightColor: Colors.transparent,
            colorScheme: ColorScheme.fromSeed(
              // 255, 190, 135, 43
              seedColor: const Color.fromARGB(255, 255, 119, 0),
              primary: const Color.fromARGB(255, 255, 140, 79),
              onPrimary: const Color.fromARGB(255, 15, 12, 9),
              error: Color.fromARGB(255, 255, 91, 79),
              
              // surfaceContainerHighest: const Color.fromARGB(255, 50, 41, 85),
              brightness: Brightness.dark,
              dynamicSchemeVariant: DynamicSchemeVariant.rainbow),
            useMaterial3: true).copyWith(
              extensions: [
                CalendarTheme.dark(),
              ]),
          routerConfig: widget.router)));
  }
}

class AuthGate extends StatefulWidget {
  const AuthGate({super.key, required this.child});

  final Widget child;

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  StreamSubscription<User?>? _authSub;

  @override
  void initState() {
    super.initState();
    final vm = context.read<UserEventsVM>();
    _authSub = FirebaseAuth.instance.authStateChanges().listen((user) {
      if (user != null) {
        vm.startWatching(user.uid);
      } else {
        vm.stopWatching();
      }
    });
  }

  @override
  void dispose() {
    _authSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

class ScaffoldWithNavBar extends StatefulWidget {
  final StatefulNavigationShell navigationShell;
  const ScaffoldWithNavBar({super.key, required this.navigationShell});

  @override
  State<ScaffoldWithNavBar> createState() => _ScaffoldWithNavBarState();
}

class _ScaffoldWithNavBarState extends State<ScaffoldWithNavBar> {
  bool toRight = true;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: widget.navigationShell.currentIndex,
        toRight: toRight,
        onTap: (int index) {
          toRight = widget.navigationShell.currentIndex < index;
          widget.navigationShell.goBranch(index);
        }),
      body: widget.navigationShell);
  }
}

class CustomBottomNavBar extends StatelessWidget {
  const CustomBottomNavBar({super.key, required this.currentIndex, required this.toRight, required this.onTap});

  final ValueChanged<int> onTap;
  final int currentIndex;
  final bool toRight;

  static const _items = [
    (icon: Icons.home, label: 'home'),
    (icon: Icons.view_week, label: 'timetable'),
    (icon: Icons.message, label: 'messages'),
    (icon: Icons.person, label: 'profile'),
  ];

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    double compAngle(bool isCurrent) {
      if (toRight && isCurrent) {
        return 0;
      } else if (isCurrent) {
        return 3.14;
      } else if (toRight) {
        return 3.14;
      }
      return 0;
    }
    return SafeArea(
      child: SizedBox(
        height: 60,
        child: Row(
          children: [
            for (final (i, item) in _items.indexed)
              Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onTap: () => onTap(i),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        item.icon,
                        color: colorScheme.onSurface),
                      Text(item.label, style: TextStyle(
                        color: colorScheme.onSurface,
                        fontSize: 12))
                    ]),
                  )).animate(
                      target: i == currentIndex ? 1 : 0,
                    ).shimmer(
                      curve: Curves.easeOut,
                      angle: compAngle(i == currentIndex),
                      stops: [0.0, 0.0],
                      duration: Duration(milliseconds: 300),
                      // blendMode: BlendMode.,
                      colors: [ colorScheme.primary, const Color.fromARGB(0, 255, 255, 255)])
          ])));
  }
}
