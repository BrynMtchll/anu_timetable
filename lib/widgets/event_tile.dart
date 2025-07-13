import 'package:anu_timetable/model/event_tile_arranger.dart';
import 'package:anu_timetable/util/timetable_layout.dart';
import 'package:flutter/material.dart';

class EventTile extends StatelessWidget {
  final EventTileData eventTileData;
  const EventTile({super.key, required this.eventTileData});

  @override
  Widget build(BuildContext context) {
    final colorScheme = ColorScheme.of(context);
    return Positioned(
      top: eventTileData.top,
      left: eventTileData.left,
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(width: 0.5, color: colorScheme.primary),
          borderRadius: BorderRadius.all(Radius.circular(4)),
          color: colorScheme.onPrimaryFixedVariant),
        width: eventTileData.width,
        // margin: EdgeInsets.all(TimetableLayout.lineStrokeWidth),
        height: eventTileData.height,
        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: colorScheme.onSurfaceVariant), "Hi"),
            Text(style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: colorScheme.onSurfaceVariant), "Hey")
          ])));
  }
}
