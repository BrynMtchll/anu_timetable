import 'dart:collection';
import 'dart:math';

import 'package:anu_timetable/model/events.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';

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

class EventTileArranger {
  late List<Event> events;
  late Size size;

  late List<List<int>> columns;
  late List<EventTileLayout> eventTileLayouts;
  late List<List<int>> leftOverlaps;
  late List<List<bool>> connected;

  bool overlapping(Event a, Event b) => 
    a.startTime.compareTo(b.endTime) < 0 && b.startTime.compareTo(a.endTime) < 0;

  void prepare(Size size, List<Event> events) {
    this.size = size;
    this.events = events;
    events.sort((a, b) => a.startTime.compareTo(b.startTime));

    eventTileLayouts = [];

    leftOverlaps = [];
    connected = [];
    for (int i = 0; i < events.length; i++) {
      eventTileLayouts.add(EventTileLayout());
      leftOverlaps.add([]);
      connected.add(List.filled(events.length, false));
    }
  }

  List<EventTileLayout> arrange(Size size, List<Event> events) {
    prepare(size, events);
    columns = assignColumns(events);
    var (adjList, invAdjList) = constructGraph(events, columns);
    return fixLayouts(events, columns, adjList, invAdjList);
  }

  List<EventTileLayout> fixLayouts(List<Event> events, List<List<int>> columns, List<List<int>> adjList, List<List<int>> invAdjList) {
    final List<EventTileLayout> eventTileLayouts = [];
    final List<bool> fixed = List.filled(events.length, false);
    final BoundList leftBound = BoundList(events.length, -1);
    final BoundList rightBound = BoundList(events.length, -1);
    int numFixed = 0;

    for (int i = 0; i < events.length; i++) {
      eventTileLayouts.add(EventTileLayout());
    }

    while (numFixed < events.length) {
      List<int> path = getLongestPath(adjList, fixed);
      leftBound.fixed = List.filled(events.length, false);
      rightBound.fixed = List.filled(events.length, false);

      if (leftBound[path[0]] < 0) leftBound[path[0]] = 0;
      if (rightBound[path[path.length - 1]] < 0) rightBound[path[path.length - 1]] = size.width;

      final PriorityQueue<Section> sections = createSections(path, leftBound, rightBound);
      final List<Section> fixedSections = mergeSections(sections, path, leftBound, rightBound);
      assignLayouts(fixedSections, path, eventTileLayouts, leftBound, rightBound);

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
    return eventTileLayouts;
  }

  List<int> getLongestPath(List<List<int>> adjList, List<bool> fixed) {
    List<int> longestFrom = List.filled(events.length, 1);
    List<bool> visited = List.filled(events.length, false);
    ({int length, int event}) longest = (length: 0, event: 0);

    for (final column in columns) {
      for (final event in column) {
        int result = _searchLongestPaths(event, adjList, longestFrom, visited, fixed);
        if (result > longest.length) {
          longest = (length: result, event: event);
        }
      }
    }
    
    List<int> path = [];
    buildPathOfLongest(longest.event, adjList, longestFrom, path);
    return path;
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

  PriorityQueue<Section> createSections(List<int> path, BoundList leftBound, BoundList rightBound) {
    Section? head;
    PriorityQueue<Section> sections = PriorityQueue();

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
    return sections;
  }

   // if left merge, left must be right bound
  // if not, left is either fixed right bound or left bound
  // if right merge, right must be left bound
  // if not, right is eitehr fixed left bound or right bound

  // left and right bound can both be fixed fir same position
  void fixSection(Section sect, List<Section> fixedSections, List<int> path, BoundList leftBound, BoundList rightBound) {
    int startEvent = path[sect.start], endEvent = path[sect.end];

    if (sect.start == sect.end) {
        leftBound.fixed[startEvent] = true;
        rightBound.fixed[startEvent] = true;
    }
    else {
      if (!rightBound.fixed[startEvent]) leftBound.fixed[startEvent] = true;
      if (!leftBound.fixed[endEvent]) rightBound.fixed[endEvent] = true;
    }
    fixedSections.add(sect);
    sect.left?.canMergeRight = false;
    sect.right?.canMergeLeft = false;
  }

  List<Section> mergeSections(PriorityQueue<Section> sections, List<int> path, BoundList leftBound, BoundList rightBound) {
    List<Section> fixedSections = [];

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
        fixSection(sect, fixedSections, path, leftBound, rightBound);
      }
    }
    return fixedSections;
  }

  double _sectionOffset(Section s, int leftEvent, BoundList leftBound, BoundList rightBound) {
    if (s.start == s.end) return leftBound[leftEvent];
    return leftBound.fixed[leftEvent] ? leftBound[leftEvent] : rightBound[leftEvent];
  }

  void assignLayouts(List<Section> fixedSections, List<int> path, List<EventTileLayout> eventTileLayouts, BoundList leftBound, BoundList rightBound) {
    for (final Section sect in fixedSections) {
      final double eventWidth = sect.width / (sect.length+1);
      final double sectOffset = _sectionOffset(sect, path[sect.start], leftBound, rightBound);

      for (int i = sect.start; i <= sect.end; i++) {
        eventTileLayouts[path[i]].width = eventWidth;
        eventTileLayouts[path[i]].left = eventWidth*i + sectOffset;
      }
    }
  }

  void buildPathOfLongest(int curr, List<List<int>> adjList, List<int> longestFrom, List<int> path) {
    path.add(curr);
    for (int adj in adjList[curr]) {
      if (longestFrom[adj] == longestFrom[curr] - 1) {
        buildPathOfLongest(adj, adjList, longestFrom, path);
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

  // connect all overlapping exactly once, directly or indirectly
  // check reachable - add to left adjacent column, dfs from first columns 
  (List<List<int>> adjList, List<List<int>> invAdjList) constructGraph(List<Event> events, List<List<int>> columns) {
    List<List<int>> adjList = [];
    List<List<int>> invAdjList = [];

    for (int i = 0; i < events.length; i++) {
      adjList.add([]);
      invAdjList.add([]);
    }

    for (int i = 0; i < columns.length; i++) {
      for (int event in columns[i]) {
        for (int k = 0; k < i; k++) {
          for (int leftEvent in columns[k]) {
            if (overlapping(events[event], events[leftEvent])) {
              leftOverlaps[event].add(leftEvent);
            }
          }
        }
      }
    }

    for (int i = 1; i < columns.length; i++) {
      for (final event in columns[i]) {
        for (int j = leftOverlaps[event].length - 1; j >= 0; j--) {
          int left = leftOverlaps[event][j];

          if (connected[event][left]) continue;
          connected[event][left] = true;

          for (int i = 0; i < events.length; i++) {
            connected[event][i] = connected[event][i] || connected[left][i];
          }
          adjList[left].add(event);
          invAdjList[event].add(left);
        }
      }
    }

    return (adjList, invAdjList);
  }

  int findFirstFreeColumn(List<List<int>> columns, int event) {
    for (int i = 0; i < columns.length; i++) {
      bool spaceAvailable = true;

      for (int other in columns[i]) {
        if (overlapping(events[other], events[event])) {
          spaceAvailable = false;
          break;
        }
      }
      if (spaceAvailable) return i;
    } 
    columns.add([]);
    return columns.length-1;
  }

  List<({int count, int event})> countOverlaps() {
    List<({int count, int event})> overlapCounts = [];

    for (int i = 0; i < events.length; i++) {
      overlapCounts.add((count: 0, event: i));
    }
    for (int i = 0; i < events.length; i++) {
      for (int j = 0; j < i; j++) {
        if (overlapping(events[i], events[j])) {
          overlapCounts[i] = (count: overlapCounts[i].count + 1, event: i);
          overlapCounts[j] = (count: overlapCounts[j].count + 1, event: j);
        }
      }
    }
    return overlapCounts;
  }

  // ideal index depends on position in shorter paths
  // doesn't matter in longest
  // create sections for events with both a left and right bound
  // if overlap then path but not if path then overlap
  // building one by one doesn't really work as we need whole path to make informed decision
  // all overlaps must be connected
  // disconnect as many as possible
  // -> put those with most overlaps at the start or the end, build inwards

  List<List<int>> assignColumns(List<Event> events) {
    List<({int count, int event})> overlapCounts = countOverlaps();
    List<List<int>> columns = [];
    List<List<int>> rightColumns = [];

    for (int i = 0; i < events.length; i++) {
      overlapCounts.add((count: 0, event: i));
    }

    //sort most to least
    overlapCounts.sort((a, b) => b.count.compareTo(a.count));

    for (int i = 0; i < events.length; i++) {
      int event = overlapCounts[i].event;

      int leftCol = findFirstFreeColumn(columns, event);
      int rightCol = findFirstFreeColumn(rightColumns, event);

      if (leftCol <= rightCol) {
        columns[leftCol].add(event);
      } else {
        rightColumns[rightCol].add(event);
      }
    }

    for (int i = rightColumns.length - 1; i >= 0; i--) {
      columns.add(rightColumns[i]);
    }

    return columns;
  }
}