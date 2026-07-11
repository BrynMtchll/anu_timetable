import 'package:anu_timetable/domain/model/user.dart';
import 'package:anu_timetable/model/animation.dart';
import 'package:anu_timetable/model/controller.dart';
import 'package:anu_timetable/model/events.dart';
import 'package:anu_timetable/model/user.dart';
import 'package:anu_timetable/widgets/app_bar.dart';
import 'package:anu_timetable/widgets/list_view.dart';
import 'package:anu_timetable/widgets/day_view.dart';
import 'package:anu_timetable/widgets/week_view.dart';
import 'package:anu_timetable/widgets/week_bar.dart';
import 'package:anu_timetable/widgets/month_bar.dart';
import 'package:anu_timetable/util/timetable_layout.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class TimetablePage extends StatelessWidget {
  const TimetablePage({super.key});

  @override
  Widget build(BuildContext context) {
    final userVM = Provider.of<UserVM>(context, listen: false);
    return ListenableBuilder(
      listenable: userVM.loadCurrentUser,
      builder: (context, child) {
        final user = userVM.currentUser!;
        Provider.of<UserEventsVM>(context, listen: false)
          .loadEvents.execute(user.eventRuleKeys, DateTime(DateTime.now().year), DateTime(DateTime.now().year + 1));
        return child!;
      },
      child: Scaffold(
        appBar: MyAppBar(),
        body: LayoutBuilder(
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
                      child: GestureDetector(
                        onTap: () {
                          if (monthBarAnimationNotifier.expanded) {
                            monthBarAnimationNotifier.open = false;
                          }
                        },
                        child: child)),
                  child: TabBarView(
                    controller: Provider.of<ViewTabController>(context, listen: false),
                    physics: NeverScrollableScrollPhysics(),
                    children: [TListView(), DayView(), WeekView()]))
                ])))));
  }
}