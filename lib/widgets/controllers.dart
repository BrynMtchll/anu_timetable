import 'package:flutter/material.dart';

class DayViewPageController extends PageController {
  DayViewPageController({
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

