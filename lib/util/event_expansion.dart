// TODO: should live somewhere else?
  import 'package:anu_timetable/domain/model/event.dart';
import 'package:anu_timetable/domain/model/event_rule.dart';
import 'package:calendar_view/calendar_view.dart';


List<Event> expandEventOccurrences(List<EventRule> eventRules) {
  final List<Event> events = [];
  for (final eventRule in eventRules) {
    for (final occurrence in eventRule.occurrences) {
      DateTime startDate = occurrence.$1;
      DateTime endDate = occurrence.$2;
      events.add(Event.fromRule(eventRule, startDate, endDate));
    }
  }
  return events;
}

/// All of below is legacy (for now)
Event _eventFromRecurrence(EventRule eventRule, int dayOffset) {
  /// could alternatively use duration property?
  DateTime startDate = eventRule.startDate.add(Duration(days: dayOffset));
  DateTime endDate = eventRule.endDate.add(Duration(days: dayOffset));
  return Event.fromRule(eventRule, startDate, endDate);
}

int _weekOfYear(DateTime day) {
  final dayDiff = day.getDayDifference(DateTime.utc(day.year).firstDayOfWeek());
  return(dayDiff / 7).toInt() + 1;
}

/// Checks if given weekday is in the recurrence rule, 
/// of the right instance count if specified.
/// Whether byWeekday is null should be checked in advance.
bool _doesWeekdayFail(RecurrencePattern rec, DateTime day, List<int> currInstance) {
  if (!rec.isByWeekday) return false;
  final weekdayInd = rec.byWeekday!.indexWhere((byDay) => byDay.weekday == day.weekday);
  if (weekdayInd != -1) currInstance[weekdayInd]++;
  return weekdayInd == -1 || (currInstance[weekdayInd] != rec.byWeekday![weekdayInd].instance 
    && rec.byWeekday![weekdayInd].instance != null);
}

bool _doesPeriodFail(RecurrencePattern rec, DateTime day, DateTime firstDay) {
  return ((rec.freq == Freq.weekly && day.weekday != firstDay.weekday)
    || (rec.freq == Freq.yearly && rec.isByMonth && day.day != firstDay.day)
    || (rec.freq == Freq.yearly && !rec.isByMonth && (day.month != firstDay.month || day.day != firstDay.day)));
}

bool _doesDayFail(RecurrencePattern rec, DateTime day, DateTime firstDay, List<int> currInstance) {
  final yearDay = day.getDayDifference(DateTime.utc(day.year)) + 1;
  final byPeriodFail = rec.isFirstDayPeriodic && _doesPeriodFail(rec, day, firstDay);
  final byMonthDayFail = rec.isByMonthDay && !rec.byMonthDay!.contains(day.day);
  final byYearDayFail = rec.isByYearDay && !rec.byYearDay!.contains(yearDay);
  final byWeekdayFail = rec.isByWeekday && _doesWeekdayFail(rec, day, currInstance);
  return byMonthDayFail || byYearDayFail || byWeekdayFail || byPeriodFail;
}

/// TODO: negative indexing, bySetPos, exclusions etc.
/// TODO: closer consideration of defaults, duration??
/// NOTE: from is treated as start of day and to is treated as end of day
void _expandRecurring(List<Event> events, EventRule eventRule, DateTime from, DateTime to) {
  final rec = eventRule.recurrencePattern!;
  final count = rec.count ?? 1e9;
  final firstDay = eventRule.startDate.withoutTime;
  DateTime day = rec.periodStart(firstDay);
  int freqOffset = -1;
  int currCount = 0;
  List<int> currInstance = List.filled(rec.byWeekday?.length ?? 0, 0);

  while(currCount < count && (rec.until == null || day.isBefore(rec.until!)) && !day.isAfter(to)) {
    if (rec.isPeriodStart(day, firstDay)) {
      currInstance = List.filled(rec.byWeekday?.length ?? 0, 0);
      freqOffset++;
    }
    final intervalFail = freqOffset % rec.interval != 0;
    final byMonthFail = rec.isByMonth && !rec.byMonth!.contains(day.month);
    final byWeekFail = (rec.isByWeek && !rec.byWeek!.contains(_weekOfYear(day)));
    final byDayFail = _doesDayFail(rec, day, firstDay, currInstance);

    if (intervalFail) {
      day = rec.nextPeriod(day);
    }
    else if (byMonthFail) {
      day = DateTime.utc(day.year, day.month + 1);
    }
    else if (byWeekFail) {
      day = DateTime.utc(day.year, day.month, day.day + 1);
    }
    else if (day.isBefore(firstDay) || byDayFail) {
      day = day.add(Duration(days: 1));
    }
    else {
      final dayOffset = eventRule.startDate.getDayDifference(day);
      final event = _eventFromRecurrence(eventRule, dayOffset);
      events.add(event);
      currCount++;
      day = day.add(Duration(days: 1));
    }
  }
}

/// possibly expensive expanding all events for each query if they fall within the window, rather than memoising.
/// but otherwise would need logic to resume expansion from previous query in the case of infinitely recurring events
/// which cannot be fully expanded. Or maybe could mark those specifically as infinite? But also might have events that 
/// aren't infinite but repeat every day for a hundred years.
List<Event> expandEventRules(List<EventRule> eventRules, DateTime from, DateTime to) {
  List<Event> events = [];
  for (final EventRule eventRule in eventRules) {
    if (eventRule.isRecurring && eventRule.recurrencePattern!.until != null 
      && eventRule.recurrencePattern!.until!.isBefore(from) || eventRule.startDate.isAfter(to)) continue;
    if (!eventRule.isRecurring) {
      final event = _eventFromRecurrence(eventRule, 0);
      events.add(event);
      continue;
    }
    _expandRecurring(events, eventRule, from, to);
  }
  return events;
}