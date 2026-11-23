import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pocketbase/pocketbase.dart';

import '../../core/backend.dart';
import '../../core/theme.dart';
import '../../l10n/app_localizations.dart';
import 'finance_data.dart';

const _debtTypes = ['lend', 'collect', 'borrow', 'repay'];

/// Add or edit one transaction. The "debt" tab covers lend/collect/borrow/repay.
class TransactionForm extends StatefulWidget {
  const TransactionForm({super.key, required this.data, this.record});
  final FinanceData data;
  final RecordModel? record;

  @override
  State<TransactionForm> createState() => _TransactionFormState();
}

class _TransactionFormState extends State<TransactionForm> {
  late final r = widget.record;
  late String type = r?.getStringValue('type') ?? 'expense';
  late final amount = TextEditingController(text: r == null ? '' : '${r!.getIntValue('amount')}');
  late String account = r?.getStringValue('account') ??
      (widget.data.accounts.isEmpty ? '' : widget.data.accounts.first.id);
  late String toAccount = r?.getStringValue('to_account') ?? '';
  late String category = r?.getStringValue('category') ?? '';
  late String person = r?.getStringValue('person') ?? '';
  late final note = TextEditingController(text: r?.getStringValue('note') ?? '');
  late DateTime date = r == null ? dayOnly(DateTime.now()) : fromPbDate(r!.getStringValue('date'));
  bool busy = false;
  String? error;

  String get kind => _debtTypes.contains(type) ? 'debt' : type;

  Future<void> save() async {
    final t = AppLocalizations.of(context);
    final value = int.tryParse(amount.text) ?? 0;
    final missing = value <= 0 ||
        (kind != 'debt' && account.isEmpty) ||
        (kind == 'transfer' && (toAccount.isEmpty || toAccount == account)) ||
        (kind == 'debt' && person.trim().isEmpty);
    if (missing) return setState(() => error = t.required);

    final body = {
      'owner': userId,
      'date': toPbDate(date),
      'type': type,
      'amount': value,
      'account': account,
      'to_account': kind == 'transfer' ? toAccount : '',
      'category': kind == 'expense' || kind == 'income' ? category : '',
      'person': kind == 'debt' ? person.trim() : '',
      'note': note.text.trim(),
    };
    await _run(() => r == null
        ? pb.collection('transactions').create(body: body)
        : pb.collection('transactions').update(r!.id, body: body));
  }

  Future<void> delete() async {
    final t = AppLocalizations.of(context);
    final yes = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(t.deleteConfirm),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: Text(t.cancel)),
          TextButton(onPressed: () => Navigator.pop(c, true), child: Text(t.delete)),
        ],
      ),
    );
    if (yes == true) await _run(() => pb.collection('transactions').delete(r!.id));
  }

  Future<void> _run(Future<Object?> Function() call) async {
    setState(() => busy = true);
    try {
      await call();
      financeChanged();
      if (mounted) Navigator.pop(context);
    } catch (_) {
      if (mounted) setState(() => error = AppLocalizations.of(context).saveFailed);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Widget chips(List<(String, String)> options, String selected, ValueChanged<String> onSelect) => Wrap(
        spacing: 8,
        runSpacing: 4,
        children: [
          for (final (id, label) in options)
            ChoiceChip(label: Text(label), selected: id == selected, onSelected: (_) => setState(() => onSelect(id))),
        ],
      );

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final d = widget.data;
    final label = Theme.of(context).textTheme.labelLarge;
    final accounts = [for (final a in d.accounts) (a.id, a.getStringValue('name'))];
    final categories = [
      for (final c in d.categories)
        if (c.getStringValue('kind') == kind) (c.id, c.getStringValue('name')),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(r == null ? t.add : ''),
        actions: [
          if (r != null) IconButton(onPressed: busy ? null : delete, icon: const Icon(Icons.delete_outline), tooltip: t.delete),
          TextButton(onPressed: busy ? null : save, child: Text(t.save)),
        ],
      ),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        SegmentedButton<String>(
          showSelectedIcon: false,
          segments: [
            ButtonSegment(value: 'expense', label: Text(t.expense)),
            ButtonSegment(value: 'income', label: Text(t.income)),
            ButtonSegment(value: 'transfer', label: Text(t.transfer)),
            ButtonSegment(value: 'debt', label: Text(t.debt)),
          ],
          selected: {kind},
          onSelectionChanged: (s) => setState(() {
            type = s.first == 'debt' ? 'lend' : s.first;
            category = '';
          }),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: amount,
          autofocus: r == null,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w700, fontFeatures: tabular),
          decoration: const InputDecoration(prefixText: 'Rp ', hintText: '0', border: InputBorder.none, enabledBorder: InputBorder.none, focusedBorder: InputBorder.none, filled: false),
          onChanged: (_) => setState(() {}),
        ),
        if ((int.tryParse(amount.text) ?? 0) > 0)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(rupiah(int.parse(amount.text)), textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodySmall),
          ),
        if (kind == 'debt') ...[
          const SizedBox(height: 16),
          chips([
            ('lend', t.debtLend),
            ('collect', t.debtCollect),
            ('borrow', t.debtBorrow),
            ('repay', t.debtRepay),
          ], type, (v) => type = v),
          const SizedBox(height: 12),
          Autocomplete<String>(
            initialValue: TextEditingValue(text: person),
            optionsBuilder: (v) => d.persons.where((p) => p.toLowerCase().contains(v.text.toLowerCase())),
            onSelected: (v) => person = v,
            fieldViewBuilder: (context, controller, focus, _) => Labeled(
              t.person,
              TextField(
                controller: controller,
                focusNode: focus,
                textCapitalization: TextCapitalization.words,
                onChanged: (v) => person = v,
              ),
            ),
          ),
        ],
        const SizedBox(height: 16),
        Text(kind == 'transfer' ? '${t.account} (${t.transfer})' : t.account, style: label),
        const SizedBox(height: 4),
        chips([if (kind == 'debt') ('', t.noAccount), ...accounts], account, (v) => account = v),
        if (kind == 'transfer') ...[
          const SizedBox(height: 12),
          Text(t.toAccount, style: label),
          const SizedBox(height: 4),
          chips(accounts.where((a) => a.$1 != account).toList(), toAccount, (v) => toAccount = v),
        ],
        if (categories.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(t.category, style: label),
          const SizedBox(height: 4),
          chips(categories, category, (v) => category = v == category ? '' : v),
        ],
        const SizedBox(height: 12),
        const SizedBox(height: 4),
        Labeled(t.date, OutlinedButton.icon(
          style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(44), alignment: Alignment.centerLeft),
          icon: const Icon(Icons.calendar_today_outlined, size: 18),
          label: Text(DateFormat.yMMMMEEEEd(Localizations.localeOf(context).toString()).format(date)),
          onPressed: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: date,
              firstDate: DateTime(2000),
              lastDate: DateTime.now().add(const Duration(days: 365)),
            );
            if (picked != null) setState(() => date = picked);
          },
        )),
        const SizedBox(height: 16),
        Labeled(t.note, TextField(controller: note, maxLength: 500)),
        if (error != null) Text(error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
      ]),
    );
  }
}
