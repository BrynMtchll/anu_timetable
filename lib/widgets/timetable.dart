import 'package:flutter/material.dart';

class Timetable extends StatefulWidget {
  const Timetable({super.key});

  @override
  State<Timetable> createState() => _TimetableState();
}

class _TimetableState extends State<Timetable> {
  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        _timeSlot(),
        _timeSlot(),
        _timeSlot(),
        _timeSlot(),
        _timeSlot(),
        _timeSlot(),
        _timeSlot(),
        _timeSlot(),

      ],
    );
  }

  Container _timeSlot() {
    return Container(
        height: 50,
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(width: 1, color: Colors.grey))
        ),
      );
  }
}