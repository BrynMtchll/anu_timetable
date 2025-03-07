import 'dart:math';

import 'package:anu_timetable/model/events.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';

typedef Bounds = ({List<double> left, List<double> right});
typedef BindsPath = ({List<bool> left, List<bool> right});
typedef EventTileLayout = ({double left, double width});

/// a section of a path in the graph derived from the visual ordering of event tiles.
/// 
class Section implements Comparable {
  final int start;
  final int end;
  bool canMergeLeft;
  bool canMergeRight;
  late int length;
  late double density;
  final double width;
  // null for the first section of a path.
  Section? left;
  // null For the last section of a path.
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

  /// A section should merge left if it can merge left but no right, or it can merge left 
  /// and right but [left] has a lower density than [right].
  ///
  /// A section [canMergeLeft] if a section if [left] is not null, 
  /// i.e. it is not the leftmost section, if [left] is not already fixed, and if the shared bound
  /// between it and [left] is a right bound. 
  bool shouldMergeLeft() =>
    left != null && canMergeLeft && (!canMergeRight || (canMergeRight && left!.compareTo(right) < 0));

  /// A section should merge right if it can merge right but no left, or it can merge right 
  /// and left but [right] has a lower density than [left].
  ///
  /// A section [canMergeRight] if a section if [right] is not null, 
  /// i.e. it is not the leftmost section, if [right] is not already fixed, and if the shared bound
  /// between it and [right] is a left bound. 
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

class EventTileArranger {
  late List<Event> events;
  late Size size;

  /// Arranges a set of event tiles so that their widths are holistically 
  /// maximised.
  /// Returns a list containing the left offset and width for each event tile
  /// (the height and top offset of the tiles are already defined by the event
  /// duration and start time).
  List<EventTileLayout> arrange(Size size, List<Event> events) {
    this.size = size;
    this.events = events;
    events.sort((a, b) => a.startTime.compareTo(b.startTime));

    List<List<int>> columns = assignColumns();
    var (adjList, invAdjList) = buildGraph(columns);
    return fixLayouts(columns, adjList, invAdjList);
  }

  bool boundExists(double bound) => bound >= 0;

  /// Finds the first column in the given set of columns that doesn't 
  /// contain any events that overlap with the given event. If there 
  /// are no such columns, a new empty column is added. 
  /// Returns the index of the found column.
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

  /// Counts the number of events that overlap with each.
  /// Returns a sorted list of pairs of the event and the count for that 
  /// event.
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
    // Sort events by the number of overlaps in descending order.
    overlapCounts.sort((a, b) => b.count.compareTo(a.count));
    return overlapCounts;
  }

  /// Assigns events to columns, which denote their relative position to other events. 
  /// Returns a list of the columns.
  /// 
  /// The constraints an event has on the arrangement is proportional to the 
  /// number of overlaps an event has and how centrally it is placed.
  /// So, events with the most overlaps are assigned to the outermost columns.
  /// 
  /// In the order of the overlap count, found by [countOverlaps], each event is 
  /// assigned to the outermost column that doesn't contain any other overlapping
  /// events, using [findFirstFreeColumn]. If none is found, a new innermost column
  /// is added (within [findFirstFreeColumn]). 
  /// 
  /// The left and right column groups are maintained seperately so that this 
  /// can be done efficiently. They are joined and returned once all events have been added.
  List<List<int>> assignColumns() {
    List<({int count, int event})> overlapCounts = countOverlaps();
    List<List<int>> columns = [];
    List<List<int>> rightColumns = [];

    for (int i = 0; i < events.length; i++) {
      final event = overlapCounts[i].event;
      final leftCol = findFirstFreeColumn(columns, event);
      final rightCol = findFirstFreeColumn(rightColumns, event);
      if (leftCol <= rightCol) {
        columns[leftCol].add(event);
      } else {
        rightColumns[rightCol].add(event);
      }
    }
    // Append the right side columns to the left side columns.
    for (int i = rightColumns.length - 1; i >= 0; i--) {
      columns.add(rightColumns[i]);
    }
    return columns;
  }

  /// For each event, constructs a list of overlapping events with that event
  /// that are in a column to its left.
  /// Returns the collection of these lists.
  List<List<int>> collectLeftOverlaps(List<List<int>> columns) {
    List<List<int>> leftOverlaps = [];
    for (int i = 0; i < events.length; i++) {
      leftOverlaps.add([]);
    }
    // Construct leftOverlaps so that the events are sorted in order of column proximity. 
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
    return leftOverlaps;
  }

  /// Constructs a DAG (Directed Acyclic Graph) representation of the columned events going 
  /// left to right.
  /// Returns the adjacency list and the inverse adjacency list for this graph.
  /// 
  /// All overlaping event pairs are minimally connected; an edge is added between an event 
  /// pair if they are overlapping and not already connected.
  /// 
  /// Subgraphs are disconnected wherever there is a span of time which no events lie over.
  ///  
  /// The graph is directed from left to right. An inverse graph is also constructed for managing
  /// constraints in [fixLayouts].
  /// 
  /// For each event, the events that are to the left and overlapping, as obtained from 
  /// [collectLeftOverlaps], are iterated through and connected.
  /// 
  /// Edges are added between overlapping event pairs in the order of the proximity of their columns,
  /// starting with those nearest, in order to minimise duplicate paths.
  (List<List<int>> adjList, List<List<int>> invAdjList) buildGraph(List<List<int>> columns) {
    List<List<int>> adjList = [];
    List<List<int>> invAdjList = [];
    List<List<int>> leftOverlaps = collectLeftOverlaps(columns);
    // List for each event of events connected, i.e. reachable through the graph, to that event.
    List<List<bool>> connected = [];

    for (int i = 0; i < events.length; i++) {
      adjList.add([]);
      invAdjList.add([]);
      connected.add(List.filled(events.length, false));
    }
    // For each event, connect each overlapping event on it's left to it.
    for (int i = 1; i < columns.length; i++) {
      for (final event in columns[i]) {
        for (int j = leftOverlaps[event].length - 1; j >= 0; j--) {
          final left = leftOverlaps[event][j];

          if (connected[event][left]) continue;
          connected[event][left] = true;

          // Copy over all that are connected to the left event to the newly connected event.
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

  /// Recursively traces the longest path from [curr] as denoted by [maxLengthFrom]
  /// and appends it to [path].
  void traceLongestPath(int curr, List<List<int>> adjList, List<int> maxLengthFrom, List<int> path) {
    path.add(curr);
    for (int adj in adjList[curr]) {
      if (maxLengthFrom[adj] == maxLengthFrom[curr] - 1) {
        traceLongestPath(adj, adjList, maxLengthFrom, path);
        break;
      }
    }
  }

  /// Determines the length of the longest path from each node (event) and stores it in [maxLengthFrom].
  /// Returns the length of the longest path from [curr].
  int findMaxLengthFrom(int curr, List<List<int>> adjList, List<int> maxLengthFrom, List<bool> visited, List<bool> fixed) {
    if (fixed[curr]) {
      maxLengthFrom[curr] = -1;
      return -1;
    }
    if (visited[curr]) return maxLengthFrom[curr];
    visited[curr] = true;

    for (int adj in adjList[curr]) {
      maxLengthFrom[curr] = max(maxLengthFrom[curr], findMaxLengthFrom(adj, adjList, maxLengthFrom, visited, fixed) + 1);
    }
    return maxLengthFrom[curr];
  }

  /// Finds and returns the longest path in the graph of so far unfixed events.
  /// 
  /// The root with the max path length starting from it is found using [findMaxLengthFrom],
  /// which also stores the max path length from each node it visits in maxLengthFrom.
  /// [traceLongestPath] then traces the longest path using maxLengthFrom.
  List<int> getLongestPath(List<List<int>> columns, List<List<int>> adjList, List<bool> fixed) {
    List<int> maxLengthFrom = List.filled(events.length, 1);
    List<bool> visited = List.filled(events.length, false);
    ({int length, int root}) longest = (length: 0, root: 0);

    // Consider all unfixed roots.
    // By starting the scan from the leftmost column it's maintained that
    // if an event has not been visited then it is a root. 
    for (final column in columns) {
      for (final root in column) {
        // This is also checked in findMaxLengthFrom but checking here saves possibly redundant steps.
        if (visited[root]) continue;
        final maxLengthFromEvent = findMaxLengthFrom(root, adjList, maxLengthFrom, visited, fixed);
        if (maxLengthFromEvent > longest.length) {
          longest = (length: maxLengthFromEvent, root: root);
        }
      }
    }
    List<int> path = [];
    traceLongestPath(longest.root, adjList, maxLengthFrom, path);
    return path;
  }

  // priority queue of section densities
  // left bound on right side - merge right
  // right bound on left side - merge left
  // left bound on left side or right bound on right side - fixed

  /// Creates the initial sections of the path. This is the first step in
  /// fixing the [path].
  /// Returns a [PriorityQueue] of the created sections. 
  /// 
  /// The [path] is divided into [Section]s according to the constraints imposed
  /// by already fixed events, given in [bounds]. 
  /// 
  /// A section is created for every pair of neighbouring bounds. 
  /// Sections are contiguous across bounds and non-overlapping.
  /// Sections also minimally span 1 node and collectively encompass the whole path.
  /// 
  /// Both a left and right bound may exist on a single node. In this case,
  /// the left bound will be the right edge of the left section, 
  /// the right bound will be the left edge of the right a section,
  /// and a section will be created between those bounds spanning just that node.
  ///
  /// EXAMPLE
  /// ```
  ///           L        L R    L        R    R    L 
  /// bounds:   |        | |    |        |    |    |    
  /// nodes:    01   02   03   04   05   06   07   08
  /// sections: |--------|-|----|---------|----|----|
  ///                A    B   C      D       E    F
  /// ```
  /// Sections are merged out of order in [mergeSections]. 
  /// So that a section may be merged into its neighbours, a linked list is implicitly
  /// maintained via [Section.left] and [Section.right].
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
      final startEvent = path[start], endEvent = path[end];

      // case where both a left and right bound exist for a single node. 
      if (start == end - 1 && boundExists(bounds.right[startEvent]) && boundExists(bounds.left[startEvent])) {
        addSection(Section(
          width: bounds.right[startEvent] - bounds.left[startEvent],
          start: start,
          end: start, 
          canMergeLeft: false, 
          canMergeRight: false));
      }
      if (boundExists(bounds.right[endEvent]) || boundExists(bounds.left[endEvent])) {
        final endPos = boundExists(bounds.left[endEvent]) ? bounds.left[endEvent] : bounds.right[endEvent];
        final startPos = boundExists(bounds.right[startEvent]) ? bounds.right[startEvent] : bounds.left[startEvent];
        addSection(Section(
          width: endPos - startPos, 
          start: start, 
          end: end,
          canMergeLeft: boundExists(bounds.right[startEvent]),
          canMergeRight: boundExists(bounds.left[endEvent])));
        start = end;
      }
    }
    return sections;
  }

  // if left merge, left must be right bound
  // if not, left is either fixed right bound or left bound
  // if right merge, right must be left bound
  // if not, right is eitehr fixed left bound or right bound

  // left and right bound can both be fixed fir same position
  // DONE
  void fixSection(Section sect, List<int> path, BindsPath bindsPath) {
    final startEvent = path[sect.start], endEvent = path[sect.end];

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

  /// Merges [sections] into one another so that [Section.density] is minimised, 
  /// i.e. width is optimally distributed between the [path] nodes. 
  /// Returns the merged sections. 
  /// 
  /// [Section.density] denotes the ratio between the number of nodes and the 
  /// available width of the section. The [sections] are ordered by their densiities
  /// from highest to lowest.
  /// 
  /// Each section in [sections], starting with that with the highest density, is removed
  /// and merged with a neighbouring section if possible and preffered, as given by 
  /// [Section.shouldMergeLeft] and [Section.shouldMergeRight]. The neighbour to be merged 
  /// with is also removed from [sections] and the new merged section is inserted. 
  /// If neither side can be merged with, then the section is fixed via [fixSection], meaning it cannot be 
  /// merged into by its neighbours. 
  /// 
  /// Once all sections are fixed, the list of fixed sections are returned. 
  List<Section> mergeSections(PriorityQueue<Section> sections, List<int> path, BindsPath bindsPath) {
    final List<Section> fixedSections = [];

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

  // DONE
  double getSectionOffset(Section sect, int leftEvent, Bounds bounds, BindsPath bindsPath) {
    if (sect.start == sect.end) return bounds.left[leftEvent];
    return bindsPath.left[leftEvent] ? bounds.left[leftEvent] : bounds.right[leftEvent];
  }

  // DONE
  void fixPathLayouts(List<Section> fixedSections, List<int> path, List<EventTileLayout> eventTileLayouts, Bounds bounds, BindsPath bindsPath) {
    for (final Section sect in fixedSections) {
      final eventWidth = sect.width / (sect.length+1);
      final sectOffset = getSectionOffset(sect, path[sect.start], bounds, bindsPath);

      for (int i = sect.start; i <= sect.end; i++) {
        eventTileLayouts[path[i]] = (width: eventWidth, left: eventWidth*i + sectOffset);
      }
    }
  }

  // DONE
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

  // DONE

  /// Once an event has been fixed, [EventTileLayout.left] becomes a right bound 
  /// to events left adjacent to it, as found in [invAdjList], and it's right position 
  /// ([EventTileLayout.left] + [EventTileLayout.width]) becomes a left bound to events right 
  /// adjacent to it, as found in [adjList].
  List<EventTileLayout> fixLayouts(List<List<int>> columns, List<List<int>> adjList, List<List<int>> invAdjList) {
    final List<EventTileLayout> eventTileLayouts = [];
    final List<bool> fixed = List.filled(events.length, false);
    final Bounds bounds = (left: List.filled(events.length, -1), right: List.filled(events.length, -1));
    int numFixed = 0;
    for (int i = 0; i < events.length; i++) {
      eventTileLayouts.add((left: -1.0, width: -1.0));
    }

    while (numFixed < events.length) {
      final BindsPath bindsPath = (left: List.filled(events.length, false), right: List.filled(events.length, false));
      final List<int> path = getLongestPath(columns, adjList, fixed);
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