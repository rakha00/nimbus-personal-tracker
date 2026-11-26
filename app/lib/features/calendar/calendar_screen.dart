import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pocketbase/pocketbase.dart';

import '../../core/backend.dart';
import '../../core/theme.dart';
import '../../l10n/app_localizations.dart';
import '../assistant/assistant_sheet.dart';
import 'holidays.dart';
import 'reminders.dart';

/// A month grid with dots on days that have events, and all of that month's events under it.
class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  // One person's calendar is small: load it all and filter on the phone.
  late Future<List<RecordModel>> events = load();
  DateTime day = dayOnly(DateTime.now());
  late DateTime month = DateTime(day.year, day.month);
  Map<DateTime, List<String>> holidays = {}; // empty until fetched, or if Google can't be reached

  Future<List<RecordModel>> load() async {
    // Holidays come once per app run, beside the events; without them the calendar still works.
    if (holidays.isEmpty) {
      fetchHolidays(Localizations.localeOf(context).languageCode)
          .then((h) => mounted ? setState(() => holidays = h) : null)
          .ignore();
    }
    final list = await pb.collection('calendar_events').getFullList(sort: 'starts_at');
    // Reminders follow the saved events; a failure here mustn't hide the calendar.
    if (mounted) rescheduleReminders(list, Localizations.localeOf(context).toString()).ignore();
    return list;
  }

  void reload() => setState(() => events = load());

  Future<void> open(RecordModel? event) async {
    final changed = await Navigator.push<bool>(
        context, MaterialPageRoute(builder: (_) => EventForm(event: event, day: day)));
    if (changed == true) reload();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toString();
    final l = Ledger.of(context);
    final small = Theme.of(context).textTheme.bodySmall;
    return Scaffold(
      appBar: AppBar(title: Text(t.calendar), actions: const [AssistantButton()]),
      floatingActionButton: FloatingActionButton(onPressed: () => open(null), tooltip: t.add, child: const Icon(Icons.add)),
      body: FutureBuilder(
        future: events,
        builder: (context, snap) {
          if (snap.hasError) {
            return RefreshIndicator(
              onRefresh: () async => reload(),
              child: ListView(children: [ListTile(title: Text(t.loadFailed))]),
            );
          }
          final all = snap.data;
          if (all == null) return const Center(child: CircularProgressIndicator());
          // Every holiday and event in the shown month, by date; within a day holidays first, then all-day, then by
          // time. Each entry is (date, order in the day, a holiday's name or an event).
          final inMonth = <(DateTime, int, Object)>[
            for (final MapEntry(key: d, value: names) in holidays.entries)
              if (d.year == month.year && d.month == month.month)
                for (final name in names) (d, -1, name),
            for (final e in all)
              if (dateIn(e, month) case final d?)
                (d, e.getBoolValue('all_day') ? 0 : 1 + eventStart(e).hour * 60 + eventStart(e).minute, e),
          ]..sort((a, b) => a.$1 == b.$1 ? a.$2.compareTo(b.$2) : a.$1.compareTo(b.$1));
          final busyDays = {for (final (d, _, x) in inMonth) if (x is RecordModel) d};
          return RefreshIndicator(
            onRefresh: () async {
              reload();
              await events;
            },
            child: ListView(padding: const EdgeInsets.fromLTRB(16, 4, 16, 88), children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
                  child: _MonthGrid(
                    month: month,
                    day: day,
                    hasEvents: busyDays.contains,
                    isHoliday: holidays.containsKey,
                    // A new month starts on today if it's this month, else on its 1st (the default day for "add").
                    onMonth: (m) => setState(() {
                      month = m;
                      final today = dayOnly(DateTime.now());
                      day = today.year == m.year && today.month == m.month ? today : m;
                    }),
                    onDay: (d) => setState(() => day = d),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              if (inMonth.isEmpty)
                Padding(padding: const EdgeInsets.all(4), child: Text(t.calendarEmptyMonth, style: small))
              else
                Card(
                  clipBehavior: Clip.antiAlias,
                  child: Column(children: [
                    for (final (i, (d, _, x)) in inMonth.indexed) ...[
                      if (i > 0) const Divider(indent: 16, endIndent: 16),
                      // The picked day's rows are shaded, so the grid and the list point at each other.
                      Ink(
                        color: d == day ? l.raised : null,
                        child: InkWell(
                          onTap: x is RecordModel ? () => open(x) : null,
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                            child: Row(children: [
                              SizedBox(
                                width: 40,
                                child: Column(children: [
                                  Text('${d.day}',
                                      style: TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.w500,
                                          fontFeatures: tabular,
                                          height: 1.1,
                                          color: holidays.containsKey(d) ? l.negative : null)),
                                  Text(DateFormat.E(locale).format(d), style: small),
                                ]),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                  Text(x is RecordModel ? x.getStringValue('title') : '$x', maxLines: 2, overflow: TextOverflow.ellipsis),
                                  if (x is RecordModel)
                                    Text(
                                      x.getBoolValue('all_day') ? t.calendarAllDay : DateFormat.Hm(locale).format(eventStart(x)),
                                      style: small?.copyWith(fontFeatures: tabular),
                                    )
                                  else
                                    Text(t.calendarHoliday, style: small?.copyWith(color: l.negative)),
                                ]),
                              ),
                              if (x is RecordModel && x.getBoolValue('yearly'))
                                const Padding(padding: EdgeInsets.only(left: 8), child: Icon(Icons.repeat, size: 16)),
                              if (x is RecordModel && x.getStringValue('reminder').isNotEmpty)
                                const Padding(padding: EdgeInsets.only(left: 8), child: Icon(Icons.notifications_none, size: 16)),
                            ]),
                          ),
                        ),
                      ),
                    ],
                  ]),
                ),
            ]),
          );
        },
      ),
    );
  }
}

/// Month header with arrows, weekday initials (Monday first), and day cells.
class _MonthGrid extends StatelessWidget {
  const _MonthGrid(
      {required this.month, required this.day, required this.hasEvents, required this.isHoliday, required this.onMonth, required this.onDay});
  final DateTime month, day;
  final bool Function(DateTime) hasEvents, isHoliday;
  final ValueChanged<DateTime> onMonth, onDay;

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).toString();
    final l = Ledger.of(context);
    final today = dayOnly(DateTime.now());
    final lead = month.weekday - 1; // blank cells before the 1st
    final days = DateTime(month.year, month.month + 1, 0).day;
    final cells = [for (var i = 0; i < lead; i++) null, for (var d = 1; d <= days; d++) DateTime(month.year, month.month, d)];
    while (cells.length % 7 != 0) {
      cells.add(null);
    }
    Widget cell(DateTime? d) {
      if (d == null) return const Expanded(child: SizedBox(height: 44));
      final picked = d == day;
      return Expanded(
        child: InkWell(
          onTap: () => onDay(d),
          borderRadius: BorderRadius.circular(6),
          child: SizedBox(
            height: 44,
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Container(
                width: 30,
                height: 30,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: picked ? l.hue : null,
                  shape: BoxShape.circle,
                  border: d == today && !picked ? Border.all(color: l.text) : null,
                ),
                child: Text('${d.day}',
                    style: TextStyle(fontFeatures: tabular, color: picked ? (l.dark ? Colors.black : Colors.white) : (isHoliday(d) ? l.negative : l.text), fontWeight: d == today ? FontWeight.w600 : null)),
              ),
              const SizedBox(height: 2),
              Container(
                width: 4,
                height: 4,
                decoration: BoxDecoration(color: hasEvents(d) ? l.text : Colors.transparent, shape: BoxShape.circle),
              ),
            ]),
          ),
        ),
      );
    }

    return Column(children: [
      Row(children: [
        IconButton(onPressed: () => onMonth(DateTime(month.year, month.month - 1)), icon: const Icon(Icons.chevron_left)),
        Expanded(
          child: TextButton(
            onPressed: () async {
              final picked = await _pickMonth(context, month);
              if (picked != null) onMonth(picked);
            },
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Text(DateFormat.yMMMM(locale).format(month), style: Theme.of(context).textTheme.titleMedium),
              const Icon(Icons.arrow_drop_down),
            ]),
          ),
        ),
        IconButton(onPressed: () => onMonth(DateTime(month.year, month.month + 1)), icon: const Icon(Icons.chevron_right)),
      ]),
      Row(children: [
        // 2024-01-01 was a Monday.
        for (var i = 0; i < 7; i++)
          Expanded(
            child: Text(DateFormat.E(locale).format(DateTime(2024, 1, 1 + i)).characters.first,
                textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodySmall),
          ),
      ]),
      const SizedBox(height: 4),
      for (var r = 0; r < cells.length; r += 7) Row(children: [for (final d in cells.sublist(r, r + 7)) cell(d)]),
    ]);
  }
}

/// Jump to any month: a year stepper over a 4×3 grid of months, plus "today".
Future<DateTime?> _pickMonth(BuildContext context, DateTime current) {
  var year = current.year;
  return showModalBottomSheet<DateTime>(
    context: context,
    builder: (c) => StatefulBuilder(
      builder: (c, setSheet) {
        final locale = Localizations.localeOf(c).toString();
        final l = Ledger.of(c);
        final now = DateTime.now();
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Row(children: [
                IconButton(onPressed: () => setSheet(() => year--), icon: const Icon(Icons.chevron_left)),
                Expanded(
                  child: Text('$year',
                      textAlign: TextAlign.center, style: Theme.of(c).textTheme.titleMedium?.copyWith(fontFeatures: tabular)),
                ),
                IconButton(onPressed: () => setSheet(() => year++), icon: const Icon(Icons.chevron_right)),
              ]),
              const SizedBox(height: 8),
              for (var r = 0; r < 3; r++)
                Row(children: [
                  for (var m = r * 4 + 1; m <= r * 4 + 4; m++)
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(4),
                        child: m == current.month && year == current.year
                            ? FilledButton(
                                style: FilledButton.styleFrom(backgroundColor: l.hue, foregroundColor: l.dark ? Colors.black : Colors.white),
                                onPressed: () => Navigator.pop(c, DateTime(year, m)),
                                child: Text(DateFormat.MMM(locale).format(DateTime(year, m))),
                              )
                            : OutlinedButton(
                                style: OutlinedButton.styleFrom(minimumSize: const Size(0, 44)),
                                onPressed: () => Navigator.pop(c, DateTime(year, m)),
                                child: Text(DateFormat.MMM(locale).format(DateTime(year, m))),
                              ),
                      ),
                    ),
                ]),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => Navigator.pop(c, DateTime(now.year, now.month)),
                child: Text(AppLocalizations.of(c).today),
              ),
            ]),
          ),
        );
      },
    ),
  );
}

/// Add or edit one event; for an existing one it doubles as the detail page.
class EventForm extends StatefulWidget {
  const EventForm({super.key, this.event, required this.day, this.draft});
  final RecordModel? event; // null = new
  final DateTime day; // the picked day, for a new event
  final Map<String, dynamic>? draft; // an AI suggestion for a new one: date YYYY-MM-DD, time HH:MM

  @override
  State<EventForm> createState() => _EventFormState();
}

class _EventFormState extends State<EventForm> {
  late final e = widget.event;
  late final dr = widget.draft ?? const {};
  late final DateTime start = e != null
      ? eventStart(e!)
      : DateTime.tryParse('${dr['date']} ${dr['time'] ?? '09:00'}') ?? widget.day.add(const Duration(hours: 9));
  late final title = TextEditingController(text: e?.getStringValue('title') ?? dr['title'] as String? ?? '');
  late final note = TextEditingController(text: e?.getStringValue('note') ?? dr['note'] as String? ?? '');
  late DateTime date = dayOnly(start);
  late TimeOfDay time = TimeOfDay.fromDateTime(start);
  late bool allDay = e?.getBoolValue('all_day') ?? (widget.draft != null && dr['time'] == null);
  late bool yearly = e?.getBoolValue('yearly') ?? dr['yearly'] as bool? ?? false;
  late String reminder = e?.getStringValue('reminder') ?? dr['reminder'] as String? ?? '';
  bool busy = false;
  String? error, titleError;

  Future<void> save() async {
    if (title.text.trim().isEmpty) return setState(() => titleError = AppLocalizations.of(context).required);
    final at = DateTime(date.year, date.month, date.day, allDay ? 0 : time.hour, allDay ? 0 : time.minute);
    final body = {
      'owner': userId,
      'title': title.text.trim(),
      'starts_at': at.toUtc().toIso8601String(),
      'all_day': allDay,
      'yearly': yearly,
      'reminder': reminder,
      'note': note.text.trim(),
    };
    await _run(() => e == null
        ? pb.collection('calendar_events').create(body: body)
        : pb.collection('calendar_events').update(e!.id, body: body));
  }

  Future<void> delete() async {
    final t = AppLocalizations.of(context);
    final yes = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(t.deleteConfirm),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: Text(t.cancel)),
          TextButton(onPressed: () => Navigator.pop(c, true), child: Text(t.delete)),
        ],
      ),
    );
    if (yes == true) await _run(() => pb.collection('calendar_events').delete(e!.id));
  }

  Future<void> _run(Future<Object?> Function() call) async {
    setState(() => busy = true);
    try {
      await call();
      if (mounted) Navigator.pop(context, true);
    } catch (_) {
      if (mounted) setState(() => error = AppLocalizations.of(context).saveFailed);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toString();
    final pickerStyle = OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(44), alignment: Alignment.centerLeft);
    return Scaffold(
      appBar: AppBar(
        title: Text(e == null ? t.add : ''),
        actions: [
          if (e != null) IconButton(onPressed: busy ? null : delete, icon: const Icon(Icons.delete_outline), tooltip: t.delete),
          TextButton(onPressed: busy ? null : save, child: Text(t.save)),
        ],
      ),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        Labeled(t.calendarEventTitle,
            TextField(
              controller: title,
              autofocus: e == null,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(errorText: titleError),
              onChanged: (_) => titleError == null ? null : setState(() => titleError = null),
            )),
        const SizedBox(height: 16),
        Labeled(t.date, OutlinedButton.icon(
          style: pickerStyle,
          icon: const Icon(Icons.calendar_today_outlined, size: 18),
          label: Text(DateFormat.yMMMMEEEEd(locale).format(date)),
          onPressed: () async {
            final picked = await showDatePicker(context: context, initialDate: date, firstDate: DateTime(1900), lastDate: DateTime(2200));
            if (picked != null) setState(() => date = picked);
          },
        )),
        const SizedBox(height: 8),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(t.calendarAllDay),
          value: allDay,
          onChanged: (v) => setState(() => allDay = v),
        ),
        if (!allDay) ...[
          Labeled(t.calendarTime, OutlinedButton.icon(
            style: pickerStyle,
            icon: const Icon(Icons.schedule, size: 18),
            label: Text(time.format(context), style: const TextStyle(fontFeatures: tabular)),
            onPressed: () async {
              final picked = await showTimePicker(context: context, initialTime: time);
              if (picked != null) setState(() => time = picked);
            },
          )),
          const SizedBox(height: 8),
        ],
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(t.calendarYearly),
          value: yearly,
          onChanged: (v) => setState(() => yearly = v),
        ),
        const SizedBox(height: 8),
        Labeled(t.calendarReminder, DropdownMenu<String>(
          expandedInsets: EdgeInsets.zero,
          initialSelection: reminder,
          onSelected: (v) => setState(() => reminder = v ?? ''),
          dropdownMenuEntries: [
            for (final (v, label) in [
              ('', t.reminderNone),
              ('at_start', t.reminderAtStart),
              ('10m', t.reminder10m),
              ('1h', t.reminder1h),
              ('1d', t.reminder1d),
            ])
              DropdownMenuEntry(value: v, label: label),
          ],
        )),
        if (allDay && reminder.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(t.calendarAllDayReminderHint, style: Theme.of(context).textTheme.bodySmall),
        ],
        const SizedBox(height: 16),
        Labeled(t.note, TextField(
          controller: note,
          minLines: 3,
          maxLines: null,
          maxLength: 5000,
          textCapitalization: TextCapitalization.sentences,
        )),
        if (error != null) Text(error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
      ]),
    );
  }
}
