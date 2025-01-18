import 'package:flutter/material.dart';
import 'dart:developer' as developer;

class TimetableModel extends ChangeNotifier {
  var _activeDate = DateTime.now();
  late DateTime _activeWeekStartDate;

  TimetableModel() {
    _activeWeekStartDate = _weekStartFromDate(_activeDate);
  }


  DateTime get activeDate => _activeDate;
  DateTime get activeWeekStartDate => _activeWeekStartDate;

  set activeDate(DateTime newActiveDate) {
    if (_activeDate == newActiveDate) return;
    _activeDate = newActiveDate;
    var newActiveWeekStartDate = _weekStartFromDate(newActiveDate);
    if (_activeWeekStartDate == newActiveWeekStartDate) return;
    _activeWeekStartDate = newActiveWeekStartDate;
    notifyListeners();
  }

  set activeWeekStartDate(DateTime newActiveWeekStartDate) {
    if (newActiveWeekStartDate.weekday != DateTime.monday) {
      developer.log("Provided week start date not a monday!");
      developer.log("Date provided: " + newActiveWeekStartDate.toString() + " has weekday index: " + newActiveWeekStartDate.weekday.toString());
      
      newActiveWeekStartDate = _weekStartFromDate(newActiveWeekStartDate);
    }
    if (_activeWeekStartDate == newActiveWeekStartDate) return;
    _activeWeekStartDate = newActiveWeekStartDate;
    notifyListeners();
  }

  DateTime _weekStartFromDate(DateTime date) => date.subtract(Duration(days:  date.weekday - 1));
}