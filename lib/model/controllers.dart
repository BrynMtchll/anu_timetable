import 'package:flutter/material.dart';
import 'package:linked_scroll_controller/linked_scroll_controller.dart';

class DayViewPageController extends PageController {
  DayViewPageController({
    super.initialPage,
    super.keepPage,
    double viewportFraction = 1.0,
    super.onAttach,
    super.onDetach,
  });
}

class WeekViewPageController extends PageController {
  WeekViewPageController({
    super.initialPage,
    super.keepPage,
    double viewportFraction = 1.0,
    super.onAttach,
    super.onDetach,
  });
}

class WeekBarPageController extends PageController {
  WeekBarPageController({
    super.initialPage,
    super.keepPage,
    double viewportFraction = 1.0,
    super.onAttach,
    super.onDetach,
  });
}

