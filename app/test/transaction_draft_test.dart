import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nimbus/features/finance/finance_data.dart';
import 'package:nimbus/features/finance/transaction_form.dart';
import 'package:nimbus/l10n/app_localizations.dart';
import 'package:pocketbase/pocketbase.dart';

void main() {
  RecordModel rec(String id, Map<String, dynamic> data) => RecordModel.fromJson({'id': id, ...data});
  final data = FinanceData(
    [rec('acc1', {'name': 'BCA'}), rec('acc2', {'name': 'Cash'})],
    [rec('cat1', {'name': 'Makan & Minum', 'kind': 'expense'}), rec('cat2', {'name': 'Gaji', 'kind': 'income'})],
    [],
  );

  Future<void> pump(WidgetTester tester, Map<String, dynamic> draft) => tester.pumpWidget(MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: TransactionForm(data: data, draft: draft),
      ));

  bool selected(WidgetTester tester, String label) =>
      tester.widget<ChoiceChip>(find.widgetWithText(ChoiceChip, label)).selected;

  testWidgets('an AI draft fills the form, matching names regardless of case', (tester) async {
    await pump(tester, {'type': 'expense', 'amount': 25000, 'date': '2026-11-25', 'account': 'cash', 'category': 'makan & minum', 'note': 'Makan siang'});
    expect(find.text('25000'), findsOneWidget);
    expect(find.text('Makan siang'), findsOneWidget);
    expect(selected(tester, 'Cash'), isTrue);
    expect(selected(tester, 'BCA'), isFalse);
    expect(selected(tester, 'Makan & Minum'), isTrue);
  });

  testWidgets('unknown or missing names are left for the user to pick', (tester) async {
    await pump(tester, {'type': 'expense', 'amount': 30000, 'date': '2026-11-25', 'category': 'Gaji'}); // income category
    expect(selected(tester, 'Cash'), isFalse);
    expect(selected(tester, 'BCA'), isFalse);
    expect(selected(tester, 'Makan & Minum'), isFalse);
  });

  group('draftBody (what Approve saves)', () {
    final base = rec('tx1', {
      'date': '2026-11-20 00:00:00.000Z', 'type': 'expense', 'amount': 25000,
      'account': 'acc2', 'to_account': '', 'category': 'cat1', 'person': '', 'note': 'Makan siang',
    });

    test('a complete new transaction', () {
      expect(data.draftBody({'type': 'expense', 'amount': 18000, 'date': '2026-11-26', 'account': 'cash', 'category': 'Makan & Minum', 'note': 'kopi'}), {
        'date': '2026-11-26 00:00:00.000Z', 'type': 'expense', 'amount': 18000, 'account': 'acc2',
        'to_account': '', 'category': 'cat1', 'person': '', 'note': 'kopi',
      });
    });

    test('an unknown account or no amount cannot be approved', () {
      expect(data.draftBody({'type': 'expense', 'amount': 18000, 'account': 'Dana'}), isNull);
      expect(data.draftBody({'type': 'expense', 'account': 'Cash'}), isNull);
    });

    test('an update changes only the given fields', () {
      final b = data.draftBody({'amount': 30000, 'account': 'BCA'}, base)!;
      expect([b['amount'], b['account'], b['category'], b['date'], b['note']],
          [30000, 'acc1', 'cat1', '2026-11-20 00:00:00.000Z', 'Makan siang']);
    });

    test('changing the type drops a category of the other kind', () {
      expect(data.draftBody({'type': 'income'}, base)!['category'], '');
      expect(data.draftBody({'type': 'transfer', 'to_account': 'Cash'}, base), isNull); // same account
    });
  });
}
