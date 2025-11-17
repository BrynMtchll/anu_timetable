
import 'package:anu_timetable/model/animation_notifiers.dart';
import 'package:anu_timetable/model/controllers.dart';
import 'package:anu_timetable/util/timetable_layout.dart';
import 'package:anu_timetable/widgets/list_view.dart';
import 'package:flutter/material.dart';
import 'package:anu_timetable/widgets/day_view.dart';
import 'package:anu_timetable/widgets/week_view.dart';
import 'package:anu_timetable/widgets/week_bar.dart';
import 'package:anu_timetable/widgets/month_bar.dart';
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
        OverflowBox( 
          maxHeight: double.infinity,
          alignment: Alignment.topCenter,
          minHeight: 0,
          child: Column(
            children: [
              Stack(children: [WeekBar(), MonthBar()]),
              Consumer<MonthBarAnimationNotifier>(
                builder: (context, monthBarAnimationNotifier, child) =>
                  SizedBox(
                    height: monthBarAnimationNotifier.expanded
                    ? constraints.maxHeight - monthBarAnimationNotifier.height
                    : constraints.maxHeight - TimetableLayout.weekBarHeight,
                    width: constraints.maxWidth,
                    child: child),
                child: TabBarView(
                  controller: Provider.of<ViewTabController>(context, listen: false),
                  physics: NeverScrollableScrollPhysics(),
                  children: [TListView(), DayView(), WeekView()]))
              ])));
  }
}