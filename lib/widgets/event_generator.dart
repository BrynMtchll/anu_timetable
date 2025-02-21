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

class Section implements Comparable {
  final int l;
  final int r;
  bool canMergeLeft;
  bool canMergeRight;
  late int length;
  late double density;
  final double width;

  Section(this.width, this.l, this.r, this.canMergeLeft, this.canMergeRight) {
    length = r - l;
    density = length / width;
  }

  @override
  int compareTo(other) {
    return (density * 1000).toInt();
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

  bool _eventsOverlap(Event a, Event b) {
    //starttime a before endtime b
    // and starttime b before endtime a

    return a.startTime.compareTo(b.endTime) < 0
      && b.startTime.compareTo(a.endTime) < 0;
  }

  List<EventTileLayout> _arrangeEvents(List<Event> events) {
    events.sort((a, b) => a.startTime.compareTo(b.startTime));
    final int numEvents = events.length;
    List<List<int>> adjList = List.empty(growable: true);
    List<List<int>> invAdjList = List.empty(growable: true);
    List<List<int>> eventColumns = List.empty(growable: true);
    // print("hey");
    List<EventTileLayout> eventTileLayouts = List.empty(growable: true);
    for (int i = 0; i < numEvents; i++) {
      adjList.add([]);
      invAdjList.add([]);
      eventTileLayouts.add(EventTileLayout());
    }

    _columnEvents(events, eventColumns);
    
    // print("COLUMNNNSSS");
    // for (int i = 0; i < eventColumns.length; i++) {
    //   print("COLUMN $i");
    //   for (final event in eventColumns[i]) {
    //     print(event);
    //   }
    // }
    _constructDag(events, eventColumns, adjList, invAdjList);

    // print("ADJAJCJASSS");
    // for (int i = 0; i < eventColumns.length; i++) {
    //   for (final event in eventColumns[i]) {
    //     print("EVENT $event");
    //     print(adjList[event]);
    //     // for (int adj in adjList[event]) {
    //     //   print(adj);
    //     // }
    //   }
    // }
    _fixEvents(events, eventColumns, adjList, invAdjList, eventTileLayouts);
    return eventTileLayouts;
  }

  void _fixEvents(List<Event> events, List<List<int>> eventColumns, List<List<int>> adjList, List<List<int>> invAdjList, List<EventTileLayout> eventTileLayouts) {
    List<bool> fixed = List.filled(events.length, false);
    List<double> leftBound = List.filled(events.length, -1);
    List<double> rightBound = List.filled(events.length, -1);

    int numFixed = 0;
    while (numFixed < events.length) {
      int longest = 0;
      List<int> longestFrom = List.filled(events.length, 1);
      List<bool> visited = List.filled(events.length, false);

      //TODO store pair to avoid double looping
      List<int> path = List.empty(growable: true);
      for (final column in eventColumns) {
        for (final start in column) {
          longest = max(longest, _searchLongestPaths(start, adjList, longestFrom, visited, fixed));
        }
      }

      for (final column in eventColumns) {
        print("COLUMN");
        for (final event in column) {
          print("event: $event longestfrom ${longestFrom[event]}");
        }
      }
      outerLoop:
      for (final column in eventColumns) {
        for (final start in column) {
          if (longest == longestFrom[start]) {
            _pathOfLongest(start, adjList, longestFrom, path);
            break outerLoop;
          }
        }
      }
      print("PATH: ${path}");
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
  void _fixPath(List<Event> events, List<int> path, List<EventTileLayout> eventTileLayouts, List<double> leftBound, List<double> rightBound) {
    List<bool> fixedlb = List.filled(events.length, false);
    List<bool> fixedrb = List.filled(events.length, false);
    print("heyeyyyyy");

    Map<int, Section> right = {};
    Map<int, Section> left = {};

    List<Section> fixedSections = [];

    //fix!!!
    double totalWidth = 300;

    final PriorityQueue<Section> pq = PriorityQueue();

    if (leftBound[path[0]] < 0) leftBound[path[0]] = 0;
    if (rightBound[path[path.length - 1]] < 0) rightBound[path[path.length - 1]] = totalWidth;
    print(leftBound[path[0]]);
    print(rightBound[path[path.length - 1]]);

    left[0] = Section(1, 0, 0, false, false);
    right[path.length - 1] = Section(1, 0, 0, false, false);

    for (int i = 0; i < path.length; i++) {
      if (rightBound[path[i]] < 0 || leftBound[path[i]] < 0) continue;
      double width = rightBound[path[i]] - leftBound[path[i]];
      Section s = Section(width, i, i, false, false);
      left[i] = s;
      right[i] = s;
      pq.add(s);
      print("adding ${s.l} ${s.r}");
    }

    for (int r = 1, l = 0; r < path.length; r++) {
      if (rightBound[path[r]] < 0 && leftBound[path[r]] < 0) continue;

      double width = 0;
      bool canMergeLeft = false, canMergeRight = false;

      if (leftBound[path[r]] >= 0) {
        width = leftBound[path[r]];
        canMergeRight = true;
      } else {
        width = rightBound[path[r]];
      }

      if (rightBound[path[l]] >= 0) {
        width -= rightBound[path[l]];
        canMergeLeft = true;
      } else {
        width -= leftBound[path[l]];
      }

      Section s = Section(width, l, r, canMergeLeft, canMergeRight);
      left[r] = s;
      right[l] = s;
      pq.add(s);
      print("adding ${s.l} ${s.r}");
      l = r;
    }

    Section merge(Section a, Section b) =>
      Section(a.width + b.width, a.l, b.r, a.canMergeLeft, b.canMergeRight);
    

    // don't need a pq - just sort a list and iterate through 
    while (pq.isNotEmpty) {
      Section s = pq.removeFirst();
      print("popping ${s.l} ${s.r}");
      Section ls = left[s.l]!;
      Section rs = right[s.r]!;

      if (s.canMergeLeft && (!s.canMergeRight || (s.canMergeRight && ls.compareTo(rs) < 0))) {
        pq.remove(ls);
        Section newSection = merge(ls, s);
        left[s.r] = newSection;
        right[ls.l] = newSection;
        right.remove(s.l); 
        left.remove(s.l);
      }
      else if (s.canMergeRight && (!s.canMergeLeft || (s.canMergeLeft && rs.compareTo(ls) < 0))) {
        pq.remove(rs);
        Section ns = merge(s, rs);
        right[s.l] = ns;
        left[rs.r] = ns;
        left.remove(s.r); 
        right.remove(s.r);
      }
      // if left merge, left must be right bound
      // if not, left is either fixed right bound or left bound
      // if right merge, right must be left bound
      // if not, right is eitehr fixed left bound or right bound

      // left and right bound can both be fixed fir same position
      else if (!s.canMergeLeft && !s.canMergeRight) {
        if (s.l == s.r) {
          fixedlb[path[s.l]] = true;
          fixedrb[path[s.l]] = true;
        }
        else {
          if (!fixedrb[path[s.l]] && !fixedlb[path[s.l]]) {
            fixedlb[path[s.l]] = true;
          }
          if (!fixedlb[path[s.r]] && !fixedrb[path[s.r]]) {
            fixedrb[path[s.r]] = true;
          }
        }
        fixedSections.add(s);
        left[s.l]!.canMergeRight = false;
        right[s.r]!.canMergeLeft = false;
      }
    }

    for (final Section s in fixedSections) {
      print("section: ${s.l} ${s.r}");
      double sOffset;

      if (s.l == s.r) {
        sOffset = leftBound[path[s.l]];
      } else {
        if (fixedrb[path[s.l]]) {
          sOffset = rightBound[path[s.l]];
        } else if (fixedlb[path[s.l]]) {
          sOffset = leftBound[path[s.l]];
        }
        else {
          throw Error();
        }
      }

      // print("path start ${path[section.l]}");

      final double eventWidth = s.width / (s.length+1);
      for (int i = s.l; i <= s.r; i++) {
        final double eventOffset = eventWidth*i + sOffset;
        final int event = path[i];
        eventTileLayouts[event].width = eventWidth;
        eventTileLayouts[event].left = eventOffset;
        print("event $event: $eventOffset ${eventWidth}");
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