import 'package:anu_timetable/model/current_datetime_notifiers.dart';

class Event {
  late String title;
  late DateTime startTime;
  late DateTime endTime;
  late String? location;

  Event({
    required this.title,
    required this.startTime,
    required this.endTime,
    this.location,
  });

  bool overlapping(Event other) => 
    startTime.compareTo(other.endTime) < 0 && other.startTime.compareTo(endTime) < 0;
}

class EventsModel {
  final Map<DateTime, List<Event>> _events = {};

  List<Event> getEventsOnDay(DateTime day) {
    // print(_events[day]![0].startTime);
    populateEventsForToday();
    return _events.containsKey(day) ? _events[day]! : List.empty();
  }

  populateEventsForToday() {
    // List<String> titles = ["awesome event", "cool event", "boring lecture", "really fun lab", "tutorial of stoke", "bing bang bap", "an importance"];
    List<String> titles = ["blah", "blah", "blah", "blah", "blah", "blah", "blah", "blah", "blah", "blah", "blah", "blah"];
    DateTime todayStart = CurrentDay.roundDay(DateTime.now());
    // OVERLAPS: 1-2, 4-5, 5-6
    List<int> startHours = [1, 1, 1, 1, 2, 2, 2, 2, 2, 2];
    List<int> endHours = [2, 2, 2, 3, 3, 3, 3, 3, 3, 3];
    // List<int> startHours = [5, 7, 7, 9, 13, 14, 16];
    // List<int> endHours = [6, 8, 9, 11, 15, 17, 17];

    List<Event> todaysEvents = [];

    for (int i = 0; i < 10; i++) {
      DateTime startTime = todayStart.add(Duration(hours: startHours[i]));
      DateTime endTime = todayStart.add(Duration(hours: endHours[i]));
      todaysEvents.add(Event(title: titles[i], startTime: startTime, endTime: endTime));
    }

    _events[todayStart] = todaysEvents;
    print(_events);
  }
}