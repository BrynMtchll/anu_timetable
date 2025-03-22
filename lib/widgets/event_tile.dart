import 'package:anu_timetable/model/event_tile_arranger.dart';
import 'package:flutter/material.dart';

class EventTile extends StatelessWidget {
  final EventTileData eventTileData;
  
  const EventTile({super.key, required this.eventTileData});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: eventTileData.top,
      left: eventTileData.left,
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(width: 0.5),
          borderRadius: BorderRadius.all(Radius.circular(8)),
          color: ColorScheme.of(context).surfaceContainer),
        width: eventTileData.width,
        height: eventTileData.height,
        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600), "Hi"),
            Text(style: TextStyle(fontSize: 12), "Hey")
          ])));
  }
}
