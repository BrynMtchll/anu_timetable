import 'package:flutter/material.dart';
import 'package:calendar_date_picker2/calendar_date_picker2.dart';
import 'package:provider/provider.dart';
import 'package:anu_timetable/model/current_datetime_notifiers.dart';
import 'package:anu_timetable/model/timetable_model.dart';
import 'package:anu_timetable/widgets/tab_bar.dart';

class MyAppBar extends StatelessWidget implements PreferredSizeWidget{
  const MyAppBar({super.key});

  void _onPressed(context, currentDay, timetableModel) async {
    print(currentDay.yearStart());

    CalendarDatePicker2Config config = CalendarDatePicker2Config(
      firstDate: currentDay.yearStart(),
      lastDate: currentDay.yearEnd(),
      hideLastMonthIcon: true,
      hideNextMonthIcon: true,
      hideYearPickerDividers: true,
      hideMonthPickerDividers: true,
      currentDate: currentDay.value,
      modePickerBuilder: ({isMonthPicker, required monthDate, required viewMode}) {
        if (isMonthPicker == null || !isMonthPicker) {
          return SizedBox(height: 0);
        }
      },
    );

    ColorScheme colorScheme = Theme.of(context).colorScheme;
    
    await showDialog(
      context: context,
      barrierColor: Colors.transparent,
      // barrierColor: const Color.fromARGB(70, 41, 41, 41),
      builder:(context) => Dialog(
        alignment: Alignment.center,
        backgroundColor: colorScheme.surface,
        child: Container(
            height: 325,
            width: 325,
            decoration: BoxDecoration(
              border: Border.all(color: colorScheme.onSurface, width: 0.5),
              borderRadius: BorderRadius.circular(25)
            ),
            child: CalendarDatePicker2(
              onValueChanged: (value) {
                if (!value.isEmpty) {
                  timetableModel.jumpToDay(value[0]);
                }
                Navigator.pop(context);
              },
              config: config, 
              value: List.empty(),
            )
          ) 
      )
    );
  }

  @override
  Widget build(BuildContext context) {
    CurrentDay currentDay = Provider.of<CurrentDay>(context);

    TimetableModel timetableModel = Provider.of<TimetableModel>(context);

    ColorScheme colorScheme = Theme.of(context).colorScheme;

    return AppBar(
      leadingWidth: 120,
      leading: Align(
        alignment: Alignment.centerLeft,
        child: GestureDetector(
          onTap: () => _onPressed(context, currentDay, timetableModel),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 15, vertical: 7),
            child: Row(
              children: [
                Text(
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                  TimetableModel.monthString(timetableModel.weekOfActiveDay.month)
                ),
                Icon(
                  Icons.arrow_drop_down,
                  color: colorScheme.onSurface,
                  size: 20
                )
              ],
            )
          )
        )
      ),
      actions: [
        MyTabBar()
      ],
    );
  }
  
  @override
  Size get preferredSize => Size.fromHeight(50);
}