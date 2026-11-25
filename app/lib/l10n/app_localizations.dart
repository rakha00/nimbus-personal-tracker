import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_id.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('id'),
  ];

  /// No description provided for @finance.
  ///
  /// In en, this message translates to:
  /// **'Finance'**
  String get finance;

  /// No description provided for @diary.
  ///
  /// In en, this message translates to:
  /// **'Diary'**
  String get diary;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @totalBalance.
  ///
  /// In en, this message translates to:
  /// **'Total balance'**
  String get totalBalance;

  /// No description provided for @receivables.
  ///
  /// In en, this message translates to:
  /// **'Receivables'**
  String get receivables;

  /// No description provided for @payables.
  ///
  /// In en, this message translates to:
  /// **'Debts'**
  String get payables;

  /// No description provided for @add.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @deleteConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete this?'**
  String get deleteConfirm;

  /// No description provided for @expense.
  ///
  /// In en, this message translates to:
  /// **'Expense'**
  String get expense;

  /// No description provided for @income.
  ///
  /// In en, this message translates to:
  /// **'Income'**
  String get income;

  /// No description provided for @transfer.
  ///
  /// In en, this message translates to:
  /// **'Transfer'**
  String get transfer;

  /// No description provided for @debt.
  ///
  /// In en, this message translates to:
  /// **'Debt'**
  String get debt;

  /// No description provided for @amount.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get amount;

  /// No description provided for @account.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get account;

  /// No description provided for @toAccount.
  ///
  /// In en, this message translates to:
  /// **'To account'**
  String get toAccount;

  /// No description provided for @category.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get category;

  /// No description provided for @date.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get date;

  /// No description provided for @note.
  ///
  /// In en, this message translates to:
  /// **'Note (optional)'**
  String get note;

  /// No description provided for @person.
  ///
  /// In en, this message translates to:
  /// **'Person'**
  String get person;

  /// No description provided for @noAccount.
  ///
  /// In en, this message translates to:
  /// **'No account'**
  String get noAccount;

  /// No description provided for @debtLend.
  ///
  /// In en, this message translates to:
  /// **'Lend'**
  String get debtLend;

  /// No description provided for @debtCollect.
  ///
  /// In en, this message translates to:
  /// **'Paid back'**
  String get debtCollect;

  /// No description provided for @debtBorrow.
  ///
  /// In en, this message translates to:
  /// **'Borrow'**
  String get debtBorrow;

  /// No description provided for @debtRepay.
  ///
  /// In en, this message translates to:
  /// **'Pay back'**
  String get debtRepay;

  /// No description provided for @txLend.
  ///
  /// In en, this message translates to:
  /// **'Lent to {person}'**
  String txLend(String person);

  /// No description provided for @txCollect.
  ///
  /// In en, this message translates to:
  /// **'{person} paid back'**
  String txCollect(String person);

  /// No description provided for @txBorrow.
  ///
  /// In en, this message translates to:
  /// **'Borrowed from {person}'**
  String txBorrow(String person);

  /// No description provided for @txRepay.
  ///
  /// In en, this message translates to:
  /// **'Paid back {person}'**
  String txRepay(String person);

  /// No description provided for @today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;

  /// No description provided for @writeToday.
  ///
  /// In en, this message translates to:
  /// **'Write today\'s note'**
  String get writeToday;

  /// No description provided for @diaryHint.
  ///
  /// In en, this message translates to:
  /// **'What happened today?'**
  String get diaryHint;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @accounts.
  ///
  /// In en, this message translates to:
  /// **'Accounts'**
  String get accounts;

  /// No description provided for @debts.
  ///
  /// In en, this message translates to:
  /// **'Debts and receivables'**
  String get debts;

  /// No description provided for @newAccount.
  ///
  /// In en, this message translates to:
  /// **'New account'**
  String get newAccount;

  /// No description provided for @name.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get name;

  /// No description provided for @openingBalance.
  ///
  /// In en, this message translates to:
  /// **'Opening balance'**
  String get openingBalance;

  /// No description provided for @typeCash.
  ///
  /// In en, this message translates to:
  /// **'Cash'**
  String get typeCash;

  /// No description provided for @typeBank.
  ///
  /// In en, this message translates to:
  /// **'Bank'**
  String get typeBank;

  /// No description provided for @typeEwallet.
  ///
  /// In en, this message translates to:
  /// **'E-wallet'**
  String get typeEwallet;

  /// No description provided for @setupTitle.
  ///
  /// In en, this message translates to:
  /// **'Connect to Nimbus'**
  String get setupTitle;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @connect.
  ///
  /// In en, this message translates to:
  /// **'Connect'**
  String get connect;

  /// No description provided for @loginFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t sign in. Check your email and password.'**
  String get loginFailed;

  /// No description provided for @unlock.
  ///
  /// In en, this message translates to:
  /// **'Unlock'**
  String get unlock;

  /// No description provided for @unlockReason.
  ///
  /// In en, this message translates to:
  /// **'Unlock Nimbus'**
  String get unlockReason;

  /// No description provided for @loadFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load data. Pull down to try again.'**
  String get loadFailed;

  /// No description provided for @saveFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t save. Try again.'**
  String get saveFailed;

  /// No description provided for @required.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get required;

  /// No description provided for @noTransactions.
  ///
  /// In en, this message translates to:
  /// **'No transactions yet'**
  String get noTransactions;

  /// No description provided for @noDebts.
  ///
  /// In en, this message translates to:
  /// **'No open debts'**
  String get noDebts;

  /// No description provided for @noAccounts.
  ///
  /// In en, this message translates to:
  /// **'Add an account first in Settings'**
  String get noAccounts;

  /// No description provided for @signOut.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get signOut;

  /// No description provided for @theme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get theme;

  /// No description provided for @themeSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get themeSystem;

  /// No description provided for @themeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeDark;

  /// No description provided for @appearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get appearance;

  /// No description provided for @data.
  ///
  /// In en, this message translates to:
  /// **'Data'**
  String get data;

  /// No description provided for @accountSection.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get accountSection;

  /// No description provided for @filter.
  ///
  /// In en, this message translates to:
  /// **'Filter'**
  String get filter;

  /// No description provided for @reset.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get reset;

  /// No description provided for @all.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get all;

  /// No description provided for @moneyIn.
  ///
  /// In en, this message translates to:
  /// **'In'**
  String get moneyIn;

  /// No description provided for @moneyOut.
  ///
  /// In en, this message translates to:
  /// **'Out'**
  String get moneyOut;

  /// No description provided for @search.
  ///
  /// In en, this message translates to:
  /// **'Search notes or names'**
  String get search;

  /// No description provided for @noMatches.
  ///
  /// In en, this message translates to:
  /// **'No transactions match these filters'**
  String get noMatches;

  /// No description provided for @spending.
  ///
  /// In en, this message translates to:
  /// **'Spending by category'**
  String get spending;

  /// No description provided for @noSpending.
  ///
  /// In en, this message translates to:
  /// **'No spending this month'**
  String get noSpending;

  /// No description provided for @allAccounts.
  ///
  /// In en, this message translates to:
  /// **'Total across accounts'**
  String get allAccounts;

  /// No description provided for @peopleOwe.
  ///
  /// In en, this message translates to:
  /// **'{count} people'**
  String peopleOwe(int count);

  /// No description provided for @signOutHint.
  ///
  /// In en, this message translates to:
  /// **'You\'ll need your email and password again'**
  String get signOutHint;

  /// No description provided for @show.
  ///
  /// In en, this message translates to:
  /// **'Show'**
  String get show;

  /// No description provided for @uncategorized.
  ///
  /// In en, this message translates to:
  /// **'Uncategorized'**
  String get uncategorized;

  /// No description provided for @diaryEmpty.
  ///
  /// In en, this message translates to:
  /// **'Nothing written yet'**
  String get diaryEmpty;

  /// No description provided for @kind.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get kind;

  /// No description provided for @categoryNotUsed.
  ///
  /// In en, this message translates to:
  /// **'Not used for this type'**
  String get categoryNotUsed;

  /// No description provided for @mediaTab.
  ///
  /// In en, this message translates to:
  /// **'Media'**
  String get mediaTab;

  /// No description provided for @mediaWishlist.
  ///
  /// In en, this message translates to:
  /// **'Want to'**
  String get mediaWishlist;

  /// No description provided for @mediaDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get mediaDone;

  /// No description provided for @mediaFilm.
  ///
  /// In en, this message translates to:
  /// **'Film'**
  String get mediaFilm;

  /// No description provided for @mediaBook.
  ///
  /// In en, this message translates to:
  /// **'Book'**
  String get mediaBook;

  /// No description provided for @mediaTitle.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get mediaTitle;

  /// No description provided for @mediaDirector.
  ///
  /// In en, this message translates to:
  /// **'Director (optional)'**
  String get mediaDirector;

  /// No description provided for @mediaAuthor.
  ///
  /// In en, this message translates to:
  /// **'Author (optional)'**
  String get mediaAuthor;

  /// No description provided for @mediaYear.
  ///
  /// In en, this message translates to:
  /// **'Year released (optional)'**
  String get mediaYear;

  /// No description provided for @mediaFinishedOn.
  ///
  /// In en, this message translates to:
  /// **'Date finished'**
  String get mediaFinishedOn;

  /// No description provided for @mediaRating.
  ///
  /// In en, this message translates to:
  /// **'Rating (optional)'**
  String get mediaRating;

  /// No description provided for @mediaMarkDone.
  ///
  /// In en, this message translates to:
  /// **'Mark as done'**
  String get mediaMarkDone;

  /// No description provided for @mediaEmptyWishlist.
  ///
  /// In en, this message translates to:
  /// **'Nothing on your list yet'**
  String get mediaEmptyWishlist;

  /// No description provided for @mediaEmptyDone.
  ///
  /// In en, this message translates to:
  /// **'Nothing watched or read yet'**
  String get mediaEmptyDone;

  /// No description provided for @mediaSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Type a title'**
  String get mediaSearchHint;

  /// No description provided for @mediaSearchFailed.
  ///
  /// In en, this message translates to:
  /// **'Search failed. Check your connection.'**
  String get mediaSearchFailed;

  /// No description provided for @mediaNoResults.
  ///
  /// In en, this message translates to:
  /// **'Nothing found'**
  String get mediaNoResults;

  /// No description provided for @mediaManual.
  ///
  /// In en, this message translates to:
  /// **'Enter manually'**
  String get mediaManual;

  /// No description provided for @mediaSynopsis.
  ///
  /// In en, this message translates to:
  /// **'Synopsis'**
  String get mediaSynopsis;

  /// No description provided for @mediaFilterHint.
  ///
  /// In en, this message translates to:
  /// **'Search title or creator'**
  String get mediaFilterHint;

  /// No description provided for @mediaSeries.
  ///
  /// In en, this message translates to:
  /// **'Series'**
  String get mediaSeries;

  /// No description provided for @mediaAnime.
  ///
  /// In en, this message translates to:
  /// **'Anime'**
  String get mediaAnime;

  /// No description provided for @mediaProgress.
  ///
  /// In en, this message translates to:
  /// **'Ongoing'**
  String get mediaProgress;

  /// No description provided for @mediaStart.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get mediaStart;

  /// No description provided for @mediaCreator.
  ///
  /// In en, this message translates to:
  /// **'Creator (optional)'**
  String get mediaCreator;

  /// No description provided for @mediaStudio.
  ///
  /// In en, this message translates to:
  /// **'Studio (optional)'**
  String get mediaStudio;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'id'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'id':
      return AppLocalizationsId();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
