import 'dart:ui';

import 'package:anu_timetable/model/event_tile_arranger.dart';
import 'package:anu_timetable/model/events.dart';
import 'package:anu_timetable/util/timetable_layout.dart';
import 'package:checks/checks.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {

  // arrangeEvenTiles
  //  assignColumns
  //    countOverlaps
  //    findFirstFreeColumn
  //  buildGraph
  //    collectLeftOverlaps
  //  fix
  //    getLongestPath
  //      findMaxLengthFrom
  //      traceLongestPath
  //    createSections
  //      getHead
  //    coalesceSections
  //      getHighestDensityUnfixed
  //      coalesce
  //    fixPath


  // densly connected - all overlapping
  // adjacent but not overlapping
  // overlapping with 2 that don't overlap with each other

  List<EventTileData> threeNonOverlappingEvents() {
    Event e1 = Event(title: "", startTime: DateTime(1, 1, 1, 0), endTime: DateTime(1, 1, 1, 1));
    Event e2 = Event(title: "", startTime: DateTime(1, 1, 1, 1), endTime: DateTime(1, 1, 1, 2));
    Event e3 = Event(title: "", startTime: DateTime(1, 1, 1, 2), endTime: DateTime(1, 1, 1, 3));
    return [EventTileData(event: e1), EventTileData(event: e2), EventTileData(event: e3)];
  }

  List<EventTileData> threeDenseOverlappingEvents() {
     final event = Event(title: "", startTime: DateTime(1, 1, 1, 0), endTime: DateTime(1, 1, 1, 24));
     return [EventTileData(event: event), EventTileData(event: event), EventTileData(event: event)];
  }
  group("countOverlaps", () {

    test("dense overlapping", () async {
      final eventTilesData = threeDenseOverlappingEvents();
      countOverlaps(eventTilesData);
      for (final eventTileData in eventTilesData) {
        check(eventTileData.overlapCount).equals(eventTilesData.length - 1);
      }
    });

    test("non overlapping", () async {
      final eventTilesData = threeNonOverlappingEvents();
      countOverlaps(eventTilesData);
      for (final eventTileData in eventTilesData) {
        check(eventTileData.overlapCount).equals(0);
      }
    });

    test("one overlapping with two non overlapping", () async {
      Event e1 = Event(title: "", startTime: DateTime(1, 1, 1, 0), endTime: DateTime(1, 1, 1, 2));
      Event e2 = Event(title: "", startTime: DateTime(1, 1, 1, 1), endTime: DateTime(1, 1, 1, 3));
      Event e3 = Event(title: "", startTime: DateTime(1, 1, 1, 2), endTime: DateTime(1, 1, 1, 4));
      List<EventTileData> eventTilesData = [EventTileData(event: e1), EventTileData(event: e2), EventTileData(event: e3)];
      countOverlaps(eventTilesData);
      check(eventTilesData[0].overlapCount).equals(1);
      check(eventTilesData[1].overlapCount).equals(2);
      check(eventTilesData[2].overlapCount).equals(1);
    });
  });

  group("findFirstFreeColumn", () {
    
  });

  // assigning columns - common cases
  // no events
  // no overlaps
  // all overlaps
  // one overlap with all (2) (order invariant)
  // 2 non overlapping pairs - mesh (order invariant)
  // 1 overlapping and 1 non overlapping pair - sandwich (order invariant)

  group("assignColumns", () {    
    test("non overlapping", () async {
      final eventTilesData = threeNonOverlappingEvents();
      List<List<int>> columns = assignColumns(eventTilesData);
      check(columns.length).equals(1);
      check(columns[0].length).equals(3);
    });

    test("dense overlapping", () async {
      final eventTilesData = threeNonOverlappingEvents();
      List<List<int>> columns = assignColumns(eventTilesData);
      check(columns.length).equals(3);
      for (final column in columns) {
        check(column.length).equals(0);
      }
    });

    test("one overlapping with two non overlapping", () async {
      // should be order invariant
      Event e1 = Event(title: "", startTime: DateTime(1, 1, 1, 0), endTime: DateTime(1, 1, 1, 2));
      Event e2 = Event(title: "", startTime: DateTime(1, 1, 1, 1), endTime: DateTime(1, 1, 1, 3));
      Event e3 = Event(title: "", startTime: DateTime(1, 1, 1, 2), endTime: DateTime(1, 1, 1, 4));
      List<EventTileData> eventTilesData = [EventTileData(event: e1), EventTileData(event: e2), EventTileData(event: e3)];
      
      List<List<int>> columns = assignColumns(eventTilesData);
      check(columns.length).equals(2);

      check(columns[0].length).equals(1);
      check(columns[0][0]).equals(1);

      check(columns[1].length).equals(2);
      check(columns[1][0]).equals(0);
      check(columns[1][1]).equals(2);
    });
    
  });


}