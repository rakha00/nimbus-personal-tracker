import 'package:flutter_test/flutter_test.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:nimbus/features/calendar/reminders.dart';

void main() {
  final now = DateTime(2026, 11, 26, 12);

  test('one-off: reminder ahead is scheduled, past or none is not', () {
    final start = DateTime(2026, 11, 27, 9, 30);
    expect(nextReminder(start: start, allDay: false, yearly: false, reminder: '1h', now: now),
        (start, DateTime(2026, 11, 27, 8, 30)));
    expect(nextReminder(start: start, allDay: false, yearly: false, reminder: '', now: now), isNull);
    expect(nextReminder(start: DateTime(2026, 11, 26, 11), allDay: false, yearly: false, reminder: 'at_start', now: now), isNull);
  });

  test('all-day counts from 08:00', () {
    expect(nextReminder(start: DateTime(2026, 11, 28), allDay: true, yearly: false, reminder: '1d', now: now)?.$2,
        DateTime(2026, 11, 27, 8));
  });

  test('dateIn: one-off only in its own month, yearly every year from the first', () {
    RecordModel ev(String start, {bool yearly = false}) =>
        RecordModel.fromJson({'id': 'x', 'starts_at': DateTime.parse(start).toUtc().toIso8601String(), 'yearly': yearly});
    expect(dateIn(ev('2026-11-20 09:00'), DateTime(2026, 11)), DateTime(2026, 11, 20));
    expect(dateIn(ev('2026-11-20 09:00'), DateTime(2027, 11)), isNull);
    expect(dateIn(ev('1990-12-01', yearly: true), DateTime(2026, 12)), DateTime(2026, 12, 1));
    expect(dateIn(ev('2030-12-01', yearly: true), DateTime(2026, 12)), isNull);
    expect(dateIn(ev('2024-02-29', yearly: true), DateTime(2027, 2)), isNull); // no 29 Feb that year
  });

  test('yearly: this year if still ahead, else next year; never before the first year', () {
    final birthday = DateTime(1990, 12, 1);
    expect(nextReminder(start: birthday, allDay: true, yearly: true, reminder: 'at_start', now: now)?.$1, DateTime(2026, 12, 1, 8));
    final past = DateTime(2000, 3, 5, 10);
    expect(nextReminder(start: past, allDay: false, yearly: true, reminder: '10m', now: now)?.$1, DateTime(2027, 3, 5, 10));
    // A 1-day reminder for 1 Jan next year is due on 31 Dec this year.
    expect(nextReminder(start: DateTime(2020, 1, 1), allDay: true, yearly: true, reminder: '1d', now: DateTime(2026, 12, 31, 7))?.$2,
        DateTime(2026, 12, 31, 8));
    expect(nextReminder(start: DateTime(2030, 5, 1), allDay: true, yearly: true, reminder: 'at_start', now: now)?.$1, DateTime(2030, 5, 1, 8));
  });
}
