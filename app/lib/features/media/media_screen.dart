import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pocketbase/pocketbase.dart';

import '../../core/backend.dart';
import '../../core/theme.dart';
import '../../l10n/app_localizations.dart';
import 'media_api.dart';

/// Films and books: a wishlist, and a log of what's been watched or read.
class MediaScreen extends StatefulWidget {
  const MediaScreen({super.key});

  @override
  State<MediaScreen> createState() => _MediaScreenState();
}

class _MediaScreenState extends State<MediaScreen> {
  // Wishlist items have no finished_on, so they fall back to newest added first.
  late Future<List<RecordModel>> items = load();
  String status = 'wishlist';
  String type = ''; // '' = all
  final filter = TextEditingController();
  List<RecordModel> saved = []; // last load, so search can tell what's already in the list

  Future<List<RecordModel>> load() async =>
      saved = await pb.collection('media_items').getFullList(sort: '-finished_on,-created');

  void reload() => setState(() => items = load());

  Future<void> open(Widget page) async {
    final changed = await Navigator.push<bool>(context, MaterialPageRoute(builder: (_) => page));
    if (changed == true) reload();
  }

  void edit(RecordModel item, {bool finish = false}) => open(MediaForm(
        data: item.data,
        id: item.id,
        status: finish ? 'done' : item.getStringValue('status'),
      ));

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(t.mediaTab)),
      floatingActionButton: FloatingActionButton(
        onPressed: () => open(MediaSearch(
          type: type.isEmpty ? 'film' : type,
          status: status,
          saved: {
            for (final e in saved)
              if (e.getStringValue('external_id').isNotEmpty) e.getStringValue('external_id'): e,
          },
        )),
        tooltip: t.add,
        child: const Icon(Icons.add),
      ),
      body: FutureBuilder(
        future: items,
        builder: (context, snap) {
          if (snap.hasError) {
            return RefreshIndicator(
              onRefresh: () async => reload(),
              child: ListView(children: [ListTile(title: Text(t.loadFailed))]),
            );
          }
          final all = snap.data;
          if (all == null) return const Center(child: CircularProgressIndicator());
          final q = filter.text.trim().toLowerCase();
          final list = all
              .where((e) =>
                  e.getStringValue('status') == status &&
                  (type.isEmpty || e.getStringValue('type') == type) &&
                  (q.isEmpty ||
                      e.getStringValue('title').toLowerCase().contains(q) ||
                      e.getStringValue('creator').toLowerCase().contains(q)))
              .toList();
          return RefreshIndicator(
            onRefresh: () async {
              reload();
              await items;
            },
            child: ListView(padding: const EdgeInsets.fromLTRB(16, 4, 16, 88), children: [
              SegmentedButton<String>(
                showSelectedIcon: false,
                segments: [
                  ButtonSegment(value: 'wishlist', label: Text(t.mediaWishlist)),
                  ButtonSegment(value: 'done', label: Text(t.mediaDone)),
                ],
                selected: {status},
                onSelectionChanged: (s) => setState(() => status = s.first),
              ),
              const SizedBox(height: 12),
              Wrap(spacing: 8, children: [
                for (final (id, label) in [('', t.all), ('film', t.mediaFilm), ('book', t.mediaBook)])
                  ChoiceChip(label: Text(label), selected: type == id, onSelected: (_) => setState(() => type = id)),
              ]),
              const SizedBox(height: 12),
              TextField(
                controller: filter,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: t.mediaFilterHint,
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: q.isEmpty
                      ? null
                      : IconButton(
                          onPressed: () => setState(filter.clear),
                          icon: const Icon(Icons.close),
                          tooltip: t.reset,
                        ),
                ),
              ),
              const SizedBox(height: 16),
              if (list.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(4),
                  child: Text(q.isNotEmpty ? t.mediaNoResults : status == 'wishlist' ? t.mediaEmptyWishlist : t.mediaEmptyDone,
                      style: Theme.of(context).textTheme.bodySmall),
                )
              else
                Card(
                  clipBehavior: Clip.antiAlias,
                  child: Column(children: [
                    for (final (i, e) in list.indexed) ...[
                      if (i > 0) const Divider(indent: 16, endIndent: 16),
                      _MediaRow(
                        data: e.data,
                        onTap: () => edit(e),
                        trailing: e.getStringValue('status') == 'done'
                            ? (e.getIntValue('rating') > 0 ? Stars(e.getIntValue('rating'), size: 14) : null)
                            : IconButton(
                                onPressed: () => edit(e, finish: true),
                                icon: const Icon(Icons.check_circle_outline),
                                tooltip: t.mediaMarkDone,
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

/// Cover, title, and "creator · year · finished" under it. Used for saved items and search hits.
class _MediaRow extends StatelessWidget {
  const _MediaRow({required this.data, required this.onTap, this.trailing});
  final Map<String, dynamic> data;
  final VoidCallback onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final year = data['year'] as num? ?? 0;
    final finished = data['status'] == 'done' ? data['finished_on'] as String? ?? '' : '';
    final sub = [
      data['creator'] as String? ?? '',
      if (year > 0) '$year',
      if (finished.isNotEmpty) DateFormat.yMMMd(Localizations.localeOf(context).toString()).format(fromPbDate(finished)),
    ].where((s) => s.isNotEmpty).join(' · ');
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
        child: Row(children: [
          Cover(data['cover_url'] as String? ?? '', type: data['type'] as String? ?? 'film', width: 40),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(data['title'] as String? ?? '', maxLines: 2, overflow: TextOverflow.ellipsis),
              if (sub.isNotEmpty) Text(sub, style: Theme.of(context).textTheme.bodySmall, maxLines: 1, overflow: TextOverflow.ellipsis),
            ]),
          ),
          ?trailing,
        ]),
      ),
    );
  }
}

/// 2:3 cover from a link; an icon on a plain tile when there's none or it fails to load.
class Cover extends StatelessWidget {
  const Cover(this.url, {super.key, required this.type, required this.width});
  final String url, type;
  final double width;

  @override
  Widget build(BuildContext context) {
    final l = Ledger.of(context);
    final empty = Container(
      color: l.raised,
      alignment: Alignment.center,
      child: Icon(type == 'book' ? Icons.menu_book_outlined : Icons.movie_outlined, size: width * .45),
    );
    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: SizedBox(
        width: width,
        height: width * 1.5,
        child: url.isEmpty ? empty : Image.network(url, fit: BoxFit.cover, errorBuilder: (_, _, _) => empty),
      ),
    );
  }
}

/// 1–5 stars in ink. With [onTap] it's an input; tapping the current value clears it.
class Stars extends StatelessWidget {
  const Stars(this.value, {super.key, this.size = 28, this.onTap});
  final int value;
  final double size;
  final ValueChanged<int>? onTap;

  @override
  Widget build(BuildContext context) {
    final l = Ledger.of(context);
    Widget star(int i) =>
        Icon(i <= value ? Icons.star : Icons.star_border, size: size, color: i <= value ? l.text : l.control);
    return Row(mainAxisSize: MainAxisSize.min, children: [
      for (var i = 1; i <= 5; i++)
        onTap == null
            ? star(i)
            : IconButton(onPressed: () => onTap!(i == value ? 0 : i), icon: star(i), tooltip: '$i'),
    ]);
  }
}

/// Type a title, pick a hit from TMDB / Google Books; the form opens already filled.
class MediaSearch extends StatefulWidget {
  const MediaSearch({super.key, required this.type, required this.status, required this.saved});
  final String type, status;
  final Map<String, RecordModel> saved; // by external_id

  @override
  State<MediaSearch> createState() => _MediaSearchState();
}

class _MediaSearchState extends State<MediaSearch> {
  late String type = widget.type;
  final query = TextEditingController();
  Future<List<Hit>>? results;
  bool busy = false;
  Timer? typing;

  void search() {
    typing?.cancel();
    final q = query.text.trim();
    // FutureBuilder only follows the latest future, so a slow earlier search can't overwrite this one.
    setState(() => results = q.length < 2 ? null : searchMedia(type, q, Localizations.localeOf(context).languageCode));
  }

  @override
  void dispose() {
    typing?.cancel();
    super.dispose();
  }

  Future<void> pick(Hit? hit) async {
    // Already in the list: open that item instead of adding it twice.
    final existing = widget.saved[hit?['external_id']];
    if (existing != null) {
      return done(MediaForm(data: existing.data, id: existing.id, status: existing.getStringValue('status')));
    }
    setState(() => busy = true);
    // Without the extra details the pick is still worth saving, so fall back to the bare hit.
    final Hit data = hit == null ? {'type': type, 'title': query.text.trim()} : await completeHit(hit).catchError((_) => hit);
    if (!mounted) return;
    setState(() => busy = false);
    await done(MediaForm(data: data, status: widget.status));
  }

  Future<void> done(MediaForm form) async {
    final changed = await Navigator.push<bool>(context, MaterialPageRoute(builder: (_) => form));
    if (changed == true && mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final small = Theme.of(context).textTheme.bodySmall;
    final manual = TextButton.icon(
      onPressed: busy ? null : () => pick(null),
      icon: const Icon(Icons.edit_outlined, size: 18),
      label: Text(t.mediaManual),
    );
    return Scaffold(
      appBar: AppBar(title: Text(t.add)),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        SegmentedButton<String>(
          showSelectedIcon: false,
          segments: [
            ButtonSegment(value: 'film', label: Text(t.mediaFilm), icon: const Icon(Icons.movie_outlined)),
            ButtonSegment(value: 'book', label: Text(t.mediaBook), icon: const Icon(Icons.menu_book_outlined)),
          ],
          selected: {type},
          onSelectionChanged: (s) {
            type = s.first;
            search();
          },
        ),
        const SizedBox(height: 12),
        TextField(
          controller: query,
          autofocus: true,
          textInputAction: TextInputAction.search,
          onSubmitted: (_) => search(),
          onChanged: (_) {
            typing?.cancel();
            typing = Timer(const Duration(milliseconds: 400), search);
          },
          decoration: InputDecoration(
            hintText: t.mediaSearchHint,
            prefixIcon: const Icon(Icons.search),
            suffixIcon: IconButton(onPressed: search, icon: const Icon(Icons.arrow_forward), tooltip: t.search),
          ),
        ),
        if (busy) const Padding(padding: EdgeInsets.only(top: 12), child: LinearProgressIndicator()),
        const SizedBox(height: 16),
        if (results != null)
          FutureBuilder(
            future: results,
            builder: (context, snap) {
              // While the next keystroke's search runs, the previous hits stay on screen.
              if (snap.connectionState != ConnectionState.done && !snap.hasData) {
                return const Padding(padding: EdgeInsets.all(24), child: Center(child: CircularProgressIndicator()));
              }
              final hits = snap.data ?? [];
              if (hits.isEmpty) {
                return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Padding(
                    padding: const EdgeInsets.all(4),
                    child: Text(snap.hasError ? t.mediaSearchFailed : t.mediaNoResults, style: small),
                  ),
                  manual,
                ]);
              }
              return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Card(
                  clipBehavior: Clip.antiAlias,
                  child: Column(children: [
                    for (final (i, h) in hits.indexed) ...[
                      if (i > 0) const Divider(indent: 16, endIndent: 16),
                      _MediaRow(
                        data: h,
                        onTap: busy ? () {} : () => pick(h),
                        trailing: switch (widget.saved[h['external_id']]?.getStringValue('status')) {
                          null => null,
                          final s => Padding(
                              padding: const EdgeInsets.only(left: 8, right: 8),
                              child: Text(s == 'done' ? t.mediaDone : t.mediaWishlist, style: small),
                            ),
                        },
                      ),
                    ],
                  ]),
                ),
                const SizedBox(height: 8),
                manual,
              ]);
            },
          )
        else
          manual,
      ]),
    );
  }
}

/// Add or edit one item; for an existing one it doubles as the detail page.
/// Items picked from search show their details read-only; manual ones get plain fields.
class MediaForm extends StatefulWidget {
  const MediaForm({super.key, required this.data, this.id, required this.status});
  final Map<String, dynamic> data;
  final String? id; // null = new
  final String status;

  @override
  State<MediaForm> createState() => _MediaFormState();
}

class _MediaFormState extends State<MediaForm> {
  late final d = widget.data;
  late final fromSearch = (d['external_id'] as String? ?? '').isNotEmpty;
  late String type = d['type'] as String? ?? 'film';
  late String status = widget.status;
  late final title = TextEditingController(text: d['title'] as String? ?? '');
  late final creator = TextEditingController(text: d['creator'] as String? ?? '');
  late final year = TextEditingController(text: (d['year'] as num? ?? 0) > 0 ? '${d['year']}' : '');
  late final note = TextEditingController(text: d['note'] as String? ?? '');
  late int rating = (d['rating'] as num? ?? 0).toInt();
  late DateTime finished = (d['finished_on'] as String? ?? '').isEmpty
      ? dayOnly(DateTime.now())
      : fromPbDate(d['finished_on'] as String);
  bool busy = false;
  String? error;

  Future<void> save() async {
    if (title.text.trim().isEmpty) return setState(() => error = AppLocalizations.of(context).required);
    final done = status == 'done';
    final body = {
      'owner': userId,
      'type': type,
      'title': title.text.trim(),
      'creator': creator.text.trim(),
      'year': int.tryParse(year.text) ?? 0,
      'external_id': d['external_id'] ?? '',
      'cover_url': d['cover_url'] ?? '',
      'synopsis': d['synopsis'] ?? '',
      'status': status,
      'finished_on': done ? toPbDate(finished) : '',
      'rating': done ? rating : 0,
      'note': note.text.trim(),
    };
    final id = widget.id;
    await _run(() => id == null
        ? pb.collection('media_items').create(body: body)
        : pb.collection('media_items').update(id, body: body));
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
    if (yes == true) await _run(() => pb.collection('media_items').delete(widget.id!));
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
    final text = Theme.of(context).textTheme;
    final sub = [creator.text, year.text].where((s) => s.isNotEmpty).join(' · ');
    final synopsis = d['synopsis'] as String? ?? '';
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.id == null ? t.add : ''),
        actions: [
          if (widget.id != null)
            IconButton(onPressed: busy ? null : delete, icon: const Icon(Icons.delete_outline), tooltip: t.delete),
          TextButton(onPressed: busy ? null : save, child: Text(t.save)),
        ],
      ),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        if (fromSearch) ...[
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Cover(d['cover_url'] as String? ?? '', type: type, width: 96),
            const SizedBox(width: 16),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(title.text, style: text.titleMedium),
                if (sub.isNotEmpty) ...[const SizedBox(height: 4), Text(sub, style: text.bodySmall)],
              ]),
            ),
          ]),
          if (synopsis.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(t.mediaSynopsis, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
            const SizedBox(height: 4),
            Text(synopsis, style: text.bodyMedium?.copyWith(height: 1.45)),
          ],
        ] else ...[
          SegmentedButton<String>(
            showSelectedIcon: false,
            segments: [
              ButtonSegment(value: 'film', label: Text(t.mediaFilm), icon: const Icon(Icons.movie_outlined)),
              ButtonSegment(value: 'book', label: Text(t.mediaBook), icon: const Icon(Icons.menu_book_outlined)),
            ],
            selected: {type},
            onSelectionChanged: (s) => setState(() => type = s.first),
          ),
          const SizedBox(height: 16),
          Labeled(t.mediaTitle, TextField(controller: title, autofocus: title.text.isEmpty, textCapitalization: TextCapitalization.sentences)),
          const SizedBox(height: 16),
          Labeled(type == 'book' ? t.mediaAuthor : t.mediaDirector,
              TextField(controller: creator, textCapitalization: TextCapitalization.words)),
          const SizedBox(height: 16),
          Labeled(t.mediaYear, TextField(
            controller: year,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(4)],
            style: const TextStyle(fontFeatures: tabular),
          )),
        ],
        const SizedBox(height: 24),
        SegmentedButton<String>(
          showSelectedIcon: false,
          segments: [
            ButtonSegment(value: 'wishlist', label: Text(t.mediaWishlist)),
            ButtonSegment(value: 'done', label: Text(t.mediaDone)),
          ],
          selected: {status},
          onSelectionChanged: (s) => setState(() => status = s.first),
        ),
        if (status == 'done') ...[
          const SizedBox(height: 16),
          Labeled(t.mediaFinishedOn, OutlinedButton.icon(
            style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(44), alignment: Alignment.centerLeft),
            icon: const Icon(Icons.calendar_today_outlined, size: 18),
            label: Text(DateFormat.yMMMMEEEEd(Localizations.localeOf(context).toString()).format(finished)),
            onPressed: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: finished,
                firstDate: DateTime(1950),
                lastDate: DateTime.now(),
              );
              if (picked != null) setState(() => finished = picked);
            },
          )),
          const SizedBox(height: 16),
          Labeled(t.mediaRating, Stars(rating, onTap: (v) => setState(() => rating = v))),
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
