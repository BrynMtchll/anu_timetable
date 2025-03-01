import 'dart:math';

import 'package:anu_timetable/model/events.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';

typedef Bounds = ({List<double> left, List<double> right});
typedef BindsPath = ({List<bool> left, List<bool> right});

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

  List<EventTileLayout> arrange(Size size, List<Event> events) {
    this.size = size;
    this.events = events;
    events.sort((a, b) => a.startTime.compareTo(b.startTime));

    List<List<int>> columns = assignColumns();
    var (adjList, invAdjList) = constructGraph(columns);
    return fixLayouts(columns, adjList, invAdjList);
  }

  bool boundExists(double bound) => bound >= 0;

    //DONE
  int findFirstFreeColumn(List<List<int>> columns, int event) {
    for (int i = 0; i < columns.length; i++) {
      bool spaceAvailable = true;

      for (int other in columns[i]) {
        if (events[event].overlapping(events[other])) {
          spaceAvailable = false;
          break;
        }
      }
      if (spaceAvailable) return i;
    } 
    columns.add([]);
    return columns.length-1;
  }

  //DONE
  List<({int count, int event})> countOverlaps() {
    List<({int count, int event})> overlapCounts = [];

    for (int i = 0; i < events.length; i++) {
      overlapCounts.add((count: 0, event: i));
    }
    for (int i = 0; i < events.length; i++) {
      for (int j = 0; j < i; j++) {
        if (events[i].overlapping(events[j])) {
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

  //DONE
  List<List<int>> assignColumns() {
    List<({int count, int event})> overlapCounts = countOverlaps();
    List<List<int>> columns = [];
    List<List<int>> rightColumns = [];

    for (int i = 0; i < events.length; i++) {
      overlapCounts.add((count: 0, event: i));
    }

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

  // connect all overlapping exactly once, directly or indirectly
  // check reachable - add to left adjacent column, dfs from first columns 

  //DONE
  (List<List<int>> adjList, List<List<int>> invAdjList) constructGraph(List<List<int>> columns) {
    List<List<int>> adjList = [];
    List<List<int>> invAdjList = [];
    List<List<int>> leftOverlaps = [];
    List<List<bool>> connected = [];

    for (int i = 0; i < events.length; i++) {
      adjList.add([]);
      invAdjList.add([]);
      leftOverlaps.add([]);
      connected.add(List.filled(events.length, false));
    }

    for (int i = 0; i < columns.length; i++) {
      for (int event in columns[i]) {
        for (int k = 0; k < i; k++) {
          for (int leftEvent in columns[k]) {
            if (events[event].overlapping(events[leftEvent])) {
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

  //DONE
  void buildPathOfLongest(int curr, List<List<int>> adjList, List<int> longestFrom, List<int> path) {
    path.add(curr);
    for (int adj in adjList[curr]) {
      if (longestFrom[adj] == longestFrom[curr] - 1) {
        buildPathOfLongest(adj, adjList, longestFrom, path);
        break;
      }
    }
  }

  //DONE
  int searchLongestPaths(int curr, List<List<int>> adjList, List<int> longestFrom, List<bool> visited, List<bool> fixed) {
    if (fixed[curr]) {
      longestFrom[curr] = -1;
      return -1;
    }
    if (visited[curr]) return longestFrom[curr];
    visited[curr] = true;

    for (int adj in adjList[curr]) {
      longestFrom[curr] = max(longestFrom[curr], searchLongestPaths(adj, adjList, longestFrom, visited, fixed) + 1);
    }
    return longestFrom[curr];
  }

  //DONE
  List<int> getLongestPath(List<List<int>> columns, List<List<int>> adjList, List<bool> fixed) {
    List<int> longestFrom = List.filled(events.length, 1);
    List<bool> visited = List.filled(events.length, false);
    ({int length, int startEvent}) longest = (length: 0, startEvent: 0);

    for (final column in columns) {
      for (final event in column) {
        int longestFromEvent = searchLongestPaths(event, adjList, longestFrom, visited, fixed);
        if (longestFromEvent > longest.length) {
          longest = (length: longestFromEvent, startEvent: event);
        }
      }
    }
    
    List<int> path = [];
    buildPathOfLongest(longest.startEvent, adjList, longestFrom, path);
    return path;
  }

  // priority queue of section densities
  // left bound on right side - merge right
  // right bound on left side - merge left
  // left bound on left side or right bound on right side - fixed

  // back edge for right bound
  // left and right bound on same event
  // right bound less than or equal to left bound - error!
  // if equal then event would have zero width
  PriorityQueue<Section> createSections(List<int> path, Bounds bounds) {
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
      if (!boundExists(bounds.right[endEvent]) && !boundExists(bounds.left[endEvent])) continue;

      if (start == end - 1 && boundExists(bounds.right[startEvent]) && boundExists(bounds.left[startEvent])) {
        addSection(Section(
          width: bounds.right[startEvent] - bounds.left[startEvent],
          start: start,
          end: start, 
          canMergeLeft: false, 
          canMergeRight: false));
      }

      double endPos = boundExists(bounds.left[endEvent]) ? bounds.left[endEvent] : bounds.right[endEvent];
      double startPos = boundExists(bounds.right[startEvent]) ? bounds.right[startEvent] : bounds.left[startEvent];

      addSection(Section(
        width: endPos - startPos, 
        start: start, 
        end: end,
        canMergeLeft: boundExists(bounds.right[startEvent]),
        canMergeRight: boundExists(bounds.left[endEvent])));

      start = end;
    }
    return sections;
  }

  // if left merge, left must be right bound
  // if not, left is either fixed right bound or left bound
  // if right merge, right must be left bound
  // if not, right is eitehr fixed left bound or right bound

  // left and right bound can both be fixed fir same position
  void fixSection(Section sect, List<int> path, BindsPath bindsPath) {
    int startEvent = path[sect.start], endEvent = path[sect.end];

    if (sect.start == sect.end) {
        bindsPath.left[startEvent] = true;
        bindsPath.right[startEvent] = true;
    }
    else {
      if (!bindsPath.right[startEvent]) bindsPath.left[startEvent] = true;
      if (!bindsPath.left[endEvent]) bindsPath.right[endEvent] = true;
    }
    sect.left?.canMergeRight = false;
    sect.right?.canMergeLeft = false;
  }

  List<Section> mergeSections(PriorityQueue<Section> sections, List<int> path, BindsPath bindsPath) {
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
        fixSection(sect, path, bindsPath);
        fixedSections.add(sect);
      }
    }
    return fixedSections;
  }

  double getSectionOffset(Section s, int leftEvent, Bounds bounds, BindsPath bindsPath) {
    if (s.start == s.end) return bounds.left[leftEvent];
    return bindsPath.left[leftEvent] ? bounds.left[leftEvent] : bounds.right[leftEvent];
  }

  void fixPathLayouts(List<Section> fixedSections, List<int> path, List<EventTileLayout> eventTileLayouts, Bounds bounds, BindsPath bindsPath) {
    for (final Section sect in fixedSections) {
      final double eventWidth = sect.width / (sect.length+1);
      final double sectOffset = getSectionOffset(sect, path[sect.start], bounds, bindsPath);

      for (int i = sect.start; i <= sect.end; i++) {
        eventTileLayouts[path[i]].width = eventWidth;
        eventTileLayouts[path[i]].left = eventWidth*i + sectOffset;
      }
    }
  }

  void setBoundsForPath(List<EventTileLayout> eventTileLayouts, List<int> path, List<List<int>> adjList, List<List<int>> invAdjList, Bounds bounds) {
    for (final event in path) {
      for (final adj in adjList[event]) {
        bounds.left[adj] = eventTileLayouts[event].width + eventTileLayouts[event].left;
      }
      for (final adj in invAdjList[event]) {
        bounds.right[adj] = eventTileLayouts[event].left;
      }
    }
  }

  List<EventTileLayout> fixLayouts(List<List<int>> columns, List<List<int>> adjList, List<List<int>> invAdjList) {
    final List<EventTileLayout> eventTileLayouts = [];
    final List<bool> fixed = List.filled(events.length, false);
    Bounds bounds = (left: List.filled(events.length, -1), right: List.filled(events.length, -1));
    int numFixed = 0;

    for (int i = 0; i < events.length; i++) {
      eventTileLayouts.add(EventTileLayout());
    }

    while (numFixed < events.length) {
      BindsPath bindsPath = (left: List.filled(events.length, false), right: List.filled(events.length, false));
      
      List<int> path = getLongestPath(columns, adjList, fixed);
      if (!boundExists(bounds.left[path.first])) bounds.left[path.first] = max(bounds.left[path.first], 0);
      if (!boundExists(bounds.right[path.last])) bounds.right[path.last] = size.width;

      final PriorityQueue<Section> sections = createSections(path, bounds);
      final List<Section> fixedSections = mergeSections(sections, path, bindsPath);
      fixPathLayouts(fixedSections, path, eventTileLayouts, bounds, bindsPath);
      setBoundsForPath(eventTileLayouts, path, adjList, invAdjList, bounds);
      for (final event in path) {
        fixed[event] = true;
      }
      numFixed += path.length;
    }
    return eventTileLayouts;
  }
}