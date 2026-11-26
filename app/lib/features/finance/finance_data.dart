import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:pocketbase/pocketbase.dart';

import '../../core/backend.dart';
import 'ledger.dart';

/// Bumped after every finance write so open screens reload.
final financeVersion = ValueNotifier(0);
void financeChanged() => financeVersion.value++;

String rupiah(int v) => '${v < 0 ? '-' : ''}Rp${NumberFormat.decimalPattern('id').format(v.abs())}';

const debtTypes = ['lend', 'collect', 'borrow', 'repay'];

/// Id of the record whose name matches, ignoring case; '' if none, so the user picks.
String idByName(Iterable<RecordModel> list, Object? name) =>
    list.where((x) => x.getStringValue('name').toLowerCase() == '${name ?? ''}'.toLowerCase()).firstOrNull?.id ?? '';

/// A transaction as saved: fields that don't apply to its type are cleared. Null if something
/// required is missing (amount, account, a different transfer target, a person for debts).
/// Shared by the form and the assistant so both save exactly the same way.
Map<String, Object>? txBody({
  required String date,
  required String type,
  required int amount,
  required String account,
  required String toAccount,
  required String category,
  required String person,
  required String note,
}) {
  final kind = debtTypes.contains(type) ? 'debt' : type;
  if (amount <= 0 ||
      (kind != 'debt' && account.isEmpty) ||
      (kind == 'transfer' && (toAccount.isEmpty || toAccount == account)) ||
      (kind == 'debt' && person.trim().isEmpty)) {
    return null;
  }
  return {
    'date': date,
    'type': type,
    'amount': amount,
    'account': account,
    'to_account': kind == 'transfer' ? toAccount : '',
    'category': kind == 'expense' || kind == 'income' ? category : '',
    'person': kind == 'debt' ? person.trim() : '',
    'note': note.trim(),
  };
}

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

  /// The body for an AI draft (names, not ids): a new transaction, or [base] with only the
  /// draft's fields changed. Null if the result is incomplete, e.g. an unknown account name.
  Map<String, Object>? draftBody(Map<String, dynamic> d, [RecordModel? base]) {
    String old(String k) => base?.getStringValue(k) ?? '';
    final type = d['type'] as String? ?? (base == null ? 'expense' : old('type'));
    String account(String k) => d[k] is String ? idByName(accounts, d[k]) : old(k);
    final date = DateTime.tryParse('${d['date']}');
    return txBody(
      date: date != null ? toPbDate(date) : base != null ? old('date') : toPbDate(dayOnly(DateTime.now())),
      type: type,
      amount: (d['amount'] as num?)?.toInt() ?? base?.getIntValue('amount') ?? 0,
      account: account('account'),
      toAccount: account('to_account'),
      // A category only fits its own kind, so a changed type drops the old one.
      category: d['category'] is String
          ? idByName(categories.where((c) => c.getStringValue('kind') == type), d['category'])
          : type == old('type') ? old('category') : '',
      person: d['person'] as String? ?? old('person'),
      note: d['note'] as String? ?? old('note'),
    );
  }
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
