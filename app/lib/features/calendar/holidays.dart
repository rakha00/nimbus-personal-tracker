import 'package:http/http.dart' as http;

/// Indonesian public holidays and cuti bersama, by day, from Google's public holiday calendar
/// (follows the yearly SKB; covers last few years to next year). Observances like "1 Ramadan" are left out.
Map<DateTime, List<String>> parseHolidays(String ics) {
  final out = <DateTime, List<String>>{};
  // Long iCal lines continue on the next line after a leading space.
  final text = ics.replaceAll(RegExp(r'\r?\n[ \t]'), '');
  for (final event in text.split('BEGIN:VEVENT').skip(1)) {
    String? field(String name) => RegExp('^$name[;:](?:VALUE=DATE:)?(.*)\$', multiLine: true).firstMatch(event)?.group(1)?.trim();
    final description = field('DESCRIPTION') ?? '';
    final date = DateTime.tryParse(field('DTSTART') ?? '');
    final name = field('SUMMARY');
    if (date == null || name == null) continue;
    if (!description.startsWith('Hari libur nasional') && !description.startsWith('Public holiday')) continue;
    (out[date] ??= []).add(name.replaceAll(r'\,', ','));
  }
  return out;
}

/// [lang] is the app's language code ("id" or "en"); Google names the holidays in it.
Future<Map<DateTime, List<String>>> fetchHolidays(String lang) async {
  final id = Uri.encodeComponent('${lang == 'en' ? 'en' : 'id'}.indonesian#holiday@group.v.calendar.google.com');
  final res = await http
      .get(Uri.parse('https://calendar.google.com/calendar/ical/$id/public/basic.ics'))
      .timeout(const Duration(seconds: 15));
  if (res.statusCode != 200) throw http.ClientException('HTTP ${res.statusCode}');
  return parseHolidays(res.body);
}
