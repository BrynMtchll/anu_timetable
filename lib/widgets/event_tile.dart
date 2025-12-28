import 'package:anu_timetable/model/animation.dart';
import 'package:anu_timetable/util/event_tile_arranger.dart';
import 'package:anu_timetable/util/timetable_layout.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class EventTile extends StatelessWidget {
  final EventTileData eventTileData;
  final EventTileAnimationNotifier eventTileAnimationNotifier;
  final Size size;
  late bool onLeft = false;
  late bool collapse = false;
  EventTile({super.key, required this.eventTileData, required this.eventTileAnimationNotifier, required this.size});

  @override
  Widget build(BuildContext context) {
    final colorScheme = ColorScheme.of(context);
    print(eventTileAnimationNotifier.dayIndex);

    double left() {
      if (eventTileAnimationNotifier.eventId == eventTileData.event.id) {
        return eventTileData.left == 0 ? 0 : 2;
      } else if (eventTileAnimationNotifier.expanded && collapse) {
        if (onLeft) {
          return 0;
        } else {
          return size.width-2;
        }
      } else {
        return eventTileData.left;
      }
    }

    double width() {
      if (eventTileAnimationNotifier.eventId == eventTileData.event.id) {
        if (eventTileData.left == 0 || eventTileData.left + eventTileData.width >= size.width) {
          return size.width - 2;
        } else {
          return size.width - 4;
        }
      } else if (eventTileAnimationNotifier.expanded && collapse) {
        return 2;
      } else {
        return eventTileData.width;
      }
    }
    return ListenableBuilder(listenable: eventTileAnimationNotifier, 
      builder:(context, child) => AnimatedPositioned(
        duration: Duration(milliseconds: 150),
        top: eventTileData.top,
        left: left(),
        child: TapRegion(
          onTapOutside: (details) {
            if (eventTileAnimationNotifier.eventId == eventTileData.event.id) {
              eventTileAnimationNotifier.shrink();
            }
          },
          child: GestureDetector(
            onTap: () {
              if (eventTileAnimationNotifier.eventId == eventTileData.event.id || eventTileData.width >= 40) {
                context.push("/timetable/event/${eventTileData.event.id}");
              } else {
                eventTileAnimationNotifier.expand(eventTileData.event.id);
              }
            },
            child: AnimatedContainer(
              duration: Duration(milliseconds: 150),
            decoration: BoxDecoration(
              border: Border.all(width: 0.7, color: colorScheme.primary),
              borderRadius: BorderRadius.all(Radius.circular(8)),
              color: colorScheme.onPrimary),
            width: width(),
            height: eventTileData.height,
            padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            child: AnimatedOpacity(
              curve: Interval(eventTileAnimationNotifier.expanded ? 0.4 : 0, eventTileAnimationNotifier.expanded ? 1 : 0.6),
              duration: Duration(milliseconds: 150),
              opacity: (eventTileAnimationNotifier.eventId == eventTileData.event.id || eventTileData.width >= 40) ? 1.0 : 0.0,
              child: ClipRect(
              child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: colorScheme.onSurfaceVariant), "Hi"),
                Text(style: TextStyle(fontSize: 12, fontWeight: FontWeight.w400, color: colorScheme.onSurfaceVariant), "Hey")
              ]))))))));
  }
}
