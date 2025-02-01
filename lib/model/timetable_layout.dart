class TimetableLayout {

  static final double leftMargin = 50;

  static final double height = 1500;

  static final double tabBarHeight = 45;

  static final double weekBarHeight = 80;

  /// An even segment for each of the 24 hours of the day,
  /// plus a half hour top and bottom for padding.
  static final double hourHeight = height / 25;

  static final double vertPadding = hourHeight / 2;

  static final double dayHeight = height - 2 * vertPadding;
}