import 'package:anu_timetable/util/event_tile_arranger.dart';
import 'package:anu_timetable/model/events.dart';
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

  EventTileData fullDay() => EventTileData(event: Event(title: "", startTime: DateTime(1, 1, 1, 0), endTime: DateTime(1, 1, 1, 24)));
  EventTileData firstHalf() => EventTileData(event: Event(title: "", startTime: DateTime(1, 1, 1, 0), endTime: DateTime(1, 1, 1, 12)));
  EventTileData secondHalf() => EventTileData(event: Event(title: "", startTime: DateTime(1, 1, 1, 12), endTime: DateTime(1, 1, 1, 24)));
  EventTileData firstThird() => EventTileData(event: Event(title: "", startTime: DateTime(1, 1, 1, 8), endTime: DateTime(1, 1, 1, 8)));
  EventTileData secondThird() => EventTileData(event: Event(title: "", startTime: DateTime(1, 1, 1, 8), endTime: DateTime(1, 1, 1, 16)));
  EventTileData thirdThird() => EventTileData(event: Event(title: "", startTime: DateTime(1, 1, 1, 16), endTime: DateTime(1, 1, 1, 24)));

  group("countOverlaps", () {
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

    test("two overlapping with one", () async {
      final eventTilesData = [fullDay(), firstHalf(), secondHalf()];
      countOverlaps(eventTilesData);
      check(eventTilesData[0].overlapCount).equals(2);
      check(eventTilesData[1].overlapCount).equals(1);
      check(eventTilesData[2].overlapCount).equals(1);
    });
  });

  group("findFirstFreeColumn", () {
    test("no columns", () async {
      final eventTilesData = [fullDay()];
      final List<List<int>> columns = [];
      check(findFirstFreeColumn(eventTilesData, columns, 0)).equals(0);
    });

    test("none free", () async {
      final eventTilesData = [fullDay(), fullDay(), fullDay()];
      final columns = [[0], [1]];
      check(findFirstFreeColumn(eventTilesData, columns, 2))
        .equals(columns.length);
    });

    test("multiple free", () {
      final eventTilesData = [firstThird(), secondThird(), thirdThird()];
      final columns = [[0], [1]];
      check(findFirstFreeColumn(eventTilesData, columns, 2))
        .equals(0);
    });

    test("first free", () {
      final eventTilesData = [firstHalf(), fullDay(), secondHalf()];
      final columns = [[0], [1]];
      check(findFirstFreeColumn(eventTilesData, columns, 2))
        .equals(0);
    });

    test("last free", () {
      final eventTilesData = [fullDay(), firstHalf(), secondHalf()];
      final columns = [[0], [1]];
      check(findFirstFreeColumn(eventTilesData, columns, 2))
        .equals(1);
    });
  });

  group("assignColumns", () {
    /// col 0: ___|___|___
    test("non overlapping", () async {
      final eventTilesData = [firstThird(), secondThird(), thirdThird()];
      final columns = assignColumns(eventTilesData);
      check(columns.length).equals(1);
      check(columns[0].length).equals(3);
    });

    /// col 2: _______
    /// col 1: _______
    /// col 0: _______
    test("all overlapping", () async {
      final eventTilesData = [fullDay(), fullDay(), fullDay()];
      final columns = assignColumns(eventTilesData);
      check(columns.length).equals(3);
      for (final column in columns) {
        check(column.length).equals(1);
      }
    });

    /// col 1: ___|___ 
    /// col 0: _______
    test("one overlapping with two non overlapping", () async {
      final eventTilesData = [firstHalf(), secondHalf(), fullDay()];
      final columns = assignColumns(eventTilesData);
      check(columns.length).equals(2);
      check(columns[0].length).equals(1);
      check(columns[1].length).equals(2);
      check(columns[0][0]).equals(2);
    });

    /// col 2: _______
    /// col 1: ___|___
    /// col 0: _______
    test("two overlapping with two non overlapping", () async {
      final eventTilesData = [firstHalf(), fullDay(), fullDay(), secondHalf()];
      final columns = assignColumns(eventTilesData);
      check(columns.length).equals(3);
      check(columns[0].length).equals(1);
      check(columns[1].length).equals(2);
      check(columns[2].length).equals(1);
      check(columns[0][0]).equals(1);
      check(columns[2][0]).equals(2);
    });
  });

  group("collectLeftOverlaps", () {
    test("non overlapping", () async {
      final eventTilesData = [firstThird(), secondThird(), thirdThird()];
      final columns = [[0, 1, 2]];
      final leftOverlaps = collectLeftOverlaps(eventTilesData, columns);
      for (int i = 0; i < 3; i++) {
        check(leftOverlaps[i].length).equals(0);
      }
    });
    test("all overlapping", () async {
      final eventTilesData = [fullDay(), fullDay(), fullDay()];
      final columns = [[0], [1], [2]];
      final leftOverlaps = collectLeftOverlaps(eventTilesData, columns);
      check(leftOverlaps[0].length).equals(0);

      check(leftOverlaps[1].length).equals(1);
      check(leftOverlaps[1][0]).equals(0);

      check(leftOverlaps[2].length).equals(2);
      check(leftOverlaps[2][0]).equals(0);
      check(leftOverlaps[2][1]).equals(1);
    });

    test("left but not overlapping", () async {
      final eventTilesData = [fullDay(), firstHalf(), secondHalf(), firstThird()];
      final columns = [[0], [1, 2], [3]];
      final leftOverlaps = collectLeftOverlaps(eventTilesData, columns);
      check(leftOverlaps[0].length).equals(0);

      check(leftOverlaps[1].length).equals(1);
      check(leftOverlaps[1][0]).equals(0);

      check(leftOverlaps[2].length).equals(1);
      check(leftOverlaps[2][0]).equals(0);

      check(leftOverlaps[3].length).equals(2);
      check(leftOverlaps[3][0]).equals(0);
      check(leftOverlaps[3][1]).equals(1);
    });
  });
}