import 'dart:convert';

import 'package:http/http.dart' as http;

/// Set at build time from config.json, like the server URL.
const _tmdbKey = String.fromEnvironment('TMDB_KEY');

/// A search hit, already shaped like a `media_items` record body.
typedef Hit = Map<String, dynamic>;

int _year(Object? date) => int.tryParse('${date ?? ''}'.padRight(4).substring(0, 4)) ?? 0;

/// Films, series and anime all come from TMDB; series and anime are TV shows (`name` / `first_air_date`,
/// their own id space), and anime keeps only animated shows (genre 16).
List<Hit> parseTmdb(Map<String, dynamic> json, [String type = 'film']) => [
      for (final m in (json['results'] as List? ?? []).cast<Map<String, dynamic>>())
        if (type != 'anime' || (m['genre_ids'] as List? ?? []).contains(16)) {
          'type': type,
          'external_id': '${type == 'film' ? 'tmdb' : 'tmdbtv'}:${m['id']}',
          'title': m['title'] ?? m['name'] ?? '',
          'creator': '',
          'year': _year(m['release_date'] ?? m['first_air_date']),
          'cover_url': m['poster_path'] == null ? '' : 'https://image.tmdb.org/t/p/w342${m['poster_path']}',
          'synopsis': m['overview'] ?? '',
        },
    ];

List<Hit> parseBooks(Map<String, dynamic> json) => [
      for (final b in (json['items'] as List? ?? []).cast<Map<String, dynamic>>())
        if (b['volumeInfo'] case final Map<String, dynamic> v)
          {
            'type': 'book',
            'external_id': 'gbooks:${b['id']}',
            'title': v['title'] ?? '',
            'creator': (v['authors'] as List? ?? []).join(', '),
            'year': _year(v['publishedDate']),
            'cover_url': ((v['imageLinks'] as Map?)?['thumbnail'] as String? ?? '').replaceFirst('http://', 'https://'),
            'synopsis': v['description'] ?? '',
          },
    ];

Future<Map<String, dynamic>> _get(Uri uri, [Map<String, String>? headers]) async {
  final res = await http.get(uri, headers: headers).timeout(const Duration(seconds: 15));
  if (res.statusCode != 200) throw http.ClientException('HTTP ${res.statusCode}', uri);
  return jsonDecode(res.body) as Map<String, dynamic>;
}

// v3 API keys (32 chars) go in the query; v4 read-access tokens (long JWTs) go in a header.
Future<Map<String, dynamic>> _tmdb(String path, Map<String, String> query) {
  final bearer = _tmdbKey.length > 40;
  return _get(
    Uri.https('api.themoviedb.org', '/3$path', {...query, if (!bearer) 'api_key': _tmdbKey}),
    bearer ? {'Authorization': 'Bearer $_tmdbKey'} : null,
  );
}

/// [lang] is the app's language code ("id" or "en").
Future<List<Hit>> searchMedia(String type, String query, String lang) async => switch (type) {
      'book' => parseBooks(await _get(Uri.https('www.googleapis.com', '/books/v1/volumes', {'q': query, 'maxResults': '20'}))),
      _ => parseTmdb(
          await _tmdb(type == 'film' ? '/search/movie' : '/search/tv', {'query': query, 'language': lang == 'id' ? 'id-ID' : 'en-US'}),
          type),
    };

/// A film's director, a series' creators, an anime's studios (and an English synopsis when there's none
/// in Indonesian) need extra calls, so they're fetched only for the picked hit. Books are already complete.
Future<Hit> completeHit(Hit hit) async {
  final id = (hit['external_id'] as String).split(':').last;
  var synopsis = hit['synopsis'] as String;
  if (hit['type'] case 'series' || 'anime') {
    final tv = await _tmdb('/tv/$id', {'language': 'en-US'});
    if (synopsis.isEmpty) synopsis = tv['overview'] ?? '';
    final people = tv[hit['type'] == 'anime' ? 'production_companies' : 'created_by'] as List? ?? [];
    return {...hit, 'creator': [for (final c in people) c['name']].join(', '), 'synopsis': synopsis};
  }
  if (hit['type'] != 'film') return hit;
  final credits = await _tmdb('/movie/$id/credits', {});
  final directors = [
    for (final c in (credits['crew'] as List? ?? []).cast<Map<String, dynamic>>())
      if (c['job'] == 'Director') c['name'],
  ];
  if (synopsis.isEmpty) synopsis = (await _tmdb('/movie/$id', {'language': 'en-US'}))['overview'] ?? '';
  return {...hit, 'creator': directors.join(', '), 'synopsis': synopsis};
}
