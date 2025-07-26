import 'package:anu_timetable/model/timetable_model.dart';
import 'package:anu_timetable/util/timetable_layout.dart';
import 'package:flutter/material.dart';

mixin PageLinker on PageController {
  double get pageWidth;
  bool get isScrolling;

  void matchToOther(PageLinker otherController) {
    if (isScrolling || !otherController.isScrolling || !hasClients) return;

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
  bool isScrolling = false;

  /// When animating the [page], by default intermediate 
  /// pages are animated. [_pageOverride] is used so that the target page can be 
  /// animated to as though it were the adjacent page and not have [page] 
  /// mistakenly return the adjacent page instead of the target page.
  int? _pageOverride;
  int? _adjacentPage;
  int _persistedPage = TimetableModel.getDayPage(DateTime.now());

  @override get page {
    if (!hasClients) {
      return _persistedPage.toDouble();
    }
    else if (_pageOverride != null) {
      return _pageOverride!.toDouble();
    }
    else {
      return super.page;
    }
  }

  @override jumpToPage(int newPage) {
    _persistedPage = newPage;
    super.jumpToPage(newPage);
  }
  @override animateToPage(int newPage, {required Curve curve, required Duration duration}) {
    _persistedPage = newPage;
    return super.animateToPage(newPage, curve: curve, duration: duration);
  }

  int overridePage(int page) => page == _adjacentPage ? _pageOverride! : page;
  DayViewPageController({
    super.initialPage,
    super.keepPage,
    super.viewportFraction = 1.0,
    super.onAttach,
    super.onDetach,
  });

  void syncToOther(PageController weekBarPageController) {
    if (position.hasContentDimensions && weekBarPageController.position.hasContentDimensions) {
      int newDayViewPage = TimetableModel.getDayPage(
        TimetableModel.dayOfWeek(weekBarPageController.page!,  TimetableModel.day(page!).weekday));
      jumpToPage(newDayViewPage);
    }
  }

  /// Workaround to animate directly to a non adjacent day as though it were adjacent.
  ///   1.  Set [_pageOverride] to the new page,
  ///   2.  animate to the adjacent page of the same side,
  ///   3.  jump to the target page,
  ///   4.  set [_pageOverride] to null.
  void animateDirectToPage(int newPage) async {
    int currPage = page!.round();
    _adjacentPage = newPage > page! ? currPage +1 : currPage -1;
    _pageOverride = newPage;
    notifyListeners();

    await animateToPage(
      _adjacentPage!,
      curve: Curves.easeInOut,
      duration: Duration(milliseconds: 350),
    );
    _pageOverride = null;
    _adjacentPage = null;

    notifyListeners();
    jumpToPage(newPage);
  }
}

class WeekViewPageController extends PageController with PageLinker {
  @override
  final double pageWidth = TimetableLayout.screenWidth - TimetableLayout.leftMargin;

  @override
  bool isScrolling = false;

  WeekViewPageController({
    super.initialPage,
    super.keepPage,
    super.viewportFraction = 1.0,
    super.onAttach,
    super.onDetach,
  });
}

class WeekBarPageController extends PageController with PageLinker {
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

class MonthBarPageController extends PageController {
  bool isScrolling = false;
  
  MonthBarPageController({
    super.initialPage,
    super.keepPage,
    super.viewportFraction = 1.0,
    super.onAttach,
    super.onDetach,
  });
}

class ViewTabController extends TabController {
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

class MonthListScrollController extends ScrollController{
  MonthListScrollController({
    super.initialScrollOffset,
    super.keepScrollOffset,
    super.debugLabel,
    super.onAttach,
    super.onDetach,
  });
}
