import 'package:anu_timetable/domain/model/event.dart';
import 'package:anu_timetable/util/shaders.dart';
import 'package:anu_timetable/util/theme_extension.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class EventItem extends StatelessWidget {
  const EventItem({super.key, required this.event, this.now = false});

  final Event event;
  final bool now;

  @override
  Widget build(BuildContext context) {
    final eventColorScheme = Theme.of(context).extension<CalendarTheme>()!
      .eventColors[event.type.typeEnum]!;

    Text timeText(DateTime time) => Text(
      DateFormat("hh:mma").format(time),
      style: TextStyle(fontSize: 12, fontWeight: now ? FontWeight.w600 : FontWeight.w400,
        color: eventColorScheme.text));

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () {
        context.push("/event/${event.id}", extra: event);
      },
      child: ShaderMask(
        shaderCallback: (Rect bounds) => eventTileShader(bounds, eventColorScheme.shade),
        child: Container(
          height: now ? 52 : 51,
          decoration: BoxDecoration(
            color: eventColorScheme.background,
            border: Border.all(width: now ? 1 : 0.3, color: eventColorScheme.border),
            borderRadius: BorderRadius.all(Radius.circular(8))),
          margin: EdgeInsets.only(bottom: 6),
          padding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          width: double.infinity,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(style: TextStyle(fontSize: 12, fontWeight: now ? FontWeight.w800 : FontWeight.w600, color: eventColorScheme.text),
                      "${event.title} - ${event.type.typeStrFull}"),
                    Text(style: TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w400,color: eventColorScheme.text),
                      overflow: TextOverflow.ellipsis, softWrap: false, maxLines: 1, event.summary),
                  ])),
              SizedBox(width: 10),
              Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  timeText(event.startDate), timeText(event.endDate)
                ])
            ]))));
  }
}