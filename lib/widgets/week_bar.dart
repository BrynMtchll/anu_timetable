import 'package:anu_timetable/controllers.dart';
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

class WeekBar extends StatelessWidget implements PreferredSizeWidget {
  const WeekBar({super.key});

  @override
  Size get preferredSize => Size.fromHeight(80);

  Color? _weekdayItemColor(TimetableModel timetableModel, int page, int weekday) {
    DateTime weekdayDate = timetableModel.weekdayDate(page.toDouble(), weekday);
    return weekdayDate == timetableModel.activeDay() ?Colors.lightBlue : null;
  }

  /// Widget for each day of the week bar, i.e. each item of the page.
  Consumer _weekdayItem(int page, int weekday) => Consumer<TimetableModel>(
    builder: (context, timetableModel, child) => GestureDetector(
      onTap: () {
        Provider.of<TimetableModel>(context, listen: false)
          .handleWeekBarWeekdayTap(page, weekday);
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
          
          Container(
            width: 33,
            height: 33,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: _weekdayItemColor(timetableModel, page, weekday),
            ),
            child: Align(
              alignment: Alignment.center,
              child:  Text(
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
                timetableModel.weekdayDate(page.toDouble(), weekday).day.toString()
              )
            ),
          )
        ],
      )
    )
  );

  /// row element for the [_weekdayItem]s.
  Align _weekBuilder(int page) {
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

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 80, 
      child: PageView.builder(
        controller: Provider.of<WeekBarPageController>(context, listen: false),
        onPageChanged: (page) {
          Provider.of<TimetableModel>(context, listen: false)
            .handleWeekBarPageChanged();
        },
        itemBuilder: (context, page) => _weekBuilder(page),
      )
    );
  }
}
