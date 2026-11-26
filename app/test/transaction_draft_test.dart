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
}
