import 'package:calendar_view/calendar_view.dart';
import 'package:flutter/material.dart';
import 'dart:async';

/// Holds the current day, updated on change. This is checked every 
/// second (but listeners are only notified upon change).
class CurrentDay extends ChangeNotifier {
  late DateTime value = _roundDay(DateTime.now());

  CurrentDay() {
    Timer.periodic(Duration(seconds: 1), _onTick);
  }

  void _onTick(Timer? timer) {
    DateTime newValue = _roundDay(DateTime.now());
    if (newValue != value) {
      value = newValue;
      notifyListeners();
    }
  }

  static DateTime _roundDay(DateTime day) {
    return DateTime(day.year, day.month, day.day);
  }
}

/// Holds the current time, updated every minute. 
class CurrentMinute extends ChangeNotifier {
  DateTime value = DateTime.now();

  CurrentMinute() {
    Timer.periodic(Duration(minutes: 1), _onTick);
  }

  void _onTick(Timer? timer) {
    value = DateTime.now();
    notifyListeners();
  }

  int get getTotalMinutes => value.getTotalMinutes;

  /// returns the absolute difference between the current time and the given
  /// hour in minutes.
  int differenceFromHour(int hour) => 
    (getTotalMinutes - TimeOfDay(hour: hour, minute: 0).getTotalMinutes).abs();
}

/// Holds the current time, updated every second. 
/// Some methods of this class work as generic extensions on [DateTime].
class CurrentSecond extends ChangeNotifier {

  DateTime value = DateTime.now();

  static const int secondsPerDay = 60 * 60 * 24;

  CurrentSecond() {
   Timer.periodic(Duration(seconds: 1), _onTick);
  }

  void _onTick(Timer? timer) {
    value = DateTime.now();
    notifyListeners();
  }

  int get getTotalMinutes => value.getTotalMinutes;
  
  int get getTotalSeconds => getTotalMinutes * 60 + value.second;
  
  /// Returns the time at the current second as a fraction of the day.
  double getFractionOfDay() =>
    getTotalSeconds / secondsPerDay;

  int get hourOfPeriod  => value.hour == 12 ? 12 : value.hour % 12;
  
  String get string =>
    "$hourOfPeriod:${value.minute.toString().padLeft(2, '0')}";
}