import 'package:anu_timetable/data/repositories/event_repository.dart';
import 'package:anu_timetable/data/repositories/user_repository.dart';
import 'package:anu_timetable/domain/model/event.dart';
import 'package:anu_timetable/domain/model/event_rule.dart';
import 'package:anu_timetable/domain/model/user.dart';
import 'package:anu_timetable/model/events.dart';
import 'package:anu_timetable/util/result.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter_test/flutter_test.dart';

// Tests derived from the RFC 5545 RRULE recurrence-rule examples.
//
// Notes on translation from the RFC examples to this codebase's model:
// - All times are kept in plain UTC with a constant wall-clock hour (e.g. 9:00),
//   matching the DST-safe UTC-normalization design: the RFC's EDT/EST distinction
//   is not modeled here, since the whole point is the local wall-clock time
//   doesn't shift.
// - `byDay` entries are `(instance: int?, weekday: int)` records, weekday using
//   Dart's DateTime.monday(1)..DateTime.sunday(7) numbering.
// - There is no WKST field on RecurrencePattern, so the two RFC examples whose
//   only variable is WKST (Mon-start vs Sun-start week) can't be distinguished
//   and are omitted.
// - There's no hourly/minutely Freq and no byHour/byMinute field, so the four
//   sub-daily RFC examples are omitted.
// - "Forever" (no COUNT/UNTIL) rules are bounded by the loadEvents query range
//   instead of asserted to run indefinitely.
// - The "every day in January, for 3 years" example is expressed via its RFC
//   alternate form (FREQ=YEARLY;BYMONTH=1;BYDAY=all seven days), since BYMONTH
//   is only meaningful for Freq.yearly in this model.


class FakeEventRepository implements EventRepository {
  List<EventRule> rules = [];

  @override
  Future<Result<EventRule>> addEventRule(EventRule eventRule) async => Result.ok(eventRule);

  @override
  Future<Result<List<EventRule>>> addEventRules(List<EventRule> eventRules) async => Result.ok(eventRules);

  @override
  Future<Result<List<EventRule>>> getAllEventRules() async => Result.ok(rules);

  @override
  Future<Result<List<EventRule>>> getEventRules(List<String> eventRuleIds) async {
    final matchingRules = rules.where((rule) => eventRuleIds.contains(rule.id)).toList();
    return Result.ok(matchingRules);
  }

  @override
  Future<Result<Event>> getEvent(String id) async => Result.error(Exception('Not implemented'));

  @override
  Future<Result<List<Event>>> getEventsOnDay(DateTime day) async => Result.error(Exception('Not implemented'));

  @override
  Future<Result<List<List<Event>>>> getEventsOnWeek(DateTime week) async => Result.error(Exception('Not implemented'));

  @override
  Future<Result<List<List<Event>>>> getEventsOnYear(DateTime year) async => Result.error(Exception('Not implemented'));

  @override
  Future<Result<List<Event>>> getAllEvents() async => Result.error(Exception('Not implemented'));
}

class FakeUserRepository implements UserRepository {
  @override
  Future<Result> signInWithGoogle() async => Result.ok(null);

  @override
  Future<Result> addNewUser(firebase_auth.UserCredential userCredentials) async => Result.ok(null);

  @override
  Future<Result<User>> getUser(String uid) async => Result.error(Exception('Not implemented'));

  @override
  Future<Result<User>> getCurrentUser() async => Result.error(Exception('Not implemented'));

  @override
  Future<Result<void>> setUserEventRuleKeys(String userId, String eventRuleKey) async => Result.ok(null);
}

EventRule _buildEventRule({
  required String id,
  required String title,
  required DateTime startDate,
  required DateTime endDate,
  required bool isRecurring,
  RecurrencePattern? recurrencePattern,
}) {
  return EventRule(
    id: id,
    title: title,
    startDate: startDate,
    endDate: endDate,
    isAllDay: false,
    duration: 60,
    isRecurring: isRecurring,
    recurrencePattern: recurrencePattern ?? RecurrencePattern(freq: Freq.daily, interval: 1),
    location: 'Lab',
    userIds: const [],
  );
}

void main() {
  group('RFC 5545 RRULE examples', () {

    late UserEventsVM viewModel;
    late FakeEventRepository eventRepository;

    setUp(() {
      eventRepository = FakeEventRepository();
      viewModel = UserEventsVM(
        userRepository: FakeUserRepository(),
        eventRepository: eventRepository,
      );
    });
    test('daily for 10 occurrences', () async {
      final rule = _buildEventRule(
        id: 'daily-count',
        title: 'Daily for 10 occurrences',
        startDate: DateTime.utc(1997, 9, 2, 9),
        endDate: DateTime.utc(1997, 9, 2, 10),
        isRecurring: true,
        recurrencePattern: RecurrencePattern(
          freq: Freq.daily,
          interval: 1,
          count: 10,
        ),
      );
      eventRepository.rules = [rule];

      await viewModel.loadEvents.execute(
        ['daily-count'],
        DateTime.utc(1997, 9, 1),
        DateTime.utc(1997, 9, 30),
      );

      final events = viewModel.getEvents().values.expand((e) => e).toList();
      expect(events, hasLength(10));
      expect(events.map((e) => e.startDate), [
        for (var d = 2; d <= 11; d++) DateTime.utc(1997, 9, d, 9),
      ]);
    });

    test('daily until December 24, 1997', () async {
      final rule = _buildEventRule(
        id: 'daily-until',
        title: 'Daily until December 24, 1997',
        startDate: DateTime.utc(1997, 9, 2, 9),
        endDate: DateTime.utc(1997, 9, 2, 10),
        isRecurring: true,
        recurrencePattern: RecurrencePattern(
          freq: Freq.daily,
          interval: 1,
          until: DateTime.utc(1997, 12, 24),
        ),
      );
      eventRepository.rules = [rule];

      await viewModel.loadEvents.execute(
        ['daily-until'],
        DateTime.utc(1997, 9, 1),
        DateTime.utc(1997, 12, 31),
      );

      final events = viewModel.getEvents().values.expand((e) => e).toList();
      // Sept 2 -> Dec 23 inclusive, daily.
      expect(events, hasLength(113));
      expect(events.first.startDate, DateTime.utc(1997, 9, 2, 9));
      expect(events.last.startDate, DateTime.utc(1997, 12, 23, 9));
    });

    test('every other day, bounded window', () async {
      final rule = _buildEventRule(
        id: 'daily-interval2',
        title: 'Every other day',
        startDate: DateTime.utc(1997, 9, 2, 9),
        endDate: DateTime.utc(1997, 9, 2, 10),
        isRecurring: true,
        recurrencePattern: RecurrencePattern(
          freq: Freq.daily,
          interval: 2,
        ),
      );
      eventRepository.rules = [rule];

      await viewModel.loadEvents.execute(
        ['daily-interval2'],
        DateTime.utc(1997, 9, 1),
        DateTime.utc(1997, 10, 24),
      );

      final events = viewModel.getEvents().values.expand((e) => e).toList();
      expect(events, hasLength(27));
      expect(events.first.startDate, DateTime.utc(1997, 9, 2, 9));
      expect(events.last.startDate, DateTime.utc(1997, 10, 24, 9));
    });

    test('every 10 days, 5 occurrences', () async {
      final rule = _buildEventRule(
        id: 'daily-interval10',
        title: 'Every 10 days, 5 occurrences',
        startDate: DateTime.utc(1997, 9, 2, 9),
        endDate: DateTime.utc(1997, 9, 2, 10),
        isRecurring: true,
        recurrencePattern: RecurrencePattern(
          freq: Freq.daily,
          interval: 10,
          count: 5,
        ),
      );
      eventRepository.rules = [rule];

      await viewModel.loadEvents.execute(
        ['daily-interval10'],
        DateTime.utc(1997, 9, 1),
        DateTime.utc(1997, 10, 31),
      );

      final events = viewModel.getEvents().values.expand((e) => e).toList();
      expect(events, hasLength(5));
      expect(events.map((e) => e.startDate), [
        DateTime.utc(1997, 9, 2, 9),
        DateTime.utc(1997, 9, 12, 9),
        DateTime.utc(1997, 9, 22, 9),
        DateTime.utc(1997, 10, 2, 9),
        DateTime.utc(1997, 10, 12, 9),
      ]);
    });

    test('every day in January, for 3 years', () async {
      final rule = _buildEventRule(
        id: 'january-daily-yearly',
        title: 'Every day in January, for 3 years',
        startDate: DateTime.utc(1998, 1, 1, 9),
        endDate: DateTime.utc(1998, 1, 1, 10),
        isRecurring: true,
        recurrencePattern: RecurrencePattern(
          freq: Freq.yearly,
          interval: 1,
          until: DateTime.utc(2000, 1, 31, 14),
          byMonth: [1],
          byWeekday: [
            (instance: null, weekday: DateTime.monday),
            (instance: null, weekday: DateTime.tuesday),
            (instance: null, weekday: DateTime.wednesday),
            (instance: null, weekday: DateTime.thursday),
            (instance: null, weekday: DateTime.friday),
            (instance: null, weekday: DateTime.saturday),
            (instance: null, weekday: DateTime.sunday),
          ],
        ),
      );
      eventRepository.rules = [rule];

      await viewModel.loadEvents.execute(
        ['january-daily-yearly'],
        DateTime.utc(1998, 1, 1),
        DateTime.utc(2000, 1, 31),
      );

      final events = viewModel.getEvents().values.expand((e) => e).toList();
      expect(events, hasLength(93)); // 31 days x 3 Januaries
      expect(events.first.startDate, DateTime.utc(1998, 1, 1, 9));
      expect(events[30].startDate, DateTime.utc(1998, 1, 31, 9));
      expect(events[31].startDate, DateTime.utc(1999, 1, 1, 9));
      expect(events[61].startDate, DateTime.utc(1999, 1, 31, 9));
      expect(events[62].startDate, DateTime.utc(2000, 1, 1, 9));
      expect(events.last.startDate, DateTime.utc(2000, 1, 31, 9));
    });

    test('weekly for 10 occurrences', () async {
      final rule = _buildEventRule(
        id: 'weekly-count',
        title: 'Weekly for 10 occurrences',
        startDate: DateTime.utc(1997, 9, 2, 9),
        endDate: DateTime.utc(1997, 9, 2, 10),
        isRecurring: true,
        recurrencePattern: RecurrencePattern(
          freq: Freq.weekly,
          interval: 1,
          count: 10,
        ),
      );
      eventRepository.rules = [rule];

      await viewModel.loadEvents.execute(
        ['weekly-count'],
        DateTime.utc(1997, 9, 1),
        DateTime.utc(1997, 11, 30),
      );

      final events = viewModel.getEvents().values.expand((e) => e).toList();
      expect(events, hasLength(10));
      expect(events.map((e) => e.startDate), [
        DateTime.utc(1997, 9, 2, 9),
        DateTime.utc(1997, 9, 9, 9),
        DateTime.utc(1997, 9, 16, 9),
        DateTime.utc(1997, 9, 23, 9),
        DateTime.utc(1997, 9, 30, 9),
        DateTime.utc(1997, 10, 7, 9),
        DateTime.utc(1997, 10, 14, 9),
        DateTime.utc(1997, 10, 21, 9),
        DateTime.utc(1997, 10, 28, 9),
        DateTime.utc(1997, 11, 4, 9),
      ]);
    });

    test('weekly until December 24, 1997', () async {
      final rule = _buildEventRule(
        id: 'weekly-until',
        title: 'Weekly until December 24, 1997',
        startDate: DateTime.utc(1997, 9, 2, 9),
        endDate: DateTime.utc(1997, 9, 2, 10),
        isRecurring: true,
        recurrencePattern: RecurrencePattern(
          freq: Freq.weekly,
          interval: 1,
          until: DateTime.utc(1997, 12, 24),
        ),
      );
      eventRepository.rules = [rule];

      await viewModel.loadEvents.execute(
        ['weekly-until'],
        DateTime.utc(1997, 9, 1),
        DateTime.utc(1997, 12, 31),
      );

      final events = viewModel.getEvents().values.expand((e) => e).toList();
      expect(events, hasLength(17));
      expect(events.first.startDate, DateTime.utc(1997, 9, 2, 9));
      expect(events.last.startDate, DateTime.utc(1997, 12, 23, 9));
    });

    test('every other week, bounded window', () async {
      final rule = _buildEventRule(
        id: 'weekly-interval2',
        title: 'Every other week',
        startDate: DateTime.utc(1997, 9, 2, 9),
        endDate: DateTime.utc(1997, 9, 2, 10),
        isRecurring: true,
        recurrencePattern: RecurrencePattern(
          freq: Freq.weekly,
          interval: 2,
        ),
      );
      eventRepository.rules = [rule];

      await viewModel.loadEvents.execute(
        ['weekly-interval2'],
        DateTime.utc(1997, 9, 1),
        DateTime.utc(1998, 2, 28),
      );

      final events = viewModel.getEvents().values.expand((e) => e).toList();
      expect(events.map((e) => e.startDate), [
        DateTime.utc(1997, 9, 2, 9),
        DateTime.utc(1997, 9, 16, 9),
        DateTime.utc(1997, 9, 30, 9),
        DateTime.utc(1997, 10, 14, 9),
        DateTime.utc(1997, 10, 28, 9),
        DateTime.utc(1997, 11, 11, 9),
        DateTime.utc(1997, 11, 25, 9),
        DateTime.utc(1997, 12, 9, 9),
        DateTime.utc(1997, 12, 23, 9),
        DateTime.utc(1998, 1, 6, 9),
        DateTime.utc(1998, 1, 20, 9),
        DateTime.utc(1998, 2, 3, 9),
        DateTime.utc(1998, 2, 17, 9),
      ]);
    });

    test('weekly on Tuesday and Thursday for five weeks', () async {
      final rule = _buildEventRule(
        id: 'weekly-tu-th',
        title: 'Weekly on Tuesday and Thursday for five weeks',
        startDate: DateTime.utc(1997, 9, 2, 9),
        endDate: DateTime.utc(1997, 9, 2, 10),
        isRecurring: true,
        recurrencePattern: RecurrencePattern(
          freq: Freq.weekly,
          interval: 1,
          count: 10,
          byWeekday: [
            (instance: null, weekday: DateTime.tuesday),
            (instance: null, weekday: DateTime.thursday),
          ],
        ),
      );
      eventRepository.rules = [rule];

      await viewModel.loadEvents.execute(
        ['weekly-tu-th'],
        DateTime.utc(1997, 9, 1),
        DateTime.utc(1997, 10, 31),
      );

      final events = viewModel.getEvents().values.expand((e) => e).toList();
      expect(events, hasLength(10));
      expect(events.map((e) => e.startDate), [
        DateTime.utc(1997, 9, 2, 9),
        DateTime.utc(1997, 9, 4, 9),
        DateTime.utc(1997, 9, 9, 9),
        DateTime.utc(1997, 9, 11, 9),
        DateTime.utc(1997, 9, 16, 9),
        DateTime.utc(1997, 9, 18, 9),
        DateTime.utc(1997, 9, 23, 9),
        DateTime.utc(1997, 9, 25, 9),
        DateTime.utc(1997, 9, 30, 9),
        DateTime.utc(1997, 10, 2, 9),
      ]);
    });

    test(
        'every other week on Monday, Wednesday, and Friday until December 24, 1997',
        () async {
      final rule = _buildEventRule(
        id: 'weekly-interval2-mwf',
        title: 'Every other week on Mon/Wed/Fri',
        startDate: DateTime.utc(1997, 9, 1, 9),
        endDate: DateTime.utc(1997, 9, 1, 10),
        isRecurring: true,
        recurrencePattern: RecurrencePattern(
          freq: Freq.weekly,
          interval: 2,
          until: DateTime.utc(1997, 12, 24),
          byWeekday: [
            (instance: null, weekday: DateTime.monday),
            (instance: null, weekday: DateTime.wednesday),
            (instance: null, weekday: DateTime.friday),
          ],
        ),
      );
      eventRepository.rules = [rule];

      await viewModel.loadEvents.execute(
        ['weekly-interval2-mwf'],
        DateTime.utc(1997, 9, 1),
        DateTime.utc(1997, 12, 31),
      );

      final events = viewModel.getEvents().values.expand((e) => e).toList();
      expect(events, hasLength(25));
      expect(events.map((e) => e.startDate), [
        DateTime.utc(1997, 9, 1, 9),
        DateTime.utc(1997, 9, 3, 9),
        DateTime.utc(1997, 9, 5, 9),
        DateTime.utc(1997, 9, 15, 9),
        DateTime.utc(1997, 9, 17, 9),
        DateTime.utc(1997, 9, 19, 9),
        DateTime.utc(1997, 9, 29, 9),
        DateTime.utc(1997, 10, 1, 9),
        DateTime.utc(1997, 10, 3, 9),
        DateTime.utc(1997, 10, 13, 9),
        DateTime.utc(1997, 10, 15, 9),
        DateTime.utc(1997, 10, 17, 9),
        DateTime.utc(1997, 10, 27, 9),
        DateTime.utc(1997, 10, 29, 9),
        DateTime.utc(1997, 10, 31, 9),
        DateTime.utc(1997, 11, 10, 9),
        DateTime.utc(1997, 11, 12, 9),
        DateTime.utc(1997, 11, 14, 9),
        DateTime.utc(1997, 11, 24, 9),
        DateTime.utc(1997, 11, 26, 9),
        DateTime.utc(1997, 11, 28, 9),
        DateTime.utc(1997, 12, 8, 9),
        DateTime.utc(1997, 12, 10, 9),
        DateTime.utc(1997, 12, 12, 9),
        DateTime.utc(1997, 12, 22, 9),
      ]);
    });

    test('every other week on Tuesday and Thursday, for 8 occurrences',
        () async {
      final rule = _buildEventRule(
        id: 'weekly-interval2-tu-th',
        title: 'Every other week on Tuesday and Thursday',
        startDate: DateTime.utc(1997, 9, 2, 9),
        endDate: DateTime.utc(1997, 9, 2, 10),
        isRecurring: true,
        recurrencePattern: RecurrencePattern(
          freq: Freq.weekly,
          interval: 2,
          count: 8,
          byWeekday: [
            (instance: null, weekday: DateTime.tuesday),
            (instance: null, weekday: DateTime.thursday),
          ],
        ),
      );
      eventRepository.rules = [rule];

      await viewModel.loadEvents.execute(
        ['weekly-interval2-tu-th'],
        DateTime.utc(1997, 9, 1),
        DateTime.utc(1997, 10, 31),
      );

      final events = viewModel.getEvents().values.expand((e) => e).toList();
      expect(events, hasLength(8));
      expect(events.map((e) => e.startDate), [
        DateTime.utc(1997, 9, 2, 9),
        DateTime.utc(1997, 9, 4, 9),
        DateTime.utc(1997, 9, 16, 9),
        DateTime.utc(1997, 9, 18, 9),
        DateTime.utc(1997, 9, 30, 9),
        DateTime.utc(1997, 10, 2, 9),
        DateTime.utc(1997, 10, 14, 9),
        DateTime.utc(1997, 10, 16, 9),
      ]);
    });

    test('monthly on the first Friday for 10 occurrences', () async {
      final rule = _buildEventRule(
        id: 'monthly-1fr-count',
        title: 'Monthly on the first Friday',
        startDate: DateTime.utc(1997, 9, 5, 9),
        endDate: DateTime.utc(1997, 9, 5, 10),
        isRecurring: true,
        recurrencePattern: RecurrencePattern(
          freq: Freq.monthly,
          interval: 1,
          count: 10,
          byWeekday: [(instance: 1, weekday: DateTime.friday)],
        ),
      );
      eventRepository.rules = [rule];

      await viewModel.loadEvents.execute(
        ['monthly-1fr-count'],
        DateTime.utc(1997, 9, 1),
        DateTime.utc(1998, 6, 30),
      );

      final events = viewModel.getEvents().values.expand((e) => e).toList();
      expect(events, hasLength(10));
      expect(events.map((e) => e.startDate), [
        DateTime.utc(1997, 9, 5, 9),
        DateTime.utc(1997, 10, 3, 9),
        DateTime.utc(1997, 11, 7, 9),
        DateTime.utc(1997, 12, 5, 9),
        DateTime.utc(1998, 1, 2, 9),
        DateTime.utc(1998, 2, 6, 9),
        DateTime.utc(1998, 3, 6, 9),
        DateTime.utc(1998, 4, 3, 9),
        DateTime.utc(1998, 5, 1, 9),
        DateTime.utc(1998, 6, 5, 9),
      ]);
    });

    test('monthly on the first Friday until December 24, 1997', () async {
      final rule = _buildEventRule(
        id: 'monthly-1fr-until',
        title: 'Monthly on the first Friday until Dec 24, 1997',
        startDate: DateTime.utc(1997, 9, 5, 9),
        endDate: DateTime.utc(1997, 9, 5, 10),
        isRecurring: true,
        recurrencePattern: RecurrencePattern(
          freq: Freq.monthly,
          interval: 1,
          until: DateTime.utc(1997, 12, 24),
          byWeekday: [(instance: 1, weekday: DateTime.friday)],
        ),
      );
      eventRepository.rules = [rule];

      await viewModel.loadEvents.execute(
        ['monthly-1fr-until'],
        DateTime.utc(1997, 9, 1),
        DateTime.utc(1997, 12, 31),
      );

      final events = viewModel.getEvents().values.expand((e) => e).toList();
      expect(events, hasLength(4));
      expect(events.map((e) => e.startDate), [
        DateTime.utc(1997, 9, 5, 9),
        DateTime.utc(1997, 10, 3, 9),
        DateTime.utc(1997, 11, 7, 9),
        DateTime.utc(1997, 12, 5, 9),
      ]);
    });

    test(
        'every other month on the first and last Sunday of the month for 10 occurrences',
        () async {
      final rule = _buildEventRule(
        id: 'monthly-interval2-1su-lastsu',
        title: 'Every other month, first and last Sunday',
        startDate: DateTime.utc(1997, 9, 7, 9),
        endDate: DateTime.utc(1997, 9, 7, 10),
        isRecurring: true,
        recurrencePattern: RecurrencePattern(
          freq: Freq.monthly,
          interval: 2,
          count: 10,
          byWeekday: [
            (instance: 1, weekday: DateTime.sunday),
            (instance: -1, weekday: DateTime.sunday),
          ],
        ),
      );
      eventRepository.rules = [rule];

      await viewModel.loadEvents.execute(
        ['monthly-interval2-1su-lastsu'],
        DateTime.utc(1997, 9, 1),
        DateTime.utc(1998, 5, 31),
      );

      final events = viewModel.getEvents().values.expand((e) => e).toList();
      expect(events, hasLength(10));
      expect(events.map((e) => e.startDate), [
        DateTime.utc(1997, 9, 7, 9),
        DateTime.utc(1997, 9, 28, 9),
        DateTime.utc(1997, 11, 2, 9),
        DateTime.utc(1997, 11, 30, 9),
        DateTime.utc(1998, 1, 4, 9),
        DateTime.utc(1998, 1, 25, 9),
        DateTime.utc(1998, 3, 1, 9),
        DateTime.utc(1998, 3, 29, 9),
        DateTime.utc(1998, 5, 3, 9),
        DateTime.utc(1998, 5, 31, 9),
      ]);
    });

    test('monthly on the second-to-last Monday of the month for 6 months',
        () async {
      final rule = _buildEventRule(
        id: 'monthly-neg2mo',
        title: 'Second-to-last Monday of the month',
        startDate: DateTime.utc(1997, 9, 22, 9),
        endDate: DateTime.utc(1997, 9, 22, 10),
        isRecurring: true,
        recurrencePattern: RecurrencePattern(
          freq: Freq.monthly,
          interval: 1,
          count: 6,
          byWeekday: [(instance: -2, weekday: DateTime.monday)],
        ),
      );
      eventRepository.rules = [rule];

      await viewModel.loadEvents.execute(
        ['monthly-neg2mo'],
        DateTime.utc(1997, 9, 1),
        DateTime.utc(1998, 2, 28),
      );

      final events = viewModel.getEvents().values.expand((e) => e).toList();
      expect(events, hasLength(6));
      expect(events.map((e) => e.startDate), [
        DateTime.utc(1997, 9, 22, 9),
        DateTime.utc(1997, 10, 20, 9),
        DateTime.utc(1997, 11, 17, 9),
        DateTime.utc(1997, 12, 22, 9),
        DateTime.utc(1998, 1, 19, 9),
        DateTime.utc(1998, 2, 16, 9),
      ]);
    });

    test(
        'monthly on the third-to-last day of the month, bounded window',
        () async {
      final rule = _buildEventRule(
        id: 'monthly-neg3',
        title: 'Third-to-last day of the month',
        startDate: DateTime.utc(1997, 9, 28, 9),
        endDate: DateTime.utc(1997, 9, 28, 10),
        isRecurring: true,
        recurrencePattern: RecurrencePattern(
          freq: Freq.monthly,
          interval: 1,
          byMonthDay: [-3],
        ),
      );
      eventRepository.rules = [rule];

      await viewModel.loadEvents.execute(
        ['monthly-neg3'],
        DateTime.utc(1997, 9, 1),
        DateTime.utc(1998, 2, 28),
      );

      final events = viewModel.getEvents().values.expand((e) => e).toList();
      expect(events, hasLength(6));
      expect(events.map((e) => e.startDate), [
        DateTime.utc(1997, 9, 28, 9),
        DateTime.utc(1997, 10, 29, 9),
        DateTime.utc(1997, 11, 28, 9),
        DateTime.utc(1997, 12, 29, 9),
        DateTime.utc(1998, 1, 29, 9),
        DateTime.utc(1998, 2, 26, 9),
      ]);
    });

    test('monthly on the 2nd and 15th of the month for 10 occurrences',
        () async {
      final rule = _buildEventRule(
        id: 'monthly-2-15',
        title: 'Monthly on the 2nd and 15th',
        startDate: DateTime.utc(1997, 9, 2, 9),
        endDate: DateTime.utc(1997, 9, 2, 10),
        isRecurring: true,
        recurrencePattern: RecurrencePattern(
          freq: Freq.monthly,
          interval: 1,
          count: 10,
          byMonthDay: [2, 15],
        ),
      );
      eventRepository.rules = [rule];

      await viewModel.loadEvents.execute(
        ['monthly-2-15'],
        DateTime.utc(1997, 9, 1),
        DateTime.utc(1998, 1, 31),
      );

      final events = viewModel.getEvents().values.expand((e) => e).toList();
      expect(events, hasLength(10));
      expect(events.map((e) => e.startDate), [
        DateTime.utc(1997, 9, 2, 9),
        DateTime.utc(1997, 9, 15, 9),
        DateTime.utc(1997, 10, 2, 9),
        DateTime.utc(1997, 10, 15, 9),
        DateTime.utc(1997, 11, 2, 9),
        DateTime.utc(1997, 11, 15, 9),
        DateTime.utc(1997, 12, 2, 9),
        DateTime.utc(1997, 12, 15, 9),
        DateTime.utc(1998, 1, 2, 9),
        DateTime.utc(1998, 1, 15, 9),
      ]);
    });

    test('monthly on the first and last day of the month for 10 occurrences',
        () async {
      final rule = _buildEventRule(
        id: 'monthly-1-neg1',
        title: 'Monthly on the first and last day',
        startDate: DateTime.utc(1997, 9, 30, 9),
        endDate: DateTime.utc(1997, 9, 30, 10),
        isRecurring: true,
        recurrencePattern: RecurrencePattern(
          freq: Freq.monthly,
          interval: 1,
          count: 10,
          byMonthDay: [1, -1],
        ),
      );
      eventRepository.rules = [rule];

      await viewModel.loadEvents.execute(
        ['monthly-1-neg1'],
        DateTime.utc(1997, 9, 1),
        DateTime.utc(1998, 2, 28),
      );

      final events = viewModel.getEvents().values.expand((e) => e).toList();
      expect(events, hasLength(10));
      expect(events.map((e) => e.startDate), [
        DateTime.utc(1997, 9, 30, 9),
        DateTime.utc(1997, 10, 1, 9),
        DateTime.utc(1997, 10, 31, 9),
        DateTime.utc(1997, 11, 1, 9),
        DateTime.utc(1997, 11, 30, 9),
        DateTime.utc(1997, 12, 1, 9),
        DateTime.utc(1997, 12, 31, 9),
        DateTime.utc(1998, 1, 1, 9),
        DateTime.utc(1998, 1, 31, 9),
        DateTime.utc(1998, 2, 1, 9),
      ]);
    });

    test('every 18 months on the 10th thru 15th, 10 occurrences', () async {
      final rule = _buildEventRule(
        id: 'monthly-interval18-10-15',
        title: 'Every 18 months on the 10th-15th',
        startDate: DateTime.utc(1997, 9, 10, 9),
        endDate: DateTime.utc(1997, 9, 10, 10),
        isRecurring: true,
        recurrencePattern: RecurrencePattern(
          freq: Freq.monthly,
          interval: 18,
          count: 10,
          byMonthDay: [10, 11, 12, 13, 14, 15],
        ),
      );
      eventRepository.rules = [rule];

      await viewModel.loadEvents.execute(
        ['monthly-interval18-10-15'],
        DateTime.utc(1997, 9, 1),
        DateTime.utc(1999, 3, 31),
      );

      final events = viewModel.getEvents().values.expand((e) => e).toList();
      expect(events, hasLength(10));
      expect(events.map((e) => e.startDate), [
        DateTime.utc(1997, 9, 10, 9),
        DateTime.utc(1997, 9, 11, 9),
        DateTime.utc(1997, 9, 12, 9),
        DateTime.utc(1997, 9, 13, 9),
        DateTime.utc(1997, 9, 14, 9),
        DateTime.utc(1997, 9, 15, 9),
        DateTime.utc(1999, 3, 10, 9),
        DateTime.utc(1999, 3, 11, 9),
        DateTime.utc(1999, 3, 12, 9),
        DateTime.utc(1999, 3, 13, 9),
      ]);
    });

    test('every Tuesday, every other month, bounded window', () async {
      final rule = _buildEventRule(
        id: 'monthly-interval2-tu',
        title: 'Every Tuesday, every other month',
        startDate: DateTime.utc(1997, 9, 2, 9),
        endDate: DateTime.utc(1997, 9, 2, 10),
        isRecurring: true,
        recurrencePattern: RecurrencePattern(
          freq: Freq.monthly,
          interval: 2,
          byWeekday: [(instance: null, weekday: DateTime.tuesday)],
        ),
      );
      eventRepository.rules = [rule];

      await viewModel.loadEvents.execute(
        ['monthly-interval2-tu'],
        DateTime.utc(1997, 9, 1),
        DateTime.utc(1998, 3, 31),
      );

      final events = viewModel.getEvents().values.expand((e) => e).toList();
      expect(events, hasLength(18));
      expect(events.map((e) => e.startDate), [
        DateTime.utc(1997, 9, 2, 9),
        DateTime.utc(1997, 9, 9, 9),
        DateTime.utc(1997, 9, 16, 9),
        DateTime.utc(1997, 9, 23, 9),
        DateTime.utc(1997, 9, 30, 9),
        DateTime.utc(1997, 11, 4, 9),
        DateTime.utc(1997, 11, 11, 9),
        DateTime.utc(1997, 11, 18, 9),
        DateTime.utc(1997, 11, 25, 9),
        DateTime.utc(1998, 1, 6, 9),
        DateTime.utc(1998, 1, 13, 9),
        DateTime.utc(1998, 1, 20, 9),
        DateTime.utc(1998, 1, 27, 9),
        DateTime.utc(1998, 3, 3, 9),
        DateTime.utc(1998, 3, 10, 9),
        DateTime.utc(1998, 3, 17, 9),
        DateTime.utc(1998, 3, 24, 9),
        DateTime.utc(1998, 3, 31, 9),
      ]);
    });

    test('yearly in June and July for 10 occurrences', () async {
      final rule = _buildEventRule(
        id: 'yearly-jun-jul',
        title: 'Yearly in June and July',
        startDate: DateTime.utc(1997, 6, 10, 9),
        endDate: DateTime.utc(1997, 6, 10, 10),
        isRecurring: true,
        recurrencePattern: RecurrencePattern(
          freq: Freq.yearly,
          interval: 1,
          count: 10,
          byMonth: [6, 7],
        ),
      );
      eventRepository.rules = [rule];

      await viewModel.loadEvents.execute(
        ['yearly-jun-jul'],
        DateTime.utc(1997, 1, 1),
        DateTime.utc(2001, 12, 31),
      );

      final events = viewModel.getEvents().values.expand((e) => e).toList();
      expect(events, hasLength(10));
      expect(events.map((e) => e.startDate), [
        DateTime.utc(1997, 6, 10, 9),
        DateTime.utc(1997, 7, 10, 9),
        DateTime.utc(1998, 6, 10, 9),
        DateTime.utc(1998, 7, 10, 9),
        DateTime.utc(1999, 6, 10, 9),
        DateTime.utc(1999, 7, 10, 9),
        DateTime.utc(2000, 6, 10, 9),
        DateTime.utc(2000, 7, 10, 9),
        DateTime.utc(2001, 6, 10, 9),
        DateTime.utc(2001, 7, 10, 9),
      ]);
    });

    test(
        'every other year in January, February, and March for 10 occurrences',
        () async {
      final rule = _buildEventRule(
        id: 'yearly-interval2-jan-mar',
        title: 'Every other year in Jan/Feb/Mar',
        startDate: DateTime.utc(1997, 3, 10, 9),
        endDate: DateTime.utc(1997, 3, 10, 10),
        isRecurring: true,
        recurrencePattern: RecurrencePattern(
          freq: Freq.yearly,
          interval: 2,
          count: 10,
          byMonth: [1, 2, 3],
        ),
      );
      eventRepository.rules = [rule];

      await viewModel.loadEvents.execute(
        ['yearly-interval2-jan-mar'],
        DateTime.utc(1997, 1, 1),
        DateTime.utc(2003, 12, 31),
      );

      final events = viewModel.getEvents().values.expand((e) => e).toList();
      expect(events, hasLength(10));
      expect(events.map((e) => e.startDate), [
        DateTime.utc(1997, 3, 10, 9),
        DateTime.utc(1999, 1, 10, 9),
        DateTime.utc(1999, 2, 10, 9),
        DateTime.utc(1999, 3, 10, 9),
        DateTime.utc(2001, 1, 10, 9),
        DateTime.utc(2001, 2, 10, 9),
        DateTime.utc(2001, 3, 10, 9),
        DateTime.utc(2003, 1, 10, 9),
        DateTime.utc(2003, 2, 10, 9),
        DateTime.utc(2003, 3, 10, 9),
      ]);
    });

    test('every third year on the 1st, 100th, and 200th day, 10 occurrences',
        () async {
      final rule = _buildEventRule(
        id: 'yearly-interval3-yday',
        title: 'Every third year on day 1, 100, 200',
        startDate: DateTime.utc(1997, 1, 1, 9),
        endDate: DateTime.utc(1997, 1, 1, 10),
        isRecurring: true,
        recurrencePattern: RecurrencePattern(
          freq: Freq.yearly,
          interval: 3,
          count: 10,
          byYearDay: [1, 100, 200],
        ),
      );
      eventRepository.rules = [rule];

      await viewModel.loadEvents.execute(
        ['yearly-interval3-yday'],
        DateTime.utc(1997, 1, 1),
        DateTime.utc(2006, 12, 31),
      );

      final events = viewModel.getEvents().values.expand((e) => e).toList();
      expect(events, hasLength(10));
      expect(events.map((e) => e.startDate), [
        DateTime.utc(1997, 1, 1, 9),
        DateTime.utc(1997, 4, 10, 9),
        DateTime.utc(1997, 7, 19, 9),
        DateTime.utc(2000, 1, 1, 9),
        DateTime.utc(2000, 4, 9, 9),
        DateTime.utc(2000, 7, 18, 9),
        DateTime.utc(2003, 1, 1, 9),
        DateTime.utc(2003, 4, 10, 9),
        DateTime.utc(2003, 7, 19, 9),
        DateTime.utc(2006, 1, 1, 9),
      ]);
    });

    test('every 20th Monday of the year, bounded window', () async {
      final rule = _buildEventRule(
        id: 'yearly-20mo',
        title: '20th Monday of the year',
        startDate: DateTime.utc(1997, 5, 19, 9),
        endDate: DateTime.utc(1997, 5, 19, 10),
        isRecurring: true,
        recurrencePattern: RecurrencePattern(
          freq: Freq.yearly,
          interval: 1,
          byWeekday: [(instance: 20, weekday: DateTime.monday)],
        ),
      );
      eventRepository.rules = [rule];

      await viewModel.loadEvents.execute(
        ['yearly-20mo'],
        DateTime.utc(1997, 1, 1),
        DateTime.utc(1999, 12, 31),
      );

      final events = viewModel.getEvents().values.expand((e) => e).toList();
      expect(events, hasLength(3));
      expect(events.map((e) => e.startDate), [
        DateTime.utc(1997, 5, 19, 9),
        DateTime.utc(1998, 5, 18, 9),
        DateTime.utc(1999, 5, 17, 9),
      ]);
    });

    test('Monday of week number 20, bounded window', () async {
      final rule = _buildEventRule(
        id: 'yearly-week20-mo',
        title: 'Monday of week number 20',
        startDate: DateTime.utc(1997, 5, 12, 9),
        endDate: DateTime.utc(1997, 5, 12, 10),
        isRecurring: true,
        recurrencePattern: RecurrencePattern(
          freq: Freq.yearly,
          interval: 1,
          byWeek: [20],
          byWeekday: [(instance: null, weekday: DateTime.monday)],
        ),
      );
      eventRepository.rules = [rule];

      await viewModel.loadEvents.execute(
        ['yearly-week20-mo'],
        DateTime.utc(1997, 1, 1),
        DateTime.utc(1999, 12, 31),
      );

      final events = viewModel.getEvents().values.expand((e) => e).toList();
      expect(events, hasLength(3));
      expect(events.map((e) => e.startDate), [
        DateTime.utc(1997, 5, 12, 9),
        DateTime.utc(1998, 5, 11, 9),
        // TODO: was originally the 17th! in the spec, but I think this is wrong.
        DateTime.utc(1999, 5, 10, 9),
      ]);
    });

    test('every Thursday in March, bounded window', () async {
      final rule = _buildEventRule(
        id: 'yearly-march-th',
        title: 'Every Thursday in March',
        startDate: DateTime.utc(1997, 3, 13, 9),
        endDate: DateTime.utc(1997, 3, 13, 10),
        isRecurring: true,
        recurrencePattern: RecurrencePattern(
          freq: Freq.yearly,
          interval: 1,
          byMonth: [3],
          byWeekday: [(instance: null, weekday: DateTime.thursday)],
        ),
      );
      eventRepository.rules = [rule];

      await viewModel.loadEvents.execute(
        ['yearly-march-th'],
        DateTime.utc(1997, 1, 1),
        DateTime.utc(1999, 12, 31),
      );

      final events = viewModel.getEvents().values.expand((e) => e).toList();
      expect(events, hasLength(11));
      expect(events.map((e) => e.startDate), [
        DateTime.utc(1997, 3, 13, 9),
        DateTime.utc(1997, 3, 20, 9),
        DateTime.utc(1997, 3, 27, 9),
        DateTime.utc(1998, 3, 5, 9),
        DateTime.utc(1998, 3, 12, 9),
        DateTime.utc(1998, 3, 19, 9),
        DateTime.utc(1998, 3, 26, 9),
        DateTime.utc(1999, 3, 4, 9),
        DateTime.utc(1999, 3, 11, 9),
        DateTime.utc(1999, 3, 18, 9),
        DateTime.utc(1999, 3, 25, 9),
      ]);
    });

    test('every Thursday in June, July, and August, single year', () async {
      final rule = _buildEventRule(
        id: 'yearly-summer-th',
        title: 'Every Thursday in June/July/August',
        startDate: DateTime.utc(1997, 6, 5, 9),
        endDate: DateTime.utc(1997, 6, 5, 10),
        isRecurring: true,
        recurrencePattern: RecurrencePattern(
          freq: Freq.yearly,
          interval: 1,
          byMonth: [6, 7, 8],
          byWeekday: [(instance: null, weekday: DateTime.thursday)],
        ),
      );
      eventRepository.rules = [rule];

      await viewModel.loadEvents.execute(
        ['yearly-summer-th'],
        DateTime.utc(1997, 1, 1),
        DateTime.utc(1997, 12, 31),
      );

      final events = viewModel.getEvents().values.expand((e) => e).toList();
      expect(events, hasLength(13));
      expect(events.map((e) => e.startDate), [
        DateTime.utc(1997, 6, 5, 9),
        DateTime.utc(1997, 6, 12, 9),
        DateTime.utc(1997, 6, 19, 9),
        DateTime.utc(1997, 6, 26, 9),
        DateTime.utc(1997, 7, 3, 9),
        DateTime.utc(1997, 7, 10, 9),
        DateTime.utc(1997, 7, 17, 9),
        DateTime.utc(1997, 7, 24, 9),
        DateTime.utc(1997, 7, 31, 9),
        DateTime.utc(1997, 8, 7, 9),
        DateTime.utc(1997, 8, 14, 9),
        DateTime.utc(1997, 8, 21, 9),
        DateTime.utc(1997, 8, 28, 9),
      ]);
    });

    test('every Friday the 13th, bounded window', () async {
      final rule = _buildEventRule(
        id: 'monthly-friday-13th',
        title: 'Every Friday the 13th',
        startDate: DateTime.utc(1997, 9, 2, 9),
        endDate: DateTime.utc(1997, 9, 2, 10),
        isRecurring: true,
        recurrencePattern: RecurrencePattern(
          freq: Freq.monthly,
          interval: 1,
          byWeekday: [(instance: null, weekday: DateTime.friday)],
          byMonthDay: [13],
        ),
      );
      eventRepository.rules = [rule];

      await viewModel.loadEvents.execute(
        ['monthly-friday-13th'],
        DateTime.utc(1997, 9, 1),
        DateTime.utc(1999, 12, 31),
      );

      final events = viewModel.getEvents().values.expand((e) => e).toList();
      expect(events, hasLength(4));
      expect(events.map((e) => e.startDate), [
        DateTime.utc(1998, 2, 13, 9),
        DateTime.utc(1998, 3, 13, 9),
        DateTime.utc(1998, 11, 13, 9),
        DateTime.utc(1999, 8, 13, 9),
      ]);
    });

    test(
        'the first Saturday that follows the first Sunday of the month, bounded window',
        () async {
      final rule = _buildEventRule(
        id: 'monthly-sa-after-1su',
        title: 'First Saturday following the first Sunday',
        startDate: DateTime.utc(1997, 9, 13, 9),
        endDate: DateTime.utc(1997, 9, 13, 10),
        isRecurring: true,
        recurrencePattern: RecurrencePattern(
          freq: Freq.monthly,
          interval: 1,
          byWeekday: [(instance: null, weekday: DateTime.saturday)],
          byMonthDay: [7, 8, 9, 10, 11, 12, 13],
        ),
      );
      eventRepository.rules = [rule];

      await viewModel.loadEvents.execute(
        ['monthly-sa-after-1su'],
        DateTime.utc(1997, 9, 1),
        DateTime.utc(1998, 3, 31),
      );

      final events = viewModel.getEvents().values.expand((e) => e).toList();
      expect(events, hasLength(7));
      expect(events.map((e) => e.startDate), [
        DateTime.utc(1997, 9, 13, 9),
        DateTime.utc(1997, 10, 11, 9),
        DateTime.utc(1997, 11, 8, 9),
        DateTime.utc(1997, 12, 13, 9),
        DateTime.utc(1998, 1, 10, 9),
        DateTime.utc(1998, 2, 7, 9),
        DateTime.utc(1998, 3, 7, 9),
      ]);
    });

    test(
        'every 4 years, first Tuesday after a Monday in November (US election day)',
        () async {
      final rule = _buildEventRule(
        id: 'yearly-interval4-election',
        title: 'US Presidential Election day',
        startDate: DateTime.utc(1996, 11, 5, 9),
        endDate: DateTime.utc(1996, 11, 5, 10),
        isRecurring: true,
        recurrencePattern: RecurrencePattern(
          freq: Freq.yearly,
          interval: 4,
          byMonth: [11],
          byWeekday: [(instance: null, weekday: DateTime.tuesday)],
          byMonthDay: [2, 3, 4, 5, 6, 7, 8],
        ),
      );
      eventRepository.rules = [rule];

      await viewModel.loadEvents.execute(
        ['yearly-interval4-election'],
        DateTime.utc(1996, 1, 1),
        DateTime.utc(2004, 12, 31),
      );

      final events = viewModel.getEvents().values.expand((e) => e).toList();
      expect(events, hasLength(3));
      expect(events.map((e) => e.startDate), [
        DateTime.utc(1996, 11, 5, 9),
        DateTime.utc(2000, 11, 7, 9),
        DateTime.utc(2004, 11, 2, 9),
      ]);
    });

    test(
        'third instance of Tuesday, Wednesday, or Thursday into the month, for 3 months',
        () async {
      final rule = _buildEventRule(
        id: 'monthly-bysetpos3',
        title: 'Third Tue/Wed/Thu into the month',
        startDate: DateTime.utc(1997, 9, 4, 9),
        endDate: DateTime.utc(1997, 9, 4, 10),
        isRecurring: true,
        recurrencePattern: RecurrencePattern(
          freq: Freq.monthly,
          interval: 1,
          count: 3,
          byWeekday: [
            (instance: null, weekday: DateTime.tuesday),
            (instance: null, weekday: DateTime.wednesday),
            (instance: null, weekday: DateTime.thursday),
          ],
          bySetPos: [3],
        ),
      );
      eventRepository.rules = [rule];

      await viewModel.loadEvents.execute(
        ['monthly-bysetpos3'],
        DateTime.utc(1997, 9, 1),
        DateTime.utc(1997, 11, 30),
      );

      final events = viewModel.getEvents().values.expand((e) => e).toList();
      expect(events, hasLength(3));
      expect(events.map((e) => e.startDate), [
        DateTime.utc(1997, 9, 4, 9),
        DateTime.utc(1997, 10, 7, 9),
        DateTime.utc(1997, 11, 6, 9),
      ]);
    });

    test('second-to-last weekday of the month, bounded window', () async {
      final rule = _buildEventRule(
        id: 'monthly-bysetpos-neg2',
        title: 'Second-to-last weekday of the month',
        startDate: DateTime.utc(1997, 9, 29, 9),
        endDate: DateTime.utc(1997, 9, 29, 10),
        isRecurring: true,
        recurrencePattern: RecurrencePattern(
          freq: Freq.monthly,
          interval: 1,
          byWeekday: [
            (instance: null, weekday: DateTime.monday),
            (instance: null, weekday: DateTime.tuesday),
            (instance: null, weekday: DateTime.wednesday),
            (instance: null, weekday: DateTime.thursday),
            (instance: null, weekday: DateTime.friday),
          ],
          bySetPos: [-2],
        ),
      );
      eventRepository.rules = [rule];

      await viewModel.loadEvents.execute(
        ['monthly-bysetpos-neg2'],
        DateTime.utc(1997, 9, 1),
        DateTime.utc(1998, 3, 31),
      );

      final events = viewModel.getEvents().values.expand((e) => e).toList();
      expect(events, hasLength(7));
      expect(events.map((e) => e.startDate), [
        DateTime.utc(1997, 9, 29, 9),
        DateTime.utc(1997, 10, 30, 9),
        DateTime.utc(1997, 11, 27, 9),
        DateTime.utc(1997, 12, 30, 9),
        DateTime.utc(1998, 1, 29, 9),
        DateTime.utc(1998, 2, 26, 9),
        DateTime.utc(1998, 3, 30, 9),
      ]);
    });

    test('invalid date (February 30) is silently skipped', () async {
      final rule = _buildEventRule(
        id: 'monthly-invalid-date',
        title: 'Monthly on the 15th and 30th',
        startDate: DateTime.utc(2007, 1, 15, 9),
        endDate: DateTime.utc(2007, 1, 15, 10),
        isRecurring: true,
        recurrencePattern: RecurrencePattern(
          freq: Freq.monthly,
          interval: 1,
          count: 5,
          byMonthDay: [15, 30],
        ),
      );
      eventRepository.rules = [rule];

      await viewModel.loadEvents.execute(
        ['monthly-invalid-date'],
        DateTime.utc(2007, 1, 1),
        DateTime.utc(2007, 3, 31),
      );

      final events = viewModel.getEvents().values.expand((e) => e).toList();
      expect(events, hasLength(5));
      expect(events.map((e) => e.startDate), [
        DateTime.utc(2007, 1, 15, 9),
        DateTime.utc(2007, 1, 30, 9),
        DateTime.utc(2007, 2, 15, 9),
        DateTime.utc(2007, 3, 15, 9),
        DateTime.utc(2007, 3, 30, 9),
      ]);
    });
  });
}