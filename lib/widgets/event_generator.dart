import 'dart:collection';
import 'dart:math';

import 'package:anu_timetable/model/events.dart';
import 'package:anu_timetable/util/timetable_layout.dart';
import 'package:anu_timetable/widgets/event_tile.dart';
import 'package:calendar_view/calendar_view.dart';
import 'package:flutter/material.dart';
import 'package:collection/collection.dart';



// dag going strictly right representing set of overlapping events
// compute longest path through each node with linear scan
// find start of longest and trace (if multiple / options, choose any)
// fix widths - evenly distribute if no bounding conditions, otherwise ???
// add bounding conditions to connected nodes not in path and remove path nodes 
// repeat

class BoundList extends ListBase<double> {
  late List<double> l = [];
  late List<bool> fixed = [];

  BoundList(int length, double value) {
    l = List.filled(length, value);
    fixed = List.filled(length, false);
  }

  @override
  set length(int newLength) { 
    l.length = newLength; 
    fixed.length = newLength;
  }
  @override
  int get length => l.length;
  @override
  double operator [](int index) => l[index];
  @override
  void operator []=(int index, double value) { l[index] = value; }

  bool exists(int index) => l[index] >= 0;
}

class Section implements Comparable {
  final int start;
  final int end;
  bool canMergeLeft;
  bool canMergeRight;
  late int length;
  late double density;
  final double width;
  Section? left;
  Section? right;

  Section({ 
    required this.width,
    required this.start,
    required this.end,
    required this.canMergeLeft,
    required this.canMergeRight,
    this.left,
    this.right
  }) {
    length = end - start;
    density = length / width;
  }

  @override
  int compareTo(other) {
    return (density * 1000).toInt();
  }

  bool shouldMergeLeft() =>
    left != null && canMergeLeft && (!canMergeRight || (canMergeRight && left!.compareTo(right) < 0));
    
  bool shouldMergeRight() =>
    right != null && canMergeRight && (!canMergeLeft || (canMergeLeft && right!.compareTo(left) < 0));

  static Section merge(Section a, Section b) {
    Section newSect = Section(
      width: a.width + b.width, 
      start: a.start, 
      end: b.end, 
      canMergeLeft: a.canMergeLeft, 
      canMergeRight: b.canMergeRight, 
      left: a.left, 
      right: b.right
    );
    a.left?.right = newSect;
    b.right?.left = newSect;

    return newSect;
  }
}

class EventTileLayout {
  late double left;
  late double width;
}

class EventGenerator extends StatelessWidget {
  final Size size; 
  final DateTime day;
  const EventGenerator({super.key, required this.size, required this.day});

  bool _eventsOverlap(Event a, Event b) => 
    a.startTime.compareTo(b.endTime) < 0 && b.startTime.compareTo(a.endTime) < 0;

  List<EventTileLayout> _arrangeEvents(List<Event> events) {
    events.sort((a, b) => a.startTime.compareTo(b.startTime));
    final int numEvents = events.length;
    List<List<int>> adjList = [];
    List<List<int>> invAdjList = [];
    List<List<int>> eventColumns = [];
    List<EventTileLayout> eventTileLayouts = [];
    for (int i = 0; i < numEvents; i++) {
      adjList.add([]);
      invAdjList.add([]);
      eventTileLayouts.add(EventTileLayout());
    }

    _columnEvents(events, eventColumns);
    _constructDag(events, eventColumns, adjList, invAdjList);
    _fixEvents(events, eventColumns, adjList, invAdjList, eventTileLayouts);
    return eventTileLayouts;
  }

  void _fixEvents(List<Event> events, List<List<int>> eventColumns, List<List<int>> adjList, List<List<int>> invAdjList, List<EventTileLayout> eventTileLayouts) {
    List<bool> fixed = List.filled(events.length, false);
    BoundList leftBound = BoundList(events.length, -1);
    BoundList rightBound = BoundList(events.length, -1);
    int numFixed = 0;

    while (numFixed < events.length) {
      List<int> longestFrom = List.filled(events.length, 1);
      List<bool> visited = List.filled(events.length, false);
      List<int> path = [];
      ({int length, int event}) longest = (length: 0, event: 0);

      for (final column in eventColumns) {
        for (final event in column) {
          int result = _searchLongestPaths(event, adjList, longestFrom, visited, fixed);
          if (result > longest.length) {
            longest = (length: result, event: event);
          }
        }
      }

      _pathOfLongest(longest.event, adjList, longestFrom, path);
      
      leftBound.fixed = List.filled(events.length, false);
      rightBound.fixed = List.filled(events.length, false);
      _fixPath(events, path, eventTileLayouts, leftBound, rightBound);

      for (final event in path) {
        fixed[event] = true;
        for (final adj in adjList[event]) {
          leftBound[adj] = eventTileLayouts[event].width + eventTileLayouts[event].left;
        }
        for (final adj in invAdjList[event]) {
          rightBound[adj] = eventTileLayouts[event].left;
        }
      }
      numFixed += path.length;
    }
  }

  // priority queue of section densities
  // merge right 
  // left bound on right side - merge right
  // right bound on left side - merge left
  // left bound on left side or right bound on right side - fixed

  // back edge for right bound
  // left and right bound on same event
  // right bound less than or equal to left bound - error!
  // if equal then event would have zero width
  // take inside? - higher density - will be merged into outside
  void _fixPath(List<Event> events, List<int> path, List<EventTileLayout> eventTileLayouts, BoundList leftBound, BoundList rightBound) {
    final PriorityQueue<Section> sections = PriorityQueue();
    final List<Section> fixedSections = [];
    Section? head;
    //fix!!!
    double totalWidth = 300;

    if (leftBound[path[0]] < 0) leftBound[path[0]] = 0;
    if (rightBound[path[path.length - 1]] < 0) rightBound[path[path.length - 1]] = totalWidth;

    void addSection(Section sect) {
      head?.right = sect;
      sect.left = head;
      head = sect;
      sections.add(sect);
    }

    for (int start = 0, end = 1; end < path.length; end++) {
      int startEvent = path[start], endEvent = path[end];
      if (!rightBound.exists(endEvent) && !leftBound.exists(endEvent)) continue;

      if (start == end - 1 && rightBound.exists(startEvent) && leftBound.exists(startEvent)) {
        addSection(Section(
          width: rightBound[startEvent] - leftBound[startEvent],
          start: start,
          end: start, 
          canMergeLeft: false, 
          canMergeRight: false));
      }

      double endPos = (leftBound.exists(endEvent) ? leftBound[endEvent] : rightBound[endEvent]);
      double startPos = (rightBound.exists(startEvent) ? rightBound[startEvent] : leftBound[startEvent]);

      addSection(Section(
        width: endPos - startPos, 
        start: start, 
        end: end,
        canMergeLeft: rightBound.exists(startEvent),
        canMergeRight: leftBound.exists(endEvent)));

      start = end;
    }

    // if left merge, left must be right bound
    // if not, left is either fixed right bound or left bound
    // if right merge, right must be left bound
    // if not, right is eitehr fixed left bound or right bound

    // left and right bound can both be fixed fir same position
    void fixSection(Section sect) {
      if (sect.start == sect.end) {
          leftBound.fixed[path[sect.start]] = true;
          rightBound.fixed[path[sect.start]] = true;
        }
        else {
          int startEvent = path[sect.start], endEvent = path[sect.end];

          if (!rightBound.fixed[startEvent]) leftBound.fixed[startEvent] = true;
          if (!leftBound.fixed[endEvent]) rightBound.fixed[endEvent] = true;
        }
        fixedSections.add(sect);
        sect.left?.canMergeRight = false;
        sect.right?.canMergeLeft = false;
    }

    while (sections.isNotEmpty) {
      Section sect = sections.removeFirst();
      if (sect.shouldMergeLeft()) {
        sections.remove(sect.left!);
        sections.add(Section.merge(sect.left!, sect));
      }
      else if (sect.shouldMergeRight()) {
        sections.remove(sect.right!);
        sections.add(Section.merge(sect, sect.right!));
      }
      else if (!sect.canMergeLeft && !sect.canMergeRight) {
        fixSection(sect);
      }
    }
    _assignLayouts(fixedSections, path, eventTileLayouts, leftBound, rightBound);
  }

  double _sectionOffset(Section s, int leftEvent, BoundList leftBound, BoundList rightBound) {
    if (s.start == s.end) return leftBound[leftEvent];
    return leftBound.fixed[leftEvent] ? leftBound[leftEvent] : rightBound[leftEvent];
  }

  void _assignLayouts(List<Section> fixedSections, List<int> path, List<EventTileLayout> eventTileLayouts, BoundList leftBound, BoundList rightBound) {
    for (final Section s in fixedSections) {
      final double eventWidth = s.width / (s.length+1);
      final double sectionOffset = _sectionOffset(s, path[s.start], leftBound, rightBound);
      for (int i = s.start; i <= s.end; i++) {
        eventTileLayouts[path[i]].width = eventWidth;
        eventTileLayouts[path[i]].left = eventWidth*i + sectionOffset;
      }
    }
  }

  void _pathOfLongest(int curr, List<List<int>> adjList, List<int> longestFrom, List<int> path) {
    path.add(curr);

    for (int adj in adjList[curr]) {
      if (longestFrom[adj] == longestFrom[curr] - 1) {
        _pathOfLongest(adj, adjList, longestFrom, path);
        break;
      }
    }
  }
  
  int _searchLongestPaths(int curr, List<List<int>> adjList, List<int> longestFrom, List<bool> visited, List<bool> fixed) {
    if (fixed[curr]) {
      longestFrom[curr] = -1;
      return -1;
    }
    if (visited[curr]) return longestFrom[curr];
    visited[curr] = true;

    for (int adj in adjList[curr]) {
      longestFrom[curr] = max(longestFrom[curr], _searchLongestPaths(adj, adjList, longestFrom, visited, fixed) + 1);
    }

    return longestFrom[curr];
  }

  void _constructDag(List<Event> events, List<List<int>> eventColumns, List<List<int>> adjList, List<List<int>> invAdjList) {
    // connect all overlapping exactly once, directly or indirectly
    // n^2 spacial complexity - store all indirectly and directly connected
    // sweep all right to left and if 
    // add edge for all overlapping but not connected
    // check reachable - add to left adjacent column, dfs from first columns 
    for (int i = 1; i < eventColumns.length; i++) {
      for (final event in eventColumns[i]) {
        for (final leftAdj in eventColumns[i-1]) {
          if (_eventsOverlap(events[leftAdj], events[event])) {
            print("overlap between $leftAdj and $event");
            adjList[leftAdj].add(event);
            invAdjList[event].add(leftAdj);
          }
        }
        List<bool> reachedTgt = List.filled(events.length, false);
        List<bool> visited = List.filled(events.length, false);
        for (final start in eventColumns[0]) {
          _checkReachable(start, event, adjList, reachedTgt, visited);
        }

        for (int j = 0; j < i; j++) {
          for (final left in eventColumns[j]) {
            if (_eventsOverlap(events[left], events[event]) && !reachedTgt[left]) {
              print("overlap between $left and $event");
              adjList[left].add(event);
              adjList[event].add(left);
            }
          }
        }
      }
    }
  }

  bool _checkReachable(int curr, int tgt, List<List<int>> adjList, 
    List<bool> reachedTgt, List<bool> visited) {

    if (curr == tgt) return true;
    if (visited[curr]) return reachedTgt[curr];
    visited[curr] = true;

    for (int adj in adjList[curr]) {
      reachedTgt[curr] = reachedTgt[curr] || _checkReachable(adj, tgt, adjList, reachedTgt, visited);
    }
    return reachedTgt[curr];
  }

  // ideal index depends on position in shorter paths
  // doesn't matter in longest
  // create sections for events with both a left and right bound
  // if overlap then path but not if path then overlap
  // building one by one doesn't really work as we need whole path to make informed decision
  // all overlaps must be connected
  // disconnect as many as possible
  // -> put those with most overlaps at the start or the end, build inwards

  void _columnEvents(List<Event> events, List<List<int>> eventColumns) {

    List<({int count, int event})> overlapCounts = [];

    List<List<int>> rightEventColumns = [];

    for (int i = 0; i < events.length; i++) {
      overlapCounts.add((count: 0, event: i));
    }

    for (int i = 0; i < events.length; i++) {
      for (int j = i+1; j < events.length; j++) {
        if (_eventsOverlap(events[i], events[j])) {
          overlapCounts[i] = (count: overlapCounts[i].count + 1, event: i);
          overlapCounts[j] = (count: overlapCounts[j].count + 1, event: j);
        }
      }
    }

    //sort most to least
    overlapCounts.sort((a, b) => b.count.compareTo(a.count));

    for (int i = 0; i < events.length; i++) {
      int count = overlapCounts[i].count;
      int event = overlapCounts[i].event;

      int leftCol = eventColumns.length;
      int rightCol = rightEventColumns.length;

      // find first column with no overlap
      // logic for left and right is same
      for (int c = 0; c < eventColumns.length; c++) {
        bool overlapInColumn = false;
        for (int e in eventColumns[c]) {
          if (_eventsOverlap(events[event], events[e])) {
            overlapInColumn = true;
            break;
          }
        }
        if (!overlapInColumn) {
          leftCol = c;
          break;
        }
      }

      for (int c = 0; c < rightEventColumns.length; c++) {
        bool overlapInColumn = false;
        for (int e in eventColumns[c]) {
          if (_eventsOverlap(events[event], events[e])) {
            overlapInColumn = true;
            break;
          }
        }
        if (!overlapInColumn) {
          rightCol = c;
          break;
        }
      }

      if (leftCol <= rightCol) {
        //insert left
        if (leftCol == eventColumns.length) eventColumns.add([]);
        eventColumns[leftCol].add(event);
      } else {
      if (rightCol == rightEventColumns.length) rightEventColumns.add([]);
        rightEventColumns[rightCol].add(event);
        //insert right
      }
    }

    for (int i = rightEventColumns.length - 1; i >= 0; i--) {
      eventColumns.add(rightEventColumns[i]);
    }
    // List<bool> columned = List.filled(events.length, false);
    // for (int i = 0; i < events.length; i++) {
    //   if (columned[i]) continue;
    //   eventColumns.add([i]);
    //   columned[i] = true;
    //   int last = i;

    //   for (int j = i+1; j < events.length; j++) {
    //     if (_eventsOverlap(events[last], events[j]) || columned[j]) continue;
    //     eventColumns.last.add(j);
    //     columned[j] = true;
    //     last = j;
    //   }
    // }
  }

  List<Widget> _generateEvents(List<Event> events, List<EventTileLayout> eventTileLayouts) {
    print(eventTileLayouts);
    for (final eventTileLayout in eventTileLayouts) {
      print("${eventTileLayout.width} ${eventTileLayout.left}");
    }
    return List.generate(events.length, (index) {
      double top = TimetableLayout.vertOffset(events[index].startTime.getTotalMinutes);
      double bottom = TimetableLayout.vertOffset(events[index].endTime.getTotalMinutes);
      Size size = Size(eventTileLayouts[index].width, bottom - top);
      print("top $top bottom $bottom");
      print("whaththeel");
      print(events[index].startTime);
      print(events[index].endTime);

      return Positioned(
        left: eventTileLayouts[index].left,
        top: top,
        child: EventTile(
          size: size,
        )
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    EventsModel eventsModel = EventsModel();
    eventsModel.populateEventsForToday();
    List<Event> events = eventsModel.getEventsOnDay(day);
    return Container(
      width: size.width,
      height: size.height,
      child: Stack(
        children: _generateEvents(events, _arrangeEvents(eventsModel.getEventsOnDay(day))),
      )
    );
  }
}