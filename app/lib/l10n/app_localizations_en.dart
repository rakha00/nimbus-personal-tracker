// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get finance => 'Finance';

  @override
  String get diary => 'Diary';

  @override
  String get settings => 'Settings';

  @override
  String get totalBalance => 'Total balance';

  @override
  String get receivables => 'Receivables';

  @override
  String get payables => 'Debts';

  @override
  String get add => 'Add';

  @override
  String get save => 'Save';

  @override
  String get cancel => 'Cancel';

  @override
  String get delete => 'Delete';

  @override
  String get deleteConfirm => 'Delete this?';

  @override
  String get expense => 'Expense';

  @override
  String get income => 'Income';

  @override
  String get transfer => 'Transfer';

  @override
  String get debt => 'Debt';

  @override
  String get amount => 'Amount';

  @override
  String get account => 'Account';

  @override
  String get toAccount => 'To account';

  @override
  String get category => 'Category';

  @override
  String get date => 'Date';

  @override
  String get note => 'Note (optional)';

  @override
  String get person => 'Person';

  @override
  String get noAccount => 'No account';

  @override
  String get debtLend => 'Lend';

  @override
  String get debtCollect => 'Paid back';

  @override
  String get debtBorrow => 'Borrow';

  @override
  String get debtRepay => 'Pay back';

  @override
  String txLend(String person) {
    return 'Lent to $person';
  }

  @override
  String txCollect(String person) {
    return '$person paid back';
  }

  @override
  String txBorrow(String person) {
    return 'Borrowed from $person';
  }

  @override
  String txRepay(String person) {
    return 'Paid back $person';
  }

  @override
  String get today => 'Today';

  @override
  String get writeToday => 'Write today\'s note';

  @override
  String get diaryHint => 'What happened today?';

  @override
  String get language => 'Language';

  @override
  String get accounts => 'Accounts';

  @override
  String get debts => 'Debts and receivables';

  @override
  String get newAccount => 'New account';

  @override
  String get name => 'Name';

  @override
  String get openingBalance => 'Opening balance';

  @override
  String get typeCash => 'Cash';

  @override
  String get typeBank => 'Bank';

  @override
  String get typeEwallet => 'E-wallet';

  @override
  String get setupTitle => 'Connect to Nimbus';

  @override
  String get email => 'Email';

  @override
  String get password => 'Password';

  @override
  String get connect => 'Connect';

  @override
  String get loginFailed => 'Couldn\'t sign in. Check your email and password.';

  @override
  String get unlock => 'Unlock';

  @override
  String get unlockReason => 'Unlock Nimbus';

  @override
  String get loadFailed => 'Couldn\'t load data. Pull down to try again.';

  @override
  String get saveFailed => 'Couldn\'t save. Try again.';

  @override
  String get required => 'Required';

  @override
  String get noTransactions => 'No transactions yet';

  @override
  String get noDebts => 'No open debts';

  @override
  String get noAccounts => 'Add an account first in Settings';

  @override
  String get signOut => 'Sign out';

  @override
  String get theme => 'Theme';

  @override
  String get themeSystem => 'System';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get appearance => 'Appearance';

  @override
  String get data => 'Data';

  @override
  String get accountSection => 'Account';

  @override
  String get filter => 'Filter';

  @override
  String get reset => 'Reset';

  @override
  String get all => 'All';

  @override
  String get moneyIn => 'In';

  @override
  String get moneyOut => 'Out';

  @override
  String get search => 'Search notes or names';

  @override
  String get noMatches => 'No transactions match these filters';

  @override
  String get spending => 'Spending by category';

  @override
  String get noSpending => 'No spending this month';

  @override
  String get allAccounts => 'Total across accounts';

  @override
  String peopleOwe(int count) {
    return '$count people';
  }

  @override
  String get signOutHint => 'You\'ll need your email and password again';

  @override
  String get show => 'Show';

  @override
  String get uncategorized => 'Uncategorized';

  @override
  String get diaryEmpty => 'Nothing written yet';

  @override
  String get kind => 'Type';

  @override
  String get categoryNotUsed => 'Not used for this type';
}
