
import 'package:flutter/material.dart';
import 'package:anu_timetable/widgets/day_view.dart';
import 'package:anu_timetable/widgets/week_view.dart';
import 'package:anu_timetable/widgets/week_bar.dart';
import 'package:anu_timetable/model/timetable_layout.dart';
import 'package:provider/provider.dart';


class TimetablePage extends StatefulWidget {

  const TimetablePage({super.key});

  @override
  State<TimetablePage> createState() => _TimetablePageState();
}

class _TimetablePageState extends State<TimetablePage> {
  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        return Consumer<TabController>(
          builder: (context, tabController, child) => 
            Column(
            children: [
              SizedBox(
                height: TimetableLayout.tabBarHeight,
                child: Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  margin: EdgeInsets.symmetric(horizontal: 20, vertical: 7.5),
                  child: TabBar(
                    splashFactory: NoSplash.splashFactory,
                    dividerHeight: 0,
                    labelColor: Theme.of(context).colorScheme.onInverseSurface,
                    indicatorSize: TabBarIndicatorSize.tab,
                    indicatorPadding: EdgeInsets.symmetric(horizontal: 2, vertical: 2),
                    indicator: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceTint,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    controller: tabController,
                    tabs: [
                      Tab(text: "day"),
                      Tab(text: "week"),
                    ],
                  ),
                )
              ),
              Column(
                children: [
                  WeekBar(),
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight: constraints.maxHeight - TimetableLayout.tabBarHeight - TimetableLayout.weekBarHeight,
                      maxWidth: constraints.maxWidth,
                    ),
                    child: TabBarView(
                      controller: tabController,
                      children: [
                        DayView(),
                        WeekView(),
                      ]
                    )
                  ),
                ]
              )
            ]
          )
        );
      }
    );
  }
}