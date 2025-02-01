import 'package:anu_timetable/model/controllers.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:anu_timetable/model/timetable_model.dart';
import 'package:anu_timetable/model/timetable_layout.dart';

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
  Size get preferredSize => Size.fromHeight(80);

  @override
  State<WeekBar> createState() => _WeekBarState();
}

class _WeekBarState extends State<WeekBar>{

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder:(context, constraints) => Align(
        alignment: Alignment.centerRight,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: 80,
            maxWidth: Provider.of<TabController>(context).index == 1 ? constraints.maxWidth : constraints.maxWidth,
          ),
          child: PageView.builder(
            controller: Provider.of<WeekBarPageController>(context, listen: false),
            onPageChanged: (page) {
              Provider.of<TimetableModel>(context, listen: false)
                .handleWeekBarPageChanged();
            },
            itemBuilder: (context, page) {
              EdgeInsets padding = 
                Provider.of<TabController>(context).index == 1 ? 
                EdgeInsets.only(left: TimetableLayout().leftMargin) : 
                EdgeInsets.all(0);
                
              return AnimatedPadding(
              duration: Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              padding: padding,
              child: _weekBuilder(page, constraints),
            );
            }
          )
        )
      )
    );
  }

  /// row element for the [_weekdayItem]s.
  Align _weekBuilder(int page, constraints) {
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
  Consumer<TimetableModel> _weekdayItem(int page, int weekday) => Consumer<TimetableModel>(
    builder: (BuildContext context, TimetableModel timetableModel, Widget? child) => GestureDetector(
      onTap: () {
        timetableModel.handleWeekBarWeekdayTap(page, weekday);
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
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: _weekdayItemColor(context, timetableModel, page, weekday),
            ),
            child: Align(
              alignment: Alignment.center,
              child:  Text(
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: _weekdayItemTextColor(timetableModel, page, weekday),
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
  
  Color? _weekdayItemColor(BuildContext context, TimetableModel timetableModel, int page, int weekday) {
    if (Provider.of<TabController>(context).index != 0) return null;
    DateTime weekdayDate = timetableModel.weekdayDate(page.toDouble(), weekday);
    return weekdayDate == timetableModel.activeDay ?Colors.lightBlue : null;
  }

  Color? _weekdayItemTextColor(TimetableModel timetableModel, int page, int weekday) {
    if (Provider.of<TabController>(context).index != 0) return null;
    DateTime weekdayDate = timetableModel.weekdayDate(page.toDouble(), weekday);
    return weekdayDate == timetableModel.activeDay ?Colors.grey[50] : Colors.grey[900];
  }
}
