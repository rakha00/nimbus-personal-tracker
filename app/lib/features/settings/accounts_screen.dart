import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pocketbase/pocketbase.dart';

import '../../core/backend.dart';
import '../../core/theme.dart';
import '../../l10n/app_localizations.dart';
import '../finance/finance_data.dart';

/// List, add and edit accounts. No delete: old transactions still point at them.
class AccountsScreen extends StatefulWidget {
  const AccountsScreen({super.key});

  @override
  State<AccountsScreen> createState() => _AccountsScreenState();
}

class _AccountsScreenState extends State<AccountsScreen> {
  late Future<FinanceData> data = loadFinance();

  Future<void> edit([RecordModel? a]) async {
    final t = AppLocalizations.of(context);
    final name = TextEditingController(text: a?.getStringValue('name') ?? '');
    final opening = TextEditingController(text: a == null ? '' : '${a.getIntValue('opening_balance')}');
    var type = a?.getStringValue('type') ?? 'bank';
    final saved = await showDialog<bool>(
      context: context,
      builder: (c) => StatefulBuilder(
        builder: (c, setDialog) => AlertDialog(
          title: Text(a == null ? t.newAccount : t.accounts),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            Labeled(t.name, TextField(controller: name, autofocus: true)),
            const SizedBox(height: 12),
            SegmentedButton<String>(
              showSelectedIcon: false,
              segments: [
                ButtonSegment(value: 'cash', label: Text(t.typeCash)),
                ButtonSegment(value: 'bank', label: Text(t.typeBank)),
                ButtonSegment(value: 'ewallet', label: Text(t.typeEwallet)),
              ],
              selected: {type},
              onSelectionChanged: (s) => setDialog(() => type = s.first),
            ),
            const SizedBox(height: 12),
            Labeled(
              t.openingBalance,
              TextField(
                controller: opening,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(prefixText: 'Rp '),
              ),
            ),
          ]),
          actions: [
            TextButton(onPressed: () => Navigator.pop(c, false), child: Text(t.cancel)),
            TextButton(onPressed: () => Navigator.pop(c, name.text.trim().isNotEmpty), child: Text(t.save)),
          ],
        ),
      ),
    );
    if (saved != true) return;
    final body = {
      'owner': userId,
      'name': name.text.trim(),
      'type': type,
      'opening_balance': int.tryParse(opening.text) ?? 0,
    };
    try {
      a == null
          ? await pb.collection('accounts').create(body: body)
          : await pb.collection('accounts').update(a.id, body: body);
      financeChanged();
      setState(() => data = loadFinance());
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t.saveFailed)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(t.accounts)),
      floatingActionButton: FloatingActionButton(onPressed: edit, tooltip: t.newAccount, child: const Icon(Icons.add)),
      body: FutureBuilder(
        future: data,
        builder: (context, snap) {
          if (snap.hasError) return Center(child: Text(t.loadFailed));
          final d = snap.data;
          if (d == null) return const Center(child: CircularProgressIndicator());
          return ListView(padding: const EdgeInsets.fromLTRB(16, 4, 16, 88), children: [
            Card(
              clipBehavior: Clip.antiAlias,
              child: d.accounts.isEmpty
                  ? Padding(padding: const EdgeInsets.all(16), child: Text(t.noAccounts))
                  : Column(children: [
                      for (final (i, a) in d.accounts.indexed) ...[
                        if (i > 0) const Divider(indent: 16, endIndent: 16),
                        ListTile(
                          title: Text(a.getStringValue('name')),
                          subtitle: Text(switch (a.getStringValue('type')) {
                            'cash' => t.typeCash,
                            'ewallet' => t.typeEwallet,
                            _ => t.typeBank,
                          }),
                          trailing: Text(rupiah(d.balance[a.id] ?? 0), style: const TextStyle(fontFeatures: tabular)),
                          onTap: () => edit(a),
                        ),
                      ],
                    ]),
            ),
          ]);
        },
      ),
    );
  }
}
