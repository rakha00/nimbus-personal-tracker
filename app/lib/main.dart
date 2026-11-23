import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/backend.dart';
import 'core/theme.dart';
import 'features/auth/lock_gate.dart';
import 'features/auth/setup_screen.dart';
import 'features/diary/diary_screen.dart';
import 'features/finance/finance_screen.dart';
import 'features/settings/settings_screen.dart';
import 'l10n/app_localizations.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initBackend();
  runApp(const NimbusApp());
}

class NimbusApp extends StatelessWidget {
  const NimbusApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([localeNotifier, themeNotifier]),
      builder: (context, _) => MaterialApp(
        title: 'Nimbus',
        theme: buildTheme(Ledger.light),
        darkTheme: buildTheme(Ledger.darkTheme),
        themeMode: themeNotifier.value,
        locale: localeNotifier.value,
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: const Root(),
      ),
    );
  }
}

/// Setup once (server login), then every launch goes through the device lock.
class Root extends StatefulWidget {
  const Root({super.key});

  @override
  State<Root> createState() => _RootState();
}

class _RootState extends State<Root> {
  @override
  Widget build(BuildContext context) {
    if (!pb.authStore.isValid) return SetupScreen(onDone: () => setState(() {}));
    return LockGate(child: HomeShell(onSignOut: () => setState(() {})));
  }
}

class HomeShell extends StatefulWidget {
  const HomeShell({super.key, required this.onSignOut});
  final VoidCallback onSignOut;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int tab = 0;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final l = Ledger.of(context);
    return Scaffold(
      body: IndexedStack(index: tab, children: [
        const FinanceScreen(),
        const DiaryScreen(),
        SettingsScreen(onSignOut: widget.onSignOut),
      ]),
      bottomNavigationBar: DecoratedBox(
        decoration: BoxDecoration(border: Border(top: BorderSide(color: l.border))),
        child: NavigationBar(
          selectedIndex: tab,
          onDestinationSelected: (i) => setState(() => tab = i),
          destinations: [
            NavigationDestination(icon: const Icon(Icons.account_balance_wallet_outlined), label: t.finance),
            NavigationDestination(icon: const Icon(Icons.book_outlined), label: t.diary),
            NavigationDestination(icon: const Icon(Icons.settings_outlined), label: t.settings),
          ],
        ),
      ),
    );
  }
}
