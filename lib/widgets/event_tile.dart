import 'package:anu_timetable/model/animation.dart';
import 'package:anu_timetable/util/event_tile_arranger.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

class EventTile extends StatelessWidget {
  final EventTileData eventTileData;
  final EventTileAnimationNotifier eventTileAnimationNotifier;
  final Size size;
  final int index;
  const EventTile({super.key, required this.eventTileData, required this.eventTileAnimationNotifier, required this.size, required this.index});

  double left(bool collapse, bool onLeft) {
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

  double width(bool collapse) {
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

  onTap(BuildContext context) {
    if (eventTileAnimationNotifier.eventId == eventTileData.event.id || eventTileData.width >= 40) {
      context.push("/timetable/event/${eventTileData.event.id}");
    } else {
      eventTileAnimationNotifier.expand(eventTileData.event.id, index);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = ColorScheme.of(context);
    return ListenableBuilder(listenable: eventTileAnimationNotifier, 
      builder: (context, child) {
        bool collapse = eventTileAnimationNotifier.collapse[index];
        bool onLeft = eventTileAnimationNotifier.onLeft[index];
        return AnimatedPositioned(
          duration: Duration(milliseconds: 150),
          top: eventTileData.top,
          left: left(collapse, onLeft),
          child: TapRegion(
            onTapOutside: (details) {
              if (eventTileAnimationNotifier.eventId == eventTileData.event.id) eventTileAnimationNotifier.shrink();
            },
            child: GestureDetector(
              onTap: () => onTap(context),
              // TODO: extract, share with `listView`
              child: ShaderMask(
                shaderCallback: (Rect bounds) {
                  return LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    // TODO: use color scheme
                    // burnt orange: 255, 255, 204, 168
                    colors: [const Color.fromARGB(255, 255, 255, 255), const Color.fromARGB(255, 226, 168, 255)])
                      .createShader(bounds);
                },
                child: AnimatedContainer(
                  duration: Duration(milliseconds: 150),
                  decoration: BoxDecoration(
                    border: Border.all(width: 0.7, color: colorScheme.primary),
                    borderRadius: BorderRadius.all(Radius.circular(8)),
                    color: colorScheme.onPrimary),
                  width: width(collapse),
                  height: eventTileData.height,
                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    child: ClipRect(
                      child: OverflowBox(
                        alignment: Alignment.centerLeft,
                        maxWidth: double.infinity,
                        child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: colorScheme.onSurfaceVariant),
                            "Hi"),
                          Text(style: TextStyle(fontSize: 12, fontWeight: FontWeight.w400, color: colorScheme.onSurfaceVariant), 
                            "Hey")
                        ]))).animate(
                          target: eventTileAnimationNotifier.eventId == eventTileData.event.id || eventTileData.width >= 40 
                            ? 1.0 : 0.0)
                          .shimmer(
                            angle: 0,
                            curve: Curves.linear,
                            duration: Duration(milliseconds: 150),
                            blendMode: BlendMode.dstIn,
                            colors: [Colors.white, const Color.fromARGB(0, 255, 255, 255)]))))));
      });
  }
}
