import 'package:anu_timetable/model/controllers.dart';
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
      child: 
        SizedBox(
          height: TimetableLayout.tabBarHeight,
          width: 180,
          child: Container(
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(10)),
            child: Consumer<ViewTabController>(
              builder: (context, tabController, child) => 
                TabBar(
                  splashFactory: NoSplash.splashFactory,
                  dividerHeight: 0,
                  indicatorSize: TabBarIndicatorSize.tab,
                  labelColor: colorScheme.onSurface,
                  indicatorPadding: EdgeInsets.symmetric(horizontal: 1.5, vertical: 1.5),
                  labelStyle: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                  unselectedLabelStyle: TextStyle(
                    fontSize: 14, 
                    fontWeight: FontWeight.w500, 
                    color: colorScheme.onSurface),
                  indicator: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: colorScheme.surface),
                  controller: tabController,
                  tabs: [
                    Tab(text: "day"),
                    Tab(text: "week"),
                  ])))));
  }
}
