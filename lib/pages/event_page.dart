import 'package:anu_timetable/domain/model/event.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class EventPage extends StatelessWidget {
  final Event event;
  const EventPage({super.key, required this.event});

  @override
  Widget build(BuildContext context) {
    ColorScheme colorScheme = ColorScheme.of(context);
    print(event.location);
    return Scaffold(
      appBar: AppBar(),
      body: Container(
        margin: EdgeInsets.symmetric(horizontal: 20, vertical: 0),
        child: Column(
          spacing: 5,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800), 
              "${event.title} - ${event.type.typeStrFull}"),
            Text(style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500), 
              event.summary),
            Container(
              margin: EdgeInsets.symmetric(vertical: 5),
              padding: EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainer,
                borderRadius: BorderRadius.circular(10)),
              child: Row(
                spacing: 10,
                children: [
                  Icon(Icons.date_range_outlined, color: colorScheme.primary),
                  Text(style: TextStyle(fontSize: 15, fontWeight: FontWeight.w400), 
                    "${DateFormat("h:mma, EE, MMM d, yyyy").format(event.startDate)} \u{2014} \n${DateFormat("h:mma, EEE, MMM d, yyyy").format(event.endDate)}"),
                ])),
            Container(
              margin: EdgeInsets.symmetric(vertical: 5),
              padding: EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainer,
                borderRadius: BorderRadius.circular(10)),
              child: Row(
                spacing: 10,
                children: [
                  Icon(Icons.location_pin, color: colorScheme.primary),
                  Expanded(
                    child: Text(style: TextStyle(fontSize: 15, fontWeight: FontWeight.w400), softWrap: true,
                      "${event.room}${event.room !="" ? '\n' : ''}${event.location}"))
                ])),
          ])));
    }
}
