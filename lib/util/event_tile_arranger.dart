import 'dart:math';

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

List<int> getminWidthInds(List<double> widths, List<bool> fixed) {
  List<int> minWidthInds = [];
  double minWidthUnfixed = double.infinity;
  for (final (i, width) in widths.indexed) {
    if (!fixed[i] && width < minWidthUnfixed) {
      minWidthUnfixed = width;
    }
  }
  for (final (i, width) in widths.indexed) {
    if (width == minWidthUnfixed && !fixed[i]) {
      minWidthInds.add(i);
    }
  }
  return minWidthInds;
}

double getNextSmallestWidth(List<double> widths, List<bool> fixed, int spanStart) {
  double nextSmallestWidth = double.infinity;
  // only have to up to before span since only those before can expand into it
  for (int sectInd = 0; sectInd < spanStart; sectInd++) {
    if (!fixed[sectInd] && widths[sectInd] < nextSmallestWidth) {
      nextSmallestWidth = widths[sectInd];
    }
  }
  return nextSmallestWidth;
}

void increaseSubSpanWidths(List<double> widths, List<bool> fixed, int spanStart, int spanEnd, double widthTotal) {
  int len = spanEnd - spanStart + 1;
  double subNewWidth = widthTotal / len;

  // fix if less than next smallest since we can't expand further and don't want to shrink further 
  // (by loop invariant that it was (non strictly) smallest before)
  double nextSmallestWidth = getNextSmallestWidth(widths, fixed, spanStart);
  for (int sectInd = spanStart; sectInd <= spanEnd; sectInd++) {
    widths[sectInd] = subNewWidth;
  }
  if (subNewWidth <= nextSmallestWidth) {
    for (int sectInd = spanStart; sectInd <= spanEnd; sectInd++) {
      fixed[sectInd] = true;
    }
  }
}

void increaseWidths(List<double> widths, Bounds bounds, List<int> path, List<bool> fixed, int sectStart, int spanStart, int spanEnd) {
  int len = spanEnd - spanStart + 1;
  double widthTotal = widths[spanEnd] * len + widths[spanEnd + 1];
  double newWidth = widthTotal / (len + 1);

  double lb = bounds.left[path[sectStart + spanStart]];
  double left = lb;
  
  for (int i = spanStart; i <= spanEnd; i++) {
    final event = path[sectStart + i];
    // Check if increasing to newWidth would violate right bound.
    if (newWidth >= bounds.right[event] - left) {
      double subWidthTotal = bounds.right[event] - lb;
      increaseSubSpanWidths(widths, fixed, spanStart, spanEnd, subWidthTotal);

      spanStart = i+1;
      widthTotal -= subWidthTotal;
      lb = bounds.right[event];
      left = lb;
      newWidth = widthTotal / ((spanEnd - i + 1));
    } else if (i == spanEnd) {
      for (int sectInd = spanStart; sectInd <= i; sectInd++) {
        widths[sectInd] = newWidth;
      }
    } else {
      left += newWidth;
    }
  }
  widths[spanEnd + 1] = newWidth;
}

void balanceWidths(List<double> widths, Bounds bounds, List<int> path, int sectStart, int sectEnd) {
  int len = sectEnd - sectStart + 1;
  List<bool> fixed = [for (int i = 0; i < len; i++) false];
  List<int> minWidthInds = getminWidthInds(widths, fixed);

  while (minWidthInds.isNotEmpty) {
    int spanStart = -1, spanEnd = -1;
    for (final ind in minWidthInds) {
    if (ind == len - 1 || fixed[ind + 1]) {
        fixed[ind] = true;
        if (spanStart == -1) {
          continue;
        }
        for (int j = spanStart; j <= spanEnd; j++) {
          fixed[j] = true;
        }
        continue;
      }
      if (spanStart == -1) {
        spanStart = ind;
      }
      spanEnd = ind;
      if (minWidthInds.contains(ind + 1)) {
        continue;
      }
      increaseWidths(widths, bounds, path, fixed, sectStart, spanStart, spanEnd);
      spanStart = -1;
    }
    minWidthInds = getminWidthInds(widths, fixed);
  }
}

/// Left bounds are inherited to the right, and right bounds to the left, of adjacent events.
/// This function updates the bounds for events in [path] to reflect this, which is more 
/// efficient than doing so via a dfs for every bound update.
void propagateBounds(Bounds bounds, List<int> path) {
  double lb = bounds.left[path.first], rb = bounds.right[path.last];
  for (final event in path) {
    bounds.left[event] = max(lb, bounds.left[event]);
    lb = bounds.left[event];
  }
  for (final event in path.reversed) {
    bounds.right[event] = min(rb, bounds.right[event]);
    rb = bounds.right[event];
  }
}

void setPositions(List<EventTileData> eventTilesData, Bounds bounds, List<List<int>> adjList, List<List<int>> invAdjList, List<int> path, List<double> widths) {
  double l = bounds.left[path[0]];
  for (final (i, w) in widths.indexed) {
    final event = path[i];
    eventTilesData[event].left = l;
    eventTilesData[event].width = w;
    for (final adj in adjList[event]) {
      bounds.left[adj] = max(bounds.left[adj], w + l);
    }
    for (final adj in invAdjList[event]) {
      bounds.right[adj] = min(bounds.right[adj], l);
    }
    l += w;
  }
}

List<double> initWidths(List<int> path, Bounds bounds, int start, int end) {
  List<double> widths = [];
  int len = end - start + 1;

  for (int i = start; i <= end; i++) {
    final event = path[i];
    if (i - start == len - 1) {
      widths.add(bounds.right[event] - bounds.left[event]);
      break;
    }
    final nextEvent = path[i+1];
    assert(bounds.right[event] >= bounds.left[nextEvent]);
    assert(bounds.left[event] <= bounds.left[nextEvent]);

    final l = bounds.left[event];
    final r = bounds.left[nextEvent];
    final w = r - l;
    widths.add(w);
  }
  return widths;
}
// TODO: need to re pick path after each section fix
/// divide the path into sections of contiguous sequences of events with overlapping bounds
/// widths are initialised such that each event's width is the distance from its left bound
/// to the next event's left bound
/// widths are then balanced by growing the smallest widths to the right, shrinking their larger right neighbours.
List<double> detWidths(List<EventTileData> eventTilesData, List<int> path, List<List<int>> adjList, List<List<int>> invAdjList, Bounds bounds) {
  propagateBounds(bounds, path);
  List<double> pathWidths = [for (int i = 0; i < path.length; i++) -1];
  for (int sectStart = 0, sectEnd = 0; sectEnd < path.length; sectEnd++) {
    if (sectEnd < path.length - 1 && bounds.right[path[sectEnd]] > bounds.left[path[sectEnd + 1]]) continue;
    List<double> sectWidths = initWidths(path, bounds, sectStart, sectEnd);
    balanceWidths(sectWidths, bounds, path, sectStart, sectEnd);

    for (final (i, w) in sectWidths.indexed) {
      pathWidths[sectStart + i] = w;
    }
    sectStart = sectEnd + 1;
  }
  return pathWidths;
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
    List<double> widths = detWidths(eventTilesData, path, adjList, invAdjList, bounds);
    setPositions(eventTilesData, bounds, adjList, invAdjList, path, widths);
    for (final event in path) {
      fixed[event] = true;
    }
    numFixed += path.length;
  }
}
