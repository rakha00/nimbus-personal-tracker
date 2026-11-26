import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pocketbase/pocketbase.dart';

import '../../core/backend.dart';
import '../../l10n/app_localizations.dart';
import '../calendar/calendar_screen.dart';
import '../diary/diary_screen.dart';
import '../finance/finance_data.dart';
import '../finance/transaction_form.dart';
import '../media/media_api.dart';
import '../media/media_screen.dart';

/// Bumped after the assistant's drafts were saved, so every tab reloads.
final assistantSaved = ValueNotifier(0);

/// App bar button that opens the assistant.
class AssistantButton extends StatelessWidget {
  const AssistantButton({super.key});

  @override
  Widget build(BuildContext context) => IconButton(
        // Claude Spark from the Anthropic press kit; ImageIcon takes the app bar's icon color.
        icon: const ImageIcon(AssetImage('assets/claude_spark.png'), size: 20),
        tooltip: AppLocalizations.of(context).assistant,
        onPressed: () async {
          var saved = false;
          await showModalBottomSheet<void>(
            context: context,
            isScrollControlled: true,
            useSafeArea: true,
            builder: (_) => AssistantSheet(onSaved: () => saved = true),
          );
          if (saved) assistantSaved.value++;
        },
      );
}

/// One box for both: a note becomes drafts, a question gets a short answer; the AI decides which.
/// Transaction drafts (add, change, delete) are approved or rejected right here; other drafts open
/// their normal form. Either way the app writes, as the user: the AI itself can't write anything.
class AssistantSheet extends StatefulWidget {
  const AssistantSheet({super.key, required this.onSaved});
  final VoidCallback onSaved;

  @override
  State<AssistantSheet> createState() => _AssistantSheetState();
}

class _AssistantSheetState extends State<AssistantSheet> {
  final prompt = TextEditingController();
  bool busy = false;
  String? answer, error;
  List<Map<String, dynamic>> drafts = [];
  FinanceData? finance; // loaded when there are transaction drafts, to map names and find records
  List<RecordModel> media = [], events = []; // loaded when there are media / calendar drafts
  final outcome = <int, String>{}; // draft index → working | saved | rejected | failed

  Future<void> send() async {
    final t = AppLocalizations.of(context);
    final text = prompt.text.trim();
    if (text.isEmpty || busy) return;
    FocusScope.of(context).unfocus();
    setState(() {
      busy = true;
      answer = error = null;
      drafts = [];
      outcome.clear();
    });
    final requests = pb.collection('ai_requests');
    try {
      var r = await requests.create(body: {'owner': userId, 'mode': 'auto', 'prompt': text});
      // The worker usually answers in ~10 s and gives up at 90 s itself.
      final until = DateTime.now().add(const Duration(minutes: 2));
      while (!{'done', 'error'}.contains(r.getStringValue('status'))) {
        if (DateTime.now().isAfter(until)) throw TimeoutException(null);
        await Future.delayed(const Duration(milliseconds: 1500));
        if (!mounted) return;
        r = await requests.getOne(r.id);
      }
      final list = [for (final d in r.data['drafts'] as List? ?? []) Map<String, dynamic>.from(d as Map)];
      final f = list.any(_isTx) ? await loadFinance() : null;
      final m = list.any(_isMedia) ? await pb.collection('media_items').getFullList() : <RecordModel>[];
      final e = list.any(_isEvent) ? await pb.collection('calendar_events').getFullList() : <RecordModel>[];
      if (!mounted) return;
      setState(() {
        if (r.getStringValue('status') == 'error') {
          error = switch (r.getStringValue('error')) {
            'rate_limit' => t.assistantRateLimit,
            'timeout' => t.assistantTimeout,
            _ => t.assistantFailed,
          };
        } else {
          answer = r.getStringValue('answer');
          drafts = list;
          finance = f;
          media = m;
          events = e;
        }
      });
    } on TimeoutException {
      if (mounted) setState(() => error = t.assistantTimeout);
    } catch (_) {
      if (mounted) setState(() => error = t.assistantFailed);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  void _done(int i, String result) {
    setState(() => outcome[i] = result);
    if (result == 'saved') widget.onSaved();
  }

  /// Writes an approved transaction or media draft, with the user's own login.
  Future<void> approve(int i) async {
    final d = drafts[i];
    final lang = Localizations.localeOf(context).languageCode;
    setState(() => outcome[i] = 'working'); // a spinner while it saves (media also fetches details)
    final tx = pb.collection('transactions'), items = pb.collection('media_items'), cal = pb.collection('calendar_events');
    try {
      switch (d['module']) {
        case 'transaction_delete':
          await tx.delete(d['id'] as String);
        case 'transaction_update':
          await tx.update(d['id'] as String, body: finance!.draftBody(d, _base(d))!);
        case 'transaction':
          await tx.create(body: {'owner': userId, ...finance!.draftBody(d)!});
        case 'media_delete':
          await items.delete(d['id'] as String);
        case 'media_update':
          await items.update(d['id'] as String, body: mediaDraftBody(d, base: _base(d))!);
        case 'event':
          await cal.create(body: {'owner': userId, ...eventDraftBody(d)!});
        case 'event_update':
          await cal.update(d['id'] as String, body: eventDraftBody(d, _base(d))!);
        default: // a new media item
          // The draft only names the pick; cover, creator and synopsis come straight from the API.
          final ext = d['external_id'] as String? ?? '';
          final hit = ext.isEmpty ? null : await completeHit(await fetchHit(ext, d['media_type'] as String, lang));
          await items.create(body: {'owner': userId, ...mediaDraftBody(d, hit: hit)!});
      }
      if (_isTx(d)) financeChanged();
      _done(i, 'saved');
    } catch (_) {
      _done(i, 'failed');
    }
  }

  /// The existing record a change or deletion points at.
  RecordModel? _base(Map<String, dynamic> d) =>
      (_isTx(d) ? finance?.txs ?? [] : _isMedia(d) ? media : events).where((r) => r.id == d['id']).firstOrNull;

  /// Opens the module's normal form filled with the draft; the user saves it there.
  Future<void> open(int i) async {
    final d = drafts[i];
    final date = DateTime.tryParse('${d['date']}') ?? dayOnly(DateTime.now());
    try {
      final Widget page = switch (d['module']) {
        'transaction' => TransactionForm(data: finance!, draft: d),
        _ => await _diaryEditor(d, date),
      };
      if (!mounted) return;
      final ok = await Navigator.push<bool>(context, MaterialPageRoute(builder: (_) => page));
      if (ok == true && mounted) _done(i, 'saved');
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context).loadFailed)));
    }
  }

  /// A diary draft adds lines under that day's entry; a diary_update replaces its text (the AI
  /// keeps what wasn't asked to change). The user still saves in the editor; the AI never deletes.
  Future<DiaryEditor> _diaryEditor(Map<String, dynamic> d, DateTime date) async {
    final entry = (await pb.collection('diary_entries').getList(perPage: 1, filter: pb.filter('date = {:d}', {'d': toPbDate(date)})))
        .items
        .firstOrNull;
    final old = entry?.getStringValue('content') ?? '';
    final text = d['module'] == 'diary_update'
        ? d['content'] as String? ?? ''
        : [old, d['text'] as String? ?? ''].where((s) => s.isNotEmpty).join('\n');
    // An empty text would delete the entry on save; deleting is left to the user.
    return DiaryEditor(date: date, entry: entry, text: text.trim().isEmpty ? old : text);
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: ListView(shrinkWrap: true, padding: const EdgeInsets.fromLTRB(16, 8, 16, 24), children: [
        TextField(
          controller: prompt,
          autofocus: true,
          enabled: !busy,
          minLines: 1,
          maxLines: 5,
          maxLength: 500,
          textCapitalization: TextCapitalization.sentences,
          decoration: InputDecoration(
            hintText: t.assistantHint,
            suffixIcon: IconButton(onPressed: busy ? null : send, icon: const Icon(Icons.send), tooltip: t.assistantSend),
          ),
        ),
        if (busy) const LinearProgressIndicator(),
        if (error != null) Text(error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
        if (answer != null && answer!.isNotEmpty) ...[
          const SizedBox(height: 8),
          SelectableText(answer!),
        ],
        if (drafts.isNotEmpty) ...[
          const SizedBox(height: 12),
          Card(
            clipBehavior: Clip.antiAlias,
            child: Column(children: [
              for (final (i, d) in drafts.indexed) ...[
                if (i > 0) const Divider(indent: 16, endIndent: 16),
                if (_isTx(d))
                  _TxDraftTile(
                    draft: d,
                    finance: finance!,
                    base: _base(d),
                    outcome: outcome[i],
                    onApprove: () => approve(i),
                    onReject: () => _done(i, 'rejected'),
                    onComplete: () => open(i),
                  )
                else if (_isMedia(d))
                  _MediaDraftTile(
                    draft: d,
                    base: _base(d),
                    outcome: outcome[i],
                    onApprove: () => approve(i),
                    onReject: () => _done(i, 'rejected'),
                  )
                else if (_isEvent(d))
                  _EventDraftTile(
                    draft: d,
                    base: _base(d),
                    outcome: outcome[i],
                    onApprove: () => approve(i),
                    onReject: () => _done(i, 'rejected'),
                  )
                else
                  _DraftTile(draft: d, saved: outcome[i] == 'saved', onTap: () => open(i)),
              ],
            ]),
          ),
        ],
      ]),
    );
  }
}

bool _isTx(Map<String, dynamic> d) => '${d['module']}'.startsWith('transaction');
bool _isMedia(Map<String, dynamic> d) => '${d['module']}'.startsWith('media');
bool _isEvent(Map<String, dynamic> d) => '${d['module']}'.startsWith('event');

String _txType(AppLocalizations t, Object? type) => switch (type) {
      'income' => t.income,
      'transfer' => t.transfer,
      'lend' => t.debtLend,
      'collect' => t.debtCollect,
      'borrow' => t.debtBorrow,
      'repay' => t.debtRepay,
      _ => t.expense,
    };

String _day(BuildContext context, Object? date) {
  final d = DateTime.tryParse('$date');
  return d == null ? '' : DateFormat.MMMd(Localizations.localeOf(context).toString()).format(d); // "26 Nov": short for one line
}

/// A transaction to add, change or delete, with Reject / Approve. Changes and deletions show the
/// record as it is in the database, not the AI's description of it.
class _TxDraftTile extends StatelessWidget {
  const _TxDraftTile({
    required this.draft,
    required this.finance,
    required this.base,
    required this.outcome,
    required this.onApprove,
    required this.onReject,
    required this.onComplete,
  });
  final Map<String, dynamic> draft;
  final FinanceData finance;
  final RecordModel? base; // the existing transaction, for a change or deletion
  final String? outcome;
  final VoidCallback onApprove, onReject, onComplete;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final f = finance;
    final action = draft['module'];
    final isNew = action == 'transaction';
    final body = action == 'transaction_delete' ? null : f.draftBody(draft, isNew ? null : base);

    // A saved-shape map (ids) → "Expense Rp18.000" and "26 Nov · Cash · Makan & Minum · kopi".
    (String, String) describe(Map<String, dynamic> x) => (
          '${_txType(t, x['type'])} ${rupiah((x['amount'] as num? ?? 0).toInt())}',
          [
            _day(context, x['date']),
            f.accountName[x['account']] ?? '',
            if ('${x['to_account']}'.isNotEmpty) '→ ${f.accountName[x['to_account']] ?? ''}',
            f.categoryName[x['category']] ?? '',
            '${x['person'] ?? ''}',
            '${x['note'] ?? ''}',
          ].where((s) => s.isNotEmpty).join(' · '),
        );

    final missing = !isNew && base == null;
    final (title, line) = missing
        ? (t.assistantNotFound, '')
        : body != null
            ? describe(body)
            : base != null && !isNew
                ? describe(base!.data)
                // An incomplete new one: show the AI's words, the user completes it in the form.
                : (
                    '${_txType(t, draft['type'])} ${rupiah((draft['amount'] as num? ?? 0).toInt())}',
                    [_day(context, draft['date']), draft['account'], draft['category'], draft['person'], draft['note']]
                        .whereType<String>()
                        .where((s) => s.isNotEmpty)
                        .join(' · '),
                  );
    final before = action == 'transaction_update' && base != null ? describe(base!.data) : null;
    final incomplete = isNew && body == null;
    return _ApprovalTile(
      leading: _actionIcon(context, action, Icons.account_balance_wallet_outlined),
      title: title,
      line: line,
      before: before == null ? null : '${before.$1} · ${before.$2}',
      outcome: outcome,
      onReject: onReject,
      onApprove: !missing && (action == 'transaction_delete' || body != null) ? onApprove : null,
      onComplete: incomplete ? onComplete : null,
    );
  }
}

/// The leading icon: what the draft does. A new one shows [add].
Widget _actionIcon(BuildContext context, Object? module, IconData add) => switch ('$module') {
      final m when m.endsWith('_update') => const Icon(Icons.edit_outlined),
      final m when m.endsWith('_delete') => Icon(Icons.delete_outline, color: Theme.of(context).colorScheme.error),
      _ => Icon(add),
    };

/// One compact draft row: what it does, one line of detail, then reject / approve (or the outcome).
class _ApprovalTile extends StatelessWidget {
  const _ApprovalTile({
    required this.leading,
    required this.title,
    required this.line,
    this.before,
    required this.outcome,
    required this.onReject,
    required this.onApprove,
    this.onComplete,
  });
  final Widget leading;
  final String title, line;
  final String? before; // a change's previous values
  final String? outcome;
  final VoidCallback onReject;
  final VoidCallback? onApprove; // null: can't be approved as is
  final VoidCallback? onComplete; // set: incomplete, so open the form instead of approving

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final cs = Theme.of(context).colorScheme;
    Text oneLine(String s, [TextStyle? style]) => Text(s, maxLines: 1, overflow: TextOverflow.ellipsis, style: style);
    return ListTile(
      dense: true,
      contentPadding: const EdgeInsets.only(left: 16, right: 4),
      leading: leading,
      title: oneLine(title),
      subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        if (line.isNotEmpty) oneLine(line),
        if (before != null) oneLine('${t.assistantBefore}: $before', Theme.of(context).textTheme.bodySmall),
        if (onComplete != null) oneLine(t.assistantIncomplete, TextStyle(color: cs.error)),
      ]),
      trailing: Row(mainAxisSize: MainAxisSize.min, children: [
        if (outcome != null)
          Padding(
            padding: const EdgeInsets.all(12),
            child: switch (outcome) {
              'working' => const SizedBox.square(dimension: 24, child: CircularProgressIndicator(strokeWidth: 2.5)),
              'saved' => Icon(Icons.check_circle, semanticLabel: t.assistantSaved),
              'rejected' => Icon(Icons.block, color: cs.outline, semanticLabel: t.assistantRejected),
              _ => Icon(Icons.error_outline, color: cs.error, semanticLabel: t.saveFailed),
            },
          )
        else ...[
          IconButton(onPressed: onReject, icon: const Icon(Icons.close), tooltip: t.assistantReject),
          onComplete != null
              ? IconButton.filled(onPressed: onComplete, icon: const Icon(Icons.edit), tooltip: t.assistantComplete)
              : IconButton.filled(onPressed: onApprove, icon: const Icon(Icons.check), tooltip: t.assistantApprove),
        ],
      ]),
    );
  }
}

/// A film, series, anime or book to add, change or delete. A new one shows its cover; changes and
/// deletions show the item as it is in the log.
class _MediaDraftTile extends StatelessWidget {
  const _MediaDraftTile({required this.draft, required this.base, required this.outcome, required this.onApprove, required this.onReject});
  final Map<String, dynamic> draft;
  final RecordModel? base;
  final String? outcome;
  final VoidCallback onApprove, onReject;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final d = draft, action = d['module'];
    final isNew = action == 'media';
    final missing = !isNew && base == null;
    // A new draft names the hit (media_type, title, year, cover); an existing item is a saved record.
    final Map<String, dynamic> shown = isNew
        ? {...d, 'type': d['media_type']}
        : action == 'media_update' && base != null
            ? mediaDraftBody(d, base: base) ?? base!.data
            : base?.data ?? {};
    // "Dune: Part Two (2024)" and "Film · Done · 20 Nov · ★4 · note".
    (String, String) describe(Map<String, dynamic> x) {
      final year = (x['year'] as num? ?? 0).toInt(), rating = (x['rating'] as num? ?? 0).toInt();
      final done = x['status'] == 'done';
      return (
        '${x['title'] ?? ''}${year > 0 ? ' ($year)' : ''}',
        [
          switch (x['type']) { 'series' => t.mediaSeries, 'anime' => t.mediaAnime, 'book' => t.mediaBook, _ => t.mediaFilm },
          switch (x['status']) { 'done' => t.mediaDone, 'progress' => t.mediaProgress, _ => t.mediaWishlist },
          if (done) _day(context, x['finished_on']),
          if (done && rating > 0) '★$rating',
          '${x['note'] ?? ''}',
        ].where((s) => s.isNotEmpty).join(' · '),
      );
    }

    final (title, line) = missing ? (t.mediaNotFound, '') : describe(shown);
    final before = action == 'media_update' && base != null ? describe(base!.data) : null;
    return _ApprovalTile(
      leading: isNew
          ? Cover(d['cover_url'] as String? ?? '', type: d['media_type'] as String? ?? 'film', width: 28)
          : _actionIcon(context, action, Icons.movie_outlined),
      title: title,
      line: line,
      before: before == null ? null : '${before.$1} · ${before.$2}',
      outcome: outcome,
      onReject: onReject,
      onApprove: missing || (isNew && mediaDraftBody(d) == null) ? null : onApprove,
    );
  }
}

/// A calendar event to add or change (the assistant can't delete events). A change shows the
/// event as it will be, with its previous values from the database.
class _EventDraftTile extends StatelessWidget {
  const _EventDraftTile({required this.draft, required this.base, required this.outcome, required this.onApprove, required this.onReject});
  final Map<String, dynamic> draft;
  final RecordModel? base;
  final String? outcome;
  final VoidCallback onApprove, onReject;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final isNew = draft['module'] == 'event';
    final missing = !isNew && base == null;
    final body = missing ? null : eventDraftBody(draft, base);
    // A saved-shape event → "Servis motor" and "5 Dec · 09:30 · Yearly · 1 hour before · note".
    (String, String) describe(Map<String, dynamic> x) {
      final start = DateTime.parse('${x['starts_at']}').toLocal();
      return (
        '${x['title'] ?? ''}',
        [
          _day(context, start),
          x['all_day'] == true ? t.calendarAllDay : DateFormat.Hm().format(start),
          if (x['yearly'] == true) t.calendarYearly,
          switch (x['reminder']) {
            'at_start' => t.reminderAtStart,
            '10m' => t.reminder10m,
            '1h' => t.reminder1h,
            '1d' => t.reminder1d,
            _ => '',
          },
          '${x['note'] ?? ''}',
        ].where((s) => s.isNotEmpty).join(' · '),
      );
    }

    final (title, line) = body == null ? (missing ? t.eventNotFound : '', '') : describe(body);
    final before = !isNew && base != null ? describe(base!.data) : null;
    return _ApprovalTile(
      leading: _actionIcon(context, draft['module'], Icons.calendar_month_outlined),
      title: title,
      line: line,
      before: before == null ? null : '${before.$1} · ${before.$2}',
      outcome: outcome,
      onReject: onReject,
      onApprove: body == null ? null : onApprove,
    );
  }
}

/// A diary draft: tapping it opens the diary editor.
class _DraftTile extends StatelessWidget {
  const _DraftTile({required this.draft, required this.saved, required this.onTap});
  final Map<String, dynamic> draft;
  final bool saved;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final d = draft;
    final day = _day(context, d['date']);
    final update = d['module'] == 'diary_update';
    return ListTile(
      leading: Icon(update ? Icons.edit_note : Icons.book_outlined),
      title: Text('${t.diary} · $day'),
      subtitle: Text('${(update ? d['content'] : d['text']) ?? ''}', maxLines: 2, overflow: TextOverflow.ellipsis),
      trailing: Icon(saved ? Icons.check_circle : Icons.chevron_right),
      onTap: saved ? null : onTap,
    );
  }
}
