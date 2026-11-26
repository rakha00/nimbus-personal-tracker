import '../src/tools.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:test/test.dart';

void main() {
  test('yearly events repeat from their first year, one-off events only once', () {
    final from = DateTime(2026, 1, 1), to = DateTime(2027, 12, 31);
    expect(occurrences(DateTime(2001, 3, 5), true, from, to), [DateTime(2026, 3, 5), DateTime(2027, 3, 5)]);
    expect(occurrences(DateTime(2027, 3, 5), true, from, to), [DateTime(2027, 3, 5)]);
    expect(occurrences(DateTime(2000, 2, 29), true, DateTime(2027, 1, 1), DateTime(2028, 12, 31)), [DateTime(2028, 2, 29)]);
    expect(occurrences(DateTime(2026, 6, 1, 9), false, from, to), [DateTime(2026, 6, 1)]);
    expect(occurrences(DateTime(2025, 6, 1), false, from, to), isEmpty);
  });

  test('month summary counts only income and expense', () {
    RecordModel tx(String type, int amount, [String category = '']) =>
        RecordModel.fromJson({'id': '$type$amount', 'type': type, 'amount': amount, 'category': category});
    final s = monthSummary([
      tx('income', 1000, 'gaji'),
      tx('expense', 200, 'makan'),
      tx('expense', 50, 'makan'),
      tx('expense', 300, 'listrik'),
      tx('expense', 10),
      tx('transfer', 999),
      tx('lend', 500),
    ], {'gaji': 'Gaji', 'makan': 'Makan', 'listrik': 'Listrik'});
    expect(s['income'], 1000);
    expect(s['expense'], 560);
    expect(s['net'], 440);
    expect((s['expense_by_category'] as Map).entries.map((e) => '${e.key}=${e.value}'),
        ['Listrik=300', 'Makan=250', '(no category)=10']);
  });

  test('ranges are capped', () {
    expect(range({'from': '2026-01-01', 'to': '2026-01-31'}, 31).$2, DateTime(2026, 1, 31));
    expect(() => range({'from': '2026-01-01', 'to': '2026-02-01'}, 31), throwsArgumentError);
    expect(() => range({'from': '2026-02-01', 'to': '2026-01-01'}, 31), throwsArgumentError);
    expect(() => range({'from': 'kemarin', 'to': '2026-01-01'}, 31), throwsArgumentError);
  });
}
