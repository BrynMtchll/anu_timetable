import 'package:anu_timetable/util/timetable_layout.dart';
import 'package:flutter/material.dart';

class MonthBarAnimationNotifier extends ChangeNotifier {
  bool isScrolling = false;
  bool visible = false;
  bool open = false;
  bool shrunk = true;
  late double displayHeight = TimetableLayout.weekBarHeight;
  late double _height;
  static const int duration = 300;

  MonthBarAnimationNotifier(DateTime currentDay) {
    _height = TimetableLayout.monthBarHeight(currentDay);
  }

  set height(double newVal) {
    if (newVal != _height) {
      _height = newVal;
      if (open) displayHeight = _height;
      notifyListeners();
    }
  }

  double get height => _height;
  
  void toggleOpen(bool val) {
    if (val) {
      visible = true;
      open = true;
      shrunk = false;
      displayHeight = _height;
      notifyListeners();
    }
    else {
      open = false;
      displayHeight = TimetableLayout.weekBarHeight;
      notifyListeners();
      Future.delayed(const Duration(milliseconds: duration)).then((_) {
        shrunk = true;
        notifyListeners();
      });
      Future.delayed(const Duration(milliseconds: duration + 100)).then((_) {
        visible = false;
        notifyListeners();
      });
    }
  }
}

class SelectBarWeekdayNotifier extends ChangeNotifier{
  SelectBarWeekdayNotifier();
  void notify() {
    notifyListeners();
  }
}