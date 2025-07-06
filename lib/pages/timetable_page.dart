
import 'package:anu_timetable/model/controllers.dart';
import 'package:flutter/material.dart';
import 'package:anu_timetable/widgets/day_view.dart';
import 'package:anu_timetable/widgets/week_view.dart';
import 'package:anu_timetable/widgets/week_bar.dart';
import 'package:anu_timetable/widgets/month_bar.dart';
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
        Consumer2<ViewTabController, MonthBarPageController>(
          builder: (context, viewTabController, monthBarPageController, child) => 
          OverflowBox( 
                  maxHeight: double.infinity,
                  alignment: Alignment.topCenter,
                  minHeight: 0,
            child: Column(
              children: [
                Stack(children: [
                  WeekBar(),
                  Visibility(
                    maintainState: true,
                    maintainAnimation: true,
                    visible: monthBarPageController.show,
                    child: MonthBar()
                  )]),
                AnimatedContainer(
                    duration: Duration(milliseconds: 200),
                    curve: Curves.easeInOut,
                    height: constraints.maxHeight - monthBarPageController.height,
                    width: constraints.maxWidth,
                  child: TabBarView(
                    controller: viewTabController,
                    physics: NeverScrollableScrollPhysics(),
                    children: [
                      DayView(),
                      WeekView(),
                    ]))
              ]))));
  }
}