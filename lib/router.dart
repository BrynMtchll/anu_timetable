import 'package:anu_timetable/app.dart';
import 'package:anu_timetable/model/event.dart';
import 'package:anu_timetable/pages/event_page.dart';
import 'package:anu_timetable/pages/home_page.dart';
import 'package:anu_timetable/pages/login_page.dart';
import 'package:anu_timetable/pages/messages_page.dart';
import 'package:anu_timetable/pages/timetable_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class MyRouter {
  final router = GoRouter(
    initialLocation: '/timetable',
    routes: <RouteBase>[
      GoRoute(
        path: '/login',
        builder: (BuildContext context, GoRouterState state) => const LoginPage()
      ),
      StatefulShellRoute.indexedStack(
        builder: (BuildContext context, GoRouterState state, 
          StatefulNavigationShell navigationShell) =>
          ScaffoldWithNavBar(navigationShell: navigationShell),
        branches: <StatefulShellBranch>[
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: '/home',
                builder: (BuildContext context, GoRouterState state) => 
                  const HomePage()),
            ]),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: '/timetable',
                builder: (BuildContext context, GoRouterState state) => 
                  const TimetablePage(),
                routes: <RouteBase>[
                  GoRoute(
                    path: "event/:id",
                    builder: (BuildContext context, GoRouterState state) {
                      final id = state.pathParameters['id']!;
                      final eventVM = EventVM(eventRepository: context.read());
                      eventVM.loadEvent.execute(id);
                      return EventPage(eventVM: eventVM, id: id);
                    }),
                ]),
            ]),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: '/messages',
                builder: (BuildContext context, GoRouterState state) => 
                  const MessagesPage()),
            ])
        ]),
    ],

    
    redirect: (BuildContext context, GoRouterState state) {
      final bool loggedIn = FirebaseAuth.instance.currentUser != null;
      final bool loggingIn = state.matchedLocation == '/login';
      if (!loggedIn) return '/login';
      if (loggingIn) return '/home';
      return null;
    });
}