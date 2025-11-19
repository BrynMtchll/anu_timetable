import 'package:anu_timetable/model/controller.dart';
import 'package:flutter/material.dart';
import 'package:anu_timetable/util/timetable_layout.dart';
import 'package:provider/provider.dart';

class MyTabBar extends StatelessWidget {
  const MyTabBar({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      alignment: Alignment.center,
      height: TimetableLayout.tabBarHeight,
      width: 210,
      decoration: BoxDecoration(
        color: colorScheme.surfaceBright,
        borderRadius: BorderRadius.circular(50)),
          child: Consumer<ViewTabController>(
            builder: (context, tabController, child) => TabBar(
              splashFactory: NoSplash.splashFactory,
              dividerHeight: 0,
              indicatorSize: TabBarIndicatorSize.tab,
              labelColor: colorScheme.onSurface,
              indicatorPadding: EdgeInsets.symmetric(horizontal: 1.5, vertical: 1.5),
              labelStyle: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
              unselectedLabelStyle: TextStyle(
                fontSize: 13, 
                fontWeight: FontWeight.w500, 
                color: colorScheme.onSurface),
              indicator: BoxDecoration(
                borderRadius: BorderRadius.circular(50),
                color: colorScheme.surface),
              controller: tabController,
              tabs: [Tab(text: "list"), Tab(text: "day"),Tab(text: "week")])));
  }
}
