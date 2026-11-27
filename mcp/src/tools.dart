/// Read-only tools over Nimbus data. Every tool only lists records; the `ai_readers` login it
/// runs as can't write (enforced by PocketBase rules), so nothing here can change data.
library;

import 'package:pocketbase/pocketbase.dart';

// Same balance/debt math as the app, so answers match what the phone shows. Imported by path
// (not package:) since the app is a Flutter package; that's also why this file isn't in lib/.
import '../../app/lib/features/finance/ledger.dart';
// TMDB / Google Books / RAWG search, shared with the app's media screen.
import '../../app/lib/features/media/media_api.dart';

/// Indonesia (WIB) has no DST. ponytail: fixed +7; make it configurable if the user ever moves zones.
DateTime wibNow() => DateTime.now().toUtc().add(const Duration(hours: 7));

String ymd(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

/// Parses YYYY-MM-DD; throws a message the model can act on.
DateTime parseDay(Object? v, String name) {
  final d = v is String && RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(v) ? DateTime.tryParse(v) : null;
  if (d == null) throw ArgumentError('$name must be a date YYYY-MM-DD');
  return d;
}

/// Inclusive [from, to] range, at most [maxDays] long.
(DateTime, DateTime) range(Map args, int maxDays) {
  final from = parseDay(args['from'], 'from'), to = parseDay(args['to'], 'to');
  if (to.isBefore(from)) throw ArgumentError('to is before from');
  if (to.difference(from).inDays >= maxDays) throw ArgumentError('range is longer than $maxDays days; ask for a shorter one');
  return (from, to);
}

/// Dates of a calendar event inside [from, to] (local WIB days). Yearly events repeat from their
/// first year on; a yearly 29 Feb only shows in leap years, as in the app.
List<DateTime> occurrences(DateTime start, bool yearly, DateTime from, DateTime to) {
  final day = DateTime(start.year, start.month, start.day);
  if (!yearly) return day.isBefore(from) || day.isAfter(to) ? [] : [day];
  return [
    for (var y = from.year; y <= to.year; y++)
      if (y >= start.year)
        if (DateTime(y, start.month, start.day) case final d when d.month == start.month)
          if (!d.isBefore(from) && !d.isAfter(to)) d,
  ];
}

/// Totals for one month's transactions. Transfers and debts are moves, not income or spending.
Map<String, Object> monthSummary(Iterable<RecordModel> txs, Map<String, String> categoryName) {
  var income = 0, expense = 0;
  final byCategory = <String, int>{};
  for (final r in txs) {
    final type = r.getStringValue('type'), amount = r.getIntValue('amount');
    if (type != 'income' && type != 'expense') continue;
    type == 'income' ? income += amount : expense += amount;
    if (type == 'expense') {
      final c = categoryName[r.getStringValue('category')] ?? '(no category)';
      byCategory[c] = (byCategory[c] ?? 0) + amount;
    }
  }
  final sorted = byCategory.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
  return {'income': income, 'expense': expense, 'net': income - expense, 'expense_by_category': {for (final e in sorted) e.key: e.value}};
}

/// Lowercase words, punctuation dropped: "Teka-Teki Tika" → {teka, tika}.
Set<String> words(String s) => s.toLowerCase().split(RegExp(r'[^\p{L}\p{N}]+', unicode: true)).where((w) => w.isNotEmpty).toSet();

const _limit = 100;
const _txTypes = ['income', 'expense', 'transfer', 'lend', 'collect', 'borrow', 'repay'];

class Nimbus {
  Nimbus(this.pb);
  final PocketBase pb;

  Future<List<RecordModel>> _all(String collection, {String filter = '', String sort = ''}) =>
      pb.collection(collection).getFullList(filter: filter, sort: sort);

  Future<Map<String, String>> _names(String collection) async =>
      {for (final r in await _all(collection)) r.id: r.getStringValue('name')};

  String _dayFilter(String field, DateTime from, DateTime to) =>
      pb.filter('$field >= {:a} && $field <= {:b}', {'a': '${ymd(from)} 00:00:00', 'b': '${ymd(to)} 23:59:59'});

  late final tools = <String, ({String description, Map<String, Object> schema, Future<Object> Function(Map) run})>{
    'lookup': (
      description: 'Today\'s date (WIB) and the names used in Nimbus: accounts, categories by kind, '
          'and people with loan history. Use it to match words in a note to exact names.',
      schema: _schema({}),
      run: (_) async {
        final accounts = await _all('accounts', sort: 'created');
        final categories = await _all('categories', sort: 'created');
        final people = {for (final r in await _all('transactions', filter: 'person != ""')) r.getStringValue('person')};
        return {
          'today': ymd(wibNow()),
          'accounts': [for (final a in accounts) {'name': a.getStringValue('name'), 'type': a.getStringValue('type')}],
          'categories': {
            for (final kind in ['expense', 'income'])
              kind: [for (final c in categories) if (c.getStringValue('kind') == kind) c.getStringValue('name')],
          },
          'people': people.toList()..sort(),
        };
      },
    ),
    'finance_status': (
      description: 'Current balance of every account (Rupiah) and outstanding loans per person '
          '(positive = they owe the user, negative = the user owes them). Computed exactly as the app does.',
      schema: _schema({}),
      run: (_) async {
        final accounts = await _all('accounts', sort: 'created');
        final ledger = [
          for (final r in await _all('transactions'))
            Tx(r.getStringValue('type'), r.getIntValue('amount'),
                account: r.getStringValue('account'), toAccount: r.getStringValue('to_account'), person: r.getStringValue('person')),
        ];
        final b = balances({for (final a in accounts) a.id: a.getIntValue('opening_balance')}, ledger);
        return {
          'balances': {for (final a in accounts) a.getStringValue('name'): b[a.id]},
          'total': b.values.fold(0, (s, v) => s + v),
          'debts': debtsByPerson(ledger),
        };
      },
    ),
    'finance_summary': (
      description: 'Income, spending and spending per category for one month (Rupiah). '
          'Transfers and loans are not counted as income or spending.',
      schema: _schema({'month': _str('Month as YYYY-MM')}, required: ['month']),
      run: (args) async {
        final m = args['month'];
        if (m is! String || !RegExp(r'^\d{4}-\d{2}$').hasMatch(m)) throw ArgumentError('month must be YYYY-MM');
        final from = DateTime.parse('$m-01'), to = DateTime(from.year, from.month + 1, 0);
        final txs = await _all('transactions', filter: _dayFilter('date', from, to));
        return {'month': m, ...monthSummary(txs, await _names('categories'))};
      },
    ),
    'transactions': (
      description: 'Transactions between two dates (at most 92 days), newest first, at most $_limit. '
          'Optional filters match exact names from lookup; query searches the note.',
      schema: _schema({
        'from': _str('YYYY-MM-DD'),
        'to': _str('YYYY-MM-DD'),
        'type': {'type': 'string', 'enum': _txTypes},
        'account': _str('Account name'),
        'category': _str('Category name'),
        'person': _str('Person name'),
        'query': _str('Text to find in the note'),
      }, required: ['from', 'to']),
      run: (args) async {
        final (from, to) = range(args, 92);
        final accounts = await _names('accounts'), categories = await _names('categories');
        String? want(String k) => (args[k] as String?)?.trim().toLowerCase();
        final type = want('type'), account = want('account'), category = want('category'), person = want('person'), q = want('query');
        final rows = [
          for (final r in await _all('transactions', filter: _dayFilter('date', from, to), sort: '-date,-created'))
            if ((type == null || r.getStringValue('type') == type) &&
                (account == null ||
                    [r.getStringValue('account'), r.getStringValue('to_account')].any((id) => accounts[id]?.toLowerCase() == account)) &&
                (category == null || categories[r.getStringValue('category')]?.toLowerCase() == category) &&
                (person == null || r.getStringValue('person').toLowerCase() == person) &&
                (q == null || r.getStringValue('note').toLowerCase().contains(q)))
              {
                'id': r.id, // so a change or deletion can point at it
                'date': r.getStringValue('date').substring(0, 10),
                'type': r.getStringValue('type'),
                'amount': r.getIntValue('amount'),
                'account': accounts[r.getStringValue('account')],
                'to_account': accounts[r.getStringValue('to_account')],
                'category': categories[r.getStringValue('category')],
                'person': r.getStringValue('person'),
                'note': r.getStringValue('note'),
              }..removeWhere((_, v) => v == null || v == ''),
        ];
        return {'count': rows.length, 'truncated': rows.length > _limit, 'transactions': rows.take(_limit).toList()};
      },
    ),
    'diary': (
      description: 'Diary entries (one per day) between two dates, at most 31 days, oldest first.',
      schema: _schema({'from': _str('YYYY-MM-DD'), 'to': _str('YYYY-MM-DD')}, required: ['from', 'to']),
      run: (args) async {
        final (from, to) = range(args, 31);
        return [
          for (final r in await _all('diary_entries', filter: _dayFilter('date', from, to), sort: 'date'))
            {'date': r.getStringValue('date').substring(0, 10), 'content': r.getStringValue('content')},
        ];
      },
    ),
    'media': (
      description: 'Films, series, anime, books and games in the media log, at most $_limit, latest finished first. '
          'status: wishlist, progress (watching/reading/playing) or done. query matches items whose title or '
          'creator has every typed word, ignoring case and punctuation ("teka teki tika" finds '
          '"Teka-Teki Tika"); titles may be stored in their original language.',
      schema: _schema({
        'status': {'type': 'string', 'enum': ['wishlist', 'progress', 'done']},
        'type': {'type': 'string', 'enum': ['film', 'series', 'anime', 'book', 'game']},
        'query': _str('Text to find in title or creator'),
      }),
      run: (args) async {
        final filter = [
          for (final k in ['status', 'type'])
            if (args[k] case final String v) pb.filter('$k = {:v}', {'v': v}),
        ].join(' && ');
        final q = words('${args['query'] ?? ''}');
        final rows = [
          for (final r in await _all('media_items', filter: filter, sort: '-finished_on,-created'))
            if (words('${r.getStringValue('title')} ${r.getStringValue('creator')}').containsAll(q))
              {
                'id': r.id, // so a change or deletion can point at it
                'title': r.getStringValue('title'),
                'type': r.getStringValue('type'),
                'external_id': r.getStringValue('external_id'),
                'status': r.getStringValue('status'),
                'creator': r.getStringValue('creator'),
                'year': r.getIntValue('year'),
                'finished_on': r.getStringValue('finished_on').split(' ').first,
                'rating': r.getIntValue('rating'),
                'note': r.getStringValue('note'),
              }..removeWhere((_, v) => v == '' || v == 0),
        ];
        return {'count': rows.length, 'truncated': rows.length > _limit, 'items': rows.take(_limit).toList()};
      },
    ),
    'media_search': (
      description: 'Search TMDB (film, series, anime), Google Books (book) or RAWG (game) by title; up to 5 hits with '
          'external_id, title, year, creator (books only) and cover_url, best match first. Not the log: use media for that.',
      schema: _schema({
        'type': {'type': 'string', 'enum': ['film', 'series', 'anime', 'book', 'game']},
        'query': _str('Title to search for'),
      }, required: ['type', 'query']),
      run: (args) async {
        final query = '${args['query']}';
        final hits = await searchMedia(args['type'] as String, query, 'id');
        // Titles sharing more of the typed words first (so "bumi manusia" beats "This Earth of
        // Mankind"); the API's own order breaks ties.
        final typed = words(query);
        int score(Hit h) => typed.intersection(words('${h['title']}')).length;
        final ranked = hits.indexed.toList()..sort((a, b) => score(b.$2) != score(a.$2) ? score(b.$2) - score(a.$2) : a.$1 - b.$1);
        return [
          for (final (_, h) in ranked.take(5))
            {for (final k in ['external_id', 'title', 'year', 'creator', 'cover_url']) k: h[k]}..removeWhere((_, v) => v == '' || v == 0),
        ];
      },
    ),
    'events': (
      description: 'Calendar events between two dates (at most 366 days), in date order, with yearly '
          'events (birthdays, anniversaries) repeated; each has the event id. Times are WIB. query keeps '
          'events whose title has every typed word, ignoring case and punctuation.',
      schema: _schema({
        'from': _str('YYYY-MM-DD'),
        'to': _str('YYYY-MM-DD'),
        'query': _str('Words to find in the title'),
      }, required: ['from', 'to']),
      run: (args) async {
        final (from, to) = range(args, 366);
        final q = words('${args['query'] ?? ''}');
        final out = <Map<String, Object>>[];
        // ponytail: loads every event to expand yearly ones; fine for a personal calendar.
        for (final r in await _all('calendar_events')) {
          if (!words(r.getStringValue('title')).containsAll(q)) continue;
          final start = DateTime.parse(r.getStringValue('starts_at')).toUtc().add(const Duration(hours: 7));
          final allDay = r.getBoolValue('all_day');
          for (final d in occurrences(start, r.getBoolValue('yearly'), from, to)) {
            out.add({
              'id': r.id, // so a change can point at it
              'date': ymd(d),
              if (!allDay) 'time': '${start.hour.toString().padLeft(2, '0')}:${start.minute.toString().padLeft(2, '0')}',
              'title': r.getStringValue('title'),
              if (r.getBoolValue('yearly')) 'yearly': true,
              if (r.getStringValue('reminder').isNotEmpty) 'reminder': r.getStringValue('reminder'),
              if (r.getStringValue('note').isNotEmpty) 'note': r.getStringValue('note'),
            });
          }
        }
        out.sort((a, b) => '${a['date']} ${a['time'] ?? ''}'.compareTo('${b['date']} ${b['time'] ?? ''}'));
        return out;
      },
    ),
  };
}

Map<String, Object> _str(String description) => {'type': 'string', 'description': description};

Map<String, Object> _schema(Map<String, Object> properties, {List<String> required = const []}) =>
    {'type': 'object', 'properties': properties, if (required.isNotEmpty) 'required': required, 'additionalProperties': false};
