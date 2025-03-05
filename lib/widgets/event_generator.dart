import 'package:anu_timetable/model/events.dart';
import 'package:anu_timetable/util/timetable_layout.dart';
import 'package:anu_timetable/widgets/event_tile.dart';
import 'package:calendar_view/calendar_view.dart';
import 'package:flutter/material.dart';
import 'package:anu_timetable/model/event_tile_arranger.dart';

class EventGenerator extends StatelessWidget {
  final Size size; 
  final DateTime day;

  const EventGenerator({super.key, required this.size, required this.day});
  
  List<Widget> _generateEvents(List<Event> events, List<EventTileLayout> eventTileLayouts) {
    return List.generate(events.length, (index) {
      final top = TimetableLayout.vertOffset(events[index].startTime.getTotalMinutes);
      final bottom = TimetableLayout.vertOffset(events[index].endTime.getTotalMinutes);
      final size = Size(eventTileLayouts[index].width, bottom - top);
      return Positioned(
        left: eventTileLayouts[index].left,
        top: top,
        child: EventTile(size: size));
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
        children: _generateEvents(events, 
          EventTileArranger().arrange(size, eventsModel.getEventsOnDay(day)))));
  }
}