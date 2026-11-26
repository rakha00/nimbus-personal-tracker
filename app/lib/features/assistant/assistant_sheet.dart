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

/// One box for both: a note becomes drafts (the user checks and saves each in its normal form),
/// a question gets a short answer; the AI decides which. It runs on the server (`ai_requests` +
/// worker) and can't write anything.
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
  final saved = <int>{};

  Future<void> send() async {
    final t = AppLocalizations.of(context);
    final text = prompt.text.trim();
    if (text.isEmpty || busy) return;
    FocusScope.of(context).unfocus();
    setState(() {
      busy = true;
      answer = error = null;
      drafts = [];
      saved.clear();
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
      setState(() {
        if (r.getStringValue('status') == 'error') {
          error = switch (r.getStringValue('error')) {
            'rate_limit' => t.assistantRateLimit,
            'timeout' => t.assistantTimeout,
            _ => t.assistantFailed,
          };
        } else {
          answer = r.getStringValue('answer');
          drafts = [for (final d in r.data['drafts'] as List? ?? []) Map<String, dynamic>.from(d as Map)];
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

  /// Opens the module's normal form filled with the draft; the user saves it there.
  Future<void> open(int i) async {
    final d = drafts[i];
    final date = DateTime.tryParse('${d['date']}') ?? dayOnly(DateTime.now());
    try {
      final Widget page = switch (d['module']) {
        'transaction' => TransactionForm(data: await loadFinance(), draft: d),
        'diary' => DiaryEditor(
            date: date,
            entry: (await pb.collection('diary_entries').getList(perPage: 1, filter: pb.filter('date = {:d}', {'d': toPbDate(date)})))
                .items
                .firstOrNull,
            append: d['text'] as String? ?? '',
          ),
        'media' => await _mediaForm(d),
        _ => EventForm(day: date, draft: d),
      };
      if (!mounted) return;
      final ok = await Navigator.push<bool>(context, MaterialPageRoute(builder: (_) => page));
      if (ok == true && mounted) {
        setState(() => saved.add(i));
        widget.onSaved();
      }
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context).loadFailed)));
    }
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
    final small = Theme.of(context).textTheme.bodySmall;
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
          const SizedBox(height: 16),
          Text(t.assistantDraftsHint, style: small),
          const SizedBox(height: 8),
          Card(
            clipBehavior: Clip.antiAlias,
            child: Column(children: [
              for (final (i, d) in drafts.indexed) ...[
                if (i > 0) const Divider(indent: 16, endIndent: 16),
                _DraftTile(draft: d, saved: saved.contains(i), onTap: () => open(i)),
              ],
            ]),
          ),
        ],
      ]),
    );
  }
}

class _DraftTile extends StatelessWidget {
  const _DraftTile({required this.draft, required this.saved, required this.onTap});
  final Map<String, dynamic> draft;
  final bool saved;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final d = draft;
    final date = DateTime.tryParse('${d['date'] ?? d['finished_on']}');
    final day = date == null ? '' : DateFormat.yMMMd(Localizations.localeOf(context).toString()).format(date);
    final (icon, title, parts) = switch (d['module']) {
      'transaction' => (
          Icons.account_balance_wallet_outlined,
          '${switch (d['type']) {
            'income' => t.income,
            'transfer' => t.transfer,
            'lend' => t.debtLend,
            'collect' => t.debtCollect,
            'borrow' => t.debtBorrow,
            'repay' => t.debtRepay,
            _ => t.expense,
          }} ${rupiah((d['amount'] as num? ?? 0).toInt())}',
          [day, d['account'], d['category'], d['person'], d['note']],
        ),
      'diary' => (Icons.book_outlined, '${t.diary} · $day', [d['text']]),
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
