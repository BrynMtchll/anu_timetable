import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:anu_timetable/model/timetable_model.dart';

String _weekdayAsString(int weekday){
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

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 80, 
      child: PageView.builder(
        controller: _pageViewController,
        onPageChanged: (int newActivePage) {
          var timetableModel = Provider.of<TimetableModel>(context, listen: false);

          var differencefromActiveInDays = (newActivePage - _activePage) * 7;
          var newActiveWeekStartDate = timetableModel.activeWeekStartDate.add(Duration(days: differencefromActiveInDays));
          timetableModel.activeWeekStartDate = newActiveWeekStartDate;
          _activePage = newActivePage;
        },
        itemBuilder: (context, page) => _week(page),
        )
      );
  }

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
  
  Column _weekdayItem(int page, int weekday) => Column(
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
            _weekdayAsString(weekday)
          ),
        ),
      ),
      
      Consumer<TimetableModel>(
        builder: (context, timetableModel, child) => Container(
          width: 33,
          height: 33,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: timetableModel.activeDate.weekday == weekday ? Colors.lightBlue : null,
          ),
          child: Align(
            alignment: Alignment.center,
            child:  Text(
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
              _computeDate(page, timetableModel, weekday).day.toString()
            )
          ),
        )
      )
    ],
  );

  DateTime _computeDate(int page, timetableModel, int weekday) {
    int differencefromActiveInDays = (page - _activePage) * 7;
    DateTime pageStartDate = timetableModel.activeWeekStartDate.add(Duration(days: differencefromActiveInDays + weekday));
    return pageStartDate;
  }
}
