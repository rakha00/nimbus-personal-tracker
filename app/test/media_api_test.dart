import 'package:flutter_test/flutter_test.dart';
import 'package:nimbus/features/media/media_api.dart';

void main() {
  test('TMDB hit maps to a media_items body', () {
    final hits = parseTmdb({
      'results': [
        {'id': 42, 'title': 'Contoh Film', 'release_date': '2019-05-01', 'poster_path': '/p.jpg', 'overview': 'Sinopsis.'},
        {'id': 7, 'title': 'Tanpa Tanggal', 'release_date': '', 'poster_path': null},
      ],
    });
    expect(hits[0], {
      'type': 'film',
      'external_id': 'tmdb:42',
      'title': 'Contoh Film',
      'creator': '',
      'year': 2019,
      'cover_url': 'https://image.tmdb.org/t/p/w342/p.jpg',
      'synopsis': 'Sinopsis.',
    });
    expect([hits[1]['year'], hits[1]['cover_url'], hits[1]['synopsis']], [0, '', '']);
  });

  test('TMDB TV hits map to series, and to anime only when animated', () {
    final json = {
      'results': [
        {'id': 42, 'name': 'Contoh Serial', 'first_air_date': '2021-01-01', 'poster_path': null, 'genre_ids': [18]},
        {'id': 9, 'name': 'Contoh Anime', 'first_air_date': '2023-09-29', 'poster_path': null, 'genre_ids': [16, 10759]},
      ],
    };
    final tv = parseTmdb(json, 'series');
    expect([tv[0]['type'], tv[0]['external_id'], tv[0]['title'], tv[0]['year']], ['series', 'tmdbtv:42', 'Contoh Serial', 2021]);
    final anime = parseTmdb(json, 'anime');
    expect(anime, hasLength(1));
    expect([anime[0]['type'], anime[0]['external_id'], anime[0]['year']], ['anime', 'tmdbtv:9', 2023]);
  });

  test('Google Books hit maps authors, year and an https cover', () {
    final hits = parseBooks({
      'items': [
        {
          'id': 'abc',
          'volumeInfo': {
            'title': 'Buku Contoh',
            'authors': ['A. Penulis', 'B. Penulis'],
            'publishedDate': '2005',
            'imageLinks': {'thumbnail': 'http://books.example/c.jpg'},
          },
        },
        {'id': 'bare'}, // no volumeInfo: skipped
      ],
    });
    expect(hits, hasLength(1));
    expect(hits[0]['creator'], 'A. Penulis, B. Penulis');
    expect(hits[0]['year'], 2005);
    expect(hits[0]['cover_url'], 'https://books.example/c.jpg');
    expect(parseBooks({}), isEmpty); // no results: Google omits "items"
  });
}
