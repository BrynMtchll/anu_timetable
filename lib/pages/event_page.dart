import 'package:anu_timetable/domain/model/event.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class EventPage extends StatelessWidget {
  final Event event;
  const EventPage({super.key, required this.event});

  @override
  Widget build(BuildContext context) {
    ColorScheme colorScheme = ColorScheme.of(context);
    return Scaffold(
      appBar: AppBar(),
      body: Container(
        margin: EdgeInsets.symmetric(horizontal: 20, vertical: 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600), 
              event.title),
            Text(style: TextStyle(fontSize: 15, fontWeight: FontWeight.w400), 
              event.summary),
            Text(
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w400), 
              DateFormat('EEEE, MMMM d, yyyy').format(event.startDate)),
            Text(
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w400), 
              "${DateFormat('hh:mma').format(event.startDate)} - ${DateFormat('hh:mma').format(event.endDate)}"),
            Text(
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w400), 
              '[rm 204, Hannah Neumann building]'),
            Text(
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w400, color: colorScheme.primary), 
              "[The address blee bloue blah ln 21324]"),
          ])));
    }
}
