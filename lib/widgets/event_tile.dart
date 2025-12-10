import 'package:anu_timetable/util/event_tile_arranger.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class EventTile extends StatelessWidget {
  final EventTileData eventTileData;
  const EventTile({super.key, required this.eventTileData});

  @override
  Widget build(BuildContext context) {
    final colorScheme = ColorScheme.of(context);
    print("yo");
    return Positioned(
      top: eventTileData.top,
      left: eventTileData.left,
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () {
          context.push("/timetable/event");
        },
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(width: 0.7, color: colorScheme.primary),
            borderRadius: BorderRadius.all(Radius.circular(8)),
            color: colorScheme.onPrimary),
          width: eventTileData.width,
          height: eventTileData.height,
          padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          child: eventTileData.width < 30 ? SizedBox() : ClipRect(
            child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: colorScheme.onSurfaceVariant), "Hi"),
              Text(style: TextStyle(fontSize: 12, fontWeight: FontWeight.w400, color: colorScheme.onSurfaceVariant), "Hey")
            ])))));
  }
}
