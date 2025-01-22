import 'dart:async';

import 'package:flutter/material.dart';
import 'dart:developer' as developer;

class TimetableModel extends ChangeNotifier {

  /// Date of the currently selected day
  late DateTime _activeDate;

  /// Date of the start (the monday) of the active week. 
  /// (Day view) the active week that visible in the app bar 
  /// and the one containing the [_activeDate].
  late DateTime _activeWeekDate;

  late final currentDate;
  late final currentWeekDate;
  late final hashDate;
  // late int _weekBarActivePage;

  TimetableModel({required this.currentDate, required this.currentWeekDate, required this.hashDate}) {
    _activeDate = currentDate;
    _activeWeekDate = currentWeekDate;
    // _weekBarActivePage = weekBarInitialPage;
  }

  int get weekBarActivePage => (_activeWeekDate.difference(hashDate).inDays / 7).toInt();

  // set weekBarActivePage(int newActivePage) {
  //   if (_weekBarActivePage == newActivePage) return;
  //   _weekBarActivePage = newActivePage;
  //   developer.log("New week bar active page: $_weekBarActivePage.");
  //   notifyListeners();
  // }

  DateTime get activeDate => _activeDate;
  DateTime get activeWeekDate => _activeWeekDate;

  set activeDate(DateTime newActiveDate) {
    if (_activeDate == newActiveDate) return;
    _activeDate = newActiveDate;
    developer.log("New active date: $_activeDate.");

    notifyListeners();
  }

  set activeWeekDate(DateTime newActiveWeekDate) {
    if (newActiveWeekDate.weekday != DateTime.monday) {
      developer.log("Provided week start date not a monday!");
      developer.log('Date provided:  $newActiveWeekDate has weekday index: ${newActiveWeekDate.weekday}');

      newActiveWeekDate = weekStart(newActiveWeekDate);
    }
    if (_activeWeekDate == newActiveWeekDate) return;
    _activeWeekDate = newActiveWeekDate;
      developer.log("New active week start date: $_activeWeekDate.");

    notifyListeners();
  }

  void updateActiveWeek() {
    var newActiveWeekDate = weekStart(_activeDate);
    if (_activeWeekDate != newActiveWeekDate) {
      _activeWeekDate = newActiveWeekDate;
    }
  }

  /// Returns the page index of the week bar for the active date
  int weekBarPageForActiveDate() {
    DateTime activeDateWeekStart = weekStart(_activeDate);
    int differenceInDays = activeWeekDate.difference(activeDateWeekStart).inDays;
    if (differenceInDays % 7 != 0) {
      developer.log("err: difference between weeks in days not a multiple of 7");
      return -1;
    }
    int page = weekBarActivePage - (differenceInDays/7).toInt();
    print(weekBarActivePage);
    print("changing to page: $page");

    // print(differenceInDays);
    print(_activeDate);
    print(activeWeekDate);
    return page;
  }

    /// Computes the week start date for a given page.
  DateTime weekDate(int page, DateTime activeWeekDate) {
    int differencefromActiveInDays = (page - weekBarActivePage) * 7;
    DateTime weekStartDate = activeWeekDate.add(Duration(days: differencefromActiveInDays));
    return weekStartDate;
  }

  /// Returns the date of the given [weekday], 
  DateTime weekdayDate(int page, activeWeekDate, int weekday) 
    => weekDate(page, activeWeekDate).add(Duration(days: weekday - 1));


  bool isActiveDayInActiveWeek() {
    int diff = _activeDate.difference(_activeWeekDate).inDays;
    return 0 <= diff && diff < 7;
  }

  void shiftActiveWeek(int newWeekBarActivePage) {
    print(weekBarActivePage);
    print(newWeekBarActivePage);
    var weeks = (newWeekBarActivePage - weekBarActivePage);
    print(weeks);
    DateTime newActiveWeekDate = activeWeekDate.add(Duration(days: weeks * 7));
    activeWeekDate = newActiveWeekDate;
    // _weekBarActivePage = newWeekBarActivePage;
  }

  /// sets [activeDate] to the day [days] over
  void shiftActiveDay(int days) {
    DateTime newActiveDate = activeDate.add(Duration(days: days));
    developer.log("Active date shifted $days day(s).");
    activeDate = newActiveDate;

  }

  /// returns the week start date for a given date
  static DateTime weekStart(DateTime date) => date.subtract(Duration(days:  date.weekday - 1));
}