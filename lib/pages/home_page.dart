import 'package:anu_timetable/domain/model/event.dart';
import 'package:anu_timetable/model/current.dart';
import 'package:anu_timetable/model/events.dart';
import 'package:anu_timetable/model/timetable.dart';
import 'package:anu_timetable/widgets/event_list_item.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.all(15),
        child: Consumer<CurrentDay>(
          builder: (context, currentDay, child) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Profile(),
              _DateWidget(day: currentDay.value),
              UpcomingClasses(day: currentDay.value),
              SizedBox(height: 30),
              _friends()
            ]),
        ),
      ));
  }

  Column _friends() {
    return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20),
                  "Friends"),
                Text("plus icon")
              ]),
            SizedBox(height: 5),
            Column(
              children: [
                Container(
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(5))),
                SizedBox(height: 5),
                Container(
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(5))),
                SizedBox(height: 5),
                Container(
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(5)))
              ]),
            SizedBox(height: 10),
            Container(
              height: 40,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(5),
                color: Colors.grey[20]),
              child: Align(
                alignment: Alignment.center,
                child: Text("See All Friends")))
          ]);
  }
}
class Profile extends StatelessWidget {
  const Profile({super.key});

  @override
  Widget build(BuildContext context) {
    ColorScheme colorScheme = Theme.of(context).colorScheme;

    return Container(
      height: 40,
      width: 40,
      decoration: BoxDecoration(
        border: BoxBorder.all(color: colorScheme.onSurface, width: 0.4),
        color: colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(30)),
      child: Center(
        child: Text(
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 16),
              "BM"),
      ));
  }
}

class _DateWidget extends StatelessWidget {
  final DateTime day;
  const _DateWidget({required this.day});

  @override
  Widget build(BuildContext context) {
    ColorScheme colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Center(
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: colorScheme.onSurface,
                    fontSize: 16),
                  DateFormat("EEEE").format(day)),
                Text(
                  style: TextStyle(
                    fontWeight: FontWeight.w400,
                    color: colorScheme.secondary,
                    fontSize: 16),
                  DateFormat(", MMM").format(day)),
              ]),
            Text(
              style: TextStyle(
                height: 1,
                color: colorScheme.onSurface,
                fontSize: 50),
              day.day.toString()),
          ])));
  }
}

class UpcomingClasses extends StatelessWidget {
  final DateTime day;
  const UpcomingClasses({super.key, required this.day});

  @override
  Widget build(BuildContext context) {
    ColorScheme colorScheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: EdgeInsets.only(bottom: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface),
                "upcomming".toUpperCase()),
              Text(
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  decoration: TextDecoration.underline,
                  color: colorScheme.primary),
                "see all"),
            ])),
        Consumer<EventsVM> (
          builder: (context, eventsVM, child) { 
            List<Event> events = eventsVM.getEventsOnDay(TimetableVM.getDayIndex(day));
            return Column(
              children: [for (final event in events) EventItem(event: event)]);
          })
      ]);
  }
}