// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Indonesian (`id`).
class AppLocalizationsId extends AppLocalizations {
  AppLocalizationsId([String locale = 'id']) : super(locale);

  @override
  String get finance => 'Keuangan';

  @override
  String get diary => 'Diary';

  @override
  String get settings => 'Pengaturan';

  @override
  String get totalBalance => 'Total saldo';

  @override
  String get receivables => 'Piutang';

  @override
  String get payables => 'Utang';

  @override
  String get add => 'Tambah';

  @override
  String get save => 'Simpan';

  @override
  String get cancel => 'Batal';

  @override
  String get delete => 'Hapus';

  @override
  String get deleteConfirm => 'Hapus ini?';

  @override
  String get expense => 'Keluar';

  @override
  String get income => 'Masuk';

  @override
  String get transfer => 'Transfer';

  @override
  String get debt => 'Utang/Piutang';

  @override
  String get amount => 'Nominal';

  @override
  String get account => 'Rekening';

  @override
  String get toAccount => 'Ke rekening';

  @override
  String get category => 'Kategori';

  @override
  String get date => 'Tanggal';

  @override
  String get note => 'Catatan (opsional)';

  @override
  String get person => 'Nama orang';

  @override
  String get noAccount => 'Tanpa rekening';

  @override
  String get debtLend => 'Pinjamkan';

  @override
  String get debtCollect => 'Dibayar kembali';

  @override
  String get debtBorrow => 'Pinjam';

  @override
  String get debtRepay => 'Bayar utang';

  @override
  String txLend(String person) {
    return 'Pinjamkan ke $person';
  }

  @override
  String txCollect(String person) {
    return '$person bayar piutang';
  }

  @override
  String txBorrow(String person) {
    return 'Pinjam dari $person';
  }

  @override
  String txRepay(String person) {
    return 'Bayar utang ke $person';
  }

  @override
  String get today => 'Hari ini';

  @override
  String get writeToday => 'Tulis catatan hari ini';

  @override
  String get diaryHint => 'Apa yang terjadi hari ini?';

  @override
  String get language => 'Bahasa';

  @override
  String get accounts => 'Rekening';

  @override
  String get debts => 'Utang-piutang';

  @override
  String get newAccount => 'Rekening baru';

  @override
  String get name => 'Nama';

  @override
  String get openingBalance => 'Saldo awal';

  @override
  String get typeCash => 'Tunai';

  @override
  String get typeBank => 'Bank';

  @override
  String get typeEwallet => 'E-wallet';

  @override
  String get setupTitle => 'Hubungkan ke Nimbus';

  @override
  String get email => 'Email';

  @override
  String get password => 'Password';

  @override
  String get connect => 'Hubungkan';

  @override
  String get loginFailed => 'Gagal masuk. Periksa email dan password.';

  @override
  String get unlock => 'Buka kunci';

  @override
  String get unlockReason => 'Buka Nimbus';

  @override
  String get loadFailed => 'Gagal memuat data. Tarik ke bawah untuk coba lagi.';

  @override
  String get saveFailed => 'Gagal menyimpan. Coba lagi.';

  @override
  String get required => 'Wajib diisi';

  @override
  String get noTransactions => 'Belum ada transaksi';

  @override
  String get noDebts => 'Tidak ada utang-piutang';

  @override
  String get noAccounts => 'Tambahkan rekening dulu di Pengaturan';

  @override
  String get signOut => 'Keluar akun';

  @override
  String get theme => 'Tema';

  @override
  String get themeSystem => 'Ikuti HP';

  @override
  String get themeLight => 'Terang';

  @override
  String get themeDark => 'Gelap';

  @override
  String get appearance => 'Tampilan';

  @override
  String get data => 'Data';

  @override
  String get accountSection => 'Akun';

  @override
  String get filter => 'Filter';

  @override
  String get reset => 'Reset';

  @override
  String get all => 'Semua';

  @override
  String get moneyIn => 'Masuk';

  @override
  String get moneyOut => 'Keluar';

  @override
  String get search => 'Cari catatan atau nama';

  @override
  String get noMatches => 'Tidak ada transaksi yang cocok dengan filter ini';

  @override
  String get spending => 'Pengeluaran per kategori';

  @override
  String get noSpending => 'Belum ada pengeluaran bulan ini';

  @override
  String get allAccounts => 'Total semua rekening';

  @override
  String peopleOwe(int count) {
    return '$count orang';
  }

  @override
  String get signOutHint => 'Email dan password perlu diisi lagi';

  @override
  String get show => 'Tampilkan';

  @override
  String get uncategorized => 'Tanpa kategori';

  @override
  String get diaryEmpty => 'Belum ada catatan';

  @override
  String get kind => 'Jenis';
}
