import 'package:anu_timetable/model/timetable_model.dart';
import 'package:anu_timetable/util/timetable_layout.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class TListView extends StatefulWidget {
  const TListView({super.key});

  @override
  State<TListView> createState() => _TListViewState();
}

class _TListViewState extends State<TListView> {
  @override
  Widget build(BuildContext context) {
    return ListView.builder(itemBuilder: (context, index) {
      return _DayItem(index: index);
    },);
  }
}

class _DayItem extends StatelessWidget {
  final int index;

  const _DayItem({required this.index});
  @override
  Widget build(BuildContext context) {
    ColorScheme colorScheme = ColorScheme.of(context);
    DateTime day = TimetableModel.getDay(index);
    return Container(
      margin: EdgeInsets.only(top: 10),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            margin: EdgeInsets.symmetric(horizontal: 15, vertical: 3),
            padding: EdgeInsets.only(bottom: 2),
            decoration: BoxDecoration(
              border: Border(
)),
            child: Text(style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            DateFormat('EEEE, dd MMM').format(day))),
          Column(
            children: [
              Container(
                height: 30,
                decoration: BoxDecoration(
                  border: Border.all(color: colorScheme.primary, width: 0.7),
                  color: colorScheme.onPrimary,
                  borderRadius: BorderRadius.all(Radius.circular(4))),
                margin: EdgeInsets.symmetric(horizontal: 15, vertical: 1)),
                Container(
                height: 30,
                decoration: BoxDecoration(
                  border: Border.all(color: colorScheme.primary, width: 0.7),
                  color: colorScheme.onPrimary,
                  borderRadius: BorderRadius.all(Radius.circular(4))),
                margin: EdgeInsets.symmetric(horizontal: 15, vertical: 3))
            ])
        ]));
  }
}