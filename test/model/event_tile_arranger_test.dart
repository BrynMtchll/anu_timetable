import 'package:anu_timetable/util/event_tile_arranger.dart';
import 'package:anu_timetable/domain/model/event.dart';
import 'package:checks/checks.dart';
import 'package:flutter_test/flutter_test.dart';


void main() {

  // helper builders
  EventTileData fullDay() => EventTileData(event: Event(title: "", startTime: DateTime(1, 1, 1, 0), endTime: DateTime(1, 1, 1, 24)));
  EventTileData firstHalf() => EventTileData(event: Event(title: "", startTime: DateTime(1, 1, 1, 0), endTime: DateTime(1, 1, 1, 12)));
  EventTileData secondHalf() => EventTileData(event: Event(title: "", startTime: DateTime(1, 1, 1, 12), endTime: DateTime(1, 1, 1, 24)));
  // small helpers for commonly used event shapes

  group("countOverlaps (existing)", () {
    test("all overlapping", () async {
      final eventTilesData = [fullDay(), fullDay(), fullDay()];
      countOverlaps(eventTilesData);
      for (final eventTileData in eventTilesData) {
        check(eventTileData.overlapCount).equals(eventTilesData.length - 1);
      }
    });

    test("non overlapping", () async {
      final eventTilesData = [firstHalf(), secondHalf()];
      countOverlaps(eventTilesData);
      for (final eventTileData in eventTilesData) {
        check(eventTileData.overlapCount).equals(0);
      }
    });
  });

  group("buildGraph and getLongestPath", () {
    test("adjacency and inverse lists are correct for fully overlapping chain", () {
      final eventTilesData = [fullDay(), fullDay(), fullDay()];
      final columns = [[0], [1], [2]];
      final (adjList, invAdjList) = buildGraph(eventTilesData, columns);

  // Expect edges 0->1 and 1->2 (minimal connections created by algorithm)
      check(adjList.length).equals(3);
      check(adjList[0].contains(1)).isTrue();
  check(adjList[0].contains(2)).isFalse();
  check(adjList[1].contains(2)).isTrue();

  // inverse adjacency (1 has 0 as a parent, 2 has 1 as a parent)
  check(invAdjList[1].contains(0)).isTrue();
  check(invAdjList[2].contains(0)).isFalse();
  check(invAdjList[2].contains(1)).isTrue();
    });

    test("getLongestPath chooses full left-to-right path and respects fixed flags", () {
      final eventTilesData = [fullDay(), fullDay(), fullDay()];
      final columns = [[0], [1], [2]];
      final (adjList, invAdjList) = buildGraph(eventTilesData, columns);

  // all unfixed -> longest path should be 0->1->2
      List<bool> fixed = List.filled(3, false);
      final path = getLongestPath(3, columns, adjList, fixed);
      check(path).deepEquals([0, 1, 2]);

      // mark middle as fixed: now the longest unfixed path starting at 0 should go 0->2
      fixed[1] = true;
  final path2 = getLongestPath(3, columns, adjList, fixed);
  // with the middle node fixed the path cannot continue from 0 to 1, so it remains [0]
  check(path2).deepEquals([0]);
    });
  });

  group("arrangeEventTiles end-to-end", () {
    test("three fully overlapping events split evenly across available width", () {
      final eventTilesData = [fullDay(), fullDay(), fullDay()];
      final availableWidth = 300.0;
      arrangeEventTiles(eventTilesData, availableWidth);

      // Expect three columns => widths roughly 100 each and lefts 0,100,200
      final widths = eventTilesData.map((e) => e.width).toList();
      final lefts = eventTilesData.map((e) => e.left).toList();

      for (final w in widths) {
        expect((w - 100).abs(), lessThan(0.0001));
      }
      // left positions must be within 0..availableWidth-width and unique
      for (int i = 0; i < lefts.length; i++) {
        check(lefts[i] >= 0).isTrue();
        check(lefts[i] + widths[i] <= availableWidth).isTrue();
      }
    });

    test("regression: real-world multi-overlap case (user)", () {
  // events from user logs on 2026-01-07
      final events = [
Event(title: '', startTime: DateTime(2026,01,14,09), endTime: DateTime(2026,01,14,13)),
Event(title: '', startTime: DateTime(2026,01,14,10), endTime: DateTime(2026,01,14,14)),
Event(title: '', startTime: DateTime(2026,01,14,11), endTime: DateTime(2026,01,14,14)),
Event(title: '', startTime: DateTime(2026,01,14,13), endTime: DateTime(2026,01,14,15)),
Event(title: '', startTime: DateTime(2026,01,14,14), endTime: DateTime(2026,01,14,16)),
Event(title: '', startTime: DateTime(2026,01,14,09), endTime: DateTime(2026,01,14,13)),
Event(title: '', startTime: DateTime(2026,01,14,10), endTime: DateTime(2026,01,14,14)),
Event(title: '', startTime: DateTime(2026,01,14,10), endTime: DateTime(2026,01,14,13)),
Event(title: '', startTime: DateTime(2026,01,14,13), endTime: DateTime(2026,01,14,15)),
Event(title: '', startTime: DateTime(2026,01,14,11), endTime: DateTime(2026,01,14,15)),
Event(title: '', startTime: DateTime(2026,01,14,15), endTime: DateTime(2026,01,14,16)),
Event(title: '', startTime: DateTime(2026,01,14,08), endTime: DateTime(2026,01,14,10)),
Event(title: '', startTime: DateTime(2026,01,14,09), endTime: DateTime(2026,01,14,12)),
Event(title: '', startTime: DateTime(2026,01,14,13), endTime: DateTime(2026,01,14,16)),
Event(title: '', startTime: DateTime(2026,01,14,12), endTime: DateTime(2026,01,14,14)),
Event(title: '', startTime: DateTime(2026,01,14,11), endTime: DateTime(2026,01,14,12)),
Event(title: '', startTime: DateTime(2026,01,14,15), endTime: DateTime(2026,01,14,16)),
];

      final eventTilesData = [for (var e in events) EventTileData(event: e)];
      // Use a realistic available width similar to the logs the user pasted
      final availableWidth = 304.0;

      arrangeEventTiles(eventTilesData, availableWidth);

      // Basic invariants: non-negative left, positive width, within availableWidth
      for (int idx = 0; idx < eventTilesData.length; idx++) {
        final etd = eventTilesData[idx];
        expect(etd.width, greaterThan(0));
        expect(etd.left >= 0, isTrue);
        if (!(etd.left + etd.width <= availableWidth + 1e-6)) {
          fail('Event $idx ${etd.event.startTime}..${etd.event.endTime} exceeds available width: left=${etd.left}, width=${etd.width}, sum=${etd.left + etd.width}, available=$availableWidth');
        }
      }

      // Ensure overlapping events do not share the same horizontal interval exactly
      for (int i = 0; i < eventTilesData.length; i++) {
        for (int j = i+1; j < eventTilesData.length; j++) {
          if (eventTilesData[i].overlapping(eventTilesData[j])) {
            // they should not occupy identical horizontal spans
            final sameSpan = (eventTilesData[i].left == eventTilesData[j].left) && (eventTilesData[i].width == eventTilesData[j].width);
            final a = eventTilesData[i], b = eventTilesData[j];
            final reason = 'Overlapping events $i (${a.event.startTime.hour}:${a.event.endTime.hour}) and $j (${b.event.startTime.hour}:${b.event.endTime.hour}) share identical span: left=${a.left}, width=${a.width} vs left=${b.left}, width=${b.width}';
            expect(sameSpan, isFalse, reason: reason);
          }
        }
      }
    });
  });
}