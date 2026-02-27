import 'package:anu_timetable/domain/model/event.dart';
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
        context.push("/timetable/event/${event.id}");
      },
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: colorScheme.primary, width: 0.7),
          color: colorScheme.onPrimary,
          borderRadius: BorderRadius.all(Radius.circular(4))),
        margin: EdgeInsets.only(bottom: 6),
        padding: EdgeInsets.symmetric(horizontal: 7, vertical: 5),
        width: double.infinity,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: colorScheme.onSurfaceVariant),
                  event.title),
                Text(style: TextStyle(fontSize: 12, fontWeight: FontWeight.w400, color: colorScheme.onSurfaceVariant),
                  "Hey"),
              ]),
          Column(
            children: [
              Text(DateFormat("hh:mma").format(event.startTime),
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w400, color: colorScheme.onSurfaceVariant)),
              Text(DateFormat("hh:mma").format(event.endTime),
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w400, color: colorScheme.onSurfaceVariant)),
            ])
          ])));
  }
}