import 'package:anu_timetable/model/events.dart';
import 'package:anu_timetable/util/timetable_layout.dart';
import 'package:anu_timetable/widgets/event_tile.dart';
import 'package:calendar_view/calendar_view.dart';
import 'package:flutter/material.dart';
import 'package:anu_timetable/model/event_tile_arranger.dart';

class EventGenerator extends StatelessWidget {
  final Size size; 
  final DateTime day;
  //fix!
  final double totalWidth = 300;

  const EventGenerator({super.key, required this.size, required this.day});
  
  List<Widget> _generateEvents(List<Event> events, List<EventTileLayout> eventTileLayouts) {
    int i = 0;
    for (final eventTileLayout in eventTileLayouts) {
      print(i++);
      print("${eventTileLayout.width} ${eventTileLayout.left}");
    }
    
    return List.generate(events.length, (index) {
      double top = TimetableLayout.vertOffset(events[index].startTime.getTotalMinutes);
      double bottom = TimetableLayout.vertOffset(events[index].endTime.getTotalMinutes);
      Size size = Size(eventTileLayouts[index].width, bottom - top);
      print(eventTileLayouts[index].width);
      // return Placeholder();
      return Positioned(
        left: eventTileLayouts[index].left,
        top: top,
        child: EventTile(
          size: size,
        )
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    EventsModel eventsModel = EventsModel();
    
    eventsModel.populateEventsForToday();
    List<Event> events = eventsModel.getEventsOnDay(day);
    return SizedBox(
      width: size.width,
      height: size.height,
      child: Stack(
        children: _generateEvents(events, EventTileArranger().arrange(size, eventsModel.getEventsOnDay(day))),
      )
    );
  }
}