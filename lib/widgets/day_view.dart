import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:anu_timetable/model/timetable_model.dart';
import 'package:anu_timetable/widgets/hour_line_painter.dart';

class DayView extends StatefulWidget {
  const DayView({super.key});

  @override
  State<DayView> createState() => _DayViewState();
}

class _DayViewState extends State<DayView> {

  late PageController _pageController;
  late PageController weekBarPageController;

  static const initialPage = 7000;

  int _activePage = initialPage;

  final double leftMargin = 50;

  final double height = 1500;

  /// An even segment for each of the 24 hours of the day,
  /// plus a half hour top and bottom for padding.
  late double hourHeight = height / 25;

  late double vertPadding = hourHeight / 2;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(
      initialPage: _activePage
    );
  }

  @override
  void dispose() {
    super.dispose();
    _pageController.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    weekBarPageController = Provider.of<PageController>(context);
  }

  void _handlePageChanged(int newActivePage) {
    var timetableModel = Provider.of<TimetableModel>(context, listen: false);
    var weekBarPageController = Provider.of<PageController>(context, listen: false);
    var difference = (newActivePage - _activePage);
    timetableModel.shiftActiveDay(difference);
    _activePage = newActivePage;

    weekBarPageController.animateToPage(
      timetableModel.weekBarPageForActiveDate(),
      duration: Duration(milliseconds: 400), 
      curve: Curves.easeInOut);
  }

  LayoutBuilder _dayBuilder(int page) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: constraints.maxHeight,
            ),
            child: Stack(
              children: [
                Align(
                  alignment: Alignment.centerRight,
                  child: CustomPaint(
                    size: Size(constraints.maxWidth - leftMargin, height),
                    painter: HourLinePainter(
                      hourHeight: hourHeight, 
                      vertPadding: vertPadding
                    )
                  ),
                ),
                for (int i = 0; i < 25; i++) _hourLineLabel(i), 
              ],
            )
          ),
        );
      }
    );
  }

  Text _hourLineLabelText(int hour) {
    String number;
    String unit;

    hour % 12 == 0 ?
      number = 12.toString() :
      number = (hour % 12).toString();
    
    hour >= 12 ?
      unit = "pm" :
      unit = "am";

    return Text.rich(TextSpan(
      children: <TextSpan>[
        TextSpan(
          text: number,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 13,
          )
        ),
        TextSpan(
          style: TextStyle(
            fontSize: 11,
          ),
          text: unit,
        )
      ]
    ));
  }

  Positioned _hourLineLabel(int hour) {
    final double labelHeight = 30;
    return Positioned(
      top: hourHeight * hour + vertPadding  - (labelHeight / 2),
      left: 0,
      child: Align(
        alignment: Alignment.centerLeft,
        child: SizedBox(
          width: leftMargin,
          height: labelHeight,
          child: Align(
            alignment: Alignment.centerRight,
            child: Padding(
              padding: EdgeInsets.only(right: 5),
              child: _hourLineLabelText(hour),
          )
        )
      )
    ));
  }

  @override
  Widget build(BuildContext context) {
    return PageView.builder(
      controller: _pageController,
      onPageChanged: _handlePageChanged,
      itemBuilder: (context, page) => _dayBuilder(page),
    );
  }
}