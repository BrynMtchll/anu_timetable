import 'package:anu_timetable/domain/model/event.dart';
import 'package:anu_timetable/model/event.dart';
import 'package:anu_timetable/util/timetable_layout.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class EventPage extends StatelessWidget {
  final EventVM eventVM;
  final String id;
  late Event event;
  EventPage({super.key, required this.eventVM, required this.id});

  @override
  Widget build(BuildContext context) {
    ColorScheme colorScheme = ColorScheme.of(context);
    return Scaffold(
      appBar: AppBar(),
      body: ListenableBuilder(
        listenable: eventVM.loadEvent, 
        builder: (BuildContext context, Widget? child) {
          Event? e = eventVM.getEvent(id);
          if (e == null) return SizedBox();
          event = e;
          return Container(
            margin: EdgeInsets.symmetric(horizontal: 20, vertical: 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600), 
                  event.title),
                Text(
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w400), 
                  DateFormat('EEEE, MMM d, yyyy').format(event.startTime)),
                Text(
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w400), 
                  "${DateFormat('hh:mma').format(event.startTime)} - ${DateFormat('hh:mma').format(event.endTime)}"),
                Text(
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w400), 
                  '[rm 204, Hannah Neumann building]'),
                Text(
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w400, color: colorScheme.primary), 
                  "[The address blee bloue blah ln 21324]"),
              ]));
        }));
  }
}