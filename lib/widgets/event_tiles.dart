import 'package:anu_timetable/domain/model/event.dart';
import 'package:anu_timetable/model/animation.dart';
import 'package:anu_timetable/widgets/event_tile.dart';
import 'package:flutter/material.dart';
import 'package:anu_timetable/util/event_tile_arranger.dart';

class EventTiles extends StatelessWidget {
  final Size size; 
  final List<Event> events;
  final bool transition;

  const EventTiles({super.key, required this.events, required this.size, required this.transition});
  
  @override
  Widget build(BuildContext context) {
    List<EventTileData> eventTilesData = List.generate(events.length, (index) 
      => EventTileData(event: events[index]));
    var (adjList, invAdjList) = arrangeEventTiles(eventTilesData, size.width);
    EventTileAnimationNotifier eventTileAnimationNotifier = EventTileAnimationNotifier(
      adjList: adjList, invAdjList: invAdjList, numEvents: events.length);
    List<EventTile> eventTiles = List.generate(eventTilesData.length, (index) {
      return EventTile(event: events[index], eventTileData: eventTilesData[index], 
        animationNotifier: eventTileAnimationNotifier, size: size, index: index, transition: transition);
    });
    return SizedBox(
      width: size.width,
      height: size.height,
      child: Stack(children: eventTiles));
  }
}