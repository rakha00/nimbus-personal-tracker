import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pocketbase/pocketbase.dart';

import '../../core/backend.dart';
import '../../core/theme.dart';
import '../../l10n/app_localizations.dart';
import 'debts_screen.dart';
import 'finance_data.dart';
import 'transaction_form.dart';
import 'tx_filter.dart';

/// Answers: how much do I have now, and where did this month's money go?
class FinanceScreen extends StatefulWidget {
  const FinanceScreen({super.key});

  @override
  State<FinanceScreen> createState() => _FinanceScreenState();
}

class _FinanceScreenState extends State<FinanceScreen> {
  late Future<FinanceData> data = loadFinance();
  TxFilter filter = TxFilter(month: DateTime(DateTime.now().year, DateTime.now().month));

  @override
  void initState() {
    super.initState();
    financeVersion.addListener(reload);
  }

  @override
  void dispose() {
    financeVersion.removeListener(reload);
    super.dispose();
  }

  void reload() => setState(() => data = loadFinance());

  Future<void> openForm(FinanceData d, [RecordModel? tx]) => Navigator.push(
      context, MaterialPageRoute(builder: (_) => TransactionForm(data: d, record: tx)));

  void shiftMonth(int by) =>
      setState(() => filter = filter.copyWith(month: DateTime(filter.month.year, filter.month.month + by)));

  Future<void> openFilter(FinanceData d) async {
    final picked = await showModalBottomSheet<TxFilter>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _FilterSheet(data: d, initial: filter),
    );
    if (picked != null) setState(() => filter = picked);
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return FutureBuilder(
      future: data,
      builder: (context, snap) {
        final d = snap.data;
        return Scaffold(
          appBar: AppBar(title: Text(t.finance)),
          floatingActionButton: d == null
              ? null
              : FloatingActionButton(onPressed: () => openForm(d), tooltip: t.add, child: const Icon(Icons.add)),
          body: RefreshIndicator(
            onRefresh: () async {
              reload();
              await data;
            },
            child: switch (snap) {
              _ when snap.hasError => ListView(padding: const EdgeInsets.all(16), children: [
                  _Panel(child: Padding(padding: const EdgeInsets.all(16), child: Text(t.loadFailed))),
                ]),
              _ when d == null => const Center(child: CircularProgressIndicator()),
              _ => _body(context, d),
            },
          ),
        );
      },
    );
  }

  Widget _body(BuildContext context, FinanceData d) {
    final t = AppLocalizations.of(context);
    final l = Ledger.of(context);
    final locale = Localizations.localeOf(context).toString();
    final total = d.balance.values.fold(0, (a, b) => a + b);
    final rows = d.txs.where((r) => filter.matches(r, d.categoryName)).toList();
    int sum(String type) => rows.where((r) => r.getStringValue('type') == type).fold(0, (a, r) => a + r.getIntValue('amount'));
    final moneyIn = sum('income'), moneyOut = sum('expense');

    final children = <Widget>[
      // Balance: the screen's answer, the largest figure on it.
      _Panel(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(t.allAccounts, style: Theme.of(context).textTheme.labelMedium),
            const SizedBox(height: 4),
            Text(rupiah(total),
                style: TextStyle(fontSize: 30, fontWeight: FontWeight.w700, fontFeatures: tabular, color: l.text)),
            const SizedBox(height: 12),
            if (d.accounts.isEmpty) Padding(padding: const EdgeInsets.only(bottom: 8), child: Text(t.noAccounts)),
            for (final a in d.accounts) ...[
              Divider(color: l.rule),
              _Row(a.getStringValue('name'), rupiah(d.balance[a.id] ?? 0), dim: (d.balance[a.id] ?? 0) == 0),
            ],
          ]),
        ),
      ),
      if (d.debts.isNotEmpty) ...[
        const SizedBox(height: 12),
        _DebtsRow(debts: d.debts),
      ],
      const SizedBox(height: 24),
      // Month and filter: one row of controls.
      Row(children: [
        IconButton(onPressed: () => shiftMonth(-1), icon: const Icon(Icons.chevron_left), tooltip: '-1'),
        Expanded(
          child: Text(DateFormat.yMMMM(locale).format(filter.month),
              textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleMedium),
        ),
        IconButton(onPressed: () => shiftMonth(1), icon: const Icon(Icons.chevron_right), tooltip: '+1'),
        const SizedBox(width: 8),
        OutlinedButton.icon(
          onPressed: () => openFilter(d),
          icon: const Icon(Icons.tune, size: 18),
          label: Text(filter.extraCount == 0 ? t.filter : '${t.filter} · ${filter.extraCount}'),
        ),
      ]),
      const SizedBox(height: 8),
      _Panel(
        child: IntrinsicHeight(
          child: Row(children: [
            Expanded(child: _Figure(t.moneyIn, moneyIn == 0 ? rupiah(0) : '+${rupiah(moneyIn)}', color: moneyIn == 0 ? l.muted : l.positive)),
            VerticalDivider(color: l.border, width: 1),
            Expanded(child: _Figure(t.moneyOut, moneyOut == 0 ? rupiah(0) : '-${rupiah(moneyOut)}', color: moneyOut == 0 ? l.muted : l.text)),
          ]),
        ),
      ),
      if (filter.kind.isEmpty || filter.kind == 'expense') ...[
        const SizedBox(height: 12),
        _SpendingCard(rows: rows, categoryName: d.categoryName),
      ],
      const SizedBox(height: 24),
    ];

    if (rows.isEmpty) {
      children.add(_Panel(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(d.txs.isEmpty ? t.noTransactions : t.noMatches, style: TextStyle(color: l.muted)),
        ),
      ));
    }
    // Group by day, newest first; each day is one panel of rows.
    final days = <String, List<RecordModel>>{};
    for (final r in rows) {
      days.putIfAbsent(r.getStringValue('date').substring(0, 10), () => []).add(r);
    }
    for (final MapEntry(key: day, value: list) in days.entries) {
      children.add(Padding(
        padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
        child: Text(DateFormat.MMMMEEEEd(locale).format(fromPbDate(day)), style: Theme.of(context).textTheme.labelMedium),
      ));
      children.add(_Panel(
        child: Column(children: [
          for (final (i, r) in list.indexed) ...[
            if (i > 0) Divider(color: l.rule, indent: 16, endIndent: 16),
            _txTile(context, d, r),
          ],
        ]),
      ));
      children.add(const SizedBox(height: 16));
    }
    children.add(const SizedBox(height: 72)); // room for the add button
    return ListView(padding: const EdgeInsets.fromLTRB(16, 4, 16, 16), children: children);
  }

  Widget _txTile(BuildContext context, FinanceData d, RecordModel r) {
    final t = AppLocalizations.of(context);
    final l = Ledger.of(context);
    final type = r.getStringValue('type');
    final person = r.getStringValue('person');
    final account = d.accountName[r.getStringValue('account')];
    final note = r.getStringValue('note');
    final title = switch (type) {
      'transfer' => '${account ?? '?'} → ${d.accountName[r.getStringValue('to_account')] ?? '?'}',
      'lend' => t.txLend(person),
      'collect' => t.txCollect(person),
      'borrow' => t.txBorrow(person),
      'repay' => t.txRepay(person),
      _ => d.categoryName[r.getStringValue('category')] ?? (note.isEmpty ? t.uncategorized : note),
    };
    final sub = [if (type != 'transfer' && account != null) account, if (note.isNotEmpty && note != title) note];
    final amount = rupiah(r.getIntValue('amount'));
    // Sign carries the direction; green only for money that is really mine coming in.
    final (text, color) = switch (type) {
      'income' || 'collect' => ('+$amount', l.positive),
      'borrow' => ('+$amount', l.text),
      'transfer' => (amount, l.muted),
      _ => ('-$amount', l.text),
    };
    return InkWell(
      onTap: () => openForm(d, r),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(children: [
          if (person.isNotEmpty) ...[PersonAvatar(person, size: 28), const SizedBox(width: 12)],
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
              if (sub.isNotEmpty)
                Text(sub.join(' · '), maxLines: 1, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.bodySmall),
            ]),
          ),
          const SizedBox(width: 12),
          Text(text, style: TextStyle(color: color, fontFeatures: tabular)),
        ]),
      ),
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => Card(clipBehavior: Clip.antiAlias, child: child);
}

class _Row extends StatelessWidget {
  const _Row(this.label, this.value, {this.dim = false});
  final String label, value;
  final bool dim;

  @override
  Widget build(BuildContext context) {
    final l = Ledger.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(children: [
        Expanded(child: Text(label)),
        Text(value, style: TextStyle(fontFeatures: tabular, color: dim ? l.muted : l.text)),
      ]),
    );
  }
}

class _Figure extends StatelessWidget {
  const _Figure(this.label, this.value, {required this.color});
  final String label, value;
  final Color color;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: Theme.of(context).textTheme.labelMedium),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: color, fontFeatures: tabular)),
          ),
        ]),
      );
}

/// Who still owes or is owed: the people, in their own tints, and the total.
class _DebtsRow extends StatelessWidget {
  const _DebtsRow({required this.debts});
  final Map<String, int> debts;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final owed = debts.values.where((v) => v > 0).fold(0, (a, b) => a + b);
    final owing = debts.values.where((v) => v < 0).fold(0, (a, b) => a - b);
    final people = debts.keys.take(4).toList();
    return _Panel(
      child: InkWell(
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => DebtsScreen(debts: debts))),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(children: [
            SizedBox(
              width: 28 + 18.0 * (people.length - 1),
              height: 28,
              child: Stack(children: [
                for (final (i, p) in people.indexed)
                  Positioned(left: 18.0 * i, child: PersonAvatar(p, size: 28)),
              ]),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('${t.receivables} ${rupiah(owed)}', style: const TextStyle(fontFeatures: tabular)),
                Text(
                  [t.peopleOwe(debts.length), if (owing > 0) '${t.payables} ${rupiah(owing)}'].join(' · '),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ]),
            ),
            const Icon(Icons.chevron_right),
          ]),
        ),
      ),
    );
  }
}

/// Where the money went: a ranked list with a thin bar, the top category in the one blue.
class _SpendingCard extends StatelessWidget {
  const _SpendingCard({required this.rows, required this.categoryName});
  final List<RecordModel> rows;
  final Map<String, String> categoryName;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final l = Ledger.of(context);
    final by = <String, int>{};
    for (final r in rows.where((r) => r.getStringValue('type') == 'expense')) {
      final name = categoryName[r.getStringValue('category')] ?? t.uncategorized;
      by[name] = (by[name] ?? 0) + r.getIntValue('amount');
    }
    final ranked = by.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final top = ranked.isEmpty ? 1 : ranked.first.value;
    return _Panel(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(t.spending, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          if (ranked.isEmpty) Text(t.noSpending, style: TextStyle(color: l.muted)),
          for (final (i, e) in ranked.take(5).indexed)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Expanded(child: Text(e.key)),
                  Text(rupiah(e.value), style: const TextStyle(fontFeatures: tabular)),
                ]),
                const SizedBox(height: 6),
                FractionallySizedBox(
                  widthFactor: e.value / top,
                  child: Container(height: 3, color: i == 0 ? l.hue : l.control),
                ),
              ]),
            ),
        ]),
      ),
    );
  }
}

class _FilterSheet extends StatefulWidget {
  const _FilterSheet({required this.data, required this.initial});
  final FinanceData data;
  final TxFilter initial;

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  late TxFilter f = widget.initial;
  late final search = TextEditingController(text: f.query);

  Widget chips(List<(String, String)> options, String selected, TxFilter Function(String) apply) => Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final (id, label) in options)
            ChoiceChip(label: Text(label), selected: id == selected, onSelected: (_) => setState(() => f = apply(id))),
        ],
      );

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final d = widget.data;
    final catKind = f.kind == 'income' ? 'income' : 'expense';
    final hasCategory = f.kind.isEmpty || f.kind == 'expense' || f.kind == 'income';
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 0, 16, 16 + MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text(t.filter, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontSize: 20)),
          const SizedBox(height: 16),
          TextField(
            controller: search,
            decoration: InputDecoration(hintText: t.search, prefixIcon: const Icon(Icons.search, size: 18)),
            onChanged: (v) => f = f.copyWith(query: v.trim()),
          ),
          const SizedBox(height: 16),
          Labeled(
            t.kind,
            chips([
              ('', t.all),
              ('expense', t.expense),
              ('income', t.income),
              ('transfer', t.transfer),
              ('debt', t.debt),
            ], f.kind, (v) => f.copyWith(kind: v, category: '')),
          ),
          const SizedBox(height: 16),
          Labeled(
            t.account,
            chips([('', t.all), for (final a in d.accounts) (a.id, a.getStringValue('name'))], f.account,
                (v) => f.copyWith(account: v)),
          ),
          const SizedBox(height: 16),
          // One fixed-height field whatever the type, so the sheet doesn't jump when the type changes.
          // The list inside follows the type; transfers and debts have no category.
          Labeled(
            t.category,
            DropdownMenu<String>(
              key: ValueKey(f.kind), // reset the shown value when the type changes
              expandedInsets: EdgeInsets.zero,
              enabled: hasCategory,
              initialSelection: hasCategory ? f.category : null,
              hintText: hasCategory ? t.all : t.categoryNotUsed,
              onSelected: (v) => setState(() => f = f.copyWith(category: v ?? '')),
              dropdownMenuEntries: [
                DropdownMenuEntry(value: '', label: t.all),
                for (final c in d.categories)
                  if (f.kind.isEmpty || c.getStringValue('kind') == catKind)
                    DropdownMenuEntry(
                      value: c.id,
                      label: c.getStringValue('name'),
                      trailingIcon: f.kind.isEmpty
                          ? Text(c.getStringValue('kind') == 'income' ? t.income : t.expense,
                              style: Theme.of(context).textTheme.bodySmall)
                          : null,
                    ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Row(children: [
            TextButton(
              onPressed: () => Navigator.pop(context, f.cleared()),
              child: Text(t.reset),
            ),
            const Spacer(),
            FilledButton(onPressed: () => Navigator.pop(context, f.copyWith(query: search.text.trim())), child: Text(t.show)),
          ]),
        ]),
      ),
    );
  }
}
