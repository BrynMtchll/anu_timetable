import 'package:anu_timetable/domain/model/event.dart';
import 'package:anu_timetable/model/current.dart';
import 'package:anu_timetable/model/events.dart';
import 'package:anu_timetable/model/user.dart';
import 'package:anu_timetable/widgets/event_list_item.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<UserVM>().loadCurrentUser.execute();
    });
    super.initState();
  }
  
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.all(15),
        child: Consumer<CurrentDay>(
          builder: (context, currentDay, child) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Profile(),
              _DateWidget(day: currentDay.value),
              _SyncButton(),
              _UpcomingClasses(day: currentDay.value),
            ]))));
  }
}

Shader _shaderCallback(ColorScheme colorScheme, Rect bounds) {
  final shade = HSVColor.fromAHSV(1, HSVColor.fromColor(colorScheme.primary).hue, 0.3, 0.8).toColor();
  return LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [const Color.fromARGB(255, 255, 255, 255), shade])
      .createShader(bounds);
}

class _SyncButton extends StatelessWidget {
  const _SyncButton();

  @override
  Widget build(BuildContext context) {
    ColorScheme colorScheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: () => context.push('/syncAnu'),
      child: Center(
        child: Container(
          height: 45,
          margin: EdgeInsets.only(left: 10, right: 10, bottom: 20),
          decoration: BoxDecoration(
            border: BoxBorder.all(color: colorScheme.onSurface, width: 0.4),
            color: colorScheme.primary,
            borderRadius: BorderRadius.circular(30)),
          child: Center(
            child: Text(
              style: TextStyle(
                color: colorScheme.onPrimary,
                fontWeight: FontWeight.w600,
                fontSize: 14),
                "Sync With MyTimetable")))));
  }
}

String getInitials(String name) => name.isNotEmpty
    ? name.trim().split(RegExp(' +')).map((s) => s[0]).take(2).join() : '';

class Profile extends StatelessWidget {
  const Profile({super.key});

  @override
  Widget build(BuildContext context) {
    ColorScheme colorScheme = Theme.of(context).colorScheme;
    return Container(
      height: 40,
      width: 40,
      decoration: BoxDecoration(
        border: BoxBorder.all(color: colorScheme.onSurface, width: 0.4),
        color: colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(30)),
      child: Center(
        child: Consumer<UserVM>(
          builder: (context, userVM, child) => Text(
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 16),
            getInitials(userVM.currentUser?.displayName ?? '')))));
  }
}

class _DateWidget extends StatelessWidget {
  final DateTime day;
  const _DateWidget({required this.day});

  @override
  Widget build(BuildContext context) {
    ColorScheme colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: ShaderMask(
        shaderCallback: (bounds) => _shaderCallback(colorScheme, bounds),
        child: Container(
          width: 150,
          height: 150,
          margin: EdgeInsets.symmetric(vertical: 20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.all(Radius.circular(30)),
            color: colorScheme.surfaceContainerHigh),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        color: colorScheme.onSurface,
                        fontSize: 20),
                      DateFormat("EEEE").format(day)),
                  ]),
                Row(
                  textBaseline: TextBaseline.alphabetic,
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  children: [
                    Text(
                      style: TextStyle(
                        height: 1,
                        color: colorScheme.primary,
                        fontSize: 50),
                      day.day.toString()),
                  ]),
                Text(
                  style: TextStyle(
                    fontWeight: FontWeight.w400,
                    color: colorScheme.onSurface,
                    fontSize: 20),
                  DateFormat("MMMM").format(day)),
              ])))));
  }
}

class _UpcomingClasses extends StatelessWidget {
  final DateTime day;
  const _UpcomingClasses({required this.day});

  @override
  Widget build(BuildContext context) {
    ColorScheme colorScheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: EdgeInsets.only(bottom: 4),
          child: Text(
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface),
            "COMING UP".toUpperCase())),
        Consumer<UserEventsVM>(
          builder: (context, eventsVM, child) {
            List<Event> events = eventsVM.getEventsOnDay(day);
            return Column(
              children: [for (final event in events) EventItem(event: event)]);
          })
      ]);
  }
}
