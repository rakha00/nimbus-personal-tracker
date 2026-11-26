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
  final outcome = <int, String>{}; // draft index → saved | rejected | failed

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

  /// Writes an approved transaction draft, with the user's own login.
  Future<void> approve(int i) async {
    final d = drafts[i], f = finance!;
    final tx = pb.collection('transactions');
    try {
      switch (d['module']) {
        case 'transaction_delete':
          await tx.delete(d['id'] as String);
        case 'transaction_update':
          await tx.update(d['id'] as String, body: f.draftBody(d, _base(d))!);
        default:
          await tx.create(body: {'owner': userId, ...f.draftBody(d)!});
      }
      financeChanged();
      _done(i, 'saved');
    } catch (_) {
      _done(i, 'failed');
    }
  }

  RecordModel? _base(Map<String, dynamic> d) => finance?.txs.where((r) => r.id == d['id']).firstOrNull;

  /// Opens the module's normal form filled with the draft; the user saves it there.
  Future<void> open(int i) async {
    final d = drafts[i];
    final date = DateTime.tryParse('${d['date']}') ?? dayOnly(DateTime.now());
    try {
      final Widget page = switch (d['module']) {
        'transaction' => TransactionForm(data: finance!, draft: d),
        'diary' || 'diary_update' => await _diaryEditor(d, date),
        'media' => await _mediaForm(d),
        _ => EventForm(day: date, draft: d),
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

  /// A title already in the log is updated (e.g. wishlist → done) instead of added twice.
  Future<MediaForm> _mediaForm(Map<String, dynamic> d) async {
    final title = d['title'] as String? ?? '';
    final hits = await pb.collection('media_items').getFullList(filter: pb.filter('title ~ {:t}', {'t': title}));
    final RecordModel? existing = hits.where((h) => h.getStringValue('title').toLowerCase() == title.toLowerCase()).firstOrNull;
    final type = existing?.getStringValue('type') ?? d['media_type'] as String? ?? 'film';
    final status = d['status'] as String? ?? 'wishlist';
    return MediaForm(
      id: existing?.id,
      status: type == 'film' && status == 'progress' ? 'wishlist' : status, // films have no "in progress"
      data: {
        'type': type,
        'title': title,
        ...?existing?.data,
        'finished_on': ?d['finished_on'],
        'rating': ?d['rating'],
        if (existing == null || existing.getStringValue('note').isEmpty) 'note': ?d['note'],
      },
    );
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
    final canApprove = !missing && (action == 'transaction_delete' || body != null);
    final cs = Theme.of(context).colorScheme;
    final small = Theme.of(context).textTheme.bodySmall;
    Text oneLine(String s, [TextStyle? style]) => Text(s, maxLines: 1, overflow: TextOverflow.ellipsis, style: style);

    // One compact row: what it does (leading icon), the transaction, then reject / approve.
    return ListTile(
      dense: true,
      contentPadding: const EdgeInsets.only(left: 16, right: 4),
      leading: switch (action) {
        'transaction_update' => const Icon(Icons.edit_outlined),
        'transaction_delete' => Icon(Icons.delete_outline, color: cs.error),
        _ => const Icon(Icons.account_balance_wallet_outlined),
      },
      title: oneLine(title),
      subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        if (line.isNotEmpty) oneLine(line),
        if (before != null) oneLine('${t.assistantBefore}: ${before.$1} · ${before.$2}', small),
        if (incomplete) oneLine(t.assistantIncomplete, TextStyle(color: cs.error)),
      ]),
      trailing: Row(mainAxisSize: MainAxisSize.min, children: [
        if (outcome != null)
          Padding(
            padding: const EdgeInsets.all(12),
            child: switch (outcome) {
              'saved' => Icon(Icons.check_circle, semanticLabel: t.assistantSaved),
              'rejected' => Icon(Icons.block, color: cs.outline, semanticLabel: t.assistantRejected),
              _ => Icon(Icons.error_outline, color: cs.error, semanticLabel: t.saveFailed),
            },
          )
        else ...[
          IconButton(onPressed: onReject, icon: const Icon(Icons.close), tooltip: t.assistantReject),
          incomplete
              ? IconButton.filled(onPressed: onComplete, icon: const Icon(Icons.edit), tooltip: t.assistantComplete)
              : IconButton.filled(onPressed: canApprove ? onApprove : null, icon: const Icon(Icons.check), tooltip: t.assistantApprove),
        ],
      ]),
    );
  }
}

/// A diary, media or calendar draft: tapping it opens the normal form.
class _DraftTile extends StatelessWidget {
  const _DraftTile({required this.draft, required this.saved, required this.onTap});
  final Map<String, dynamic> draft;
  final bool saved;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final d = draft;
    final day = _day(context, d['date'] ?? d['finished_on']);
    final (icon, title, parts) = switch (d['module']) {
      'diary' => (Icons.book_outlined, '${t.diary} · $day', [d['text']]),
      'diary_update' => (Icons.edit_note, '${t.diary} · $day', [d['content']]),
      'media' => (
          Icons.movie_outlined,
          '${d['title'] ?? ''}',
          [switch (d['status']) { 'done' => t.mediaDone, 'progress' => t.mediaProgress, _ => t.mediaWishlist }, day],
        ),
      _ => (Icons.calendar_month_outlined, '${d['title'] ?? ''}', [day, d['time']]),
    };
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(parts.whereType<String>().where((s) => s.isNotEmpty).join(' · '), maxLines: 2, overflow: TextOverflow.ellipsis),
      trailing: Icon(saved ? Icons.check_circle : Icons.chevron_right),
      onTap: saved ? null : onTap,
    );
  }
}
