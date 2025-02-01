
import 'package:flutter/material.dart';
import 'package:anu_timetable/widgets/day_view.dart';
import 'package:anu_timetable/widgets/week_view.dart';
import 'package:anu_timetable/widgets/week_bar.dart';
import 'package:anu_timetable/model/timetable_model.dart';
import 'package:anu_timetable/model/controllers.dart';
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
                height: 40,
                child: TabBar(
                  controller: tabController,
                  tabs: [
                    Tab(text: "day"),
                    Tab(text: "week"),
                  ],
                ),
              ),
              Column(
                children: [
                  WeekBar(),
                  ConstrainedBox(
                      constraints: BoxConstraints(
                        maxHeight: constraints.maxHeight - 120,
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