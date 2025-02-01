import 'package:flutter/material.dart';
import 'package:anu_timetable/model/timetable_layout.dart';
import 'package:provider/provider.dart';

class MyTabBar extends StatelessWidget {
  const MyTabBar({super.key});

  @override
  Widget build(BuildContext context) {
    ColorScheme colorScheme = Theme.of(context).colorScheme;

    return Consumer<TabController>(
      builder: (context, tabController, child) => 
        SizedBox(
          height: TimetableLayout.tabBarHeight,
          width: 200,
          child: Container(
            decoration: BoxDecoration(
              // color: Theme.of(context).colorScheme.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(width: 0.5),
            ),
            margin: EdgeInsets.symmetric(horizontal: 20, vertical: 7.5),
            child: TabBar(
              splashFactory: NoSplash.splashFactory,
              dividerHeight: 0,
              // labelColor: Theme.of(context).colorScheme.onInverseSurface,
              indicatorSize: TabBarIndicatorSize.tab,
              indicatorPadding: EdgeInsets.symmetric(horizontal: 3, vertical: 3),
              indicator: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(5),
                border: Border.all(color: colorScheme.onSurface, width: 0.5)
              ),
              controller: tabController,
              tabs: [
                Tab(text: "day"),
                Tab(text: "week"),
              ],
            ),
          )
        )
    );
  }
}