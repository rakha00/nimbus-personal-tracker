import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:pocketbase/pocketbase.dart';

import '../../core/backend.dart';
import 'ledger.dart';

/// Bumped after every finance write so open screens reload.
final financeVersion = ValueNotifier(0);
void financeChanged() => financeVersion.value++;

String rupiah(int v) => '${v < 0 ? '-' : ''}Rp${NumberFormat.decimalPattern('id').format(v.abs())}';

class FinanceData {
  FinanceData(this.accounts, this.categories, this.txs);
  final List<RecordModel> accounts;
  final List<RecordModel> categories;
  final List<RecordModel> txs; // newest first

  late final accountName = {for (final a in accounts) a.id: a.getStringValue('name')};
  late final categoryName = {for (final c in categories) c.id: c.getStringValue('name')};

  late final ledger = txs.map((r) => Tx(
        r.getStringValue('type'),
        r.getIntValue('amount'),
        account: r.getStringValue('account'),
        toAccount: r.getStringValue('to_account'),
        person: r.getStringValue('person'),
      ));

  late final balance = balances({for (final a in accounts) a.id: a.getIntValue('opening_balance')}, ledger);
  late final debts = debtsByPerson(ledger);
  late final persons = {for (final r in txs) r.getStringValue('person')}..remove('');
}

// ponytail: loads every transaction each time; page by month once this gets slow (thousands of rows).
Future<FinanceData> loadFinance() async {
  final res = await Future.wait([
    pb.collection('accounts').getFullList(sort: 'created'),
    pb.collection('categories').getFullList(sort: 'created'),
    pb.collection('transactions').getFullList(sort: '-date,-created'),
  ]);
  return FinanceData(res[0], res[1], res[2]);
}
