import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:intl/intl.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:timezone/timezone.dart' as tz;

const reminderOffsets = {
  'at_start': Duration.zero,
  '10m': Duration(minutes: 10),
  '1h': Duration(hours: 1),
  '1d': Duration(days: 1),
};

/// An event's start as a local DateTime (PocketBase stores UTC).
DateTime eventStart(RecordModel e) => DateTime.parse(e.getStringValue('starts_at')).toLocal();

/// The event's date within [month], or null if it doesn't fall in it. Yearly events recur from their first year on.
// ponytail: a yearly 29 Feb only shows in leap years.
DateTime? dateIn(RecordModel e, DateTime month) {
  final s = eventStart(e);
  final yearly = e.getBoolValue('yearly');
  if (s.month != month.month || (yearly ? month.year < s.year : month.year != s.year)) return null;
  final d = DateTime(month.year, s.month, s.day);
  return d.month == s.month ? d : null;
}

/// The next occurrence whose reminder is still ahead of [now], as (occurrence start, remind at).
/// All-day events are reminded relative to 08:00 that day.
(DateTime, DateTime)? nextReminder({
  required DateTime start,
  required bool allDay,
  required bool yearly,
  required String reminder,
  required DateTime now,
}) {
  final offset = reminderOffsets[reminder];
  if (offset == null) return null;
  DateTime at(int year) => DateTime(year, start.month, start.day, allDay ? 8 : start.hour, allDay ? 0 : start.minute);
  // The offset is at most a day, so a yearly event's next reminder is within three years from the later of
  // last year and its first year.
  final from = yearly && now.year - 1 > start.year ? now.year - 1 : start.year;
  for (final year in yearly ? [from, from + 1, from + 2] : [from]) {
    final when = at(year).subtract(offset);
    if (when.isAfter(now)) return (at(year), when);
  }
  return null;
}

final notifications = FlutterLocalNotificationsPlugin();

Future<void> initReminders() =>
    notifications.initialize(settings: const InitializationSettings(android: AndroidInitializationSettings('@drawable/ic_notification')));

/// Cancel everything and schedule each event's next reminder again: simple, and never doubles up.
/// Runs whenever the calendar loads (app start, after a save or delete).
// ponytail: Android caps an app at ~500 alarms; fine for one person's calendar.
Future<void> rescheduleReminders(List<RecordModel> events, String locale) async {
  final android = notifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
  await android?.requestNotificationsPermission(); // no dialog once granted
  await notifications.cancelAll();
  final now = DateTime.now();
  for (final e in events) {
    final allDay = e.getBoolValue('all_day');
    final next = nextReminder(
      start: eventStart(e),
      allDay: allDay,
      yearly: e.getBoolValue('yearly'),
      reminder: e.getStringValue('reminder'),
      now: now,
    );
    if (next == null) continue;
    final (occurs, remindAt) = next;
    await notifications.zonedSchedule(
      id: e.id.hashCode & 0x7fffffff,
      scheduledDate: tz.TZDateTime.from(remindAt, tz.UTC),
      title: e.getStringValue('title'),
      body: (allDay ? DateFormat.MMMMEEEEd(locale) : DateFormat.MMMMEEEEd(locale).add_Hm()).format(occurs),
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails('calendar', 'Kalender', importance: Importance.high, priority: Priority.high),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }
}
