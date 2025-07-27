import 'package:anu_timetable/util/timetable_layout.dart';
import 'package:flutter/material.dart';

class MonthBarAnimationNotifier extends ChangeNotifier {
  bool isScrolling = false;
  bool visible = false;
  bool _open = false;
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
      if (_open) displayHeight = _height;
      notifyListeners();
    }
  }

  double get height => _height;

  bool get open => _open;

  set open(bool newVal) {
    _open = newVal;
    if (_open) {
      visible = true;
      shrunk = false;
      displayHeight = _height;
      notifyListeners();
    } else {
      displayHeight = TimetableLayout.weekBarHeight;
      notifyListeners();
      Future.delayed(const Duration(milliseconds: duration)).then((_) {
        if (_open) return;
        shrunk = true;
        notifyListeners();
      });
      Future.delayed(const Duration(milliseconds: duration + 100)).then((_) {
        if (_open) return;
        visible = false;
        notifyListeners();
      });
    }
  }
}
