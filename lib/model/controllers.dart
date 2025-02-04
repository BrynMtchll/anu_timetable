import 'dart:ui';

import 'package:anu_timetable/util/timetable_layout.dart';
import 'package:flutter/material.dart';

mixin ScrollLinker on PageController {
  double get pageWidth;

  void matchToOther(ScrollLinker otherController) {
    double viewportRatio = viewportFraction / otherController.viewportFraction;
    
    double widthRatio = pageWidth / otherController.pageWidth;
    double newPosition = otherController.offset * viewportRatio * widthRatio;

    position.correctPixels(newPosition);
    position.notifyListeners();
  }
}

class DayViewPageController extends PageController {
  static final pageWidth = TimetableLayout.screenWidth - TimetableLayout.leftMargin;
  
  DayViewPageController({
    super.initialPage,
    super.keepPage,
    super.viewportFraction = 1.0,
    super.onAttach,
    super.onDetach,
  });

}

class WeekViewPageController extends PageController with ScrollLinker {
  @override
  final double pageWidth = TimetableLayout.screenWidth - TimetableLayout.leftMargin;

  WeekViewPageController({
    super.initialPage,
    super.keepPage,
    super.viewportFraction = 1.0,
    super.onAttach,
    super.onDetach,
  });
}



class WeekBarPageController extends PageController with ScrollLinker{

  @override
  final double pageWidth = TimetableLayout.screenWidth;

  WeekBarPageController({
    super.initialPage,
    super.keepPage,
    super.viewportFraction = 1.0,
    super.onAttach,
    super.onDetach,
  });
}

