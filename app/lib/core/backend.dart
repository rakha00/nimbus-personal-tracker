import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:pocketbase/pocketbase.dart';

/// Set at build time: `flutter build apk --dart-define-from-file=config.json` (see config.example.json).
const serverUrl = String.fromEnvironment('NIMBUS_SERVER');

const storage = FlutterSecureStorage();
late final PocketBase pb;

/// Current UI language, persisted in secure storage.
final localeNotifier = ValueNotifier(const Locale('id'));

Future<void> initBackend() async {
  assert(serverUrl.isNotEmpty, 'NIMBUS_SERVER is not set; build with --dart-define-from-file=config.json');
  pb = PocketBase(
    serverUrl,
    authStore: AsyncAuthStore(
      save: (data) => storage.write(key: 'pb_auth', value: data),
      initial: await storage.read(key: 'pb_auth'),
      clear: () => storage.delete(key: 'pb_auth'),
    ),
  );
  final code = await storage.read(key: 'locale');
  if (code != null) localeNotifier.value = Locale(code);
  final theme = await storage.read(key: 'theme');
  themeNotifier.value = ThemeMode.values.firstWhere((m) => m.name == theme, orElse: () => ThemeMode.system);
}

Future<void> setLocale(String code) async {
  localeNotifier.value = Locale(code);
  await storage.write(key: 'locale', value: code);
}

/// Light, dark, or follow the phone. Persisted like the language.
final themeNotifier = ValueNotifier(ThemeMode.system);

Future<void> setThemeMode(ThemeMode mode) async {
  themeNotifier.value = mode;
  await storage.write(key: 'theme', value: mode.name);
}

String get userId => pb.authStore.record!.id;

/// PocketBase stores dates as UTC datetimes; we only care about the calendar day.
String toPbDate(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')} 00:00:00.000Z';

DateTime fromPbDate(String s) => DateTime.parse(s.substring(0, 10));

DateTime dayOnly(DateTime d) => DateTime(d.year, d.month, d.day);
