import 'package:flutter_test/flutter_test.dart';
import 'package:nimbus/features/media/media_api.dart';
import 'package:nimbus/features/media/media_screen.dart';
import 'package:pocketbase/pocketbase.dart';

void main() {
  final base = RecordModel.fromJson({
    'id': 'm1', 'type': 'film', 'title': 'Dune', 'creator': 'Denis Villeneuve', 'year': 2021,
    'external_id': 'tmdb:438631', 'cover_url': 'https://x/c.jpg', 'synopsis': 'Arrakis.',
    'status': 'wishlist', 'finished_on': '', 'rating': 0, 'note': 'Lihat di bioskop',
  });

  test('a new item takes its details from the fetched hit, status and rating from the draft', () {
    final hit = {'type': 'film', 'external_id': 'tmdb:693134', 'title': 'Dune: Part Two', 'creator': 'Denis Villeneuve', 'year': 2024, 'cover_url': 'u', 'synopsis': 's'};
    final b = mediaDraftBody({'module': 'media', 'media_type': 'film', 'title': 'dune 2', 'status': 'done', 'finished_on': '2026-11-20', 'rating': 4}, hit: hit)!;
    expect([b['title'], b['external_id'], b['status'], b['finished_on'], b['rating']],
        ['Dune: Part Two', 'tmdb:693134', 'done', '2026-11-20 00:00:00.000Z', 4]);
  });

  test('a manual item uses the typed title; no title, no save', () {
    expect(mediaDraftBody({'media_type': 'book', 'title': 'Catatan Kecil', 'status': 'wishlist'})!['external_id'], '');
    expect(mediaDraftBody({'media_type': 'book', 'title': ' ', 'status': 'wishlist'}), isNull);
  });

  test('an update keeps the item and changes only what the draft gives', () {
    final b = mediaDraftBody({'module': 'media_update', 'id': 'm1', 'status': 'done', 'rating': 5}, base: base)!;
    expect([b['title'], b['external_id'], b['note'], b['status'], b['rating']], ['Dune', 'tmdb:438631', 'Lihat di bioskop', 'done', 5]);
    expect(b['finished_on'], isNotEmpty); // done without a date: today
  });

  test('films have no "in progress", and only finished items keep a rating', () {
    expect(mediaBody({'type': 'film', 'title': 'X', 'status': 'progress'})!['status'], 'wishlist');
    expect(mediaBody({'type': 'book', 'title': 'X', 'status': 'progress', 'rating': 4, 'finished_on': '2026-01-01'}), containsPair('rating', 0));
  });

  test('a RAWG game becomes a hit with developers, year and key image', () {
    final h = parseRawg({'results': [{'id': 59, 'name': 'Chrono Trigger', 'released': '1995-03-11', 'background_image': 'https://media.rawg.io/c.jpg', 'developers': [{'name': 'Square'}]}]}).single;
    expect([h['type'], h['external_id'], h['title'], h['creator'], h['year'], h['cover_url']],
        ['game', 'rawg:59', 'Chrono Trigger', 'Square', 1995, 'https://media.rawg.io/c.jpg']);
    expect(mediaBody({...h, 'status': 'progress'})!['status'], 'progress'); // unlike films, games can be in progress
  });
}
