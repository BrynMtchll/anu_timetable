class TimetableLayout {

  final double leftMargin = 50;

  final double height = 1500;

  /// An even segment for each of the 24 hours of the day,
  /// plus a half hour top and bottom for padding.
  late double hourHeight = height / 25;

  late double vertPadding = hourHeight / 2;

  late double dayHeight = height - 2 * vertPadding;
}