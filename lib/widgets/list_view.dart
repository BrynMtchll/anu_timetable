// ignore_for_file: curly_braces_in_flow_control_structures
import 'dart:math';
import 'package:anu_timetable/domain/model/event.dart';
import 'package:anu_timetable/model/animation.dart';
import 'package:anu_timetable/model/current.dart';
import 'package:anu_timetable/model/events.dart';
import 'package:anu_timetable/model/timetable.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

class TListView extends StatefulWidget {
  const TListView({super.key});
  @override
  State<TListView> createState() => _TListViewState();
}

class _TListViewState extends State<TListView> {
  late ItemPositionsListener itemPositionsListener;
  @override
  void initState() {
    super.initState();
    itemPositionsListener = ItemPositionsListener.create();
  }
  @override
  Widget build(BuildContext context) {
    TimetableVM timetableModel = Provider.of<TimetableVM>(context, listen: false);
    int activeDayIndex = TimetableVM.getDayIndex(timetableModel.activeDay);

    itemPositionsListener.itemPositions.addListener(() {
      int newActiveDayIndex =itemPositionsListener.itemPositions.value.first.index;
      Iterator<ItemPosition> iterator = itemPositionsListener.itemPositions.value.iterator;

      while (iterator.moveNext()) {
        newActiveDayIndex = min(newActiveDayIndex, iterator.current.index);
      }
      if (newActiveDayIndex != activeDayIndex) {
        activeDayIndex = newActiveDayIndex;
        timetableModel.handleTListViewDayChanged(context, TimetableVM.getDay(newActiveDayIndex));
      }
    });
    return Consumer<EventsVM> (
      builder: (context, eventsVM, child) => NotificationListener<UserScrollNotification>(
      onNotification: timetableModel.onTListNotification,
      child: ScrollablePositionedList.builder(
        initialScrollIndex: TimetableVM.getDayIndex(timetableModel.activeDay),
        itemScrollController: timetableModel.tListViewItemScrollController,
        itemPositionsListener: itemPositionsListener,
        itemCount: 10000,
        itemBuilder: (context, index) => Consumer<MonthBarAnimationNotifier>(
          builder: (context, monthBarAnimationNotifier, child) => IgnorePointer(
            ignoring: monthBarAnimationNotifier.open,
            child: child),
          child: _DayItem(index: index, eventsVM: eventsVM)))));
  }
}

class _DayItem extends StatelessWidget {
  final int index;
  final EventsVM eventsVM;

  Color dayColor(bool dayIsCurrent, ColorScheme colorScheme, List<Event> events) {
    if (dayIsCurrent) return colorScheme.primary;
    else if (events.isNotEmpty) return colorScheme.onSurface;
    else return colorScheme.outline;
  }

  const _DayItem({required this.index, required this.eventsVM});

  @override
  Widget build(BuildContext context) {
    DateTime day = TimetableVM.getDay(index);
    ColorScheme colorScheme = ColorScheme.of(context);
    List<Event> events = eventsVM.getEventsOnDay(index);
    events.sort((a, b) {
      int startOrder = a.startTime.compareTo(b.startTime);
      return startOrder == 0 ? a.endTime.compareTo(b.endTime) : startOrder;
    });
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 0, vertical: 8),
      child: Column(
        children: [
          Consumer<CurrentDay>(builder: (context, currentDay, child) {
            bool dayIsCurrent = TimetableVM.dayEquiv(day, currentDay.value);
            return Container(
              width: double.infinity,
              margin: EdgeInsets.only(bottom: events.isNotEmpty ? 10 : 7),
              padding: EdgeInsets.only(left: 20, right: 15, bottom: 2),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: dayColor(dayIsCurrent, colorScheme, events), 
                    width: 0.4))),
              child: Text(
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600,
                  color: dayColor(dayIsCurrent, colorScheme, events)),
                DateFormat('EEEE dd MMM').format(day).toUpperCase()));
          }),
          Column(
            children: [for (final event in events) _EventItem(event: event)])
        ]));
  }
}

class _EventItem extends StatelessWidget {
  final Event event;
  const _EventItem({required this.event});

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
        margin: EdgeInsets.only(left: 20, right: 15, bottom: 6),
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