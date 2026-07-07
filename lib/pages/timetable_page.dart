
import 'package:anu_timetable/domain/model/event_rule.dart';
import 'package:anu_timetable/domain/model/user.dart';
import 'package:anu_timetable/model/animation.dart';
import 'package:anu_timetable/model/controller.dart';
import 'package:anu_timetable/model/events.dart';
import 'package:anu_timetable/model/user.dart';
import 'package:anu_timetable/util/timetable_layout.dart';
import 'package:anu_timetable/widgets/app_bar.dart';
import 'package:anu_timetable/widgets/list_view.dart';
import 'package:flutter/material.dart';
import 'package:anu_timetable/widgets/day_view.dart';
import 'package:anu_timetable/widgets/week_view.dart';
import 'package:anu_timetable/widgets/week_bar.dart';
import 'package:anu_timetable/widgets/month_bar.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

class TimetablePage extends StatefulWidget {
  const TimetablePage({super.key});

  @override
  State<TimetablePage> createState() => _TimetablePageState();
}

void startup(BuildContext context) async {
  // TODO all to view model
  final userVM = context.read<UserVM>();
  final userEventsVM = context.read<UserEventsVM>();
  await userVM.loadCurrentUser.execute();
  User user = userVM.currentUser!;
  // EventRule eventRule = EventRule(id: Uuid().v4(), title: '', startDate: DateTime(DateTime.now().year - 1, 1, 1, 10), 
  //   endDate: DateTime(DateTime.now().year - 1, 1, 1, 12), isAllDay: false, duration: 120, isRecurring: true, 
  //   recurrencePattern: RecurrencePattern(freq: Freq.daily, interval: 2), location: '', userIds: ["LmyIsYZXRXUq2MvwAq1pLdGQ87en"]);
  // await userEventsVM.addEventRules.execute([eventRule]);
  await userEventsVM.loadEvents.execute(user.eventRuleIds, DateTime(DateTime.now().year), DateTime(DateTime.now().year + 1));
}

class _TimetablePageState extends State<TimetablePage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      startup(context);
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
              ]))));
  }
}