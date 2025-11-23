import 'dart:math';
import 'dart:math' as math;

import 'package:anu_timetable/domain/model/event.dart';
import 'package:anu_timetable/util/timetable_layout.dart';
import 'package:calendar_view/calendar_view.dart';

typedef Bounds = ({List<double> left, List<double> right});
enum BoundType {left, right}

class EventTileData {
  final Event event;
  late double left;
  late double top;
  late double bottom;
  late double width;
  late double height;
  late int overlapCount = 0;

  EventTileData({required this.event}) {
    top = TimetableLayout.vertOffset(event.startTime.getTotalMinutes);
    bottom = TimetableLayout.vertOffset(event.endTime.getTotalMinutes);
    height = bottom - top;
  }

  bool overlapping(EventTileData other) {
    return event.overlapping(other.event);
  }
}

class Section {
  final int pathStart;
  final int pathEnd;
  /// A section [canCoalesceLeft] if:
  ///   1. [left] is not null, i.e. it is not the leftmost section, 
  ///   2. [left] is not fixed,
  ///   3. the shared bound between it and [left] is a right bound. 
  bool get canCoalesceLeft => left != null && !left!.fixed && leftBoundType == BoundType.right;
  /// A section [canCoalesceRight] if 
  ///   1. [right] is not null, i.e. it is not the leftmost section, 
  ///   2. [right] is not fixed, 
  ///   3. the shared bound between it and [right] is a left bound. 
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
  // null for the last section of a path.
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
}

/// Arranges a set of event tiles so that their widths are holistically
/// maximised.
/// Returns a list containing the left offset and width for each event tile
/// (the height and top offset of the tiles are already defined by the event
/// duration and start time).
/// 
/// The constraints an event has on the arrangement is proportional to the 
/// number of overlaps an event has and how centrally it is placed.
/// So, events with the most overlaps are assigned to the outermost columns.
void arrangeEventTiles(List<EventTileData> eventTilesData, double availableWidth) {
  List<List<int>> columns = assignColumns(eventTilesData);
  var (adjList, invAdjList) = buildGraph(eventTilesData, columns);
  fix(eventTilesData, availableWidth, columns, adjList, invAdjList);
}

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
  return columns.length;
}

/// Counts the number of events that overlap with each.
/// Returns a sorted list of pairs of the event and the count for that 
/// event.
void countOverlaps(List<EventTileData> eventTilesData) {
  for (int i = 0; i < eventTilesData.length; i++) {
    for (int j = 0; j < i; j++) {
      if (eventTilesData[i].overlapping(eventTilesData[j])) {
        eventTilesData[i].overlapCount++;
        eventTilesData[j].overlapCount++;
      }
    }
  }
}

/// Assigns events to columns, which denote their relative position to other events,
/// given the list [eventTilesData] sorted in descending order of [EventTileData.overlapCount].
/// Returns a list of the columns.
/// 
/// In descending order of the overlap count, each event is assigned to the outermost column 
/// on either the left or right side that doesn't contain any overlapping
/// events, found using [findFirstFreeColumn]. If none is found, a new innermost column
/// is added. 
/// 
/// The left and right column groups are maintained seperately so that they can be 
/// efficiently grown. They are joined once all events have been added.
List<List<int>> assignColumns(List<EventTileData> eventTilesData) {
  List<List<int>> columns = [];
  List<List<int>> rightColumns = [];

  countOverlaps(eventTilesData);
  final overlapCountOrder = [for (var i = 0; i < eventTilesData.length; i++) i];
  overlapCountOrder.sort((a, b) => 
    eventTilesData[b].overlapCount.compareTo(eventTilesData[a].overlapCount));

  for (final event in overlapCountOrder) {
    final leftCol = findFirstFreeColumn(eventTilesData, columns, event);
    final rightCol = findFirstFreeColumn(eventTilesData, rightColumns, event);
    if (leftCol <= rightCol) {
      if (leftCol == columns.length) columns.add([]);
      columns[leftCol].add(event);
    } else {
      if (rightCol == rightColumns.length) rightColumns.add([]);
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
List<int> getLongestPath(int numEvents, List<List<int>> columns, List<List<int>> adjList, List<bool> fixed, Bounds bounds) {
  List<int> maxLengthFrom = List.filled(numEvents, 1);
  List<bool> visited = List.filled(numEvents, false);
  ({int length, int root}) longest = (length: 0, root: -1);

  // Consider all unfixed roots.
  // By starting the scan from the leftmost column it's maintained that
  // if an event has not been visited then it is a root. 
  for (final column in columns) {
    for (final root in column) {
      // This is also checked in findMaxLengthFrom but checking here saves possibly redundant steps.
      if (visited[root]) continue;
      final maxLengthFromEvent = findMaxLengthFrom(root, adjList, maxLengthFrom, visited, fixed);
      if (maxLengthFromEvent >= longest.length) {
        print("left bound: ${bounds.left[root]}, right bound: ${bounds.right[root]}");
        print(root);
        if (longest.root == -1 || bounds.left[root] > bounds.left[longest.root]) {
          longest = (length: maxLengthFromEvent, root: root);
        }
      }
    }
  }
  List<int> path = [];
  traceLongestPath(longest.root, adjList, maxLengthFrom, path);
  return path;
}

List<double> func(List<EventTileData> eventTilesData, List<int> path, List<List<int>> adjList, List<List<int>> invAdjList, Bounds bounds) {
  print("PATH: $path");

  double lb = bounds.left[path.first], rb = bounds.right[path.last];

  List<double> widthsFinal = [for (int i = 0; i < path.length; i++) -1];

  for (final event in path) {
    bounds.left[event] = max(lb, bounds.left[event]);
    lb = bounds.left[event];
  }

  for (final event in path.reversed) {
    bounds.right[event] = min(rb, bounds.right[event]);
    rb = bounds.right[event];
  }

  for (int start = 0, end = 0; end < path.length; end++) {
    if (end < path.length - 1 && bounds.right[path[end]] > bounds.left[path[end + 1]]) continue;
    List<double> widths = [];
    List<int> smallestWidthInds = [];
    int len = end - start + 1;
    List<bool> fixed = [for (int i = 0; i < len; i++) false];
    for (int i = start; i <= end; i++) {
      final event = path[i];
      if (i - start == len - 1) {
        widths.add(bounds.right[event] - bounds.left[event]);
        break;
      }
      final nextEvent = path[i+1];
      assert(bounds.right[event] >= bounds.left[nextEvent]);
      assert(bounds.left[event] <= bounds.left[nextEvent]);

      final left = bounds.left[event];
      final right = bounds.left[nextEvent];
      final width = right - left;
      widths.add(width);
    }
    double smallestWidth = widths.reduce(math.min);
    for (int relInd = 0; relInd < widths.length; relInd++) {
      final width = widths[relInd];
      if (width == smallestWidth && !fixed[relInd]) {
        smallestWidthInds.add(relInd);
      }
    }

    while (smallestWidthInds.isEmpty == false) {
      List<int> consecs = [];
      for (final relInd in smallestWidthInds) {
        if (relInd == len - 1 || fixed[relInd + 1]) {
          print("fixing $relInd");
          fixed[relInd] = true;
          for (final prevRelInd in consecs) {
            print("fixing prev $prevRelInd");

            fixed[prevRelInd] = true;
          }
          consecs.clear();
          continue;
        }
        consecs.add(relInd);
        if (smallestWidthInds.contains(relInd + 1)) {
          continue;
        }
        // want to up the min width
        double widthTotal = widths[relInd] * consecs.length + widths[relInd + 1];
        

        double newWidth = widthTotal / (consecs.length + 1);
        int nTotal = consecs.length + 1;

        double left = bounds.left[path[start + consecs.first]];
        double lb = bounds.left[path[start + consecs.first]];
        int leftCInd = 0;
        // widthTotal += min(widths[relInd + 1], bounds.right[path[start + relInd]] - left);
        print("width total: $widthTotal, ${widths[relInd + 1]}");
        print("consecs: $consecs");
        for (int j = 0; j < consecs.length; j++) {
          final prevRelInd = consecs[j];
          final prevInd = start + prevRelInd;
          final prevEvent = path[prevInd];
          if (newWidth >= bounds.right[prevEvent] - left) {
            // cannot increase width
            // print("setting width to max from ${widths[prevRelInd]} to ${bounds.right[prevEvent] - left} instead of $newWidth");
            // nTotal -= 1;
            // newWidth = widthTotal / nTotal;
            print(j - leftCInd + 1);
            print(bounds.right[prevEvent] - lb);
            double w = (bounds.right[prevEvent] - lb) / (j - leftCInd + 1);
            for (int k = leftCInd; k <= j; k++) {
              final relInd2 = consecs[k];
              print("setting width to max from ${widths[relInd2]} to $w instead of $newWidth");
              widths[relInd2] = w;
              fixed[relInd2] = true;
            }

            leftCInd = j+1;
            widthTotal -= (bounds.right[prevEvent] - lb);
            lb = bounds.right[prevEvent];
            newWidth = widthTotal / (consecs.length - j);

          } else if (j == consecs.length - 1) {
            for (int k = leftCInd; k <= j; k++) {
              final relInd2 = consecs[k];
              print("setting width from ${widths[relInd2]} to $newWidth of $relInd2");
              widths[relInd2] = newWidth;
            }
          }
          left += newWidth;
        }
        print("hi");
        consecs.clear();
        widths[relInd + 1] = newWidth;
      }
      smallestWidthInds.clear();
      double smallestWidthUnfixed = double.infinity;
      for (int relInd = 0; relInd < widths.length; relInd++) {
        final width = widths[relInd];
        if (!fixed[relInd] && width < smallestWidthUnfixed) {
          smallestWidthUnfixed = width;
        }
      }
      print("smallest unfixed: $smallestWidthUnfixed");
      for (int relInd = 0; relInd < widths.length; relInd++) {
        final width = widths[relInd];
        if (width == smallestWidthUnfixed && !fixed[relInd]) {
          smallestWidthInds.add(relInd);
        }
      }
    }

    // for(final width in widths) {
    //   print(width);
    // }

    double left = bounds.left[path[start]];

    for (int relInd = 0; relInd < widths.length; relInd++) {
      final width = widths[relInd];
      final ind = start + relInd;
      widthsFinal[ind] = width;
      print("${path[ind]}: $left, $width");
      final event = path[ind];

      eventTilesData[event].left = left;
      eventTilesData[event].width = width;
      
      for (final adj in adjList[event]) {
        bounds.left[adj] = max(bounds.left[adj], width + left);
      }
      for (final adj in invAdjList[event]) {
        bounds.right[adj] = min(bounds.right[adj], left);
      }

      left += width;
    }
    start = end + 1;
  }
  return widthsFinal;
}

/// Once an event has been fixed, [EventTileData.left] becomes a right bound 
/// to events left adjacent to it, as found in [invAdjList], and 
/// ([EventTileData.left] + [EventTileData.width]) becomes a left bound to events right 
/// adjacent to it, as found in [adjList].
void fix(List<EventTileData> eventTilesData, double availableWidth, List<List<int>> columns, List<List<int>> adjList, List<List<int>> invAdjList) {
  final numEvents = eventTilesData.length;
  final List<bool> fixed = List.filled(numEvents, false);
  final Bounds bounds = (left: List.filled(numEvents, 0), right: List.filled(numEvents, availableWidth));
  int numFixed = 0;

  while (numFixed < numEvents) {
    final List<int> path = getLongestPath(numEvents, columns, adjList, fixed, bounds);
    
    
    List<double> widths = func(eventTilesData, path, adjList, invAdjList, bounds);

    // Section head = createSections(path, bounds);
    // head = coalesceSections(head, path);

    // List<Section> sections = [];
    // for (Section? curr = head; curr != null; curr = curr.right) {
    //   sections.add(curr);
    // }


    // fixPath(eventTilesData, widths, path, adjList, invAdjList, bounds);
    for (final event in path) {
      fixed[event] = true;
    }
    numFixed += path.length;
  }
}
