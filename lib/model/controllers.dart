import 'package:anu_timetable/model/timetable_model.dart';
import 'package:anu_timetable/util/timetable_layout.dart';
import 'package:flutter/material.dart';

mixin PageLinker on PageController {
  double get pageWidth;
  bool get isScrolling;

  void matchToOther(PageLinker otherController) {
    if (isScrolling || !hasClients) return;

    double viewportRatio = viewportFraction / otherController.viewportFraction;
    
    double widthRatio = pageWidth / otherController.pageWidth;
    double newPosition = otherController.offset * viewportRatio * widthRatio;

    position.correctPixels(newPosition);
    position.notifyListeners();
  }

  void jumpToOther(PageController otherController) {
    if (page != otherController.page) {
      jumpToPage(otherController.page!.round());
    }
  }
}

mixin ScrollLinker on ScrollController {
  void matchToOther(ScrollController otherController) {
    if (!otherController.hasClients) return;

    if (position.pixels != otherController.position.pixels) {
      position.correctPixels(otherController.position.pixels);
    }
  }
}

class DayViewPageController extends PageController with PageLinker{
  @override
  final double pageWidth = TimetableLayout.screenWidth - TimetableLayout.leftMargin;

  @override
  bool isScrolling = true;
  
  DayViewPageController({
    super.initialPage,
    super.keepPage,
    super.viewportFraction = 1.0,
    super.onAttach,
    super.onDetach,
  });

  void syncToOther(PageController weekBarPageController) {
    if (position.hasContentDimensions && weekBarPageController.position.hasContentDimensions) {
      int newDayViewPage = TimetableModel.convertToDayPage(weekBarPageController.page!, page!);
      jumpToPage(newDayViewPage);
    }
  }
}

class WeekViewPageController extends PageController with PageLinker {
  @override
  final double pageWidth = TimetableLayout.screenWidth - TimetableLayout.leftMargin;

  @override
  bool isScrolling = true;

  WeekViewPageController({
    super.initialPage,
    super.keepPage,
    super.viewportFraction = 1.0,
    super.onAttach,
    super.onDetach,
  });
}

class WeekBarPageController extends PageController with PageLinker{
  @override
  final double pageWidth = TimetableLayout.screenWidth;

  @override
  bool isScrolling = false;

  WeekBarPageController({
    super.initialPage,
    super.keepPage,
    super.viewportFraction = 1.0,
    super.onAttach,
    super.onDetach,
  });
}

class ViewTabController extends TabController{
  ViewTabController({
    super.animationDuration,
    super.initialIndex,
    required super.length,
    required super.vsync,
  });

  void matchScrollOffsets(ScrollController controller1, ScrollController controller2) {
    if (!indexIsChanging || !controller2.hasClients || !controller1.hasClients) return;
    switch (index) {
      case (1): controller2.jumpTo(controller1.offset);
      case (0): controller1.jumpTo(controller2.offset);
    }
  }
}

class WeekViewScrollController extends ScrollController with ScrollLinker{
  WeekViewScrollController({
    super.initialScrollOffset,
    super.keepScrollOffset,
    super.debugLabel,
    super.onAttach,
    super.onDetach,
  });
}

class DayViewScrollController extends ScrollController with ScrollLinker{
  DayViewScrollController({
    super.initialScrollOffset,
    super.keepScrollOffset,
    super.debugLabel,
    super.onAttach,
    super.onDetach,
  });
}