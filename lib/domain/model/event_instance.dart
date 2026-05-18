class EventInstance {
  late String id;
  final String title;
  final DateTime startTime;
  final DateTime endTime;
  final String location;
  final bool isAllDay;

  EventInstance({
    required this.id,
    required this.title,
    required this.startTime,
    required this.endTime,
    required this.location,
    required this.isAllDay,
  });

  bool overlapping(EventInstance other) =>
    startTime.compareTo(other.endTime) < 0 && other.startTime.compareTo(endTime) < 0;
}