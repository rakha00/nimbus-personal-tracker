import 'package:flutter_test/flutter_test.dart';
import 'package:nimbus/features/finance/tx_filter.dart';
import 'package:pocketbase/pocketbase.dart';

void main() {
  RecordModel tx(String date, String type, {String account = '', String to = '', String cat = '', String note = '', String person = ''}) =>
      RecordModel({
        'id': '$date$type$note',
        'date': '$date 00:00:00.000Z',
        'type': type,
        'account': account,
        'to_account': to,
        'category': cat,
        'note': note,
        'person': person,
      });

  final rows = [
    tx('2026-10-30', 'expense', account: 'bank', cat: 'food'),
    tx('2026-11-20', 'expense', account: 'bank', cat: 'power', note: 'Listrik'),
    tx('2026-11-20', 'expense', account: 'cash', cat: 'food'),
    tx('2026-11-21', 'lend', account: 'savings', person: 'Sari'),
    tx('2026-11-22', 'transfer', account: 'cash', to: 'bank'),
  ];
  const cats = {'food': 'Makan & Minum', 'power': 'Listrik & Air'};
  List<String> ids(TxFilter f) => rows.where((r) => f.matches(r, cats)).map((r) => r.id).toList();
  final nov = TxFilter(month: DateTime(2026, 11));

  test('month only', () => expect(ids(nov).length, 4));
  test('kind debt groups lend/collect/borrow/repay', () => expect(ids(nov.copyWith(kind: 'debt')), ['2026-11-21lend']));
  test('account matches either side of a transfer', () {
    expect(ids(nov.copyWith(account: 'bank')), ['2026-11-20expenseListrik', '2026-11-22transfer']);
  });
  test('search hits note, person and category name', () {
    expect(ids(nov.copyWith(query: 'sari')), ['2026-11-21lend']);
    expect(ids(nov.copyWith(query: 'makan')), ['2026-11-20expense']);
  });
  test('extra count ignores the month', () => expect(nov.copyWith(kind: 'expense', query: 'x').extraCount, 2));
}
