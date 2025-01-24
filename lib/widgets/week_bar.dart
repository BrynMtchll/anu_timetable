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
  late TimetableModel timetableModel;
  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    timetableModel = Provider.of<TimetableModel>(context);
  }


  Color? _weekdayItemColor(page, weekday) {
    return timetableModel.weekday(page.toDouble(), weekday) == timetableModel.activeDay() ? 
    Colors.lightBlue : null;
  }

  void _onWeekdayItemTap(int page, int weekday) {
    timetableModel.animateDirectToDayViewPage(timetableModel.weekday(page.toDouble(), weekday));
  }

  /// Widget for each day of the week bar, i.e. each item of the page.
  /// Tapping this widget sets that date as the [timetableModel.activeDate].
  GestureDetector _weekdayItem(int page, int weekday) => GestureDetector(
    onTap: () => _onWeekdayItemTap(page, weekday),
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
            color: _weekdayItemColor(page, weekday),
          ),
          child: Align(
            alignment: Alignment.center,
            child:  Text(
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
              timetableModel.weekday(page.toDouble(), weekday).day.toString()
            )
          ),
        )
      ],
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
    return Consumer<TimetableModel>(
      builder: (context, timetableModel, child) {
        return SizedBox(
          height: 80, 
          child: PageView.builder(
            controller: timetableModel.weekBarPageController,
            onPageChanged: timetableModel.handleWeekBarPageChanged,
            itemBuilder: (context, page) => _weekBuilder(page),
          )
        );
      }
    );
  }
}
