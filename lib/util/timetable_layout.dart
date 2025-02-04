import 'package:flutter/material.dart';

class TimetableLayout {
  static final double leftMargin = 50;

  static final double height = 1700;

  static final double tabBarHeight = 45;

  static final double weekBarHeight = 70;

  /// An even segment for each of the 24 hours of the day,
  /// plus a half hour top and bottom for padding.
  static final double hourHeight = height / 25;

  static final double vertPadding = hourHeight / 2;

  static final double dayHeight = height - 2 * vertPadding;

  final BoxConstraints constraints;

  late Size hourLineLabelsSize;
  late Size hourLinesSize;
  late Size liveTimeIndicatorSize;
  late Size liveTimeIndicatorLabelSize;

  TimetableLayout({required this.constraints}){
    hourLineLabelsSize = Size(leftMargin, height);
    hourLinesSize = Size(constraints.maxWidth - leftMargin, height);
    liveTimeIndicatorSize = Size(constraints.maxWidth - leftMargin, height);
    liveTimeIndicatorLabelSize = Size(leftMargin, height);
  }
}