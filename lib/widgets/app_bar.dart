import 'package:anu_timetable/util/timetable_layout.dart';
import 'package:flutter/material.dart';
import 'package:calendar_date_picker2/calendar_date_picker2.dart';
import 'package:provider/provider.dart';
import 'package:anu_timetable/model/current_datetime_notifiers.dart';
import 'package:anu_timetable/model/timetable_model.dart';
import 'package:anu_timetable/widgets/tab_bar.dart';

class MyAppBar extends StatelessWidget implements PreferredSizeWidget{
  const MyAppBar({super.key});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      leadingWidth: 104,
      leading: Container(
        alignment: Alignment.centerLeft,
        child: _PickerButton(),
      ),
      titleSpacing: 0,
      centerTitle: true,
      title: MyTabBar(),
      actions: [
        SizedBox(width: 104),
      ],
    );
  }
  
  @override
  Size get preferredSize => Size.fromHeight(50);
}

class _CalendarDialog extends StatelessWidget {
  final CurrentDay currentDay;
  final TimetableModel timetableModel;

  const _CalendarDialog({
    required this.currentDay, 
    required this.timetableModel
  });

  CalendarDatePicker2Config _configCalendarDatePicker2(colorScheme, currentDay) =>
    CalendarDatePicker2Config(
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

  @override
  Widget build(BuildContext context) {
    ColorScheme colorScheme = Theme.of(context).colorScheme;
    return Dialog(
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
                if (value.isNotEmpty) {
                  timetableModel.jumpToDay(value[0]);
                }
                Navigator.pop(context);
              },
              config: _configCalendarDatePicker2(colorScheme, currentDay), 
              value: List.empty(),
            )
          ) 
      );
  }
}

class _PickerButton extends StatelessWidget {
  void _onPressed(context, currentDay, timetableModel) async {
    await showDialog(
      context: context,
      barrierColor: Colors.transparent,
      // barrierColor: const Color.fromARGB(70, 41, 41, 41),
      builder:(context) => 
        _CalendarDialog(
          currentDay: currentDay, 
          timetableModel: timetableModel
        )
    );
  }

  @override
  Widget build(BuildContext context) {
    ColorScheme colorScheme = Theme.of(context).colorScheme;
    return Consumer2<CurrentDay, TimetableModel>(
      builder: (context, currentDay, timetableModel, child) => 
        GestureDetector(
          onTap: () => _onPressed(context, currentDay, timetableModel),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            child: Row(
              children: [
                _PickerButtonText(),
                Icon(
                  Icons.arrow_drop_down,
                  color: colorScheme.onSurface,
                  size: 20
                )
              ],
            )
          )
        )
    );
  }
}

class _PickerButtonText extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<TimetableModel>(
      builder: (context, timetableModel, child) => Text(
        style: TextStyle(
          fontWeight: FontWeight.w400,
          fontSize: 14,
        ),
        TimetableLayout.monthString(timetableModel.weekOfActiveDay.month)
      )
    );
  }
}