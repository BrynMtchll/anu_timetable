import 'package:anu_timetable/domain/model/event.dart';
import 'package:anu_timetable/model/animation.dart';
import 'package:anu_timetable/util/event_tile_arranger.dart';
import 'package:anu_timetable/util/shaders.dart';
import 'package:anu_timetable/util/theme_extension.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class EventTile extends StatelessWidget {
  final Event event;
  final EventTileData eventTileData;
  final EventTileAnimationNotifier animationNotifier;
  final Size size;
  final int index;
  final bool transition;
  const EventTile({super.key, required this.event, required this.eventTileData,required this.animationNotifier, 
    required this.size, required this.index, required this.transition});

  static const double collapseThreshold = 40;
  static const double horzPadding = 4;
  static const double borderWidth = 0.5;

  double left(bool collapse, bool onLeft, bool isExpanded) {
    if (isExpanded) {
      return eventTileData.left == 0 ? 0 : 2;
    } else if (animationNotifier.expanded && collapse) {
      if (onLeft) {
        return 0;
      } else {
        return size.width-2;
      }
    } else {
      return eventTileData.left;
    }
  }

  double maxContentWidth() {
    double maxWidth;
    if (eventTileData.width >= collapseThreshold) {
      maxWidth = eventTileData.width;
    }
    else if (eventTileData.left > 0 && eventTileData.left + eventTileData.width < size.width) {
      maxWidth = size.width - 4;
    } else {
      maxWidth = size.width - 2;
    }
    return maxWidth -= (horzPadding + borderWidth) * 2;
  }

  double width(bool collapse, bool isExpanded) {
    if (isExpanded) {
      if (eventTileData.left > 0 && eventTileData.left + eventTileData.width < size.width) {
        return size.width - 4;
      } else {
        return size.width - 2;
      }
    } else if (animationNotifier.expanded && collapse) {
      return 2;
    } else {
      return eventTileData.width;
    }
  }

  void onTap(BuildContext context, bool isExpanded) {
    if (isExpanded || eventTileData.width >= collapseThreshold) {
      context.push("/event/${event.id}", extra: event);
    } else {
      animationNotifier.expand(event.id, index);
    }
  }

  @override
  Widget build(BuildContext context) {
    final eventColorScheme = Theme.of(context).extension<CalendarTheme>()!.eventColors[event.type.typeEnum]!;
    return ListenableBuilder(listenable: animationNotifier, 
      builder: (context, child) {
        bool collapse = animationNotifier.collapse[index];
        bool onLeft = animationNotifier.onLeft[index];
        bool isExpanded = animationNotifier.isExpanded(event.id);
        return AnimatedPositioned(
          duration: Duration(milliseconds: 150),
          top: eventTileData.top,
          left: left(collapse, onLeft, isExpanded),
          child: TapRegion(
            onTapOutside: (details) {
              if (isExpanded) animationNotifier.shrink();
            },
            child: GestureDetector(
              onTap: () => onTap(context, isExpanded),
              child: ShaderMask(
                shaderCallback: (Rect bounds) => eventTileShader(bounds, eventColorScheme.shade),
                child: AnimatedContainer(
                  duration: Duration(milliseconds: 150),
                  decoration: BoxDecoration(
                    border: Border.all(width: borderWidth, color: eventColorScheme.border),

                    borderRadius: BorderRadius.all(Radius.circular(8)),
                    color: eventColorScheme.background),
                  width: width(collapse, isExpanded),
                  height: eventTileData.height,
                  padding: EdgeInsets.symmetric(horizontal: horzPadding, vertical: 3),
                    child: ClipRect(
                      child: OverflowBox(
                        alignment: Alignment.topLeft,
                        maxWidth: maxContentWidth(),
                        maxHeight: double.infinity,
                        child: EventTileContent(event: event, transition: transition,)))
                      .animate(
                        autoPlay: false,
                        target: isExpanded || eventTileData.width >= collapseThreshold 
                          ? 1.0 : 0.0)
                      .shimmer(
                        angle: 0,
                        curve: Curves.linear,
                        duration: Duration(milliseconds: 250),
                        blendMode: BlendMode.dstIn,
                        colors: [Colors.white, const Color.fromARGB(0, 255, 255, 255)]))))));
      });
  }
}

class EventTileContent extends StatelessWidget {
  final Event event;
  final bool transition;
  const EventTileContent({super.key, required this.event, required this.transition});

  @override
  Widget build(BuildContext context) {
    EventColorScheme eventColorScheme = Theme.of(context).extension<CalendarTheme>()!.eventColors[event.type.typeEnum]!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: transition ? [] : [
        Text(style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: eventColorScheme.text),
          event.title),
        Text(style: TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: eventColorScheme.text), 
          event.type.typeStrFull),
        // Text(style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: colorScheme.onSurfaceVariant),
        //   "${DateFormat("h:mma").format(event.startDate)} to ${DateFormat("h:mma").format(event.endDate)}".toLowerCase()),
      ]);
  }
}