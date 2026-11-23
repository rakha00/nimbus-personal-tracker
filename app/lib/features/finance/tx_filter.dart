import 'package:pocketbase/pocketbase.dart';

/// What the transaction list shows: one month plus optional kind/account/category/search.
class TxFilter {
  const TxFilter({required this.month, this.kind = '', this.account = '', this.category = '', this.query = ''});

  final DateTime month; // first day of the month
  final String kind; // '' | expense | income | transfer | debt
  final String account; // matches either side of a transfer
  final String category;
  final String query; // note, person or category name

  /// Filters beyond the month, for the badge on the Filter button.
  int get extraCount => [kind, account, category, query].where((s) => s.isNotEmpty).length;

  TxFilter copyWith({DateTime? month, String? kind, String? account, String? category, String? query}) => TxFilter(
        month: month ?? this.month,
        kind: kind ?? this.kind,
        account: account ?? this.account,
        category: category ?? this.category,
        query: query ?? this.query,
      );

  TxFilter cleared() => TxFilter(month: month);

  bool matches(RecordModel r, Map<String, String> categoryNames) {
    final prefix = '${month.year.toString().padLeft(4, '0')}-${month.month.toString().padLeft(2, '0')}';
    if (!r.getStringValue('date').startsWith(prefix)) return false;
    final type = r.getStringValue('type');
    final k = const {'lend', 'collect', 'borrow', 'repay'}.contains(type) ? 'debt' : type;
    if (kind.isNotEmpty && k != kind) return false;
    if (account.isNotEmpty && r.getStringValue('account') != account && r.getStringValue('to_account') != account) {
      return false;
    }
    if (category.isNotEmpty && r.getStringValue('category') != category) return false;
    if (query.isNotEmpty) {
      final hay = [r.getStringValue('note'), r.getStringValue('person'), categoryNames[r.getStringValue('category')] ?? '']
          .join(' ')
          .toLowerCase();
      if (!hay.contains(query.toLowerCase())) return false;
    }
    return true;
  }
}
