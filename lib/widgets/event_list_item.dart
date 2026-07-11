import 'package:anu_timetable/domain/model/event.dart';
import 'package:anu_timetable/util/shaders.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class EventItem extends StatelessWidget {
  final Event event;
  const EventItem({super.key, required this.event});

  @override
  Widget build(BuildContext context) {
    ColorScheme colorScheme = ColorScheme.of(context);
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () {
        context.push("/event/${event.id}", extra: event);
      },
      child: ShaderMask(
        shaderCallback: (Rect bounds) => eventTileShader(bounds),
        child: Container(
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.all(Radius.circular(8))),
          margin: EdgeInsets.only(bottom: 6),
          padding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          width: double.infinity,
          child: LayoutBuilder(
            builder:(context, constraints) => Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: colorScheme.onSurfaceVariant),
                      event.title),
                    SizedBox(
                      width: constraints.maxWidth - 60,
                      child: Text(style: TextStyle(fontSize: 12, fontWeight: FontWeight.w400, color: colorScheme.onSurfaceVariant, overflow: TextOverflow.fade),
                        overflow: TextOverflow.visible, maxLines: 1, event.summary)),
                  ]),
                Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(DateFormat("hh:mma").format(event.startDate),
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w400, color: colorScheme.onSurfaceVariant)),
                    Text(DateFormat("hh:mma").format(event.endDate),
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w400, color: colorScheme.onSurfaceVariant)),
                  ])
              ])))));
  }
}