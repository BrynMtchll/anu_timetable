import 'package:anu_timetable/util/timetable_layout.dart';
import 'package:flutter/material.dart';

class MonthBarAnimationNotifier extends ChangeNotifier {
  bool isScrolling = false;
  bool visible = false;
  bool open = false;
  bool shrunk = true;
  late double displayHeight = TimetableLayout.weekBarHeight;
  late double _height;

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
  
  void flip(bool val) {
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
      Future.delayed(const Duration(milliseconds: 200)).then((_) {
        shrunk = true;
        notifyListeners();
      });
      Future.delayed(const Duration(milliseconds: 300)).then((_) {
        visible = false;
        notifyListeners();
      });
    }
  }
}