import 'package:anu_timetable/model/controllers.dart';
import 'package:anu_timetable/util/timetable_layout.dart';
import 'package:flutter/material.dart';
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

class _PickerButton extends StatelessWidget {
  void _onPressed(context, currentDay, timetableModel) async {
    MonthBarPageController monthBarPageController = Provider.of<MonthBarPageController>(context, listen: false);
    monthBarPageController.show = !monthBarPageController.show;
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
                  size: 20)
              ]))));
  }
}

class _PickerButtonText extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<TimetableModel>(
      builder: (context, timetableModel, child) => Text(
        style: TextStyle(
          fontWeight: FontWeight.w400,
          fontSize: 14),
        TimetableLayout.monthString(timetableModel.weekOfActiveDay.month)));
  }
}