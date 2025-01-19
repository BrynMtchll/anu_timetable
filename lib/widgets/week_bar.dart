import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:anu_timetable/model/timetable_model.dart';

String _weekdayCharacters(int weekday){
  switch (weekday) {
    case DateTime.monday: return 'M';
    case DateTime.tuesday: return 'Tu';
    case DateTime.wednesday: return 'W';
    case DateTime.thursday: return 'Th';
    case DateTime.friday: return 'F';
    case DateTime.saturday: return 'Sa';
    case DateTime.sunday: return 'Su';
    default: return '';
  }
}

class WeekBar extends StatefulWidget implements PreferredSizeWidget {
  const WeekBar({super.key});

  @override
  State<WeekBar> createState() => _WeekBarState();
  
  @override
  Size get preferredSize => Size.fromHeight(80);
}

class _WeekBarState extends State<WeekBar> {
  late PageController _pageViewController;
  static const initialPage = 1000;
  int _activePage = initialPage;
  
  @override
  void initState() {
    super.initState();
    _pageViewController = PageController(
      initialPage: _activePage
    );
  }

  @override
  void dispose() {
    super.dispose();
    _pageViewController.dispose();
  }

  Color? _weekdayItemColor(timetableModel, weekday) 
    => timetableModel.activeDate.weekday == weekday ? Colors.lightBlue : null;

  /// Computes the week start date for a given page.
  DateTime _weekDate(int page, DateTime activeWeekDate) {
    int differencefromActiveInDays = (page - _activePage) * 7;
    DateTime pageDate = activeWeekDate.add(Duration(days: differencefromActiveInDays));
    return pageDate;
  }

  /// Returns the date of the given [weekday], 
  DateTime _weekdayDate(int page, activeWeekDate, int weekday) 
    => _weekDate(page, activeWeekDate).add(Duration(days: weekday - 1));

  /// row element for the [_weekdayItem]s.
  Align _week(int page) {
    return Align(
      alignment: Alignment.center,
      child: IntrinsicHeight(child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          for (int weekday = 1; weekday <= DateTime.daysPerWeek; weekday++) 
            _weekdayItem(page, weekday),
        ],
     ))
    );
  }

  /// Widget for each day of the week bar, i.e. each item of the page.
  /// Tapping this widget sets that date as the [timetableModel.activeDate].
  GestureDetector _weekdayItem(int page, int weekday) => GestureDetector(
    onTap: () {
      var timetableModel = Provider.of<TimetableModel>(context, listen: false);
      timetableModel.activeDate = _weekdayDate(page, timetableModel.activeWeekDate, weekday);
    },
    child: Column(
      children: [
        Padding(
          padding: EdgeInsets.all(2),
          child: Align(
            alignment: Alignment.center,
            child: Text(
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 11,
              ),
              _weekdayCharacters(weekday)
            ),
          ),
        ),
        
        Consumer<TimetableModel>(
          builder: (context, timetableModel, child) {
            return Container(
            width: 33,
            height: 33,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: _weekdayItemColor(timetableModel, weekday),
            ),
            child: Align(
              alignment: Alignment.center,
              child:  Text(
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
                _weekdayDate(page, timetableModel.activeWeekDate, weekday).day.toString()
              )
            ),
          );
          }
        )
      ],
    )
  );

  void _handlePageChanged(int newActivePage) {
    var difference = (newActivePage - _activePage);
    Provider.of<TimetableModel>(context, listen: false)
        .shiftActiveWeek(difference);
    _activePage = newActivePage;
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 80, 
      child: PageView.builder(
        controller: _pageViewController,
        onPageChanged: _handlePageChanged,
        itemBuilder: (context, page) => _week(page),
        )
      );
  }
}
