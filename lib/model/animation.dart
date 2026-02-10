import 'package:anu_timetable/util/timetable_layout.dart';
import 'package:flutter/material.dart';

class MonthBarAnimationNotifier extends ChangeNotifier {
  // visibility: final/initial state of the animation set before fade in and expansion and after shrink fade out.
  bool visible = false;
  // animation trigger
  bool _open = false;
  // use shrunk to determine toggle visibility for monthbar
  bool shrunk = true;
  bool expanded = false;
  late double _height;
  static const int duration = 350;

  MonthBarAnimationNotifier(DateTime currentDay) {
    _height = TimetableLayout.monthBarHeight(currentDay);
  }

  set height(double newVal) {
    if (newVal != _height) {
      _height = newVal;
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
      notifyListeners();
      Future.delayed(const Duration(milliseconds: duration)).then((_) {
        if (!_open) return;
        expanded = true;
        notifyListeners();
      });
    } else {
      expanded = false;
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

class EventTileAnimationNotifier extends ChangeNotifier {
  bool expanded = false;
  String? eventId;
  int dayIndex;
  late List<bool> onLeft;
  late List<bool> collapse;
  int numEvents;
  late List<List<int>> adjList;
  late List<List<int>> invAdjList;

  EventTileAnimationNotifier({required this.adjList, required this.invAdjList, required this.dayIndex, required this.numEvents}) {
    onLeft = List.filled(numEvents, false);
    collapse = List.filled(numEvents, false);
  }

  void collapseAdjacents(List<List<int>> adjList, List<bool>visited, int index, bool leftSide) {
    if (visited[index]) return;
    
    visited[index] = true;
    onLeft[index] = leftSide;
    collapse[index] = true;

    for (final adj in adjList[index]) {
      collapseAdjacents(adjList, visited, adj, leftSide);
    }
  }

  void setCollapsed(int index) {
    collapse = List.filled(numEvents, false);
    onLeft = List.filled(numEvents, false);
    List<bool> visited = List.filled(numEvents, false);
    collapseAdjacents(adjList, visited, index, false);
    visited = List.filled(numEvents, false);
    collapseAdjacents(invAdjList, visited, index, true);
  }

  void expand(String newEventId, int index) {
    if (newEventId == eventId) return;
    expanded = true;
    eventId = newEventId;
    setCollapsed(index);
    notifyListeners();
  }

  void shrink() {
    if (!expanded) return;
    eventId = null;
    expanded = false;
    notifyListeners();
  }
}