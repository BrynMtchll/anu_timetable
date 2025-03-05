import 'package:flutter/material.dart';

class MyBottomNavigationBar extends StatelessWidget {
  final int currentPageIndex;
  final void Function(int) onPageChanged;
  const MyBottomNavigationBar({
    super.key, 
    required this.currentPageIndex, 
    required this.onPageChanged
  });

  @override
  Widget build(BuildContext context) {
    ColorScheme colorScheme = Theme.of(context).colorScheme;
    return Container(
      height: 100,
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(width: 0.5, color: colorScheme.onSurface))),
      child: NavigationBar(
        elevation: 0,
        backgroundColor: colorScheme.surface,
        selectedIndex: currentPageIndex,
        indicatorColor: Colors.transparent,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        onDestinationSelected: onPageChanged,
        destinations: const <Widget>[
          NavigationDestination(
            icon: Icon(Icons.home_outlined), 
            selectedIcon: Icon(Icons.home),
            label: 'Home'
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_view_week_outlined), 
            selectedIcon: Icon(Icons.calendar_view_week),
            label: 'Timetable'),
          NavigationDestination(
            icon: Icon(Icons.chat_bubble_outline), 
            selectedIcon: Icon(Icons.chat_bubble), 
            label: 'Messages'),
        ]));
  }
}
