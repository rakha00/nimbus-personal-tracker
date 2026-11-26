import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pocketbase/pocketbase.dart';

import '../../core/backend.dart';
import '../../core/theme.dart';
import '../../l10n/app_localizations.dart';
import '../assistant/assistant_sheet.dart';

/// One entry per day. Today's card always sits on top, even before it's written.
class DiaryScreen extends StatefulWidget {
  const DiaryScreen({super.key});

  @override
  State<DiaryScreen> createState() => _DiaryScreenState();
}

class _DiaryScreenState extends State<DiaryScreen> {
  late Future<List<RecordModel>> entries = load();

  Future<List<RecordModel>> load() => pb.collection('diary_entries').getFullList(sort: '-date');

  void reload() => setState(() => entries = load());

  Future<void> open(DateTime date, RecordModel? entry) async {
    final changed = await Navigator.push<bool>(
        context, MaterialPageRoute(builder: (_) => DiaryEditor(date: date, entry: entry)));
    if (changed == true) reload();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toString();
    final today = dayOnly(DateTime.now());
    return Scaffold(
      appBar: AppBar(title: Text(t.diary), actions: const [AssistantButton()]),
      body: FutureBuilder(
        future: entries,
        builder: (context, snap) {
          if (snap.hasError) {
            return RefreshIndicator(
              onRefresh: () async => reload(),
              child: ListView(children: [ListTile(title: Text(t.loadFailed))]),
            );
          }
          final list = snap.data;
          if (list == null) return const Center(child: CircularProgressIndicator());
          final todayEntry = list.where((e) => fromPbDate(e.getStringValue('date')) == today).firstOrNull;
          final past = list.where((e) => e != todayEntry);
          return RefreshIndicator(
            onRefresh: () async {
              reload();
              await entries;
            },
            child: ListView(padding: const EdgeInsets.fromLTRB(16, 4, 16, 24), children: [
              // Today always comes first, written or not.
              Card(
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: () => open(today, todayEntry),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('${t.today} · ${DateFormat.MMMMEEEEd(locale).format(today)}',
                          style: Theme.of(context).textTheme.labelMedium),
                      const SizedBox(height: 8),
                      if (todayEntry != null)
                        Text(todayEntry.getStringValue('content'), maxLines: 6, overflow: TextOverflow.ellipsis)
                      else
                        Row(children: [
                          const Icon(Icons.edit_outlined, size: 18),
                          const SizedBox(width: 8),
                          Text(t.writeToday, style: const TextStyle(fontWeight: FontWeight.w500)),
                        ]),
                    ]),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              if (past.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(4),
                  child: Text(t.diaryEmpty, style: Theme.of(context).textTheme.bodySmall),
                )
              else
                Card(
                  clipBehavior: Clip.antiAlias,
                  child: Column(children: [
                    for (final (i, e) in past.indexed) ...[
                      if (i > 0) const Divider(indent: 16, endIndent: 16),
                      _EntryRow(entry: e, locale: locale, onTap: () => open(fromPbDate(e.getStringValue('date')), e)),
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

/// A past day: the date as a ledger column (day number large, month small), the text beside it.
class _EntryRow extends StatelessWidget {
  const _EntryRow({required this.entry, required this.locale, required this.onTap});
  final RecordModel entry;
  final String locale;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final date = fromPbDate(entry.getStringValue('date'));
    final small = Theme.of(context).textTheme.bodySmall;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          SizedBox(
            width: 48,
            child: Column(children: [
              Text('${date.day}', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w500, fontFeatures: tabular, height: 1.1)),
              Text(DateFormat.MMM(locale).format(date), style: small),
            ]),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(DateFormat.EEEE(locale).format(date), style: small),
              const SizedBox(height: 2),
              Text(entry.getStringValue('content'), maxLines: 3, overflow: TextOverflow.ellipsis),
            ]),
          ),
        ]),
      ),
    );
  }
}

class DiaryEditor extends StatefulWidget {
  const DiaryEditor({super.key, required this.date, this.entry, this.append = ''});
  final DateTime date;
  final RecordModel? entry;
  final String append; // text to add under the entry (an AI draft)

  @override
  State<DiaryEditor> createState() => _DiaryEditorState();
}

class _DiaryEditorState extends State<DiaryEditor> {
  late final text = TextEditingController(
      text: [widget.entry?.getStringValue('content') ?? '', widget.append].where((s) => s.isNotEmpty).join('\n'));
  bool busy = false;

  Future<void> save() async {
    final content = text.text.trim();
    final e = widget.entry;
    // Saving an empty entry means removing it.
    if (content.isEmpty && e == null) return Navigator.pop(context, false);
    await _run(() => content.isEmpty
        ? pb.collection('diary_entries').delete(e!.id)
        : e == null
            ? pb.collection('diary_entries').create(body: {'owner': userId, 'date': toPbDate(widget.date), 'content': content})
            : pb.collection('diary_entries').update(e.id, body: {'content': content}));
  }

  Future<void> _run(Future<Object?> Function() call) async {
    setState(() => busy = true);
    try {
      await call();
      if (mounted) Navigator.pop(context, true);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context).saveFailed)));
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(DateFormat.yMMMMEEEEd(Localizations.localeOf(context).toString()).format(widget.date)),
        actions: [TextButton(onPressed: busy ? null : save, child: Text(t.save))],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: TextField(
          controller: text,
          autofocus: widget.entry == null,
          maxLines: null,
          expands: true,
          textAlignVertical: TextAlignVertical.top,
          textCapitalization: TextCapitalization.sentences,
          decoration: InputDecoration(hintText: t.diaryHint, border: InputBorder.none),
        ),
      ),
    );
  }
}
