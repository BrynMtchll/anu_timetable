
import 'package:anu_timetable/model/controllers.dart';
import 'package:flutter/material.dart';
import 'package:anu_timetable/widgets/day_view.dart';
import 'package:anu_timetable/widgets/week_view.dart';
import 'package:anu_timetable/widgets/week_bar.dart';
import 'package:anu_timetable/util/timetable_layout.dart';
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
      builder: (BuildContext context, BoxConstraints constraints) =>
        Consumer<ViewTabController>(
          builder: (context, viewTabController, child) => 
            Column(
              children: [
                WeekBar(),
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: constraints.maxHeight - TimetableLayout.weekBarHeight,
                    maxWidth: constraints.maxWidth,
                  ),
                  child: TabBarView(
                    controller: viewTabController,
                    physics: NeverScrollableScrollPhysics(),
                    children: [
                      DayView(),
                      WeekView(),
                    ]
                  )
                ),
              ]
            )
        )
    );
  }
}