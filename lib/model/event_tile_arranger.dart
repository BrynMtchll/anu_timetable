import 'dart:math';

import 'package:anu_timetable/model/events.dart';
import 'package:anu_timetable/util/timetable_layout.dart';
import 'package:calendar_view/calendar_view.dart';

typedef Bounds = ({List<double> left, List<double> right});

class EventTileData {
  final Event event;
  late double left;
  late double top;
  late double bottom;
  late double width;
  late double height;

  EventTileData({required this.event}) {
    top = TimetableLayout.vertOffset(event.startTime.getTotalMinutes);
    bottom = TimetableLayout.vertOffset(event.endTime.getTotalMinutes);
    height = bottom - top;
  }

  bool overlapping(EventTileData other) {
    return event.overlapping(other.event);
  }
}
enum BoundType {left, right}
/// a section of a path in the graph derived from the visual ordering of event tiles.
/// 
class Section {
  final int pathStart;
  final int pathEnd;
  bool get canCoalesceLeft => left != null && !left!.fixed && leftBoundType == BoundType.right;
  bool get canCoalesceRight =>  right != null && !right!.fixed && rightBoundType == BoundType.left;
  bool fixed;
  BoundType leftBoundType;
  BoundType rightBoundType;
  late int length;
  late double density;
  final double width;
  double leftPos;
  // null for the first section of a path.
  Section? left;
  // null For the last section of a path.
  Section? right;

  Section({ 
    required this.width,
    required this.leftPos,
    required this.pathStart,
    required this.pathEnd,
    required this.leftBoundType,
    required this.rightBoundType,
    this.left,
    this.right,
    this.fixed = false,
  }) {
    length = pathEnd - pathStart;
    density = length / width;
  }

  /// A section should coalesce left if it can coalesce left but no right, or it can coalesce left 
  /// and right but [left] has a lower density than [right].
  ///
  /// A section [canCoalesceLeft] if:
  ///   1. [left] is not null, i.e. it is not the leftmost section, 
  ///   2. [left] is not already fixed,
  ///   3. the shared bound between it and [left] is a right bound. 
  bool shouldCoalsceLeft() =>
    canCoalesceLeft && (!canCoalesceRight || (canCoalesceRight && left!.density > right!.density));

  /// A section should coalesce right if it can coalesce right but not left, or it can coalesce right 
  /// and left but [right] has a lower density than [left].
  ///
  /// A section [canCoalesceRight] if 
  ///   1. [right] is not null, i.e. it is not the leftmost section, 
  ///   2. [right] is not already fixed, 
  ///   3. the shared bound between it and [right] is a left bound. 
  bool shouldCoalesceRight() =>
    canCoalesceRight && (!canCoalesceLeft || (canCoalesceLeft && right!.density > left!.density));

  static Section coalesce(Section a, Section b) {
    Section newSect = Section(
      width: a.width + b.width, 
      leftPos: a.leftPos,
      pathStart: a.pathStart,
      pathEnd: b.pathEnd,
      leftBoundType: a.leftBoundType,
      rightBoundType: b.rightBoundType,
      left: a.left,
      right: b.right
    );
    a.left?.right = newSect;
    b.right?.left = newSect;

    return newSect;
  }
}

/// Arranges a set of event tiles so that their widths are holistically
/// maximised.
/// Returns a list containing the left offset and width for each event tile
/// (the height and top offset of the tiles are already defined by the event
/// duration and start time).
void arrangeEventTiles(List<EventTileData> eventTilesData, double availableWidth) {
  eventTilesData.sort((a, b) => a.event.startTime.compareTo(b.event.startTime));

  List<List<int>> columns = assignColumns(eventTilesData);
  var (adjList, invAdjList) = buildGraph(eventTilesData, columns);
  fix(eventTilesData.length, availableWidth, columns, adjList, invAdjList);
}

bool boundExists(double bound) => bound >= 0;

/// Finds the first column in the given set of columns that doesn't 
/// contain any events that overlap with the given event. 
/// Returns the index of the found column.
/// 
/// If there is no such column, a new empty column is added and returned. 
int findFirstFreeColumn(List<EventTileData> eventTilesData, List<List<int>> columns, int event) {
  for (int i = 0; i < columns.length; i++) {
    bool spaceAvailable = true;

    for (int other in columns[i]) {
      if (eventTilesData[event].overlapping(eventTilesData[other])) {
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
List<({int count, int event})> countOverlaps(List<EventTileData> eventTilesData) {
  List<({int count, int event})> overlapCounts = [];

  for (int i = 0; i < eventTilesData.length; i++) {
    overlapCounts.add((count: 0, event: i));
  }
  for (int i = 0; i < eventTilesData.length; i++) {
    for (int j = 0; j < i; j++) {
      if (eventTilesData[i].overlapping(eventTilesData[j])) {
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
List<List<int>> assignColumns(List<EventTileData> eventTilesData) {
  List<({int count, int event})> overlapCounts = countOverlaps(eventTilesData);
  List<List<int>> columns = [];
  List<List<int>> rightColumns = [];

  for (int i = 0; i < eventTilesData.length; i++) {
    final event = overlapCounts[i].event;
    final leftCol = findFirstFreeColumn(eventTilesData, columns, event);
    final rightCol = findFirstFreeColumn(eventTilesData, rightColumns, event);
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
List<List<int>> collectLeftOverlaps(List<EventTileData> eventTilesData, List<List<int>> columns) {
  List<List<int>> leftOverlaps = [];
  for (int i = 0; i < eventTilesData.length; i++) {
    leftOverlaps.add([]);
  }
  // Construct leftOverlaps so that the events are sorted in order of column proximity. 
  for (int i = 0; i < columns.length; i++) {
    for (int event in columns[i]) {
      for (int k = 0; k < i; k++) {
        for (int leftEvent in columns[k]) {
          if (eventTilesData[event].overlapping(eventTilesData[leftEvent])) {
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
/// constraints in [fix].
/// 
/// For each event, the events that are to the left and overlapping, as obtained from 
/// [collectLeftOverlaps], are iterated through and connected.
/// 
/// Edges are added between overlapping event pairs in the order of the proximity of their columns,
/// starting with those nearest, in order to minimise duplicate paths.
(List<List<int>> adjList, List<List<int>> invAdjList) buildGraph(List<EventTileData> eventTilesData, List<List<int>> columns) {
  final List<List<int>> adjList = [];
  final List<List<int>> invAdjList = [];
  final List<List<int>> leftOverlaps = collectLeftOverlaps(eventTilesData, columns);
  // List for each event of events connected, i.e. reachable through the graph, to that event.
  final List<List<bool>> connected = [];
  final numEvents = eventTilesData.length;

  for (int i = 0; i < numEvents; i++) {
    adjList.add([]);
    invAdjList.add([]);
    connected.add(List.filled(numEvents, false));
  }
  // For each event, connect each overlapping event on it's left to it.
  for (int i = 1; i < columns.length; i++) {
    for (final event in columns[i]) {
      for (int j = leftOverlaps[event].length - 1; j >= 0; j--) {
        final left = leftOverlaps[event][j];

        if (connected[event][left]) continue;
        connected[event][left] = true;

        // Copy over all that are connected to the left event to the newly connected event.
        for (int i = 0; i < numEvents; i++) {
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
List<int> getLongestPath(int numEvents, List<List<int>> columns, List<List<int>> adjList, List<bool> fixed) {
  List<int> maxLengthFrom = List.filled(numEvents, 1);
  List<bool> visited = List.filled(numEvents, false);
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

Section getHead(Section tail) {
  Section head = tail;
  while (head.left != null) {
    head = head.left!;
  }
  return head;
}

/// Creates the initial sections of the path. This is the first step in
/// fixing the [path].
/// Returns the first [Section] in the created linked list of sections. 
/// 
/// The [path] is divided into [Section]s according to the constraints imposed
/// by already fixed events, given in [bounds]. 
/// 
/// A section is created for every pair of neighbouring bounds. 
/// Sections are contiguous across bounds and non-overlapping.
/// Sections also minimally span 1 node and collectively encompass the whole path.
/// 
/// Both a left and right bound may exist on a single node. 
/// In this case,
///   - The left bound will be the end of the left section
///   - The right bound will be the start of the right a section
///   - A section will be created between those bounds spanning just that node
///
/// EXAMPLE
/// ```
///           L        L R    L        R    R    L 
/// bounds:   |        | |    |        |    |    |    
/// nodes:    01   02   03   04   05   06   07   08
/// sections: |--------|-|----|---------|----|----|
///                A    B   C      D       E    F
/// ```
/// 
/// Initial coalescability:
///   - left bound on right side: __can__ merge right
///   - right bound on right side: __cannot__ merge right
///   - right bound on left side: __can__ merge left
///   - left bound on left side: __cannot__ merge left
Section createSections(List<int> path, Bounds bounds) {
  Section? tail;

  for (int start = 0, end = 0; end < path.length; end++) {
    final startEvent = path[start], endEvent = path[end];
    Section newSect;
    final rightBoundOnLeftSide = bounds.right[startEvent] >= 0;
    final leftBoundOnRightSide = bounds.left[endEvent] >= 0;
    final rightBoundOnRightSide = bounds.right[endEvent] >= 0;

    if (start == end && rightBoundOnLeftSide && leftBoundOnRightSide) {
      newSect = Section(
        width: bounds.right[startEvent] - bounds.left[startEvent], leftPos: bounds.left[startEvent],
        pathStart: start, pathEnd: end,
        leftBoundType: BoundType.left, rightBoundType: BoundType.right, fixed: true);
    }
    else if (start != end && (leftBoundOnRightSide || rightBoundOnRightSide)) {
      final rightBoundType = leftBoundOnRightSide ? BoundType.left : BoundType.right;
      final leftBoundType = rightBoundOnLeftSide ? BoundType.right : BoundType.left;
      final rightPos = leftBoundOnRightSide ? bounds.left[endEvent] : bounds.right[endEvent];
      final leftPos = rightBoundOnLeftSide ? bounds.right[startEvent] : bounds.left[startEvent];
      newSect = Section(
        width: rightPos - leftPos, leftPos: leftPos,
        pathStart: start, pathEnd: end,
        leftBoundType: leftBoundType, rightBoundType: rightBoundType);
      start = end--;
    } else {
      continue;
    }
    tail?.right = newSect;
    newSect.left = tail;
    tail = newSect;
  }
  return getHead(tail!);
}

Section? getHighestDensityUnfixed(Section head) {
  Section? best;
  Section? curr = head;
  while (curr != null) {
    if (!curr.fixed && (best == null || curr.density > best.density)) best = curr;
    curr = curr.right;
  }
  return best;
}

/// Coalesces sections into one another so that [Section.density] is minimised,
/// i.e. available width is optimally distributed between the [path] nodes.
/// Returns the head of the linked list of coalesced sections.
/// 
/// [Section.density] denotes the ratio between the number of nodes and the 
/// available width of the section. 
/// 
/// Until all sections cannot coalesce further, the highest density unfixed section,
/// found by [getHighestDensityUnfixed], is coalesced into one of its neighbours, 
/// depending on which can neighbour can be coalesced into and which has the higher density.
/// If neither side can be coalesced with, then the section is made fixed, i.e. no 
/// longer coalesceable.
/// 
/// Once all sections are fixed, the list of fixed sections are returned. 
Section coalesceSections(Section head, List<int> path) {
  Section? next = getHighestDensityUnfixed(head);
  while (next != null) {
    if (next.canCoalesceLeft && (!next.canCoalesceRight || (next.canCoalesceRight && next.left!.density > next.right!.density))) {
      Section newSect = Section.coalesce(next.left!, next);
      if (newSect.left == null) head = newSect;
    }
    else if (next.canCoalesceRight && (!next.canCoalesceLeft || (next.canCoalesceLeft && next.right!.density > next.left!.density))) {
      Section newSect = Section.coalesce(next, next.right!);
      if (newSect.left == null) head = newSect;
    }
    else if (!next.canCoalesceLeft && !next.canCoalesceRight) {
      next.fixed = true;
    }
    next = getHighestDensityUnfixed(head);
  }
  return head;
}

// DONE
void fixPath(List<EventTileData> eventTilesData, Section head, List<int> path, List<List<int>> adjList, List<List<int>> invAdjList, Bounds bounds) {
  Section? curr = head;

  while (curr != null) {
    final width = curr.width / (curr.length+1);

    for (int i = curr.pathStart; i <= curr.pathEnd; i++) {
      final event = path[i];
      final left = width*i + curr.leftPos;

      eventTilesData[event].left = width*i + curr.leftPos;
      eventTilesData[event].width = width;

      for (final adj in adjList[event]) {
        bounds.left[adj] = width + left;
      }
      for (final adj in invAdjList[event]) {
        bounds.right[adj] = left;
      }
    }
    curr = curr.right;
  }
}

// DONE

/// Once an event has been fixed, [EventTileData.left] becomes a right bound 
/// to events left adjacent to it, as found in [invAdjList], and 
/// ([EventTileData.left] + [EventTileData.width]) becomes a left bound to events right 
/// adjacent to it, as found in [adjList].
List<EventTileData> fix(int numEvents, double availableWidth, List<List<int>> columns, List<List<int>> adjList, List<List<int>> invAdjList) {
  final List<EventTileData> eventTileData = [];
  final List<bool> fixed = List.filled(numEvents, false);
  final Bounds bounds = (left: List.filled(numEvents, -1), right: List.filled(numEvents, -1));
  int numFixed = 0;

  while (numFixed < numEvents) {
    final List<int> path = getLongestPath(numEvents, columns, adjList, fixed);
    if (!boundExists(bounds.left[path.first])) bounds.left[path.first] = max(bounds.left[path.first], 0);
    if (!boundExists(bounds.right[path.last])) bounds.right[path.last] = availableWidth;

    Section head = createSections(path, bounds);
    head = coalesceSections(head, path);
    fixPath(eventTileData, head, path, adjList, invAdjList, bounds);
    for (final event in path) {
      fixed[event] = true;
    }
    numFixed += path.length;
  }
  return eventTileData;
}
