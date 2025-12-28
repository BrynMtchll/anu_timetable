import 'package:anu_timetable/domain/model/event.dart';
import 'package:anu_timetable/model/animation.dart';
import 'package:anu_timetable/widgets/event_tile.dart';
import 'package:flutter/material.dart';
import 'package:anu_timetable/util/event_tile_arranger.dart';

class EventTiles extends StatelessWidget {
  final Size size; 
  final List<Event> events;
  final int dayIndex;

  const EventTiles({super.key, required this.dayIndex, required this.events, required this.size});

  void connected(List<List<int>> adjList, List<bool>visited, List<EventTile> eventTiles, int event, bool leftSide) {
    if (visited[event]) {
      return;
    }
    eventTiles[event].collapse = true;
    eventTiles[event].onLeft = leftSide;
    visited[event] = true;

    for (final adj in adjList[event]) {
      connected(adjList, visited, eventTiles, adj, leftSide);
    }
  }
  
  @override
  Widget build(BuildContext context) {
    EventTileAnimationNotifier eventTileAnimationNotifier = EventTileAnimationNotifier(dayIndex: dayIndex);
    List<EventTileData> eventTilesData = List.generate(events.length, (index) {
      return EventTileData(event: events[index]);
    });
    var (adjList, invAdjList) = arrangeEventTiles(eventTilesData, size.width);
    for (int i = 0; i < events.length; i++) {
      // print("$i ${events[i].startTime} ${events[i].endTime} -> ${eventTilesData[i].width}");
    }
    List<EventTile> eventTiles = List.generate(eventTilesData.length, (index) {
       return EventTile(eventTileData: eventTilesData[index], eventTileAnimationNotifier: eventTileAnimationNotifier, size: size);
    });
    return SizedBox(
      width: size.width,
      height: size.height,
      child: ListenableBuilder(listenable: eventTileAnimationNotifier, 
      builder:(context, child) {
        if (eventTileAnimationNotifier.expanded) {
          for (final tile in eventTiles) {
            tile.collapse = false;
          }
          EventTile expandedTile = eventTiles.firstWhere((element) 
            => element.eventTileData.event.id == eventTileAnimationNotifier.eventId);
          int event = eventTiles.indexOf(expandedTile);
          List<bool> visited = List.filled(eventTilesData.length, false);

          connected(adjList, visited, eventTiles, event, false);
          visited = List.filled(eventTilesData.length, false);

          connected(invAdjList, visited, eventTiles, event, true);
          print("hey");
          // return Stack(
          //   children: [...eventTiles, Positioned(
          //     top: 0,
          //     left: 0,
          //     width: size.width,
          //     height: size.height,
          //     child: TapRegion(
          //       consumeOutsideTaps: true,
          //       child: SizedBox()))]);
        }
        return Stack(
        children: eventTiles);}));
  }
}