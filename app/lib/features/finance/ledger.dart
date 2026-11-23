/// Pure balance math, kept free of Flutter/PocketBase so it's easy to test.
library;

class Tx {
  final String type; // income|expense|transfer|lend|collect|borrow|repay
  final int amount;
  final String account; // '' = not tied to an account (debt from before tracking)
  final String toAccount;
  final String person;

  const Tx(this.type, this.amount, {this.account = '', this.toAccount = '', this.person = ''});
}

/// Sign of a transaction on its `account`: money in = +1, money out = -1.
int accountSign(String type) => switch (type) {
      'income' || 'collect' || 'borrow' => 1,
      _ => -1, // expense, transfer (source side), lend, repay
    };

/// Balance per account id, starting from each account's opening balance.
Map<String, int> balances(Map<String, int> opening, Iterable<Tx> txs) {
  final b = Map<String, int>.of(opening);
  for (final t in txs) {
    if (b.containsKey(t.account)) b[t.account] = b[t.account]! + accountSign(t.type) * t.amount;
    if (t.type == 'transfer' && b.containsKey(t.toAccount)) b[t.toAccount] = b[t.toAccount]! + t.amount;
  }
  return b;
}

/// Outstanding debt per person: positive = they owe me, negative = I owe them. Settled people are dropped.
Map<String, int> debtsByPerson(Iterable<Tx> txs) {
  final d = <String, int>{};
  for (final t in txs) {
    final delta = switch (t.type) {
      'lend' || 'repay' => t.amount,
      'collect' || 'borrow' => -t.amount,
      _ => 0,
    };
    if (delta != 0) d[t.person] = (d[t.person] ?? 0) + delta;
  }
  d.removeWhere((_, v) => v == 0);
  return d;
}
