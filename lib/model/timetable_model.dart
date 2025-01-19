import 'package:flutter/material.dart';
import 'dart:developer' as developer;

class TimetableModel extends ChangeNotifier {

  /// Date of the currently selected day
  DateTime _activeDate = DateTime.now();

  /// Date of the start (the monday) of the active week. 
  /// (Day view) the active week that visible in the app bar 
  /// and the one containing the [_activeDate].
  late DateTime _activeWeekDate;

  TimetableModel() {
    _activeWeekDate = _weekStart(_activeDate);
  }


  DateTime get activeDate => _activeDate;
  DateTime get activeWeekDate => _activeWeekDate;

  set activeDate(DateTime newActiveDate) {
    if (_activeDate == newActiveDate) return;
    _activeDate = newActiveDate;
    var newActiveWeekDate = _weekStart(newActiveDate);
    if (_activeWeekDate != newActiveWeekDate) {
      _activeWeekDate = newActiveWeekDate;
    }
    notifyListeners();
  }

  set activeWeekDate(DateTime newActiveWeekDate) {
    if (newActiveWeekDate.weekday != DateTime.monday) {
      developer.log("Provided week start date not a monday!");
      developer.log('Date provided:  $newActiveWeekDate has weekday index: ${newActiveWeekDate.weekday}');

      newActiveWeekDate = _weekStart(newActiveWeekDate);
    }
    if (_activeWeekDate == newActiveWeekDate) return;
    _activeWeekDate = newActiveWeekDate;
    notifyListeners();
  }

  /// sets [activeWeekDate] to the week [weeks] over
  void shiftActiveWeek(int weeks) {
    DateTime newActiveWeekDate = activeWeekDate.add(Duration(days: weeks * 7));
    activeWeekDate = newActiveWeekDate;
  }

  /// returns the week start date for a given date
  DateTime _weekStart(DateTime date) => date.subtract(Duration(days:  date.weekday - 1));
}