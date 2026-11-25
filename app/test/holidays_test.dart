import 'package:flutter_test/flutter_test.dart';
import 'package:nimbus/features/calendar/holidays.dart';

void main() {
  test('keeps public holidays (folded lines joined), drops observances', () {
    const ics = 'BEGIN:VCALENDAR\r\n'
        'BEGIN:VEVENT\r\nDTSTART;VALUE=DATE:20260321\r\nSUMMARY:Hari Idul Fitri\r\nDESCRIPTION:Hari libur nasional\r\nEND:VEVENT\r\n'
        'BEGIN:VEVENT\r\nDTSTART;VALUE=DATE:20260321\r\nSUMMARY:Cuti Bersama\r\n  Idul Fitri\r\nDESCRIPTION:Hari libur nasional\nTanggal\r\n  bisa berubah\r\nEND:VEVENT\r\n'
        'BEGIN:VEVENT\r\nDTSTART;VALUE=DATE:20260219\r\nSUMMARY:1 Ramadan\r\nDESCRIPTION:Perayaan\nUntuk menyembunyikan\r\nEND:VEVENT\r\n'
        'BEGIN:VEVENT\r\nDTSTART;VALUE=DATE:20261225\r\nSUMMARY:Christmas Day\r\nDESCRIPTION:Public holiday\r\nEND:VEVENT\r\n'
        'END:VCALENDAR\r\n';
    expect(parseHolidays(ics), {
      DateTime(2026, 3, 21): ['Hari Idul Fitri', 'Cuti Bersama Idul Fitri'],
      DateTime(2026, 12, 25): ['Christmas Day'],
    });
  });
}
