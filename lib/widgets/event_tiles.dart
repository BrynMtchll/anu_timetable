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
//     final events = [
//     Event(title: '', startTime: DateTime(2026,01,14,10), endTime: DateTime(2026,01,14,13)),
// Event(title: '', startTime: DateTime(2026,01,14,08), endTime: DateTime(2026,01,14,10)),
// Event(title: '', startTime: DateTime(2026,01,14,12), endTime: DateTime(2026,01,14,16)),
// Event(title: '', startTime: DateTime(2026,01,14,14), endTime: DateTime(2026,01,14,17)),
// Event(title: '', startTime: DateTime(2026,01,14,08), endTime: DateTime(2026,01,14,10)),
// Event(title: '', startTime: DateTime(2026,01,14,15), endTime: DateTime(2026,01,14,17)),
// Event(title: '', startTime: DateTime(2026,01,14,15), endTime: DateTime(2026,01,14,19)),
// Event(title: '', startTime: DateTime(2026,01,14,12), endTime: DateTime(2026,01,14,15)),
// Event(title: '', startTime: DateTime(2026,01,14,09), endTime: DateTime(2026,01,14,12)),
//       ];
// final events = [
// Event(title: '', startTime: DateTime(2025,12,19,12), endTime: DateTime(2025,12,19,14)),
// Event(title: '', startTime: DateTime(2025,12,19,08), endTime: DateTime(2025,12,19,11)),
// Event(title: '', startTime: DateTime(2025,12,19,13), endTime: DateTime(2025,12,19,17)),
// Event(title: '', startTime: DateTime(2025,12,19,15), endTime: DateTime(2025,12,19,17)),
// Event(title: '', startTime: DateTime(2025,12,19,11), endTime: DateTime(2025,12,19,15)),
// Event(title: '', startTime: DateTime(2025,12,19,10), endTime: DateTime(2025,12,19,13)),
// Event(title: '', startTime: DateTime(2025,12,19,15), endTime: DateTime(2025,12,19,17)),
// Event(title: '', startTime: DateTime(2025,12,19,14), endTime: DateTime(2025,12,19,15)),
// Event(title: '', startTime: DateTime(2025,12,19,11), endTime: DateTime(2025,12,19,15)),
// Event(title: '', startTime: DateTime(2025,12,19,09), endTime: DateTime(2025,12,19,11)),
// Event(title: '', startTime: DateTime(2025,12,19,12), endTime: DateTime(2025,12,19,14)),
// Event(title: '', startTime: DateTime(2025,12,19,09), endTime: DateTime(2025,12,19,12)),
// Event(title: '', startTime: DateTime(2025,12,19,12), endTime: DateTime(2025,12,19,15)),
// Event(title: '', startTime: DateTime(2025,12,19,09), endTime: DateTime(2025,12,19,12)),
// Event(title: '', startTime: DateTime(2025,12,19,11), endTime: DateTime(2025,12,19,13)),
// Event(title: '', startTime: DateTime(2025,12,19,13), endTime: DateTime(2025,12,19,16)),
// Event(title: '', startTime: DateTime(2025,12,19,14), endTime: DateTime(2025,12,19,18)),
// Event(title: '', startTime: DateTime(2025,12,19,08), endTime: DateTime(2025,12,19,12)),
// Event(title: '', startTime: DateTime(2025,12,19,12), endTime: DateTime(2025,12,19,16)),
//  ];

// final events = [
//   Event(title: '', startTime: DateTime(2025,12,03,08), endTime: DateTime(2025,12,03,11)),
//   Event(title: '', startTime: DateTime(2025,12,03,12), endTime: DateTime(2025,12,03,13)),
//   Event(title: '', startTime: DateTime(2025,12,03,13), endTime: DateTime(2025,12,03,15)),
//   Event(title: '', startTime: DateTime(2025,12,03,11), endTime: DateTime(2025,12,03,15)),
//   Event(title: '', startTime: DateTime(2025,12,03,08), endTime: DateTime(2025,12,03,12)),
//   Event(title: '', startTime: DateTime(2025,12,03,14), endTime: DateTime(2025,12,03,16)),
//   Event(title: '', startTime: DateTime(2025,12,03,15), endTime: DateTime(2025,12,03,16)),
//   Event(title: '', startTime: DateTime(2025,12,03,10), endTime: DateTime(2025,12,03,13)),
//   Event(title: '', startTime: DateTime(2025,12,03,12), endTime: DateTime(2025,12,03,14)),
//   Event(title: '', startTime: DateTime(2025,12,03,15), endTime: DateTime(2025,12,03,19)),
//   Event(title: '', startTime: DateTime(2025,12,03,10), endTime: DateTime(2025,12,03,14)),
//   Event(title: '', startTime: DateTime(2025,12,03,15), endTime: DateTime(2025,12,03,18)),
// ];

      // final events = [
// Event(title: '', startTime: DateTime(2025,12,09,09), endTime: DateTime(2025,12,09,10)),
// Event(title: '', startTime: DateTime(2025,12,09,09), endTime: DateTime(2025,12,09,13)),
// Event(title: '', startTime: DateTime(2025,12,09,13), endTime: DateTime(2025,12,09,14)),
// Event(title: '', startTime: DateTime(2025,12,09,08), endTime: DateTime(2025,12,09,11)),
// Event(title: '', startTime: DateTime(2025,12,09,12), endTime: DateTime(2025,12,09,16)),
// Event(title: '', startTime: DateTime(2025,12,09,10), endTime: DateTime(2025,12,09,11)),
// Event(title: '', startTime: DateTime(2025,12,09,15), endTime: DateTime(2025,12,09,19)),
// Event(title: '', startTime: DateTime(2025,12,09,08), endTime: DateTime(2025,12,09,10)),
// Event(title: '', startTime: DateTime(2025,12,09,13), endTime: DateTime(2025,12,09,15)),
// Event(title: '', startTime: DateTime(2025,12,09,15), endTime: DateTime(2025,12,09,17)),
// Event(title: '', startTime: DateTime(2025,12,09,08), endTime: DateTime(2025,12,09,09)),
// Event(title: '', startTime: DateTime(2025,12,09,08), endTime: DateTime(2025,12,09,12)),
// Event(title: '', startTime: DateTime(2025,12,09,13), endTime: DateTime(2025,12,09,16)),
// Event(title: '', startTime: DateTime(2025,12,09,10), endTime: DateTime(2025,12,09,13)),
// Event(title: '', startTime: DateTime(2025,12,09,12), endTime: DateTime(2025,12,09,16)),
// Event(title: '', startTime: DateTime(2025,12,09,15), endTime: DateTime(2025,12,09,18)),
// Event(title: '', startTime: DateTime(2025,12,09,13), endTime: DateTime(2025,12,09,15)),
// Event(title: '', startTime: DateTime(2025,12,09,12), endTime: DateTime(2025,12,09,15)),
// Event(title: '', startTime: DateTime(2025,12,09,10), endTime: DateTime(2025,12,09,14)),
// Event(title: '', startTime: DateTime(2025,12,09,15), endTime: DateTime(2025,12,09,17)),
// Event(title: '', startTime: DateTime(2025,12,09,10), endTime: DateTime(2025,12,09,11)),
// Event(title: '', startTime: DateTime(2025,12,09,10), endTime: DateTime(2025,12,09,14)),

// ];

//       final events = [
// Event(title: '', startTime: DateTime(2026,01,14,09), endTime: DateTime(2026,01,14,13)),
// Event(title: '', startTime: DateTime(2026,01,14,10), endTime: DateTime(2026,01,14,14)),
// Event(title: '', startTime: DateTime(2026,01,14,11), endTime: DateTime(2026,01,14,14)),
// Event(title: '', startTime: DateTime(2026,01,14,13), endTime: DateTime(2026,01,14,15)),
// Event(title: '', startTime: DateTime(2026,01,14,14), endTime: DateTime(2026,01,14,16)),
// Event(title: '', startTime: DateTime(2026,01,14,09), endTime: DateTime(2026,01,14,13)),
// Event(title: '', startTime: DateTime(2026,01,14,10), endTime: DateTime(2026,01,14,14)),
// Event(title: '', startTime: DateTime(2026,01,14,10), endTime: DateTime(2026,01,14,13)),
// Event(title: '', startTime: DateTime(2026,01,14,13), endTime: DateTime(2026,01,14,15)),
// Event(title: '', startTime: DateTime(2026,01,14,11), endTime: DateTime(2026,01,14,15)),
// Event(title: '', startTime: DateTime(2026,01,14,15), endTime: DateTime(2026,01,14,16)),
// Event(title: '', startTime: DateTime(2026,01,14,08), endTime: DateTime(2026,01,14,10)),
// Event(title: '', startTime: DateTime(2026,01,14,09), endTime: DateTime(2026,01,14,12)),
// Event(title: '', startTime: DateTime(2026,01,14,13), endTime: DateTime(2026,01,14,16)),
// Event(title: '', startTime: DateTime(2026,01,14,12), endTime: DateTime(2026,01,14,14)),
// Event(title: '', startTime: DateTime(2026,01,14,11), endTime: DateTime(2026,01,14,12)),
// Event(title: '', startTime: DateTime(2026,01,14,15), endTime: DateTime(2026,01,14,16)),
// ];

    List<EventTileData> eventTilesData = List.generate(events.length, (index) {
      return EventTileData(event: events[index]);
    });
    print("boo");
    print(size.width);
    // events.removeAt(2);
    // eventTilesData.removeAt(2);

    arrangeEventTiles(eventTilesData, size.width);

    for (int i = 0; i < events.length; i++) {
      print("${events[i].startTime} ${events[i].endTime}");
      print("${eventTilesData[i].top} ${eventTilesData[i].bottom}");
      print("${eventTilesData[i].height} ${eventTilesData[i].width}");
      print("${eventTilesData[i].left}");
    }

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