import 'package:flutter_test/flutter_test.dart';
import 'package:nimbus/features/calendar/calendar_screen.dart';
import 'package:pocketbase/pocketbase.dart';

void main() {
  // Saved bodies hold UTC; read them back in local time, as the app does.
  DateTime at(Map<String, Object> b) => DateTime.parse(b['starts_at'] as String).toLocal();
  RecordModel event(DateTime localStart, {bool allDay = false, bool yearly = false, String reminder = '1h'}) => RecordModel.fromJson({
        'id': 'e1', 'title': 'Rapat', 'starts_at': localStart.toUtc().toIso8601String(),
        'all_day': allDay, 'yearly': yearly, 'reminder': reminder, 'note': 'Bawa laptop',
      });

  test('a new event: with a time it is timed, without one all-day', () {
    final timed = eventDraftBody({'title': 'Servis motor', 'date': '2026-12-05', 'time': '09:30', 'reminder': '1h'})!;
    expect([at(timed), timed['all_day'], timed['reminder']], [DateTime(2026, 12, 5, 9, 30), false, '1h']);
    final allDay = eventDraftBody({'title': 'Libur', 'date': '2026-12-25'})!;
    expect([at(allDay), allDay['all_day']], [DateTime(2026, 12, 25), true]);
  });

  test('moving the time keeps the date, moving the date keeps the time', () {
    final base = event(DateTime(2026, 12, 5, 9));
    expect(at(eventDraftBody({'time': '15:00'}, base)!), DateTime(2026, 12, 5, 15));
    final moved = eventDraftBody({'date': '2026-12-08'}, base)!;
    expect([at(moved), moved['title'], moved['note'], moved['reminder']], [DateTime(2026, 12, 8, 9), 'Rapat', 'Bawa laptop', '1h']);
  });

  test('all-day and back, and removing the reminder', () {
    final base = event(DateTime(2026, 12, 5, 9));
    final allDay = eventDraftBody({'all_day': true}, base)!;
    expect([at(allDay), allDay['all_day']], [DateTime(2026, 12, 5), true]);
    final timed = eventDraftBody({'time': '10:00'}, event(DateTime(2026, 12, 5), allDay: true))!;
    expect([at(timed), timed['all_day']], [DateTime(2026, 12, 5, 10), false]);
    expect(eventDraftBody({'reminder': 'none'}, base)!['reminder'], '');
  });

  test('a yearly event keeps its first year when its day changes', () {
    final birthday = event(DateTime(1990, 3, 5), allDay: true, yearly: true);
    expect(at(eventDraftBody({'date': '2026-03-07'}, birthday)!), DateTime(1990, 3, 7));
  });

  test('no title, no save', () => expect(eventDraftBody({'title': ' ', 'date': '2026-12-05'}), isNull));
}
