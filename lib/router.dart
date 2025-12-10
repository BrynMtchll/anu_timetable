// import 'package:go_router/go_router.dart';

// func getBranches() {
//   branches: <StatefulShellBranch>[
//   // The route branch for the first tab of the bottom navigation bar.
//   StatefulShellBranch(
//     navigatorKey: _sectionANavigatorKey,
//     routes: <RouteBase>[
//       GoRoute(
//         // The screen to display as the root in the first tab of the
//         // bottom navigation bar.
//         path: '/a',
//         builder:
//             (BuildContext context, GoRouterState state) =>
//                 const RootScreen(label: 'A', detailsPath: '/a/details'),
//         routes: <RouteBase>[
//           // The details screen to display stacked on navigator of the
//           // first tab. This will cover screen A but not the application
//           // shell (bottom navigation bar).
//           GoRoute(
//             path: 'details',
//             builder:
//                 (BuildContext context, GoRouterState state) =>
//                     const DetailsScreen(label: 'A'),
//           ),
//         ],
//       ),
//     ],
//     // To enable preloading of the initial locations of branches, pass
//     // 'true' for the parameter `preload` (false is default).
//   ),
// }