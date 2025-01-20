
import 'package:flutter/material.dart';
// import 'package:table_calendar/table_calendar.dart';
import 'package:anu_timetable/widgets/day_view.dart';
// import 'package:calendar_view/calendar_view.dart';
// import 'package:anu_timetable/widgets/week_bar.dart';

class TimetablePage extends StatelessWidget {
  const TimetablePage({super.key});

  @override
  Widget build(BuildContext context) {
    return DayView();
  }
}