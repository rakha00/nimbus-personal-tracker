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

  @override
  String get mediaTab => 'Media';

  @override
  String get mediaWishlist => 'Want to';

  @override
  String get mediaDone => 'Done';

  @override
  String get mediaFilm => 'Film';

  @override
  String get mediaBook => 'Book';

  @override
  String get mediaTitle => 'Title';

  @override
  String get mediaDirector => 'Director (optional)';

  @override
  String get mediaAuthor => 'Author (optional)';

  @override
  String get mediaYear => 'Year released (optional)';

  @override
  String get mediaFinishedOn => 'Date finished';

  @override
  String get mediaRating => 'Rating (optional)';

  @override
  String get mediaMarkDone => 'Mark as done';

  @override
  String get mediaEmptyWishlist => 'Nothing on your list yet';

  @override
  String get mediaEmptyDone => 'Nothing watched or read yet';

  @override
  String get mediaSearchHint => 'Type a title';

  @override
  String get mediaSearchFailed => 'Search failed. Check your connection.';

  @override
  String get mediaNoResults => 'Nothing found';

  @override
  String get mediaManual => 'Enter manually';

  @override
  String get mediaSynopsis => 'Synopsis';

  @override
  String get mediaFilterHint => 'Search title or creator';

  @override
  String get mediaSeries => 'Series';

  @override
  String get mediaAnime => 'Anime';

  @override
  String get mediaGame => 'Game';

  @override
  String get mediaDeveloper => 'Developer (optional)';

  @override
  String get mediaProgress => 'Ongoing';

  @override
  String get mediaStart => 'Start';

  @override
  String get mediaCreator => 'Creator (optional)';

  @override
  String get mediaStudio => 'Studio (optional)';

  @override
  String get calendar => 'Calendar';

  @override
  String get calendarEmptyMonth => 'No events this month';

  @override
  String get calendarEventTitle => 'Title';

  @override
  String get calendarAllDay => 'All day';

  @override
  String get calendarTime => 'Time';

  @override
  String get calendarYearly => 'Repeat every year';

  @override
  String get calendarReminder => 'Reminder';

  @override
  String get calendarAllDayReminderHint =>
      'For all-day events, reminders count from 08:00.';

  @override
  String get reminderNone => 'None';

  @override
  String get reminderAtStart => 'When it starts';

  @override
  String get reminder10m => '10 minutes before';

  @override
  String get reminder1h => '1 hour before';

  @override
  String get reminder1d => '1 day before';

  @override
  String get calendarHoliday => 'Public holiday';

  @override
  String get assistant => 'Assistant';

  @override
  String get assistantHint =>
      'e.g. coffee 18k cash, or: how much did I spend this month?';

  @override
  String get assistantSend => 'Send';

  @override
  String get assistantApprove => 'Approve';

  @override
  String get assistantReject => 'Reject';

  @override
  String get assistantBefore => 'Before';

  @override
  String get assistantNotFound => 'Transaction not found';

  @override
  String get mediaNotFound => 'Media item not found';

  @override
  String get eventNotFound => 'Event not found';

  @override
  String get assistantIncomplete => 'Incomplete';

  @override
  String get assistantComplete => 'Complete';

  @override
  String get assistantSaved => 'Saved';

  @override
  String get assistantRejected => 'Rejected';

  @override
  String get assistantRateLimit =>
      'Limit of 30 requests an hour reached. Try again later.';

  @override
  String get assistantTimeout => 'The assistant took too long. Try again.';

  @override
  String get assistantFailed => 'The assistant couldn\'t answer. Try again.';
}
