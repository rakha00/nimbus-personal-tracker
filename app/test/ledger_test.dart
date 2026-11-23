import 'package:flutter_test/flutter_test.dart';
import 'package:nimbus/features/finance/ledger.dart';

void main() {
  // Sample month: two old loans, some spending, a loan paid back in part.
  final txs = [
    const Tx('lend', 500000, person: 'Budi'), // predates tracking: no account
    const Tx('lend', 150000, person: 'Rina'),
    const Tx('expense', 103000, account: 'bank'),
    const Tx('expense', 119000, account: 'cash'),
    const Tx('lend', 1000000, account: 'savings', person: 'Sari'),
    const Tx('expense', 103000, account: 'bank'),
    const Tx('transfer', 50000, account: 'bank', toAccount: 'cash'),
    const Tx('collect', 400000, account: 'savings', person: 'Sari'),
    const Tx('borrow', 20000, account: 'cash', person: 'Budi'),
  ];

  test('balances', () {
    final b = balances({'cash': 200000, 'bank': 900000, 'savings': 3000000}, txs);
    expect(b, {'cash': 200000 - 119000 + 50000 + 20000, 'bank': 900000 - 206000 - 50000, 'savings': 2400000});
  });

  test('debts by person, settled dropped', () {
    final d = debtsByPerson([...txs, const Tx('collect', 150000, person: 'Rina')]);
    expect(d, {'Budi': 480000, 'Sari': 600000});
  });
}
