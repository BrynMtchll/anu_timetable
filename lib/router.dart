import 'package:anu_timetable/app.dart';
import 'package:anu_timetable/domain/model/event.dart';
import 'package:anu_timetable/pages/event_page.dart';
import 'package:anu_timetable/pages/home_page.dart';
import 'package:anu_timetable/pages/login_page.dart';
import 'package:anu_timetable/pages/messages_page.dart';
import 'package:anu_timetable/pages/profile_page.dart';
import 'package:anu_timetable/pages/sync_anu_page.dart';
import 'package:anu_timetable/pages/timetable_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';

class MyRouter {
  final router = GoRouter(
    initialLocation: '/home',
    routes: <RouteBase>[
      GoRoute(
        path: '/syncAnu',
        builder: (final context, final state) => SyncAnuPage()),
      GoRoute(
        path: "/event/:id",
        builder: (final context, final state) {
          final event = state.extra as Event;
          return EventPage(event: event);
        }),
      GoRoute(
        path: '/login',
        builder: (final context, final state) => const LoginPage()),
      StatefulShellRoute.indexedStack(
        builder: (final context, final state, StatefulNavigationShell navigationShell)
          => ScaffoldWithNavBar(navigationShell: navigationShell),
        branches: <StatefulShellBranch>[
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: '/home',
                builder: (final context, final state) => const HomePage()),
            ]),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: '/timetable',
                builder: (final context, final state) => const TimetablePage()),
            ]),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: '/messages',
                builder: (final context, final state) => const MessagesPage()),
            ]),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: '/profile',
                builder: (final context, final state) => const ProfilePage()),
            ])
        ]),
    ],
    
    redirect: (final context, final state) {
      final bool loggedIn = FirebaseAuth.instance.currentUser != null;
      final bool loggingIn = state.matchedLocation == '/login';
      if (!loggedIn) return '/login';
      if (loggingIn) return '/home';
      return null;
    });
}