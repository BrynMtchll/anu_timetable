import 'dart:ui';

import 'package:anu_timetable/model/event_tile_arranger.dart';
import 'package:anu_timetable/util/timetable_layout.dart';
import 'package:checks/checks.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {

  // assigning columns - common cases
  // no events
  // no overlaps
  // all overlaps
  // one overlap with all (2) (order invariant)
  // 2 non overlapping pairs - mesh (order invariant)
  // 1 overlapping and 1 non overlapping pair - sandwich (order invariant)
  group("assignColumns", () {
    Size size = Size(100, TimetableLayout.innerSize.height);

    test("no events", () async {
      // final eventTileArranger = EventTileArranger(size, );

      // eventTileArranger.assignColumns()
    });
  });
}