import 'package:anu_timetable/domain/model/event_rule.dart';
import 'package:flutter/material.dart';

class EventColorScheme {
  final Color background;
  final Color shade;
  final Color border;
  final Color text;

  const EventColorScheme({required this.background, required this.shade, required this.border, required this.text});
}

class CalendarTheme extends ThemeExtension<CalendarTheme>{

  final Map<EventTypeEnum, EventColorScheme> eventColors;

  /// Chance for repeats in number of [EventTypeEnum]s increases.
  factory CalendarTheme.dark() {
    const List<double> hues = [210,25,145,355,265,30,330,0,55,190,280,105];
    List<Color> backgrounds = hues.map((hue) => HSVColor.fromAHSV(1, hue, 0.45, 0.18).toColor()).toList();
    List<Color> shades = hues.map((hue) => HSVColor.fromAHSV(1, hue, 0.5, 0.95).toColor()).toList();
    List<Color> borders = hues.map((hue) => HSVColor.fromAHSV(1, hue, 0.7, 0.9).toColor()).toList();
    List<Color> texts = hues.map((hue) => HSVColor.fromAHSV(1, hue, 0.05, 0.95).toColor()).toList();
    Map<EventTypeEnum, EventColorScheme> eventColors = {};
    for (int i = 0; i < EventTypeEnum.values.length; i++) {
      eventColors[EventTypeEnum.values[i]] = EventColorScheme(background: backgrounds[i % backgrounds.length],
        shade: shades[i % shades.length], border: borders[i % borders.length], text: texts[i % texts.length]);
    }
    return CalendarTheme(eventColors: eventColors);
  }

  CalendarTheme({required this.eventColors});

  @override
  CalendarTheme copyWith({Map<EventTypeEnum, EventColorScheme>? eventColors}) {
    return CalendarTheme(eventColors: eventColors ?? this.eventColors);
  }

  @override
  CalendarTheme lerp(ThemeExtension<CalendarTheme>? other, double t) {
    if (other is! CalendarTheme) return this;
    return CalendarTheme(
      eventColors: eventColors.map((type, color) {
        final otherBackgroundColor = other.eventColors[type]?.background ?? color.background;
        return MapEntry(type, EventColorScheme(
          background: Color.lerp(color.background, otherBackgroundColor, t)!,
          shade: Color.lerp(color.shade, other.eventColors[type]?.shade ?? color.shade, t)!,
          border: Color.lerp(color.border, other.eventColors[type]?.border ?? color.border, t)!,
          text: Color.lerp(color.text, other.eventColors[type]?.text ?? color.text, t)!,
        ));
      }));
  }
}