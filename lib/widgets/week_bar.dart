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
  late PageController pageController;
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
    pageController = Provider.of<PageController>(context);
    timetableModel = Provider.of<TimetableModel>(context, listen: false);
  }


  Color? _weekdayItemColor(page, timetableModel, weekday) => 
    timetableModel.weekdayDate(page, timetableModel.activeWeekDate, weekday) == 
    timetableModel.activeDate ? 
    Colors.lightBlue : null;

  /// Widget for each day of the week bar, i.e. each item of the page.
  /// Tapping this widget sets that date as the [timetableModel.activeDate].
  GestureDetector _weekdayItem(int page, int weekday, timetableModel) => GestureDetector(
    onTap: () {
      var timetableModel = Provider.of<TimetableModel>(context, listen: false);
      timetableModel.activeDate = timetableModel.weekdayDate(page, timetableModel.activeWeekDate, weekday);
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
            color: _weekdayItemColor(page, timetableModel, weekday),
          ),
          child: Align(
            alignment: Alignment.center,
            child:  Text(
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
              timetableModel.weekdayDate(page, timetableModel.activeWeekDate, weekday).day.toString()
            )
          ),
        )
      ],
    )
  );

  /// row element for the [_weekdayItem]s.
  Align _weekBuilder(int page, timetableModel) {
    return Align(
      alignment: Alignment.center,
      child: IntrinsicHeight(child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          for (int weekday = 1; weekday <= DateTime.daysPerWeek; weekday++) 
            _weekdayItem(page, weekday, timetableModel),
        ],
     ))
    );
  }

  void _handlePageChanged(int newActivePage) {
    timetableModel.shiftActiveWeek(newActivePage);
    print("page change");
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<TimetableModel>(
      builder: (context, timetableModel, child) {
        return SizedBox(
          height: 80, 
          child: PageView.builder(
            controller: pageController,
            onPageChanged: _handlePageChanged,
            itemBuilder: (context, page) => _weekBuilder(page, timetableModel),
          )
        );
      }
    );
  }
}
