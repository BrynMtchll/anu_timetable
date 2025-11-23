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


  // group("fixPath behaviour", () {
  //   test("allocates widths and updates bounds for simple section", () {
  // final e0 = EventTileData(event: Event(title: '', startTime: DateTime(1,1,1,0), endTime: DateTime(1,1,1,1)));
  // final e1 = EventTileData(event: Event(title: '', startTime: DateTime(1,1,1,1), endTime: DateTime(1,1,1,2)));
  //     final eventTilesData = [e0, e1];

  //     final head = Section(width: 200, leftPos: 0, pathStart: 0, pathEnd: 1, leftBoundType: BoundType.left, rightBoundType: BoundType.right);
  //     final adjList = [<int>[], <int>[]];
  //     final invAdjList = [<int>[], <int>[]];
  //     final bounds = (left: List.filled(2, -1.0), right: List.filled(2, -1.0));

  //     // fixPath(eventTilesData, head, [0,1], adjList, invAdjList, bounds);

  //     // width per node = head.width / (length+1) => 200/(1+1)=100
  //     check(eventTilesData[0].width).equals(100);
  //     check(eventTilesData[0].left).equals(0);
  //     check(eventTilesData[1].width).equals(100);
  //     check(eventTilesData[1].left).equals(100);
  //   });
  // });

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


// Event(title: '', startTime: DateTime(2025,12,18,12), endTime: DateTime(2025,12,18,13)),
// Event(title: '', startTime: DateTime(2025,12,18,08), endTime: DateTime(2025,12,18,12)),
// Event(title: '', startTime: DateTime(2025,12,18,08), endTime: DateTime(2025,12,18,09)),
// Event(title: '', startTime: DateTime(2025,12,18,09), endTime: DateTime(2025,12,18,12)),
// Event(title: '', startTime: DateTime(2025,12,18,08), endTime: DateTime(2025,12,18,09)),
// Event(title: '', startTime: DateTime(2025,12,18,09), endTime: DateTime(2025,12,18,11)),
// Event(title: '', startTime: DateTime(2025,12,18,14), endTime: DateTime(2025,12,18,17)),
// Event(title: '', startTime: DateTime(2025,12,18,10), endTime: DateTime(2025,12,18,13)),
// Event(title: '', startTime: DateTime(2025,12,18,13), endTime: DateTime(2025,12,18,14)),
// Event(title: '', startTime: DateTime(2025,12,18,12), endTime: DateTime(2025,12,18,13)),
// Event(title: '', startTime: DateTime(2025,12,18,15), endTime: DateTime(2025,12,18,16)),
// Event(title: '', startTime: DateTime(2025,12,18,11), endTime: DateTime(2025,12,18,13)),
// Event(title: '', startTime: DateTime(2025,12,18,10), endTime: DateTime(2025,12,18,13)),
// Event(title: '', startTime: DateTime(2025,12,18,15), endTime: DateTime(2025,12,18,19)),
// Event(title: '', startTime: DateTime(2025,12,18,10), endTime: DateTime(2025,12,18,13)),
// Event(title: '', startTime: DateTime(2025,12,18,13), endTime: DateTime(2025,12,18,15)),
// Event(title: '', startTime: DateTime(2025,12,18,13), endTime: DateTime(2025,12,18,17)),
// Event(title: '', startTime: DateTime(2025,12,18,11), endTime: DateTime(2025,12,18,13)),
// Event(title: '', startTime: DateTime(2025,12,18,08), endTime: DateTime(2025,12,18,09)),
// Event(title: '', startTime: DateTime(2025,12,18,14), endTime: DateTime(2025,12,18,18)),
// Event(title: '', startTime: DateTime(2025,12,18,14), endTime: DateTime(2025,12,18,15)),
// Event(title: '', startTime: DateTime(2025,12,18,14), endTime: DateTime(2025,12,18,18)),

  
// Event(title: '', startTime: DateTime(2025,12,19,13), endTime: DateTime(2025,12,19,15)),
// Event(title: '', startTime: DateTime(2025,12,19,12), endTime: DateTime(2025,12,19,14)),
// Event(title: '', startTime: DateTime(2025,12,19,08), endTime: DateTime(2025,12,19,11)),
// Event(title: '', startTime: DateTime(2025,12,19,13), endTime: DateTime(2025,12,19,17)),
// Event(title: '', startTime: DateTime(2025,12,19,15), endTime: DateTime(2025,12,19,17)),
// Event(title: '', startTime: DateTime(2025,12,19,11), endTime: DateTime(2025,12,19,15)),
// Event(title: '', startTime: DateTime(2025,12,19,10), endTime: DateTime(2025,12,19,13)),
// Event(title: '', startTime: DateTime(2025,12,19,15), endTime: DateTime(2025,12,19,17)),
// Event(title: '', startTime: DateTime(2025,12,19,14), endTime: DateTime(2025,12,19,15)),
// Event(title: '', startTime: DateTime(2025,12,19,11), endTime: DateTime(2025,12,19,15)),
// Event(title: '', startTime: DateTime(2025,12,19,09), endTime: DateTime(2025,12,19,11)),
// Event(title: '', startTime: DateTime(2025,12,19,12), endTime: DateTime(2025,12,19,14)),
// Event(title: '', startTime: DateTime(2025,12,19,09), endTime: DateTime(2025,12,19,12)),
// Event(title: '', startTime: DateTime(2025,12,19,12), endTime: DateTime(2025,12,19,15)),
// Event(title: '', startTime: DateTime(2025,12,19,09), endTime: DateTime(2025,12,19,12)),
// Event(title: '', startTime: DateTime(2025,12,19,11), endTime: DateTime(2025,12,19,13)),
// Event(title: '', startTime: DateTime(2025,12,19,13), endTime: DateTime(2025,12,19,16)),
// Event(title: '', startTime: DateTime(2025,12,19,14), endTime: DateTime(2025,12,19,18)),
// Event(title: '', startTime: DateTime(2025,12,19,08), endTime: DateTime(2025,12,19,12)),
// Event(title: '', startTime: DateTime(2025,12,19,12), endTime: DateTime(2025,12,19,16)),

// Event(title: '', startTime: DateTime(2025,12,03,08), endTime: DateTime(2025,12,03,11)),
// Event(title: '', startTime: DateTime(2025,12,03,12), endTime: DateTime(2025,12,03,13)),
// Event(title: '', startTime: DateTime(2025,12,03,13), endTime: DateTime(2025,12,03,15)),
// Event(title: '', startTime: DateTime(2025,12,03,11), endTime: DateTime(2025,12,03,15)),
// Event(title: '', startTime: DateTime(2025,12,03,08), endTime: DateTime(2025,12,03,12)),
// Event(title: '', startTime: DateTime(2025,12,03,14), endTime: DateTime(2025,12,03,16)),
// Event(title: '', startTime: DateTime(2025,12,03,15), endTime: DateTime(2025,12,03,16)),
// Event(title: '', startTime: DateTime(2025,12,03,10), endTime: DateTime(2025,12,03,13)),
// Event(title: '', startTime: DateTime(2025,12,03,12), endTime: DateTime(2025,12,03,14)),
// Event(title: '', startTime: DateTime(2025,12,03,15), endTime: DateTime(2025,12,03,19)),
// Event(title: '', startTime: DateTime(2025,12,03,10), endTime: DateTime(2025,12,03,14)),
// Event(title: '', startTime: DateTime(2025,12,03,15), endTime: DateTime(2025,12,03,18)),


// Event(title: '', startTime: DateTime(2025,12,09,09), endTime: DateTime(2025,12,09,10)),
// Event(title: '', startTime: DateTime(2025,12,09,09), endTime: DateTime(2025,12,09,13)),
// Event(title: '', startTime: DateTime(2025,12,09,13), endTime: DateTime(2025,12,09,14)),
// Event(title: '', startTime: DateTime(2025,12,09,08), endTime: DateTime(2025,12,09,11)),
// Event(title: '', startTime: DateTime(2025,12,09,12), endTime: DateTime(2025,12,09,16)),
// Event(title: '', startTime: DateTime(2025,12,09,10), endTime: DateTime(2025,12,09,11)),
// Event(title: '', startTime: DateTime(2025,12,09,15), endTime: DateTime(2025,12,09,19)),
// Event(title: '', startTime: DateTime(2025,12,09,08), endTime: DateTime(2025,12,09,10)),
// Event(title: '', startTime: DateTime(2025,12,09,13), endTime: DateTime(2025,12,09,15)),
// Event(title: '', startTime: DateTime(2025,12,09,15), endTime: DateTime(2025,12,09,17)),
// Event(title: '', startTime: DateTime(2025,12,09,08), endTime: DateTime(2025,12,09,09)),
// Event(title: '', startTime: DateTime(2025,12,09,08), endTime: DateTime(2025,12,09,12)),
// Event(title: '', startTime: DateTime(2025,12,09,13), endTime: DateTime(2025,12,09,16)),
// Event(title: '', startTime: DateTime(2025,12,09,10), endTime: DateTime(2025,12,09,13)),
// Event(title: '', startTime: DateTime(2025,12,09,12), endTime: DateTime(2025,12,09,16)),
// Event(title: '', startTime: DateTime(2025,12,09,15), endTime: DateTime(2025,12,09,18)),
// Event(title: '', startTime: DateTime(2025,12,09,13), endTime: DateTime(2025,12,09,15)),
// Event(title: '', startTime: DateTime(2025,12,09,12), endTime: DateTime(2025,12,09,15)),
// Event(title: '', startTime: DateTime(2025,12,09,10), endTime: DateTime(2025,12,09,14)),
// Event(title: '', startTime: DateTime(2025,12,09,15), endTime: DateTime(2025,12,09,17)),
// Event(title: '', startTime: DateTime(2025,12,09,10), endTime: DateTime(2025,12,09,11)),
// Event(title: '', startTime: DateTime(2025,12,09,10), endTime: DateTime(2025,12,09,14)),



// Event(title: '', startTime: DateTime(2026,01,14,09), endTime: DateTime(2026,01,14,13)),
// Event(title: '', startTime: DateTime(2026,01,14,10), endTime: DateTime(2026,01,14,14)),
// Event(title: '', startTime: DateTime(2026,01,14,11), endTime: DateTime(2026,01,14,14)),
// Event(title: '', startTime: DateTime(2026,01,14,13), endTime: DateTime(2026,01,14,15)),
// Event(title: '', startTime: DateTime(2026,01,14,14), endTime: DateTime(2026,01,14,16)),
// Event(title: '', startTime: DateTime(2026,01,14,09), endTime: DateTime(2026,01,14,13)),
// Event(title: '', startTime: DateTime(2026,01,14,10), endTime: DateTime(2026,01,14,14)),
// Event(title: '', startTime: DateTime(2026,01,14,10), endTime: DateTime(2026,01,14,13)),
// Event(title: '', startTime: DateTime(2026,01,14,13), endTime: DateTime(2026,01,14,15)),
// Event(title: '', startTime: DateTime(2026,01,14,11), endTime: DateTime(2026,01,14,15)),
// Event(title: '', startTime: DateTime(2026,01,14,15), endTime: DateTime(2026,01,14,16)),
// Event(title: '', startTime: DateTime(2026,01,14,08), endTime: DateTime(2026,01,14,10)),
// Event(title: '', startTime: DateTime(2026,01,14,09), endTime: DateTime(2026,01,14,12)),
// Event(title: '', startTime: DateTime(2026,01,14,13), endTime: DateTime(2026,01,14,16)),
// Event(title: '', startTime: DateTime(2026,01,14,12), endTime: DateTime(2026,01,14,14)),
// Event(title: '', startTime: DateTime(2026,01,14,11), endTime: DateTime(2026,01,14,12)),
// Event(title: '', startTime: DateTime(2026,01,14,15), endTime: DateTime(2026,01,14,16)),
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
// flutter: 986.0 1054.0
// flutter: 68.0 76.0
// flutter: 0.0
// flutter: 1054.0 1190.0
// flutter: 136.0 38.0
// flutter: 0.0
// flutter: 714.0 986.0
// flutter: 272.0 76.0
// flutter: 0.0
// flutter: 714.0 782.0
// flutter: 68.0 76.0
// flutter: 304.0
// flutter: 714.0 782.0
// flutter: 68.0 76.0
// flutter: 76.0
// flutter: 1054.0 1190.0
// flutter: 136.0 38.0
// flutter: 38.0
// flutter: 646.0 782.0
// flutter: 136.0 76.0
// flutter: 228.0
// flutter: 646.0 782.0
// flutter: 136.0 76.0
// flutter: 152.0
// flutter: 918.0 1122.0
// flutter: 204.0 304.0
// flutter: 76.0
    // test("debug: trace internal fix steps for regression case", () {
    //   final events = [
    //     Event(title: '', startTime: DateTime(2026,1,7,11), endTime: DateTime(2026,1,7,15)),
    //     Event(title: '', startTime: DateTime(2026,1,7,12), endTime: DateTime(2026,1,7,16)),
    //     Event(title: '', startTime: DateTime(2026,1,7,13), endTime: DateTime(2026,1,7,17)),
    //     Event(title: '', startTime: DateTime(2026,1,7,10), endTime: DateTime(2026,1,7,14)),
    //     Event(title: '', startTime: DateTime(2026,1,7,14), endTime: DateTime(2026,1,7,18)),
    //     Event(title: '', startTime: DateTime(2026,1,7,10), endTime: DateTime(2026,1,7,13)),
    //     Event(title: '', startTime: DateTime(2026,1,7,14), endTime: DateTime(2026,1,7,15)),
    //   ];
    //   final eventTilesData = [for (var e in events) EventTileData(event: e)];
    //   final availableWidth = 304.0;

    //   final columns = assignColumns(eventTilesData);
    //   final (adjList, invAdjList) = buildGraph(eventTilesData, columns);

    //   final numEvents = eventTilesData.length;
    //   final fixed = List.filled(numEvents, false);
    //   final bounds = (left: List.filled(numEvents, -1.0), right: List.filled(numEvents, -1.0));

    //   final path = getLongestPath(numEvents, columns, adjList, fixed);
    //   print('DEBUG path: $path');

    //   if (bounds.left[path.first] == -1) bounds.left[path.first] = 0;
    //   if (bounds.right[path.last] == -1) bounds.right[path.last] = availableWidth;

    //   final head = createSections(path, bounds);
    //   // Walk sections and print
    //   Section? curr = head;
    //   while (curr != null) {
    //     print('DEBUG section start=${curr.pathStart} end=${curr.pathEnd} leftPos=${curr.leftPos} width=${curr.width} fixed=${curr.fixed} density=${curr.density}');
    //     curr = curr.right;
    //   }

    //   coalesceSections(head, path);
    //   // after coalesce
    //   curr = getHead(head);
    //   print('DEBUG after coalesce:');
    //   while (curr != null) {
    //     print('DEBUG section start=${curr.pathStart} end=${curr.pathEnd} leftPos=${curr.leftPos} width=${curr.width} fixed=${curr.fixed} density=${curr.density}');
    //     curr = curr.right;
    //   }

    //   fixPath(eventTilesData, head, path, adjList, invAdjList, bounds);

    //   print('DEBUG bounds left: ${bounds.left}');
    //   print('DEBUG bounds right: ${bounds.right}');
    //   for (int i = 0; i < eventTilesData.length; i++) {
    //     final e = eventTilesData[i];
    //     print('DEBUG event $i ${e.event.startTime.hour}-${e.event.endTime.hour}:');
    //     if (e.event.endTime.hour == 13) {
    //       print(e.width);
    //     }
    //   }
    // });

// edge case: left bound and right bound on event, neighbouring event adj bound overlap;
//  left bound on right side less than right bound on left side.
//  neither can coalesce toward each other. They should be swapped. 
// i.e. bounds should be sorted ??

//     Event(title: '', startTime: DateTime(2025,10,16,09),endTime: DateTime(2025,10,16,13),),
// Event(title: '', startTime: DateTime(2025,10,16,10),endTime: DateTime(2025,10,16,12),),
// Event(title: '', startTime: DateTime(2025,10,16,15),endTime: DateTime(2025,10,16,18),),
// Event(title: '', startTime: DateTime(2025,10,16,15),endTime: DateTime(2025,10,16,18),),
// Event(title: '', startTime: DateTime(2025,10,16,14),endTime: DateTime(2025,10,16,15),),

// Event(title: '', startTime: DateTime(2026,01,14,10), endTime: DateTime(2026,01,14,13)),
// Event(title: '', startTime: DateTime(2026,01,14,08), endTime: DateTime(2026,01,14,10)),
// Event(title: '', startTime: DateTime(2026,01,14,12), endTime: DateTime(2026,01,14,16)),
// Event(title: '', startTime: DateTime(2026,01,14,14), endTime: DateTime(2026,01,14,17)),
// Event(title: '', startTime: DateTime(2026,01,14,08), endTime: DateTime(2026,01,14,10)),
// Event(title: '', startTime: DateTime(2026,01,14,15), endTime: DateTime(2026,01,14,17)),
// Event(title: '', startTime: DateTime(2026,01,14,15), endTime: DateTime(2026,01,14,19)),
// Event(title: '', startTime: DateTime(2026,01,14,12), endTime: DateTime(2026,01,14,15)),
// Event(title: '', startTime: DateTime(2026,01,14,09), endTime: DateTime(2026,01,14,12)),

        // Event(title: '', startTime: DateTime(2025,11,29,14), endTime: DateTime(2025,11,29,15)),
        // Event(title: '', startTime: DateTime(2025,11,29,15), endTime: DateTime(2025,11,29,17)),
        // Event(title: '', startTime: DateTime(2025,11,29,10), endTime: DateTime(2025,11,29,14)),
        // Event(title: '', startTime: DateTime(2025,11,29,10), endTime: DateTime(2025,11,29,11)),
        // Event(title: '', startTime: DateTime(2025,11,29,10), endTime: DateTime(2025,11,29,11)),
        // Event(title: '', startTime: DateTime(2025,11,29,15), endTime: DateTime(2025,11,29,17)),
        // Event(title: '', startTime: DateTime(2025,11,29,09), endTime: DateTime(2025,11,29,11)),
        // Event(title: '', startTime: DateTime(2025,11,29,09), endTime: DateTime(2025,11,29,11)),
        // Event(title: '', startTime: DateTime(2025,11,29,13), endTime: DateTime(2025,11,29,16)),
//     test("debug-full: simulate fix loop and print per-iteration state", () {
//       final events = [
//     Event(title: '', startTime: DateTime(2026,01,14,10), endTime: DateTime(2026,01,14,13)),
// Event(title: '', startTime: DateTime(2026,01,14,08), endTime: DateTime(2026,01,14,10)),
// Event(title: '', startTime: DateTime(2026,01,14,12), endTime: DateTime(2026,01,14,16)),
// Event(title: '', startTime: DateTime(2026,01,14,14), endTime: DateTime(2026,01,14,17)),
// Event(title: '', startTime: DateTime(2026,01,14,08), endTime: DateTime(2026,01,14,10)),
// Event(title: '', startTime: DateTime(2026,01,14,15), endTime: DateTime(2026,01,14,17)),
// Event(title: '', startTime: DateTime(2026,01,14,15), endTime: DateTime(2026,01,14,19)),
// Event(title: '', startTime: DateTime(2026,01,14,12), endTime: DateTime(2026,01,14,15)),
// Event(title: '', startTime: DateTime(2026,01,14,09), endTime: DateTime(2026,01,14,12)),
//       ];
//       final eventTilesData = [for (var e in events) EventTileData(event: e)];
//       final availableWidth = 304.0;

//       final columns = assignColumns(eventTilesData);
//       final (adjList, invAdjList) = buildGraph(eventTilesData, columns);

//       final numEvents = eventTilesData.length;
//       final fixed = List.filled(numEvents, false);
//       final bounds = (left: List.filled(numEvents, -1.0), right: List.filled(numEvents, -1.0));
//       int numFixed = 0;

//       while (numFixed < numEvents) {
//         final path = getLongestPath(numEvents, columns, adjList, fixed);
//         print('ITER path: $path');

//         if (bounds.left[path.first] == -1) bounds.left[path.first] = 0;
//         if (bounds.right[path.last] == -1) bounds.right[path.last] = availableWidth;
        
//         final head = createSections(path, bounds);
//         print('  sections before coalesce:');
//         Section? c = head;
//         while (c != null) {
//           print('    s ${c.pathStart}-${c.pathEnd} left=${c.leftPos} width=${c.width} fixed=${c.fixed}');
//           c = c.right;
//         }

//         coalesceSections(head, path);
//         print('  sections after coalesce:');
        
//         c = head;
//         print("${head.pathStart} ${head.pathEnd}");
//         while (c != null) {
//           print('    s ${c.pathStart}-${c.pathEnd} left=${c.leftPos} width=${c.width} fixed=${c.fixed}');
//           c = c.right;
//         }

//         print('  bounds left: ${bounds.left}');
//         print('  bounds right: ${bounds.right}');

//         fixPath(eventTilesData, head, path, adjList, invAdjList, bounds);

//         print('  bounds left: ${bounds.left}');
//         print('  bounds right: ${bounds.right}');

//         for (final event in path) {
//           fixed[event] = true;
//         }
//         numFixed += path.length;
//       }

//       for (int i = 0; i < eventTilesData.length; i++) {
//         final e = eventTilesData[i];
//         print('FINAL event $i ${e.event.startTime.hour}-${e.event.endTime.hour}: left=${e.left}, width=${e.width}, sum=${e.left + e.width}');
//         expect(e.left + e.width <= 304.0 + 1e-6, isTrue, reason: 'Event $i exceeds available width');
//       }
//     });
  });
}