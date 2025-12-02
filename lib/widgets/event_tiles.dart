import 'package:anu_timetable/domain/model/event.dart';
import 'package:anu_timetable/widgets/event_tile.dart';
import 'package:flutter/material.dart';
import 'package:anu_timetable/util/event_tile_arranger.dart';

class EventTiles extends StatelessWidget {
  final Size size; 
  final DateTime day;
  final List<Event> events;

  const EventTiles({super.key, required this.events, required this.size, required this.day});

  @override
  Widget build(BuildContext context) {

    List<EventTileData> eventTilesData = List.generate(events.length, (index) {
      return EventTileData(event: events[index]);
    });
    arrangeEventTiles(eventTilesData, size.width);
    // for (int i = 0; i < events.length; i++) {
      // print("$i ${events[i].startTime} ${events[i].endTime} -> ${eventTilesData[i].width}");
    // }

    List<EventTile> eventTiles = List.generate(eventTilesData.length, (index) {
       return EventTile(eventTileData: eventTilesData[index]);
    });

    return SizedBox(
      width: size.width,
      height: size.height,
      child: Stack(
        children: eventTiles));
  }
}