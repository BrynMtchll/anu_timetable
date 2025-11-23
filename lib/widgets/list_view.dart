// ignore_for_file: curly_braces_in_flow_control_structures

import 'dart:math';

import 'package:anu_timetable/model/current.dart';
import 'package:anu_timetable/model/timetable.dart';
import 'package:flutter/material.dart';
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
    Random random = Random();
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
    List randints = [for (int i = 0; i < 10000; i++) random.nextInt(3)];
    return NotificationListener<UserScrollNotification>(
      onNotification: timetableModel.onTListNotification,
      child: ScrollablePositionedList.builder(
        initialScrollIndex: TimetableVM.getDayIndex(timetableModel.activeDay),
        itemScrollController: timetableModel.tListViewItemScrollController,
        itemPositionsListener: itemPositionsListener,
        itemCount: 10000,
        itemBuilder: (context, index) {
          return _DayItem(index: index, nItems: randints[index]);
        }));
  }
}

class _DayItem extends StatelessWidget {
  final int index;
  final int nItems;

  Color dayColor(bool dayIsCurrent, ColorScheme colorScheme) {
    if (dayIsCurrent) return colorScheme.primary;
    else if (nItems > 0) return colorScheme.onSurface;
    else return colorScheme.outline;
  }

  const _DayItem({required this.index, required this.nItems});
  @override
  Widget build(BuildContext context) {
    DateTime day = TimetableVM.getDay(index);
    ColorScheme colorScheme = ColorScheme.of(context);

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 0, vertical: 8),
      child: Column(
        children: [
          Consumer<CurrentDay>(builder: (context, currentDay, child) {
            bool dayIsCurrent = TimetableVM.dayEquiv(day, currentDay.value);
            return Container(
              width: double.infinity,
              margin: EdgeInsets.only(bottom: nItems > 0 ? 10 : 7),
              padding: EdgeInsets.only(left: 20, right: 15, bottom: 2),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: dayColor(dayIsCurrent, colorScheme), 
                    width: 0.4))),
              child: Text(
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600,
                  color: dayColor(dayIsCurrent, colorScheme)),
                DateFormat('EEEE dd MMM').format(day).toUpperCase()));
          }),
          Column(
            children: [for (int i = 0; i < nItems; i++) _EventItem()])
        ]));
  }
}

class _EventItem extends StatelessWidget {
  const _EventItem();

  @override
  Widget build(BuildContext context) {
    ColorScheme colorScheme = ColorScheme.of(context);
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: colorScheme.primary, width: 0.7),
        color: colorScheme.onPrimary,
        borderRadius: BorderRadius.all(Radius.circular(4))),
      margin: EdgeInsets.only(left: 20, right: 15, bottom: 6),
      padding: EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: colorScheme.onSurfaceVariant),
            "Hi"),
          Text(style: TextStyle(fontSize: 12, fontWeight: FontWeight.w400, color: colorScheme.onSurfaceVariant),
            "Hey"),
      ]));
  }
}