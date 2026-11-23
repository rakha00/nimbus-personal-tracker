import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../l10n/app_localizations.dart';
import 'finance_data.dart';

/// Open debts per person: positive = they owe me (receivable), negative = I owe them.
class DebtsScreen extends StatelessWidget {
  const DebtsScreen({super.key, required this.debts});
  final Map<String, int> debts;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final sorted = debts.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    return Scaffold(
      appBar: AppBar(title: Text(t.debts)),
      body: ListView(padding: const EdgeInsets.fromLTRB(16, 4, 16, 24), children: [
        Card(
          clipBehavior: Clip.antiAlias,
          child: sorted.isEmpty
              ? Padding(padding: const EdgeInsets.all(16), child: Text(t.noDebts))
              : Column(children: [
                  for (final (i, e) in sorted.indexed) ...[
                    if (i > 0) const Divider(indent: 16, endIndent: 16),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(children: [
                        PersonAvatar(e.key),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(e.key),
                            Text(e.value > 0 ? t.receivables : t.payables, style: Theme.of(context).textTheme.bodySmall),
                          ]),
                        ),
                        Text(rupiah(e.value.abs()), style: const TextStyle(fontFeatures: tabular)),
                      ]),
                    ),
                  ],
                ]),
        ),
      ]),
    );
  }
}
