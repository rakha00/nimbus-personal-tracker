import 'package:flutter/material.dart';

import '../../core/backend.dart';
import '../../core/theme.dart';
import '../../l10n/app_localizations.dart';
import '../finance/debts_screen.dart';
import '../finance/finance_data.dart';
import 'accounts_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key, required this.onSignOut});
  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final l = Ledger.of(context);
    Widget section(String title, List<Widget> rows) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
              child: Text(title, style: Theme.of(context).textTheme.labelMedium),
            ),
            Card(
              clipBehavior: Clip.antiAlias,
              child: Column(children: [
                for (final (i, r) in rows.indexed) ...[if (i > 0) const Divider(indent: 16, endIndent: 16), r],
              ]),
            ),
            const SizedBox(height: 24),
          ],
        );
    Widget choice<T>(String label, List<(T, String)> options, T selected, ValueChanged<T> onChanged) => Padding(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            SegmentedButton<T>(
              showSelectedIcon: false,
              segments: [for (final (v, text) in options) ButtonSegment(value: v, label: Text(text))],
              selected: {selected},
              onSelectionChanged: (s) => onChanged(s.first),
            ),
          ]),
        );

    return Scaffold(
      appBar: AppBar(title: Text(t.settings)),
      body: ListView(padding: const EdgeInsets.fromLTRB(16, 4, 16, 24), children: [
        section(t.appearance, [
          choice(t.language, const [('id', 'Indonesia'), ('en', 'English')],
              Localizations.localeOf(context).languageCode, setLocale),
          ListenableBuilder(
            listenable: themeNotifier,
            builder: (context, _) => choice(
              t.theme,
              [(ThemeMode.system, t.themeSystem), (ThemeMode.light, t.themeLight), (ThemeMode.dark, t.themeDark)],
              themeNotifier.value,
              setThemeMode,
            ),
          ),
        ]),
        section(t.data, [
          ListTile(
            leading: const Icon(Icons.account_balance_outlined),
            title: Text(t.accounts),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AccountsScreen())),
          ),
          ListTile(
            leading: const Icon(Icons.people_outline),
            title: Text(t.debts),
            trailing: const Icon(Icons.chevron_right),
            onTap: () async {
              final d = await loadFinance();
              if (context.mounted) {
                Navigator.push(context, MaterialPageRoute(builder: (_) => DebtsScreen(debts: d.debts)));
              }
            },
          ),
        ]),
        section(t.accountSection, [
          ListTile(
            leading: Icon(Icons.logout, color: l.negative),
            title: Text(t.signOut, style: TextStyle(color: l.negative)),
            subtitle: Text(t.signOutHint),
            onTap: () async {
              final yes = await showDialog<bool>(
                context: context,
                builder: (c) => AlertDialog(
                  title: Text('${t.signOut}?'),
                  content: Text(t.signOutHint),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(c, false), child: Text(t.cancel)),
                    TextButton(
                      onPressed: () => Navigator.pop(c, true),
                      child: Text(t.signOut, style: TextStyle(color: l.negative)),
                    ),
                  ],
                ),
              );
              if (yes == true) {
                pb.authStore.clear();
                onSignOut();
              }
            },
          ),
        ]),
        Center(child: Text('Nimbus v0.2', style: Theme.of(context).textTheme.bodySmall)),
      ]),
    );
  }
}
