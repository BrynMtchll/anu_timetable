import 'package:anu_timetable/model/controllers.dart';
import 'package:flutter/material.dart';
import 'package:anu_timetable/util/timetable_layout.dart';
import 'package:provider/provider.dart';

class MyTabBar extends StatelessWidget {
  const MyTabBar({super.key});

  @override
  Widget build(BuildContext context) {
    ColorScheme colorScheme = Theme.of(context).colorScheme;

    return Container(
      alignment: Alignment.center,
      child: 
        SizedBox(
          height: TimetableLayout.tabBarHeight,
          width: 250,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              border: Border.all(width: 0.3),
            ),
            margin: EdgeInsets.symmetric(horizontal: 0, vertical: 8),
            child: Consumer<ViewTabController>(
              builder: (context, tabController, child) => 
              TabBar(
                splashFactory: NoSplash.splashFactory,
                dividerHeight: 0,
                indicatorSize: TabBarIndicatorSize.tab,
                labelColor: Colors.black,
                indicatorPadding: EdgeInsets.symmetric(horizontal: 3, vertical: 3),
                indicator: BoxDecoration(
                  // color: const Color.fromARGB(58, 147, 148, 149),
                  borderRadius: BorderRadius.circular(2),
                  border: Border.all(color: colorScheme.onSurface, width: 0.3)
                ),
                controller: tabController,
                tabs: [
                  Tab(text: "day"),
                  Tab(text: "week"),
                ],
              ),
          )
        ))
    );
  }
}