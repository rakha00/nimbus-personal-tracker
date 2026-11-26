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
  String get themeSystem => 'Sistem';

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

  @override
  String get categoryNotUsed => 'Tidak dipakai untuk jenis ini';

  @override
  String get mediaTab => 'Media';

  @override
  String get mediaWishlist => 'Ingin';

  @override
  String get mediaDone => 'Selesai';

  @override
  String get mediaFilm => 'Film';

  @override
  String get mediaBook => 'Buku';

  @override
  String get mediaTitle => 'Judul';

  @override
  String get mediaDirector => 'Sutradara (opsional)';

  @override
  String get mediaAuthor => 'Penulis (opsional)';

  @override
  String get mediaYear => 'Tahun rilis (opsional)';

  @override
  String get mediaFinishedOn => 'Tanggal selesai';

  @override
  String get mediaRating => 'Rating (opsional)';

  @override
  String get mediaMarkDone => 'Tandai selesai';

  @override
  String get mediaEmptyWishlist => 'Belum ada yang ingin ditonton/dibaca';

  @override
  String get mediaEmptyDone => 'Belum ada yang selesai ditonton/dibaca';

  @override
  String get mediaSearchHint => 'Ketik judul';

  @override
  String get mediaSearchFailed => 'Gagal mencari. Periksa koneksi internet.';

  @override
  String get mediaNoResults => 'Tidak ditemukan';

  @override
  String get mediaManual => 'Isi manual';

  @override
  String get mediaSynopsis => 'Sinopsis';

  @override
  String get mediaFilterHint => 'Cari judul atau pembuat';

  @override
  String get mediaSeries => 'Serial';

  @override
  String get mediaAnime => 'Anime';

  @override
  String get mediaProgress => 'Sedang';

  @override
  String get mediaStart => 'Mulai';

  @override
  String get mediaCreator => 'Pembuat (opsional)';

  @override
  String get mediaStudio => 'Studio (opsional)';

  @override
  String get calendar => 'Kalender';

  @override
  String get calendarEmptyMonth => 'Tidak ada acara bulan ini';

  @override
  String get calendarEventTitle => 'Judul';

  @override
  String get calendarAllDay => 'Seharian';

  @override
  String get calendarTime => 'Jam';

  @override
  String get calendarYearly => 'Ulang tiap tahun';

  @override
  String get calendarReminder => 'Pengingat';

  @override
  String get calendarAllDayReminderHint =>
      'Untuk acara seharian, pengingat dihitung dari jam 08.00.';

  @override
  String get reminderNone => 'Tidak ada';

  @override
  String get reminderAtStart => 'Saat acara mulai';

  @override
  String get reminder10m => '10 menit sebelumnya';

  @override
  String get reminder1h => '1 jam sebelumnya';

  @override
  String get reminder1d => '1 hari sebelumnya';

  @override
  String get calendarHoliday => 'Libur nasional';

  @override
  String get assistant => 'Asisten';

  @override
  String get assistantHint =>
      'mis. kopi 18rb pakai cash, atau: pengeluaran bulan ini?';

  @override
  String get assistantSend => 'Kirim';

  @override
  String get assistantApprove => 'Setuju';

  @override
  String get assistantReject => 'Tolak';

  @override
  String get assistantBefore => 'Sebelumnya';

  @override
  String get assistantNotFound => 'Transaksi tidak ditemukan';

  @override
  String get mediaNotFound => 'Item media tidak ditemukan';

  @override
  String get eventNotFound => 'Acara tidak ditemukan';

  @override
  String get assistantIncomplete => 'Belum lengkap';

  @override
  String get assistantComplete => 'Lengkapi';

  @override
  String get assistantSaved => 'Tersimpan';

  @override
  String get assistantRejected => 'Ditolak';

  @override
  String get assistantRateLimit =>
      'Batas 30 permintaan per jam tercapai. Coba lagi nanti.';

  @override
  String get assistantTimeout => 'Asisten terlalu lama menjawab. Coba lagi.';

  @override
  String get assistantFailed => 'Asisten tidak bisa menjawab. Coba lagi.';
}
