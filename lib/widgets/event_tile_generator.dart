import 'package:anu_timetable/model/events.dart';
import 'package:anu_timetable/widgets/event_tile.dart';
import 'package:flutter/material.dart';
import 'package:anu_timetable/model/event_tile_arranger.dart';

class EventTileGenerator extends StatelessWidget {
  final Size size; 
  final DateTime day;

  const EventTileGenerator({super.key, required this.size, required this.day});

  @override
  Widget build(BuildContext context) {
    EventsModel eventsModel = EventsModel();

    List<Event> events = eventsModel.getEventsOnDay(day);
    List<EventTileData> eventTilesData = List.generate(events.length, (index) {
      return EventTileData(event: events[index]);
    });

    arrangeEventTiles(eventTilesData, size.width);

    List<EventTile> eventTiles = List.generate(eventTilesData.length, (index) {
       return EventTile(eventTileData: eventTilesData[index]);
    });

    eventsModel.populateEventsForToday();
    return SizedBox(
      width: size.width,
      height: size.height,
      child: Stack(
        children: eventTiles));
  }
}