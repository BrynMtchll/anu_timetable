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