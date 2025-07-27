import 'dart:math';

import 'package:anu_timetable/model/animation_notifiers.dart';
import 'package:anu_timetable/util/timetable_layout.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:anu_timetable/model/timetable_model.dart';
import 'package:anu_timetable/widgets/tab_bar.dart';

class MyAppBar extends StatelessWidget implements PreferredSizeWidget{
  final int currentPageIndex;
  const MyAppBar({super.key, required this.currentPageIndex});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return AppBar(
      leadingWidth: 110,
      leading: currentPageIndex == 1 ? _PickerButton() : null,
      backgroundColor: colorScheme.surfaceContainerLow,
      titleSpacing: 0,
      centerTitle: true,
      title: currentPageIndex == 1 ? MyTabBar() : null,
      actions: [
        SizedBox(width: 110),
      ]);
  }
  @override
  Size get preferredSize => Size.fromHeight(40);
}

class _PickerButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    ColorScheme colorScheme = Theme.of(context).colorScheme;
    return Consumer<MonthBarAnimationNotifier>(
      builder: (BuildContext context, MonthBarAnimationNotifier monthBarAnimationNotifier, Widget? child) =>
        GestureDetector(
          onTap: () {
            monthBarAnimationNotifier.open = !monthBarAnimationNotifier.open;
          },
          child: Padding(
            padding: EdgeInsetsGeometry.only(left: 20),
            child: Row(
              children: [
                _PickerButtonText(),
                AnimatedRotation(
                  duration: Duration(milliseconds: 200),
                  turns: monthBarAnimationNotifier.open ? -0.5 : 0,
                  child: Icon(
                  Icons.arrow_drop_down,
                  color: colorScheme.onSurface,
                  size: 20))
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
          fontSize: 13),
        TimetableLayout.monthString(timetableModel.activeDay.month)));
  }
}